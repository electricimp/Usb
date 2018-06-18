# QL720NW UART USB Driver Example

This example shows how to implement the [USB.Driver](./../../docs/DriverDevelopmentGuide.md)
interface to create a USB over UART driver for the QL720NW label printer.
The example includes
the QL720NWUartUsbDriver class with methods described below, some example
code that shows how to use the driver.

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

Please refer to the QL720NW Driver documentation on details of the [public APSs](https://github.com/electricimp/QL720NW#setorientationorientation).

**NOTE:** you don't have to initialize the driver, this is done by the USB framework automatically.