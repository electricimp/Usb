# FT232RL FTDI USB Device Driver Example

This example shows how to use the FT232RL USB driver.

The example includes the FT232RLFtdiUsbDriver implementation with public API described below,
some example code that shows how to use the driver.

## Real-World Driver Usage Examples

Please refer to the [examples](./examples) folder for a complete runnable application code,
that demonstrates the use of the driver for CH430 and FTDI232RL adapters.

## USB.Driver Interface API Implemtntaion

The driver must implement `match` and `release` methods in order to be used with the
USB Driver [Framework](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification).

### match(device, interfaces)

Implementation of the [USB.Driver.match](../../docs/DriverDevelopmentGuide.md#matchdeviceobject-interfaces) interface method.

### release()

Implementation of the [USB.Driver.release](../../docs/DriverDevelopmentGuide.md#release) interface method.

## Driver custom API

Custom API for application developers. Provides a meaningful functionality of the driver.

### write(*payload*, *callback*)

Sends text or blob data to the connected USB device.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*   | string or blob  | Yes | data to be sent |
| *callback*  | Function  | Yes      | Function to be called on write completion or error. |

#### `write` Callback

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*   | Number  | the error number |
| *data*  | string or blob  | string or blob payload. Use typeof for details. |
| *length*  | Number  | the data length |


### read(*payload*, *callback*)

Reads data from the connected USB device to the blob.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *payload*   | blob      | Yes      | data to be read from the USB device |
| *callback*  | Function  | Yes      | Function to be called on read completion or error. |


#### `read` Callback

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*   | Number  | the error number |
| *data*  | string or blob  | string or blob payload. Use typeof for details. |
| *length*  | Number  | the data length |


### _typeof()

Meta-function that returns the class name when `typeof <instance>` is called.
The promarily use of the function is to identify the driver instance type in runtime for debugging purposes.
