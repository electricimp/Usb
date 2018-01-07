## Generic HID driver

The generic HID driver implements basic functionality required to start using any device that exposes interfaces with HID functionality. It allows to discover, read and change state of any sensors, actuators, indicators and other physical parts of such devices.

It is recommended to be familiar with [Device Class Definition for Human Interface Devices (HID)](http://www.usb.org/developers/hidpage/HID1_11.pdf) prior to use this driver.

### Include the driver and dependencies

The driver depends on some constants and classes of USB Framework, so that framework has to be included by application developer. Please follow [Application Developer Guide](./ApplicationDevelopmentGuide.md#include-the-framework-and-drivers) instruction about how to start using of USB framework.

**To add HID driver to your project, add** `#require "USB.HID.device.lib.nut:1.0.0"` **to the top of your device code.**

In the example below HID driver is included into an application:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "USB.HID.device.lib.nut:1.0.0"
```



### Known limitation

### Public API

#### HIDDriver class

##### match(device, interfaces)

##### getReports()

##### getAsync(cb)

#### HIDReport class

##### constructor(interface)

##### request()

##### send()

##### setIdleTime(time_ms)

##### getInputItems()

##### getOutputItems()

##### getFeatureItems()

#### HIDReport.Item class

##### print(stream)


#### HIDReport.Item.Attributes class

##### print(stream)


#### HIDReport.CollectionPath

##### constructor(parent)

##### print(stream)
