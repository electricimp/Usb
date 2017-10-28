# FT232RL FTDI USB Driver Example

This example shows how to create a driver class for a FT232RL USB for a serial breakout.  The example includes the FT232RLFtdiUsbDriver class with methods described below, some example code that makes use of the driver, and a folder with tests for the driver class.

## FT232RL FTDI USB Driver

This class should be provided in a list of drivers-argument of the [USB.Host constructor](../USB/) and if a driver is matching to the connected device then driver will be instantiated.

The [USB.Host](../USB/) will notify the "started"/"stopped" events on instantiation of this driver class
in case if application developer is subscribed on USB events via [USB.Host.setEventListener](../USB/).


#### Driver instantiation and usage example

```squirrel
#require "USB.device.lib.nut:0.3.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"

// Provide the list of available drivers to the USB.Host
local host = USB.Host(hardware.usb, [FT232RLFtdiUsbDriver]);

host.setEventListener(function(eventName, eventDetails) {
  if (eventName == "stated") {
    local driver = eventDetails;
    server.log("FT232RLFtdiUsbDriver instantiated");

    // now you can save driver instance or call
    // a custom driver API
    // For example: driver.write("Test message", callback);
  }
});

// Log instructions for user
server.log("USB host initialized. Please, plug FTDI board in to see logs.");
```

## Driver class base methods

There are two methods which driver must to implement: match and release.

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

## Driver class custom API

Each driver could provide custom API for application developers.

There is an example of such API:

### write(*payload*, *callback*)

write method allows to write some text data via drvier and get a callback on write completion

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*  | string or blob  | Yes      | data to be sent via usb |
| *callback*  | Function  | Yes      | Function to be called on write completion or error. |


### read(*payload*, *callback*)

Read data from usb device to the blob and provide callback on completion or error

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*  | blob  | Yes      | data to be get from usb device |
| *callback*  | Function  | Yes      | Function to be called on read completion or error. |

### _typeof()

Meta-function to return class name when typeof <instance> is run.
