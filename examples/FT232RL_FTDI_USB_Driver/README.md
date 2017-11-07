# FT232RL FTDI USB Device Driver Example

This example shows how to create a driver class for a FT232RL USB for a serial breakout.

The example includes FT232RLFtdiUsbDriver class with public API methods described below, some example code that makes use of the driver and a folder with tests for the driver class.

## Driver instantiation example

For the correct example work you need to plug the USB FT232RL FTDI device.

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

## USB.Driver interface API

The driver must implement these methods in order to be integrated into the [USB Drivers Framework](https://github.com/nobitlost/Usb/blob/CSE-433/README.md).

### match(device, interfaces)

Implementation of the [USB.Driver](https://github.com/nobitlost/Usb/blob/CSE-433/README.md#matchdeviceobject-interfaces) interface

### release()

Implementation of the [USB.Driver](https://github.com/nobitlost/Usb/blob/CSE-433/README.md#matchdeviceobject-interfaces) interface

## Driver custom API

Custom API for application developers. Provides a meaningful functionality of the driver.

### write(*payload*, *callback*)

Sends text or blob data to the connected USB device.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*   | string or blob  | Yes | data to be sent |
| *callback*  | Function  | Yes      | Function to be called on write completion or error. |

#### write callback

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*   | Number  | the error number |
| *data*  | string or blob  | string or blob payload. Use typeof for details. |
| *length*  | Number  | the data length |


### read(*payload*, *callback*)

Reads data from the connected USB device to the blob.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*   | blob      | Yes      | data to be get from the USB device |
| *callback*  | Function  | Yes      | Function to be called on read completion or error. |


#### read callback

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*   | Number  | the error number |
| *data*  | string or blob  | string or blob payload. Use typeof for details. |
| *length*  | Number  | the data length |


### _typeof()

Meta-function to return class name when typeof <instance> is run. Uses to identify the driver instance type in runtime.
  
```squirrel

// For example:

host <- USB.Host(hardware.usb, ["MyCustomDriver1", "MyCustomDriver2", "FT232RLFtdiUsbDriver"]);

host.setEventListener(function(eventName, eventDetails) {
    if (eventName == "started" && typeof eventDetails == "FT232RLFtdiUsbDriver")
        server.log("FT232RLFtdiUsbDriver initialized");
});

```
