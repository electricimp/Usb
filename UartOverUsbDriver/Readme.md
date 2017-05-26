# UartOverUsbDriver

The UartOverUsbDriver class creates an interface object that exposes methods similar to the [uart](https://electricimp.com/docs/api/hardware/uart/) object to provide compatability for uart drivers over usb. 

### Setup

**To use this library add the following statements to the top of your device code:**

```
#require "USB.device.lib.nut:1.0.0"
#require "UartOverUsbDriver.device.lib.nut:1.0.0"
```

The [USB.Host](../USB/) will handle the connection/disconnection events and instantiation of this class. This class and its identifiers will be registered with the [USB.Host](../USB/) and when a device with matching identifiers is connected the device driver will be instantiated and passed to the `"connection"` event callback registered with the [USB.Host](../USB/). As this can be confusing an example of receiving an instantiated driver object is shown below:

#### Example

The example shows how to use the [Brother QL-720NW](https://github.com/electricimp/QL720NW) uart driver to demonstrate how to use UartOverUsb. Please copy the QL720NW.device.nut file from [here](https://github.com/electricimp/QL720NW) and replace the line `class QL720NW {...}` with the class retrieved.

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "UartOverUsbDriver.device.lib.nut:1.0.0"

class QL720NW {...}
// Instantiate usb host
usbHost <- USB.Host(hardware.usb);

// For a supported device like the QL720NW we directly register the Uart over Usb driver with usb host
usbHost.registerDriver(UartOverUsbDriver, UartOverUsbDriver.getIdentifiers());

// To use a device that is not directly supported by the 
// UartOverUsb class you can manually pass in identifiers using 
// the following code

// vid <- [enter device vid];
// pid <- [enter device pid];
// identifier <- {};
// identifier[vid] <- pid;
// identifiers <- [identifier]
// usbHost.registerDriver(UartOverUsbDriver, identifiers);


// Register connection event handler
usbHost.on("connected",function (device) {

    server.log(typeof device + " was connected!");
    
    switch (typeof device) {
        case ("UartOverUsbDriver"):
        
            // We pass the uart over usb interface object into 
            // the constructor of a class that takes the
            // uart object and we can use the class as per
            // its original documentation
            printer <- QL720NW(device);
            
            // Print the sentence "San Diego 48" 
            printer
                .setOrientation(QL720NW.LANDSCAPE)
                .setFont(QL720NW.FONT_SAN_DIEGO)
                .setFontSize(QL720NW.FONT_SIZE_48)
                .write("San Diego 48 ")
                .print();
            break;
    }
});
usbHost.on("disconnected",function (deviceName) {
    server.log(deviceName + " disconnected");
});
```

## Device Class Usage

### Constructor: UartOverUsbDriver(*usb*)

Class instantiation is handled by the [USB.Host](../USB/) class. This class should not be manually instantiated.



### getIdentifiers()

Returns an array of tables with VID-PID key value pairs respectively. Identifiers are used by the [USB.Host](../USB/) to instantiate the corresponding devices driver.


#### Example

```squirrel
#require "UartOverUsbDriver.device.lib.nut:1.0.0"

local identifiers = UartOverUsbDriver.getIdentifiers();

foreach (i, identifier in identifiers) {
    foreach (VID, PID in identifier){
        server.log("VID =" + VID + " PID = " + PID);
    }
}

```



### write(data)

Writes String or Blob data out to uart over usb.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *data* | String/Blob | Yes | The String or Blob to be written to uart over usb.|


#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "UartOverUsbDriver.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb);

// Register the Uart over Usb driver with usb host
usbHost.registerDriver(UartOverUsbDriver, UartOverUsbDriver.getIdentifiers());

usbHost.on("connected",function (device) {
    switch (typeof device) {
        case ("UartOverUsbDriver"):
            device.write("Testing usb over uart");
            break;
    }
});

```

## License

The UartOverUsbDriver is licensed under [MIT License](../LICENSE).