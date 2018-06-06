## Generic HID Driver Implementation

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

The Human Interface Devices group consists of devices that are used by humans to interact with computer systems. Typical examples of HID class devices include:
- Keyboards and pointing devices (mouse, trackballs, joysticks).
- Bar-code readers, thermometers, voltmeters
- LCD, LED indicator
- Speakers

To cover wide range of possible devices HID specification states that every device must describe its functionality in special form known for remote host and named as `descriptors`.  The HID driver may request those descriptors to get information about device identification and protocol required to speak with the device.

The main protocol unit used to control HID is `HID report`. HID report consists of a set of `items` -  an elementary peace of data that describes state of single part or group of parts of the device.

Every `item` is described by a set of attributes. Some of them are describing `item` function, another one is for `item` data interpretation.

To select necessary `item` application developer consults with [HID usage table](http://www.usb.org/developers/hidpage/Hut1_12v2.pdf) where to chose required attributes. For example, `USAGE PAGE KEYBOARD` indicates that the `item` may contain pressed key number, or may be used to control keyboard LED indicator. Then chosen `usage page` and `usage ID` are used to find required HID report `item` inside `report`.

This HID Driver exposes a set of classes that express HID species in squirrel language. [HIDReport class](#hidreport-class) wraps a set of input, output and feature [HID Report Item](#hidreportitem-class) objects. Typically an application receives  [HIDReport](#hidreport-class) objects from [HIDDriver](#hiddriver-class) instance, then starts working with some of them if they are containing interested items.

There are two ways to read required data from device and only one way to send to device.

- [HIDReport class](#hidreport-class) exposes [request()](#request) function to read report data from device blocking way.
- [HIDDriver class](#hiddriver-class) contains a method to get [HIDReport](#hidreport-class) asynchronously.
- [HIDReport class](#hidreport-class) exposes [send()](#send) function to send report data to device blocking way.

Asynchronous read require special attention in a case when there are several input reports described by HID Report Descriptor. Actual report read through this function depends on the rate at which duplicate reports are generated for the specified report. See section __7.2.4__ of [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

When report was read, its input items (acquired with [getInputItems()](#getinputitems) function) contain updated data.

Output items (acquired with [getOutputItems()](#getoutputitems)) need to be updated individually prior to be sent to the device.

Interpretation of item value according to value data description (see [HIDReport.Item.Attributes class](#hidreportitemattributes-class)) is out of this driver implementation scope.

### Complete example

```squirrel

hidDrv < - null;

function hidEventListener(error, report) {
    server.log("HID event");

    // Do with report here

    // Start new read
    hidDriver.getAsync(hidEventListener);
}

function usbEventListener(event, data) {
    if (event == "started") {
        local hidDrv = data;

        hidDriver.getAsync(hidEventListener);
    }
}

host <- USB.Host([HIDDriver]);

host.setEventListener(usbEventListener);

server.log("USB initialization complete");

```

### An application of this driver

[HIDKeyboard](examples/HID_Keyboard) is an example of this driver application. It converts this driver API to simple single function API.

### Known limitation

The driver issues special command `"Get Descriptor"` to acquire HID report descriptor. Some devices doesn't support this command, so the driver doesn't match such devices. Workaround for this case is a subject for future release.

### Public API

#### HID constants

Following constants is used to compose [HIDReport.Item.itemFlags](#hidreportitem-class) field.

See section __6.2.2.5__ of [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

| Constant name | Constant description |
| ------------- | -------------------- |
| HID_IOF_CONSTANT           | the item is constant value |
| HID_IOF_DATA               | the item is data value |
| HID_IOF_VARIABLE           | the item creates variable data fields in reports |
| HID_IOF_ARRAY              | the item creates array data fields in reports |
| HID_IOF_RELATIVE           | the data is relative</br>(indicating the change in value from the last report) |
| HID_IOF_ABSOLUTE           | the data is absolute</br>(based on a fixed origin) |
| HID_IOF_WRAP               | the data “rolls over”</br>when reaching either the extreme high or low value |
| HID_IOF_NO_WRAP            | the data doesn't “rolls over”</br>when reaching either the extreme high or low value |
| HID_IOF_NON_LINEAR         | the raw data from the device has been processed |
| HID_IOF_LINEAR             | the raw data from the device equals to logic data |
| HID_IOF_NO_PREFERRED_STATE | the control has not a preferred state |
| HID_IOF_PREFERRED_STATE    | the control has a preferred state  |
| HID_IOF_NULLSTATE          | the control has a state in which it is not sending meaningful data |
| HID_IOF_NO_NULL_POSITION   | the control has not a state in which it is not sending meaningful data|
| HID_IOF_VOLATILE           | the Feature or Output control's value should be changed by the host|
| HID_IOF_NON_VOLATILE       | the Feature or Output control's value may be changed not only by the host|
| HID_IOF_BUFFERED_BYTES     | the contents are not interpreted as a single numeric quantity |
| HID_IOF_BITFIELD           | the control emits a fixed-size stream of bytes |

#### HIDDriver class

**HIDDriver** is a class that represent single HID interface of any device. It retrieves HID report descriptor from peer device and convert it to a set of [HIDReport](#hidreport-class) instances. Inherits basic [USB.Driver](./DriverDevelopmentGuide.md#usbdriver-class) class.

##### match(device, interfaces)

Overridden [USB.Driver.match()](DriverDevelopmentGuide.md#matchdeviceobject-interfaces) function.

This function looks into provided [interface](./DriverDevelopmentGuide.md#interface-descriptor) list, searching for interface with class value equls 3 (HID class).  Then it try to extract and parse HID Report descriptor (see [notes](#known-limitation)). If it meets any issue the function returns `null`.

##### getReports()

Returns an array of [HIDReport](#hidreport-class) instances

##### getAsync(cb)

Performs read through Interrupt In Endpoint. The result depends on how many Input Reports are available at associated interface. In case of multiple Input Reports, the result depends on duplicate report generation rate (can be changed by [setIdleTime](#setidletimetime_ms)). See section __7.2.4__ of [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

May throw an exception if there is ongoing read from related endpoint, or input endpoint is closed, or something happens during call to native USB API, or interface descriptor doesn't describe input endpoint, or input endpoint was not open due to limit of native [USB API](https://electricimp.com/docs/api/hardware/usb/)

If endpoint was not open due to reached limit of open Interrupt Endpoints, the developer may use synchronous version provided by [HIDReport](#request) class.

###### Callback function signature

The must accept the following parameters.

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *error*   | Any  | Non null parameter indicates presence of error state |
| *report*  | [HIDReport](#hidreport-class) | Read report |

#### HIDReport class

This class represents HID Report - a data packet that can be transferred from/to the device.

##### request()

Obtains HID state from device through Endpoint 0. No result is returned but it may throws if error happens during transfer or control endpoint is closed

##### send()

Synchronous send of output items. The items value need to be updated prior to call. Throws if endpoint is closed or something happens during call to native USB API

##### setIdleTime(time_ms)

Issue "Set Idle" command for the associated interface.  Returns nothing but may trow if  EP0 is closed, or something happens during call to native USB API.

The function accepts following parameters:

| Parameters name | Type | Description |
| --------------- | ---- | ----------- |
| *time_ms* | Integer | IDLE time (in milliseconds) for this report between 4 - 1020 ms |

See more at section __7.2.4__ of [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf).

##### getInputItems()

Returns an array of input items or null if no items was found at the report descriptor.

##### getOutputItems()

Returns an array of output items or null if no items was found at the report descriptor.

##### getFeatureItems()

Returns an array of feature items or null if no items was found at the report descriptor.


#### HIDReport.Item class

This represent single report item at report packet. It is just container for a number of attributes.

| Class field | Type | Description |
| ----------- | ---- | ----------- |
| *attributes* | [HIDReport.Item.Attributes](#hidreportitemattributes-class) | Defines item tags |
| *itemFlags*  | Bitfield/Integer | Defines item value attributes. [HID Constants](#hid-constants) may be used for tag interpretation |
| *collectionPath* | [HIDReport.Collection](#hidreportcollectionpath) | Defines the collection this item is part of |

##### print(stream)

#### get()

Returns last item value.

#### set(value)

Updates item value with provided data. The parameter should be convertible to Integer with `tointeger()` function.


#### HIDReport.Item.Attributes class

This class is container for item tags.

| Class field | Type | Description |
| ----------- | ---- | ----------- |
| *logicalMaximum* | Integer | Maximum value that a variable or array item will report |
| *logicalMinimum* | Integer | Minimum value that a variable or array item will report|
| *physicalMaximum* | Integer | This represents the Logical Maximum  with units applied to it |
| *physicalMinimum* | Integer | This represents the Logical Minimum with units applied to it |
| *unitExponent* | Integer | Value of the unit exponent |
| *unitType* | Integer | Item unit |
| *usagePage* | Integer | The item Usage Page |
| *usageUsage* | Integer | The item usage ID|
| *bitSize* | Integer | A number of bits this item occupies in the report|

##### print(stream)

Debug function. Prints items with provided function `stream`.

#### HIDReport.Collection

This class is used to create items collection hierarchy. Collection Path constructs as chain of Collection.

##### constructor(parent)

New collection is always created as part of collection path and thus should receive previous chain element. Or `null` if this first element.

##### print(stream)

Debug function. Prints items with provided function `stream`.