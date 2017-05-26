# USB.DriverBase

The USB.DriverBase class is used as the base class for all drivers that make use of the USB.Host. It contains a set of functions that are expected by the USB.Host class as well as some set up functions. You must override these funtions for correct function of your driver.

### Setup

**Before your driver can be used the USB class must be required before the driver class at the top of the device code. As shown below:**

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "YourUsbDriver.device.lib.nut:1.0.0" // Replace with your custom driver

usbHost <- USB.Host(hardware.usb);
```

## Set-up Functions
This is a set of functions that are called during the set up process of the usb driver by the USB.Host. They are already implemented within the UsbDriverBase class and should not require changes.

### Constructor: USB.Host(*usb*)
 It takes `hardware.usb` as its only parameter and assigns it to internal `_usb` variable accessible within the class scope.
If custom initialization is required override the constructor as shown below but ensure the base.constructor() method is called with the usb arguement. If no initialization is required let the parent class handle constructor.

#### Example

```squirrel
class YourUsbDriver extends USB.DriverBase {
    // A custom opt to be set during initialization
    _customOpt = null;

    constructor(usb, customOpt) {
        _customOpt = customOpt;
        // Call base contructor to properly initialize base class
        base.constructor(usb);
    }
}

```

### connect(deviceAddress, speed, descriptors)
 This method is called by the USB.Host after instantiation of the usb driver class. It sets up the various endpoints (control and bulk transfer endpoints), configures the usb parameters like the baud rate and sets up the buffers.

## Required Functions
These are the functions you usb driver class must override.

### _typeof()

Metamethod that returns the class name. See https://electricimp.com/docs/resources/metamethods/

#### Example

```squirrel
class YourUsbDriver {

   // Metafunction to return class name when typeof <instance> 
   // is run
    function _typeof() {
        return "YourUsbDriver";
    }
}

```

### getIdentifiers()

Method that returns an array of tables containing VID PID pairs. The list of identifiers are used to register this driver with the USB.Host class. When a device with a matching VID PID combination is connected via usb the USB.Host class will intatiate the corresponding driver and pass this driver back to the user via the callback attached to its "connected" event.


#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"

class YourUsbDriver {

    static VID = 0x01f9;
    static PID = 0x1044;

   // Returns an array of VID PID combinations
    function getIdentifiers() {
        local identifiers = {};
        identifiers[VID] <-[PID];
        return [identifiers];
    }
}

usbHost <- USB.Host(hardware.usb);

// Register the Usb driver with usb host
usbHost.registerDriver(YourUsbDriver, YourUsbDriver.getIdentifiers());

```

### transferComplete(eventDetails)

Called when a usb transfer is completed. Below is an example of the transferComplete method for the FtdiUsbDriver class.

#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"

class YourUsbDriver {

    // Called when a Usb request is succesfully completed
    function transferComplete(eventdetails) {
        local direction = (eventdetails["endpoint"] & 0x80) >> 7;
        if (direction == USB_DIRECTION_IN) {
            local readData = _bulkIn.done(eventdetails);
            if (readData.len() >= 3) {
                // skip first two bytes
                readData.seek(2);
                // emit data event that the user can subscribe to.
                _onEvent("data", readData.readblob(readData.len()));
            }
            // Blank the buffer
            _bulkIn.read(blob(64 + 2));
        } else if (direction == USB_DIRECTION_OUT) {
            _bulkOut.done(eventdetails);
        }
    }
}
```


## Public Functions

These are publicly exposed functions that are contained within the UsbDriverBase class.

### on(*eventName, callback*)

Subscribe a callback function to a specific event. There are no events emitted by default as connection and disconnection are handled by the USB.Host. You can emit custom events in your driver using the internal `_onEvent` function but ensure to document them.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to subscribe to.|
| *callback* | Function | Yes | Function to be called on event |

### off(*eventName*)
Clears a subscribed callback function from a specific event.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to unsubscribe from.|

## Private Functions

### _onEvent(eventName, eventdetails)

This is used internal to your class to emit events. The user is able to subscribe to these events using the `on` method defined in the public functions above.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to emit to.|
| *eventdetails* | Any | Yes | If a callback is subscribed to the corresponding eventName the callback is called with eventDetails as the arguement. |


## License

The USB.DriverBase is licensed under [MIT License](./LICENSE).