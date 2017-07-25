# USB drivers

This library acts as a wrapper around the imp API **hardware.usb** object and manages USB device connections, disconnections, transfers and driver selection.

**To use this library add the following statement to the top of your device code:**

```
#require "USB.device.lib.nut:0.1.0"
```

## USB.Host

The *USB.Host* class provides methods that allow you to subscribe to events and register drivers. Please see [USB.DriverBase](#USBDriver) for more details on USB drivers.

## Class Usage

### Constructor: USB.Host(*usb[, autoConfigPins]*)

The constructor takes **hardware.usb** as a required parameter and an optional boolean flag which you to use to indicate whether the constructor should dedicate pins R and W to USB, which is the required configuration for the imp005. For more information, please see [the imp005 pin mux](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb). By default, *autoConfigPins* is `true`.

#### Example

```squirrel
usbHost <- USB.Host(hardware.usb);
```

## Class Methods

### registerDriver(*driverClass, identifiers*)

This method registers a driver by adding it to a list of VID/PID combinations. When a device is connected via USB its VID/PID combination will be looked up in the list and the matching driver will be instantiated to provide an interface to the connected device.

| Parameter     | Data Type | Required | Description |
| --- | --- | --- | --- |
| *driverClass* | Class     | Yes      | A reference to the class to be instantiated when a device with matching identifiers is connected. Must be a valid usb driver class that extends the *USB.DriverBase* class |
| *identifiers* | Array     | Yes      | An array of VID/PID combinations. When a device connected that identifies itself with any of the PID/VID combinations provided, the *driverClass* will be instantiated automatically |

#### Example

```squirrel
// Register the FTDI driver with USB host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());
```

### getDriver()

This method returns the driver for the currently connected device. It returns `null` if no device is connected or a corresponding driver for the device was not found.

#### Example

```squirrel
// Register the FTDI driver with USB host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

// Check if a recognized usb device is connected in 30 seconds
imp.wakeup(30, function() {
    local driver = usbHost.getDriver();
    if (driver != null) {
        server.log(typeof driver);
       // Do something with driver here
    }
}.bindenv(this));
```

### on(*eventName, callback*)

This method binds a callback function to a named event. There are currently two events that you can subscribe to: `"connected"` and `"disconnected"`.

| Parameter   | Data Type | Required | Description |
| --- | --- | --- | --- |
| *eventName* | String    | Yes      | The string name of the event to subscribe to |
| *callback*  | Function  | Yes      | Function to be called on event |

#### Example

```squirrel
// Subscribe to USB connection events
usbHost.on("connected", function (device) {
    local dt = typeof device;
    server.log(dt + " was connected");
    switch (dt) {
        case "FtdiUsbDriver":
            // Device is a FTDI device. Handle it here.
            break;
    }
});

// Subscribe to USB disconnection events
usbHost.on("disconnected", function(deviceName) {
    server.log(deviceName + " disconnected");
});

```

#### off(*eventName*)

This method clears any callback function that has been bound to a specific event.

| Parameter   | Data Type | Required | Description |
| --- | --- | --- | --- |
| *eventName* | String    | Yes      | The string name of the event to unsubscribe from |

#### Example

```squirrel
// Subscribe to USB connection events
usbHost.on("connected", function (device) {
    local dt = typeof device;
    server.log(dt + " was connected");
    switch (dt) {
        case "FtdiUsbDriver":
            // Device is a FTDI device. Handle it here.
            break;
    }
});

// Unsubscribe from USB connection events after 30 seconds
imp.wakeup(30, function(){
    usbHost.off("connected");
}.bindenv(this));
```

## USB.DriverBase

The *USB.DriverBase* class is used as the base for all drivers that use this library. It comprises a set of methods that are expected by [*USB.Host*](#USBhost) as well as some setup functions. There are a few required methods that **must** be overwritten. All other methods need only be overwritten as required.

## USB.DriverBase Required Methods

These are the methods your USB driver class **must** override. The default behavior for most of these methods is to throw an error.

### getIdentifiers()

This method should return an array of tables containing VID/PID pairs. These identifiers are needed when registering a driver with the *Usb.Host* class. Once the driver is registered with *USB.Host*, when a device with a matching VID PID combo is connected, an instance of this driver will be passed to the callback registered to the `"connected"` event.

#### Example

```squirrel
class MyUsbDriver extends USB.DriverBase {

    static VID = 0x01f9;
    static PID = 0x1044;

    // Returns an array of VID/PID combinations
    function getIdentifiers() {
        local identifiers = {};
        identifiers[VID] <- [PID];
        return [identifiers];
    }
}

usbHost <- USB.Host(hardware.usb);

// Register the USB driver with USB.Host
usbHost.registerDriver(MyUsbDriver, MyUsbDriver.getIdentifiers());
```

### _typeof()

The *_typeof()* method is a [Squirrel metamethod](https://electricimp.com/docs/resources/metamethods/) that returns the class name.

#### Example

```squirrel
class MyUsbDriver extends USB.DriverBase {
    // Metamethod returns class name when - typeof <instance> - is called
    function _typeof() {
        return "MyUsbDriver";
    }
}

myDriver <- MyUsbDriver();

// This will log "MyUsbDriver"
server.log(typeof myDriver);
```

#### _transferComplete(*eventDetails*)

The *_transferComplete()* method is triggered when a USB transfer is completed. This example code is taken from our example FTDI and UART drivers.

#### Example

```squirrel
class MyUsbDriver extends USB.DriverBase {

    // Called when a USB request is successfully completed
    function _transferComplete(eventDetails) {

        local direction = (eventDetails["endpoint"] & 0x80) >> 7;

        if (direction == USB_DIRECTION_IN) {
            local readData = _bulkIn.done(eventDetails);
            if (readData.len() >= 3) {
                // Skip first two bytes
                readData.seek(2);
                // Emit data event that the user can subscribe to
                _onEvent("data", readData.readblob(readData.len()));
            }

            // Blank the buffer
            _bulkIn.read(blob(64 + 2));
        } else if (direction == USB_DIRECTION_OUT) {
            _bulkOut.done(eventDetails);
        }
    }
}
```

### USB.DriverBase Setup Methods

This is a set of methods that are called when the USB driver is being instantiated by *USB.Host*. They are already implemented within the *USB.DriverBase* class and should not require changes.

### Constructor: USB.DriverBase(*usbHost*)

By default the constructor takes an instance of the *USB.Host* class as its only parameter and assigns it to the property *_usb*, which is accessible within the class scope. If custom initialization is required, override the constructor as shown below, making sure to call the *base.constructor()* method. If no initialization is required, let the parent class handle construction. The USB driver is initialized by the *USB.Host* class when a new device is connected to the USB port.

#### Example

```squirrel
class MyUsbDriver extends USB.DriverBase {

    _customOpt = null;

    constructor(usb, customOpt) {
        _customOpt = customOpt;
        base.constructor(usb);
    }
}
```

### connect(*deviceAddress, speed, descriptors*)

This method is called by the *USB.Host* class after instantiation of the USB driver class. It makes calls to internal functions to set up the various endpoints (control and bulk transfer endpoints), configures the USB parameters like the baud rate, and sets up the buffers.

### on(*eventName, callback*)

This method binds a callback function to a specific event. There are no events emitted by default as connection and disconnection are handled by the *USB.Host* class. You can emit custom events in your driver using the internal *_onEvent()* function but be sure to document them.

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *eventName* | String | Yes | The string name of the event to subscribe to |
| *callback* | Function | Yes | Function to be called then the named event occurs |

### off(*eventName*)

This method clears any callback function that has been bound to the named event.

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *eventName* | String | Yes | The string name of the event to unsubscribe from |

### _onEvent(*eventName, eventDetails*)

This method is a ‘private’ method used to emit events. The user is able to subscribe to these events using the *on()* method defined in the public methods listed above.

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *eventName* | String | Yes | The string name of the event to emit to |
| *eventDetails* | Any | Yes | If a callback is subscribed to the corresponding *eventName*, the callback is called with *eventDetails* as the argument |

## Driver Examples

### [UartOverUsbDriver](./UartOverUsbDriver/)

The *UartOverUsbDriver* class creates an interface object that exposes methods similar to the UART object to provide compatibility for UART drivers over USB.

### [FtdiUsbDriver](./FtdiUsbDriver/)

The *FtdiUsbDriver* class exposes methods to interact with a device connected to USB via an FTDI cable.

## License

This library is licensed under the [MIT License](/LICENSE).
