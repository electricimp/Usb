# QL720NW USB Driver Example #

This example shows you how to implement the [USB Drivers Framework](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification) interface to create a USB driver that replaces the UART communication for use with the Brother QL720NW label printer.

This example is dependent on the [QL720NW Library](https://github.com/electricimp/QL720NW/). Instead of passing a UART object into the QL720NW constructor, the initialized USB QL720NWUsbDriver should be used.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## QL720NW USB Driver ##

The [USB.Host](./../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification) handles the USB device connection/disconnection events and instantiation of the driver class.

Please refer to the [Application Development Guide](./../../docs/ApplicationDevelopmentGuide.md) for more details on how to use existing USB drivers.

## USB.Driver Class Base Methods Implementation ##

### match(*device, interfaces*) ###

Implementation of the [USB.Driver.match](../../docs/DriverDevelopmentGuide.md#matchdeviceobject-interfaces) interface method.

### release() ###

Implementation of the [USB.Driver.release](../../docs/DriverDevelopmentGuide.md#release) interface method.

## Driver Class Custom API ##

This USB driver was written to be compatible with Electric Imp's [QL720NW](https://github.com/electricimp/QL720NW) library. The QL720NW library was initially written to support UART communication with the printer. Its constructor expects a single parameter, a configured UART object. To maintain compatibility our driver must also contain methods that match the [impAPI UART methods](https://developer.electricimp.com/api/hardware/uart). By maintaining the same same API as the impAPI's UART object, we are able to pass in the USB driver when initializing the QL720NW printer. Once initialized the [QL720NW](https://github.com/electricimp/QL720NW) library can be used as documented.

### write(*dataToWrite*) ###

The only method used by the UART object in the QL720NW library is the write method. To maintain compatibility our driver must also contain a write method that matches the [impAPI UART write method](https://developer.electricimp.com/api/hardware/uart/write). This method takes one parameter *dataToWrite*.
