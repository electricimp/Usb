# FT232RL FTDI USB Device Driver Example #

This example shows you how to implement and use the FT232RL USB driver. It includes the FT232RLFtdiUsbDriver implementation with the public API described below, and some [example code](./examples) that shows how to use the driver with two different USB-UART adapters:

- CH430.
- FTDI232RL.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## Include The Driver And Its Dependencies ##

The driver depends on constants and classes within the [USB Drivers Framework](https://github.com/electricimp/Usb/blob/dev-docs/docs/DriverDevelopmentGuide.md).

To add the FT232RL FTDI USB Device Driver driver into your project, add the following statement on top of you application code:

```
#require "USB.device.lib.nut:1.0.0"
```

and then either include the Boot Keyboard driver in you application by pasting its code into yours or by using [Builder's @include statement](https://github.com/electricimp/builder#include):

```
#require "USB.device.lib.nut:1.0.0"
@include "~/project/FT232RLFtdiUsbDriver.device.lib.nut"
```

## The Driver API ##

This driver exposes following API for application usage.

### write(*payload*, *callback*) ###

This methods sends text or blob data to the connected USB device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *payload* | String or blob  | Yes | The data to be sent |
| *callback* | Function | Yes | A function to be called on write completion or error |

#### Callback Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *error* | Integer | The error number, or `0` |
| *data* | String or blob | The data sent. Use `typeof` for details |
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
| *data* | String or blob | The data sent. Use `typeof` for details |
| *length* | Integer | The data length in bytes |

#### Return Value ####

Nothing.
