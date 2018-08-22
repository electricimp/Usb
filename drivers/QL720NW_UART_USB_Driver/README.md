# QL720NW UART USB Driver Example #

This example shows you how to implement the [USB Drivers Framework](./../../docs/DriverDevelopmentGuide.md) interface to create a USB over UART driver for the Brother QL720NW label printer. It includes the QL720NWUartUsbDriver class with the public methods described below, plus some example ode that demonstrates how to use the driver.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## QL720NW UART USB Driver ##

The [USB.Host](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification) handles the USB device connection/disconnection events and instantiation of the driver class.

Please refer to the [Application Development Guide](./../../docs/ApplicationDevelopmentGuide.md) for more details on how to use existing USB drivers.

## The Driver API ##

The driver has the same public APIs as the [QL720NW Driver](https://github.com/electricimp/QL720NW), so please refer to its [documentation](https://github.com/electricimp/QL720NW#setorientationorientation) for more details. The [QL720NW Driver]((https://github.com/electricimp/QL720NW) will be updated to work with the USB Drivers Framework and then this driver will be removed from here to avoid duplication.

**Note** You don't have to initialize the driver &mdash; this is done by the USB Drivers Framework automatically.
