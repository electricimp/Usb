# QL720NW UART USB Driver Example

This example shows how to implement the USB.Driver interface to create a USB over UART driver for a QL720NW label printer.  The example includes the QL720NWUartUsbDriver class with methods described below, some example code that makes use of the driver, and a folder with tests for the driver class.

## QL720NW UART USB Driver

The [USB.Host](../USB/) will handle the USB device connection/disconnection events and instantiation of this class. This class should be registered with the [USB.Host](../USB/) and when a device with matching description is connected the device driver will be instantiated and passed to the `"started"` event callback registered with the [USB.Host.setEventListener](../USB/).

## Driver class base methods

There are two methods which driver must to implement: match and release.

### match(device, interfaces)

Returns an instance of the QL720NWUartUsbDriver. Return null if the attached device does not match. Implementation of this method is based on VID and PID identifiers of the plugged device.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *device*  | USB.Device  | Yes      | attached device |
| *interfaces* | Array | Yes | the list of interface descriptions |


#### Example

```squirrel
class QL720NWUartUsbDriver extends USB.Driver {
  static VID = 0x04f9;
  static PID = 0x2044;

  constructor(device, interfaces) {
    // Empty for a while
  }

  function match(device, interfaces) {
    if (device &&
        device.getVendorId() == VID &&
        device.getProductId() == PID)
        return new QL720NWUartUsbDriver(device, interfaces);
    return null;
  }
}

```

### release()

This method should implement resource freeing before driver release.

```squirrel

class QL720NWUartUsbDriver extends USB.Driver {
  // ...
  function release() {
    // For example, driver developer could release write queue
    // and free all allocated endpoints
    this._bulkIn = null;
  }
}
```

## Driver class custom API

### write(data)

Writes String or Blob data to the usb printer. Implements async queue inside.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *data* | String/Blob | Yes | The String or Blob to be written to uart over usb.|
