# QL720NW UART USB Driver Example #

This example shows you how to implement the [USB Drivers Framework](./../../docs/DriverDevelopmentGuide.md) interface to create a USB over UART driver for the Brother QL720NW label printer.

It includes the QL720NWUartUsbDriver class with the public methods that match the [QL720NWUart](https://github.com/electricimp/QL720NW/tree/e6163cef81a0dcd37f4e1205a4ab9f456f77f83b) public methods, plus some example code that demonstrates how to use the driver.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## QL720NW UART USB Driver ##

The [USB.Host](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification) handles the USB device connection/disconnection events and instantiation of the driver class.

Please refer to the [Application Development Guide](./../../docs/ApplicationDevelopmentGuide.md) for more details on how to use existing USB drivers.

## USB.Driver Class Base Methods Implementation ##

### match(device, interfaces)

Implementation of the [USB.Driver.match](../../docs/DriverDevelopmentGuide.md#matchdeviceobject-interfaces) interface method.

### release()

Implementation of the [USB.Driver.release](../../docs/DriverDevelopmentGuide.md#release) interface method.

## Driver Class Custom API ##

The driver has the same public APIs as the QL720NW Driver. So please refer to it's [documentation](https://github.com/electricimp/QL720NW/tree/e6163cef81a0dcd37f4e1205a4ab9f456f77f83b) for more details.

**Note** The driver code in this example differs from the latest release of the QL720NW library the linked documentation is from a previous version of the printer driver.
