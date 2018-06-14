## Generic HID Driver Implementation

The generic Human Interface Devices(HID) driver implements basic
functionality required to start using any device that exposes HID interfaces.
It allows to discover, read and change state of any sensors, actuators,
indicators and other physical parts of such devices.

It is recommended to be familiar with [Device Class Definition for
Human Interface Devices](http://www.usb.org/developers/hidpage/HID1_11.pdf)
prior to using this driver.

### Include the HID Driver and Dependencies

The driver depends on some constants and classes of USB Framework,
so that framework has to be included by application developer. Please follow
[Application Developer Guide](./ApplicationDevelopmentGuide.md#include-the-framework-and-drivers)
instruction about how to start using of USB framework.

**NOTE:** To add the HID driver to your application, add the following statement
on top of your code:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "USB.HID.device.lib.nut:1.0.0"
```
to the top of your device code.

### Basic Doncepts

The Human Interface Devices group consists of devices that are used by humans to interact with computer systems. Typical examples of HID class devices are:

- Keyboards and pointing devices (mouse, trackballs, joysticks)
- Bar-code readers, thermometers, voltmeters
- LCD, LED indicator
- Speakers

The USB HID class requires that every device describes how it will communicate
with the host device in order to accurately predict and define all current and
future human interface devices. During enumeration the device describes how its
reports are to be structured so that the host device can properly prepare to
receive this information.

Each USB HID interface communicates with the host using either a `control` or
an `interrupt` endpoints. `Isochronous` and `bulk` endpoints are not used in
HID class devices. Both IN and OUT control transfers are required for enumeration;
only an IN interrupt transfer is required for HID reports. OUT interrupt
transfers are kooptional in HID-class devices.

The host periodically polls the device's interrupt IN endpoint during operation.
When the device has data to send it forms a report and sends it as a reply to the
poll token. When a vendor makes a
custom USB HID class device, the reports formed by the device need to match the
report description given during enumeration and the driver installed on the host
system. In this way it is possible for the USB HID class to be extremely flexible.

For more details on the HID reports structure and attributes please refer to
HID usage table [specification](http://www.usb.org/developers/hidpage/Hut1_12v2.pdf).

The generic HID Driver implementation exposes a set of classes
that implement some of the HID Concepts
in Squirrel. [HIDReport class](#hidreport-class) wraps a
set of input, output and feature [HID Report Item](#hidreportitem-class)
objects. Typically applications deal with [HIDReport](#hidreport-class)
instances obtained from [HIDDriver](#hiddriver-class).

There are two ways to retrieve data from a device and only one way
to transfer data to a device. They are implemented as
the following APIs:

- [HIDReport.request()](#request), a synchronous request to receive inbound report data if available
- [HIDDriver.getAsync](#getasynccb) allows to asynchronously read input items for the driver reports
- [HIDReport.send](#send) Synchronously send the output items

**NOTE:** Asynchronous read require special attention in a case when there are
several input reports described by HID Report Descriptor. Actual report
read through this function depends on the rate at which duplicate reports
are generated for the specified report. See section __7.2.4__ of
[HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

When report is successfully read, its input items
(can be acquired via [getInputItems()](#getinputitems) function)
are updated with the new data.

Output items (can acquired via [getOutputItems()](#getoutputitems))
need to be updated individually prior to sending them to the device.

Data conversion between different measuring units and
logical-to-physical data item values mapping are out of the scope
of the driver implementation.

### Complete Example

```squirrel

hidDrv < - null;

hidDriver <- null;

function hidEventListener(error, report) {
    server.log("HID event");

    // Do with report here

    // Start new read
    hidDriver.getAsync(hidEventListener);
}

function usbEventListener(event, driver) {
    if (event == USB_DRIVER_STATE_STARTED) {
    	hidDriver = driver;
        hidDriver.getAsync(hidEventListener);
    }
}

host <- USB.Host(hardware.usb, [HIDDriver]);

host.setDriverListener(usbEventListener);

server.log("USB initialization complete");
```

### Real-World Application Example

Please refer to [HIDKeyboard](./../Driver/HIDKeyboard) is an
example of this driver application.

### Known Limitation

The driver issues special command `"Get Descriptor"` to acquire HID report
descriptor. Some devices don't support this command, so the driver doesn't
match such devices. This issue may be addressed in the future releases.

### Public API

#### HID Constants

Following constants are used to compose
[HIDReport.Item.itemFlags](#hidreportitem-class) field.

See section __6.2.2.5__ of
[HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

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

#### HIDDriver Class

**HIDDriver** is a class that represents a single HID interface of any device.
It retrieves HID report descriptor from the corresponding device and converts it into a set
of [HIDReport](#hidreport-class) instances. The class extends the base
[USB.Driver](./DriverDevelopmentGuide.md#usbdriver-class) class.

##### match(device, interfaces)

Overrides the base
[USB.Driver.match()](DriverDevelopmentGuide.md#matchdeviceobject-interfaces) method.

This function looks into the list of provided [interfaces](./DriverDevelopmentGuide.md#interface-descriptor),
and finds those of class value USB_CLASS_HID (`3`). Then it tries
to extract and parse HID Report descriptors (see [notes](#known-limitation)).
If a problem occurs the function returns `null`. Otherwise the methods returns
a list of HIDDriver instances, one per each of the corresponding HID interface.

##### getReports()

Returns an array of [HIDReport](#hidreport-class) instances

##### getAsync(cb)

Performs read through Interrupt In Endpoint. The result depends on how many
Input Reports are available at associated interface. In case of multiple
Input Reports, the result depends on duplicate report generation rate
(can be changed by [setIdleTimeMs](#setidletimetime_ms)). See section
__7.2.4__ of [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf)
for more details.

May throw an exception if there is ongoing read from related endpoint, or
input endpoint is closed, or something happens during call to native USB API,
or interface descriptor doesn't describe input endpoint, or input endpoint
was not open due to limit of native [USB API](https://electricimp.com/docs/api/hardware/usb/)

If endpoint was not open due to reached limit of open Interrupt Endpoints,
the developer may use synchronous version provided by [HIDReport](#request) class.

###### Callback function signature

The must accept the following parameters.

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *error*   | Any  | Non null parameter indicates presence of error state |
| *report*  | [HIDReport](#hidreport-class) | Read report |

#### HIDReport Class

This class represents HID Report - a data packet
that can be transferred from/to the device.

##### request()

Obtains HID state from device through Endpoint 0.
No result is returned but it may throws if error happens during
transfer or control endpoint is closed

##### send()

Synchronous send of output items. The items value need to be updated
prior to call. Throws if endpoint is closed or something happens
during call to native USB API

##### setIdleTimeMs(millis)

Issue "Set Idle" command for the associated interface. Returns nothing
but may trow if  EP0 is closed, or something happens during call to native USB API.

The function accepts following parameters:

| Parameters name | Type | Description |
| --------------- | ---- | ----------- |
| *millis* | Integer | IDLE time (in milliseconds) for this report between 4 - 1020 ms |

See more at section __7.2.4__ of
[HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf).

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
| *itemFlags*  | Integer | Defines item value attributes. [HID Constants](#hid-constants) may be used for tag interpretation |
| *collectionPath* | [HIDReport.Collection](#hidreportcollectionpath) | Defines the collection this item is part of |

##### print(stream)

#### get()

Returns last item value.

#### set(value)

Updates item value with provided data. The parameter should be
convertible to Integer with `tointeger()` function.


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

This class is used to create items collection hierarchy. Collection Path
constructs as chain of Collection.

##### constructor(parent)

New collection is always created as part of collection path and thus should
receive previous chain element. Or `null` if this first element.

##### print(stream)

Debug function. Prints items with provided function `stream`.