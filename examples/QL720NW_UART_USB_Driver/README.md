# QL720NW UART USB Driver Example

This example shows how to extend the USB.DriverBase class to create a USB over UART driver for a QL720NW label printer.  The example includes the QL720NWUartUsbDriver class with methods descibed below, some example code that makes use of the driver, and a folder with tests for the driver class.

## QL720NW UART USB Driver

The [USB.Host](../USB/) will handle the connection/disconnection events and instantiation of this class. This class and its identifiers will be registered with the [USB.Host](../USB/) and when a device with matching identifiers is connected the device driver will be instantiated and passed to the `"connection"` event callback registered with the [USB.Host](../USB/). As this can be confusing an example of receiving an instantiated driver object is shown in the example file - QL720NWUartUsbDriver.device.nut.

## Class Usage

### Constructor: QL720NWUartUsbDriver(*usb*)

Class instantiation is handled by the [USB.Host](../USB/) class. This class should not be manually instantiated.

### getIdentifiers()

Returns an array of tables with VID-PID key value pairs respectively. Identifiers are used by the [USB.Host](../USB/) to instantiate the corresponding devices driver.


#### Example

```squirrel
local identifiers = QL720NWUartUsbDriver.getIdentifiers();

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
// Register the Uart over Usb driver with usb host
usbHost.registerDriver(QL720NWUartUsbDriver, QL720NWUartUsbDriver.getIdentifiers());

usbHost.on("connected",function (device) {
    switch (typeof device) {
        case ("QL720NWUartUsbDriver"):
            // Write a string out
            device.write("Hello World");
            break;
    }
});

```