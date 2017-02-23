# UsbHost

The UsbHost Class acts as a wrapper around the hardware.usb object and manages USB device connections, disconnections, transfers and driver selection.

### Setup

**To add this library to your project, add** `#require "usbhost.class.nut:1.0.0"` **to the top of your device code**

## Device Class Usage

### Constructor: UsbHost(*usb*)

Instantiates the UsbHost class. It takes `hardware.usb` as its only parameter.
#### Example

```squirrel
#require "usbhost.class.nut:1.0.0"

usbHost <- UsbHost(hardware.usb);
```
 
### registerDriver(*driverClass, identifiers*)

Registers a driver to a devices list of VID/PID combinations. When a device is connected via usb its VID/PID combination will be looked up and the matching driver will be instantiated to interface with device.
å

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *driverClass* | Class | Yes | A reference to the class to be instantiated when a device with matching identifiers is connected. Must be a valid usb class that extends the *DriverBase* class. |
| *identifiers* | Array | Yes | Array of VID/PID combinations. When a device connected that identifies itself with any of the PID/VID combinations provided the driverClass will be instatiated.


#### Example

```squirrel
#require "usbhost.class.nut:1.0.0"
#require "ftdiusbdriver.class.nut:1.0.0"

usbHost <- UsbHost(hardware.usb);
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
#require "usbhost.class.nut:1.0.0"
#require "ftdiusbdriver.class.nut:1.0.0"

// Callback to handle device connection
function onDeviceConnected(device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case ("FtdiUsbDriver"):
            // device is a ftdi device. Handle it here.
            break;
    }
}

// Callback to handle device disconnection
function onDeviceDisconnected(deviceName) {
    server.log(deviceName + " disconnected");
}
usbHost <- UsbHost(hardware.usb);

// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());
usbHost.on("connected",onDeviceConnected);
usbHost.on("disconnected",onDeviceDisconnected);

```

### off(*eventName*)

Clears a subscribed callback function from a specific event.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to unsubscribe from.|


## License

The Conctr library is licensed under [MIT License](./LICENSE).