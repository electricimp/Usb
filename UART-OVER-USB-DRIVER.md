# UartOverUsbDriver

The UartOverUsbDriver class creates an interface object that exposes methods similar to the uart object to provide compatability for uart drivers over usb.

### Setup

**To add this library to your project, add** `#require "uartoverusb.class.nut:1.0.0"` **to the top of your device code**

This class requires the UsbHost class. The usb host will handle the connection and instantiation of this class. The class and its identifiers must be registered with the UsbHost and the device driver will be passed to the connection callback on the UsbHost. 

#### Example
The example shows how to use the Brother QL-720NW uart driver to demonstrate how to use UartOverUsb. Please get the QL720NW.class.nut file from [here](https://github.com/electricimp/QL720NW) and paste the class at the top of your code.
```squirrel

class QL720NW {...}

#require "usbhost.class.nut:1.0.0"
#require "uartoverusb.class.nut:1.0.0"


// Callback to handle device connection
function onDeviceConnected(device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case ("UartOverUsbDriver"):
            // We pass the uart over usb interface object into the constructor of
            // a class that takes the uart object and we can use the class as per 
            // its original documentation
            printer <- QL720NW(device);

            printer
                .setOrientation(QL720NW.LANDSCAPE)
                .setFont(QL720NW.FONT_SAN_DIEGO)
                .setFontSize(QL720NW.FONT_SIZE_48)
                .write("San Diego 48 ")
                .print();
            break;
    }
}

// Callback to handle device disconnection
function onDeviceDisconnected(deviceName) {
    server.log(deviceName + " disconnected");
}
usbHost <- UsbHost(hardware.usb);

// Register the Uart over Usb driver with usb host
usbHost.registerDriver(UartOverUsbDriver, UartOverUsbDriver.getIdentifiers());
usbHost.on("connected",onConnected);
usbHost.on("disconnected",onDisconnected);


```

## Device Class Usage

### Constructor: UartOverUsbDriver(*usb*)

Class instantiation is handled by the UsbHost class.

 
### getIdentifiers()

Returns an array of tables with VID-PID key value pairs respectively. Identifiers are used by UsbHost to instantiate a matching devices driver.

### write(data)

Writes String or Blob data out to uart over usb.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *data* | String/Blob | Yes | The String or Blob to be written to uart over usb.|



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
        case ("UartOverUsbDriver"):
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
