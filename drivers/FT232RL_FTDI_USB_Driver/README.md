# FT232RL FTDI USB Device Driver Example

This example shows how to create use the FT232RL USB driver.

The example includes the FT232RLFtdiUsbDriver implementation with public API described below,
some example code that shows how to use the driver.

## Real-World Driver Usage Examples

Please refer to the [examples](./examples) folder for examples of driver implementations
for CH430 and FTDI232RL chipsets.

## USB.Driver Interface API

The driver must implement `match` and `release` methods in order to be used with the
USB Driver [Framework](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification).

### match(device, interfaces)

Implementation of the [USB.Driver](../../docs/DriverDevelopmentGuide.md#release) interface

### release()

Implementation of the [USB.Driver](../../docs/DriverDevelopmentGuide.md#matchdeviceobject-interfaces) interface

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

host <- USB.Host(["MyCustomDriver1", "MyCustomDriver2", "FT232RLFtdiUsbDriver"]);

host.setEventListener(function(eventName, eventDetails) {
    if (eventName == "started" && typeof eventDetails == "FT232RLFtdiUsbDriver")
        server.log("FT232RLFtdiUsbDriver initialized");
});

```
