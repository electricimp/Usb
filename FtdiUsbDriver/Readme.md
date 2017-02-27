# FtdiUsbDriver

The FtdiUsbDriver class exposes methods to interact with an device connected to usb via an ftdi cable. It requires the UsbHost wrapper class to work.

### Setup

**To add this library to your project, add** `#require "ftdiusbdriver.class.nut:1.0.0"` **to the top of your device code**

This class requires the UsbHost class. The usb host will handle the connection and instantiation of this class. The class and its identifiers must be registered with the UsbHost and the device driver will be passed to the connection callback on the UsbHost. 

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
usbHost.on("connected",onConnected);
usbHost.on("disconnected",onDisconnected);


```

## Device Class Usage

### Constructor: FtdiUsbDriver(*usb*)

Class instantiation is handled by the UsbHost class.

 
### getIdentifiers()

Returns an array of tables with VID-PID key value pairs respectively. Identifiers are used by UsbHost to instantiate a matching devices driver.

### write(data)

Writes String or Blob data out to ftdi.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *data* | String/Blob | Yes | The String or Blob to be written to ftdi.|



### on(*eventName, callback*)

Subscribe a callback function to a specific event.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to subscribe to. There is currently 1 event that you can subscibe to: "data"|
| *callback* | Function | Yes | Function to be called on event |

#### Example

```squirrel
onDeviceData(data){
    server.log("Recieved " + data + " via usb");
}
// Callback to handle device connection
function onDeviceConnected(device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case ("FtdiUsbDriver"):
            device.on("data", onDeviceData);
            break;
    }
}

```

### off(*eventName*)

Clears a subscribed callback function from a specific event.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to unsubscribe from.|




## License

The Conctr library is licensed under [MIT License](./LICENSE).
