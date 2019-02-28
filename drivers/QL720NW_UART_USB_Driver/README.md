# QL720NW UART USB Driver Example

This example shows how to implement the [USB.Driver](./../../docs/DriverDevelopmentGuide.md)
interface to create a USB over UART driver for the QL720NW label printer.
The example includes
the QL720NWUartUsbDriver class with methods described below, some example
code that shows how to use the driver.

**NOTE**: Please use the driver examples for reference only. They were tested with a limited number
of devices and may not support all devices of that type.

## QL720NW UART USB Driver

The [USB.Host](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification)
handles the USB device connection/disconnection
events and instantiation of the driver class.

Please refer to the Application Development [Guide](./../../docs/ApplicationDevelopmentGuide.md) for
more details on how to use existing USB drivers.

## USB.Driver Class Base Methods Implementation

The driver must implement `match` and `release` methods in order to work with the
USB Driver [Framework](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification).

### match(device, interfaces)

Implementation of the [USB.Driver.match](../../docs/DriverDevelopmentGuide.md#matchdeviceobject-interfaces) interface method.

### release()

Implementation of the [USB.Driver.release](../../docs/DriverDevelopmentGuide.md#release) interface method.

## Driver Class Custom API

The driver has the same public APIs as the [QL720NW Driver]((https://github.com/electricimp/QL720NW). So please refer to it's [documentation](https://github.com/electricimp/QL720NW#setorientationorientation) for more details.

**NOTE:** you don't have to initialize the driver, this is done by the USB framework automatically.

**NOTE:** the [QL720NW Driver](https://github.com/electricimp/QL720NW) will be updated to work with the
USB framework and then this driver will be removed from here to avoid duplication.
