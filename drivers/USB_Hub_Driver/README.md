# USB Hub Driver 1.0.0 #

This USB hub driver provides basic support for USB hubs.

**Important** Though this driver supports hubs, it does not yet support the hot-plugging of devices to that hub. Devices **must** be connected to the hub before the hub is connected to the imp. You can use the method [*checkports()*](#checkports) to verify the status of a hub's ports at any time.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## Include USB Hub Driver And Its Dependencies ##

The driver depends on constants and classes within the [USB Drivers Framework](../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification). For more information on USB driver development, please see [**USB Driver Development Guide**](https://developer.electricimp.com/resources/usb-driver-development-guide).

To add the USB Hub driver into your project, add `#require "USB.device.lib.nut:1.1.0"` top of you application code and then either include the USB Hub driver in your application by pasting its code into yours or by using [Builder's @include statement](https://github.com/electricimp/builder#include):

```squirrel
#require "USB.device.lib.nut:1.1.0"
@include "github:electricimp/usb/drivers/USB_Hub_Driver/USB.hub.device.nut"
```

## USB.Driver Class Base Methods Implementation ##

### match(device, interfaces) ###

Implementation of the [USB.Driver.match](../../docs/DriverDevelopmentGuide.md#matchdeviceobject-interfaces) interface method.

### release() ###

Implementation of the [USB.Driver.release](../../docs/DriverDevelopmentGuide.md#release) interface method.

## Driver Class Custom API ##

### checkPorts() ###

This method provides a hub port status update that indicates which, if any, of the hub's ports are occupied.

#### Return Value ####

Table &mdash; keys are integers: the hub's port numbers; values are either `"connected"` or `"empty"`
