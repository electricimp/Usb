# QL720NW UART USB Driver Example

This example shows how to implement the USB.Driver interface to create a USB over UART driver for a QL720NW label printer.  The example includes the QL720NWUartUsbDriver class with methods described below, some example code that makes use of the driver, and a folder with tests for the driver class.

## QL720NW UART USB Driver

The [USB.Host](../USB/) will handle the USB device connection/disconnection events and instantiation of this class. This class should be registered with the [USB.Host](../USB/) and when a device with matching description is connected the device driver will be instantiated and passed to the `"started"` event callback registered with the [USB.Host.setEventListener](../USB/).

## USB.Driver class base methods

The driver must implement these methods in order to be integrated into the [USB Drivers Framework](https://github.com/nobitlost/Usb/blob/CSE-433/README.md).

### match(device, interfaces)

Implementation of the [USB.Driver](https://github.com/nobitlost/Usb/blob/CSE-433/README.md#matchdeviceobject-interfaces) interface

### release()

Implementation of the [USB.Driver](https://github.com/nobitlost/Usb/blob/CSE-433/README.md#matchdeviceobject-interfaces) interface


## Driver class custom API

### write(data)

Writes String or Blob data to the usb printer. Implements async queue inside.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *data* | String/Blob | Yes | The String or Blob to be written to uart over usb.|
