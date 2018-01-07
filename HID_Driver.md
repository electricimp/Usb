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

### Basic concepts

The HID group consists of device that are used by humans to interact with computer systems. Typical examples of HID class devices include:
- Keyboards and pointing devices (mouse, trackballs, joysticks).
- Bar-code readers, thermometers, voltmeters
- LCD, LED indicator
- Speakers

To covers wide range of possible devices HID specification states that every device must describe its functionality in special form known for remote host and named as `descriptors`.  The HID driver may request those descriptors to get information about device identification and protocol required to speak with the device.

The main protocol unit, used to control HID, is `HID report`. HID report consists of a set of `items` -  an elementary peace of data that describes state of single part or group of parts of the device.

Every `item` is described by a set of attributes. Some of them are describing `item` function, another one is for item data interpretation.

To select necessary `item` application developer consults with [HID usage table](http://www.usb.org/developers/hidpage/Hut1_12v2.pdf) where to chose required attributes. For example, `USAGE_PAGE_KEYBOARD` indicates that the `item` may contain pressed key number, or may be used to control keyboard LED indicator. Than chosen `usage page` and `usage ID` are used to find required HID report `item`.

### Known limitation

The driver issues special command `"Get Descriptor"` to acquire HID report descriptor. Some devices doesn't support this command, so the driver doesn't match such devices. Workaround for this case is a subject for future release.

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
