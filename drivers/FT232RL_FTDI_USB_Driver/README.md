# FT232RL FTDI USB Device Driver Example #

This example shows you how to implement and use the FT232RL USB driver. It includes the FT232RLFtdiUsbDriver implementation with the public API described below, and some [example code](./examples) that shows how to use the driver with two different USB-UART adapters:

- CH430.
- FTDI232RL.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## Include The Driver And Its Dependencies ##

The driver depends on constants and classes within the [USB Drivers Framework](../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification).

To add the FT232RL FTDI USB Device Driver into your project, add `#require "USB.device.lib.nut:1.1.0"` top of your application code and then either include the FT232RLFtdiUsbDriver in you application by pasting its code into yours or by using [Builder's @include statement](https://github.com/electricimp/builder#include):

```squirrel
#require "USB.device.lib.nut:1.1.0"
@include "github:electricimp/usb/drivers/FT232RL_FTDI_USB_Driver/FT232RLFtdiUsbDriver.device.nut"
```

## USB.Driver Class Base Methods Implementation ##

### match(device, interfaces)

Implementation of the [USB.Driver.match](../../docs/DriverDevelopmentGuide.md#matchdeviceobject-interfaces) interface method.

### release()

Implementation of the [USB.Driver.release](../../docs/DriverDevelopmentGuide.md#release) interface method.

## Driver Class Custom API ##

This driver exposes following API for application usage.

### write(*payload*, *callback*) ###

This methods sends text or blob data to the connected USB device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *payload* | String or Blob  | Yes | The data to be sent |
| *callback* | Function | Yes | A function to be called on write completion or error |

#### Callback Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *error* | Integer | The error number, or `0` |
| *data* | String or Blob | The data sent. Use `typeof` for details |
| *length* | Integer | The data length in bytes |

#### Return Value ####

Nothing.

### read(*data, callback*) ###

Reads data from the connected USB device to the blob.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *data* | Blob | Yes | The data read from the USB device |
| *callback* | Function | Yes | A function to be called on read completion or error |

#### Callback Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *error* | Integer | The error number, or `0` |
| *data* | String or Blob | The data sent. Use `typeof` for details |
| *length* | Integer | The data length in bytes |

#### Return Value ####

Nothing.
