# FT232RL FTDI USB Driver Example

This example shows how to create a driver class for a FT232RL USB for a serial breakout.

The example includes FT232RLFtdiUsbDriver class with public API methods described below, some example code that makes use of the driver and a folder with tests for the driver class.

## Driver instantiation example

```squirrel
#require "USB.device.lib.nut:0.3.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"

// Provide the list of available drivers to the USB.Host
local host = USB.Host(hardware.usb, [FT232RLFtdiUsbDriver]);

host.setEventListener(function(eventName, eventObject) {
  if (eventName == "started") {
    local driver = eventObject;
    server.log("FT232RLFtdiUsbDriver instantiated");

    // now you can save the driver instance 
    // and/or call methods from the driver custom API
    // For example: driver.write("Test message", callback);
  }
});

// Give instructions for user
server.log("USB host initialized. Please, plug FTDI board in to see logs.");
```

## Driver mandatory API

The driver must implement these methods in order to be integrated into USB Drivers Framework.

### match(device, interfaces)

Returns an instance of the FT232RLFtdiUsbDriver or null if device does not match. Implementation of this method for the FT232 is based on VID and PID identifiers.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *device*  | USB.Device  | Yes      | attached device |
| *interfaces* | Array | Yes | the list of interface descriptions |


#### Example

```squirrel
class FT232RLFtdiUsbDriver extends USB.Driver {
  static VID = 0x0403;
  static PID = 0x6001;

  constructor(device, interfaces) {
    // Empty for a while
  }

  function match(device, interfaces) {
    if (device &&
        device.getVendorId() == VID &&
        device.getProductId() == PID)
        return new FT232RLFtdiUsbDriver(device, interfaces);
    return null;
  }
}

```

### release()

This method should implement resource freeing before driver release.

```squirrel

class FT232RLFtdiUsbDriver extends USB.Driver {
  // ...
  function release() {
    // For example, driver developer could release write queue
    // and free all allocated endpoints
    this._bulkIn = null;
    this._bulkOut = null;
  }
}
```

## Driver custom API

Custom API for application developers. Provides a meaningful functionality of the driver.

### write(*payload*, *callback*)

Sends text or blob data to the connected USB device.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*   | string or blob  | Yes | data to be sent |
| *callback*  | Function  | Yes      | Function to be called on write completion or error. |

### read(*payload*, *callback*)

Reads data from the connected USB device to the blob.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*   | blob      | Yes      | data to be get from the USB device |
| *callback*  | Function  | Yes      | Function to be called on read completion or error. |

### _typeof()

Meta-function to return class name when typeof <instance> is run.
