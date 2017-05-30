# USB.Host

The USB.Host class acts as a wrapper around the Imp API hardware.usb object and manages USB device connections, disconnections, transfers and driver selection.

### Setup

**To use this library add the following statements to the top of your device code:**

```
#require "USB.device.lib.nut:1.0.0"
```

## Device Class Usage

### Constructor: USB.Host(*usb[, autoConfigPins]*)

Instantiates the USB.Host class. It takes `hardware.usb` as a required parameter and an optional boolean flag to set whether to automatically configure pins R and W (required for USB to work on imp005. [More info](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb) ). By default *autoConfigPins* is set to `true`.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *usb* | Object | Yes | The usb object from the hardware class. `hardware.usb` |
| *autoConfPins* | Boolean | No | Set to true by default. Setting to false will require pin R and W to be manually configured according to [electric imps docs](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb) for the usb to work on an imp005.

#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb);
```

### registerDriver(*driverClass, identifiers*)

Registers a driver to a devices list of VID/PID combinations. When a device is connected via usb its VID/PID combination will be looked up and the matching driver will be instantiated to interface with device.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *driverClass* | Class | Yes | A reference to the class to be instantiated when a device with matching identifiers is connected. Must be a valid usb driver class that extends the *USB.DriverBase* class. |
| *identifiers* | Array | Yes | Array of VID/PID combinations. When a device connected that identifies itself with any of the PID/VID combinations provided the *driverClass* will be instatiated.


#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FtdiUsbDriver.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb);
// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

```


### on(*eventName, callback*)

Subscribe a callback function to a specific event.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to subscribe to. There are currently 2 events that you can subscibe to connected and disconnected|
| *callback* | Function | Yes | Function to be called on event |

#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FtdiUsbDriver.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb);

// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

// Subscribe to usb connection events
usbHost.on("connected",function (device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case "FtdiUsbDriver":
            // device is a ftdi device. Handle it here.
            break;
    }
});

// Subscribe to usb disconnection events
usbHost.on("disconnected",function(deviceName) {
    server.log(deviceName + " disconnected");
});

```

### off(*eventName*)

Clears a subscribed callback function from a specific event.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to unsubscribe from.|

#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FtdiUsbDriver.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb);

// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

// Subscribe to usb connection events
usbHost.on("connected",function (device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case "FtdiUsbDriver":
            // device is a ftdi device. Handle it here.
            break;
    }
});

// Unsubscribe from usb connection events
usbHost.off("connected");
```


### getDriver()

Returns the driver for the currently connected devices. Returns null if no device is connected or a corresponding driver to the device was not found.

#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FtdiUsbDriver.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb);

// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

// Check if a recognized usb device is connected in 30 seconds
imp.wakeup(30,function(){
    local driver = usbHost.getDriver();
    if (driver != null){
       // handle driver here
    }
}.bindenv(this))
```

## License

The USB class is licensed under [MIT License](../LICENSE).