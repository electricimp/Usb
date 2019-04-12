# Generic HID Driver Implementation Example #

This generic Human Interface Devices (HID) driver implements the base functionality required to start using any device with an HID interface. It enables device discovery, and reading and changing the states of any sensors, actuators, indicators and other physical parts of such devices.

Please familiarize yourself with the [Device Class Definition for Human Interface Devices](http://www.usb.org/developers/hidpage/HID1_11.pdf) specification before using this driver.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## Include The HID Driver Library ##

This driver depends on the base USB Drivers Framework, which needs to be included in your application code:

```squirrel
#require "USB.device.lib.nut:1.0.1"
```

and then either include the Generic HID driver in you application by pasting its code into yours or by using [Builder's @include statement](https://github.com/electricimp/builder#include):

```squirrel
#require "USB.device.lib.nut:1.0.1"
@include "github:electricimp/usb/drivers/GenericHID_Driver/USB.HID.device.lib.nut"
```

## Basic Concepts ##

The Human Interface Devices group consists of devices that are used by people to interact with computer systems. Typical examples of HID class devices are:

- Keyboards and pointing devices (mouse, trackballs, joysticks).
- Barcode readers, thermometers, voltmeters.
- LCD displays, LED indicators.
- Speakers.

The USB HID class requires that every device describes how it will communicate with the host device. During enumeration, the device describes how its reports are to be structured so that the host device can properly prepare to receive this information.

Each USB HID interface communicates with the host using either a Control or an Interrupt endpoint. Isochronous and Bulk endpoints are not used in HID class devices. Both In and Out control transfers are required for enumeration; only an Interrupt In transfer is required for HID reports. Interrupt Out transfers are optional in HID-class devices.

The host periodically polls the device's Interrupt In endpoint during operation. When the device has data to send it forms a report and sends it as a reply to the poll token. When a vendor makes a custom USB HID class device, the reports formed by the device need to match the report description given during enumeration and to the driver installed on the host system.

For more details on the HID report structure and attributes, please refer to the HID usage table [specification](http://www.usb.org/developers/hidpage/Hut1_12v2.pdf).

The Generic HID Driver implementation exposes a set of classes that implement some of the HID Concepts in Squirrel. [HIDReport class](#hidreport-class) wraps a set of input, output and feature [HID Report Item](#hidreportitem-class) objects. Typically, applications deal with [HIDReport](#hidreport-class) instances obtained from [HIDDriver](#hiddriver-class).

There are two ways to retrieve data from a device and only one way to transfer data to a device. They are implemented as the following APIs:

- [HIDReport.request()](#request) &mdash; Asynchronous request to receive inbound report data if available.
- [HIDDriver.getAsync](#getasynccallback) &mdash; Asynchronously read Input Items for the driver reports.
- [HIDReport.send](#send) &mdash; Synchronously send the Output Items.

**Note** Asynchronous reads require special attention in cases when there are several input reports described by the HID Report Descriptor. Data read through this function depends on the rate at which duplicate reports are generated for the specified report. Please see section 7.2.4 of the [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

When a report is successfully read, its Input Items (which can be acquired via [*getInputItems()*](#getinputitems) function) are updated with the new data.

Output Items (which can acquired via [*getOutputItems()*](#getoutputitems)) must be set or updated individually before they are sent to the device.

Data conversion between different measuring units and logical-to-physical data item values mapping are out of the scope of this driver implementation.

## Real-World Application Example ##

Please refer to [HIDKeyboard](./../drivers/HIDKeyboard) as an example of this driver application.

## Known Limitation ##

The driver issues special command `"Get Descriptor"` to acquire the HID report descriptor. Some devices don't support this command, so the driver doesn't
match such devices. This issue may be addressed in a future release.

## Complete Example ##

```squirrel
hidDriver <- null;

function hidEventListener(error, report) {
  server.log("HID event");

  // Process the report here

  // Initiate a new read operation
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

## The Driver API ##

### HID Constants ###

Following constants are used to compose [HIDReport.Item.itemFlags](#hidreportitem-class) data. See section 6.2.2.5 of the [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

| Constant | Description |
| --- | --- |
| *HID_IOF_CONSTANT* | The item is constant value |
| *HID_IOF_DATA* | The item is data value |
| *HID_IOF_VARIABLE* | The item creates variable data fields in reports |
| *HID_IOF_ARRAY* | The item creates array data fields in reports |
| *HID_IOF_RELATIVE* | The data is relative (indicating the change in value from the last report) |
| *HID_IOF_ABSOLUTE* | The data is absolute (based on a fixed origin) |
| *HID_IOF_WRAP* | The data 'rolls over' when reaching either the extreme high or low value |
| *HID_IOF_NO_WRAP* | The data doesn't 'roll over' when reaching either the extreme high or low value |
| *HID_IOF_NON_LINEAR* | The raw data from the device has been processed |
| *HID_IOF_LINEAR* | The raw data from the device equals to logic data |
| *HID_IOF_NO_PREFERRED_STATE* | The control has not a preferred state |
| *HID_IOF_PREFERRED_STATE* | The control has a preferred state  |
| *HID_IOF_NULLSTATE* | The control has a state in which it is not sending meaningful data |
| *HID_IOF_NO_NULL_POSITION* | The control has not a state in which it is not sending meaningful data|
| *HID_IOF_VOLATILE* | The Feature or Output control's value should be changed by the host|
| *HID_IOF_NON_VOLATILE* | The Feature or Output control's value may be changed not only by the host|
| *HID_IOF_BUFFERED_BYTES* | The contents are not interpreted as a single numeric quantity |
| *HID_IOF_BITFIELD* | The control emits a fixed-size stream of bytes |

## HIDDriver Class ##

**HIDDriver** is a class that represents a single HID interface of any device. It retrieves the HID report descriptor from the corresponding device and converts it into a set of [HIDReport](#hidreport-class) instances. The class extends the base
[USB.Driver](./DriverDevelopmentGuide.md#usbdriver-class) class.

It matches against USB_CLASS_HID (`3`) devices.

### getReports() ###

This method provides a set of [HIDReports](#hidreport-class).

#### Return Value ####

Array of [HIDReport](#hidreport-class) instances

### getAsync(*callback*) ###

This method performs a read through an Interrupt IN endpoint. The result depends on how many Input Reports are available for the associated interface. In case of multiple Input Reports, the result depends on duplicate report generation rate (which can be changed with [*setIdleTimeMs()*](#setidletimemsmillis)). Please see section 7.2.4 of the [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

The method may throw an exception in the following situations:

1. There is an ongoing read operation from the corresponding endpoint.
2. The input endpoint is closed.
3. An error occurred at the imp API USB object level.
4. The interface descriptor doesn't declare any IN endpoints on the device.
5. The input endpoint was not open due to the limits of the [imp API USB object](https://developer.electricimp.com/api/hardware/usb).

**Note** If the endpoint was not open due to the limit on the number of open Interrupt Endpoints, the developer may use the synchronous [*HIDReport.request()*](#request) call, which works through the endpoint 0 and isn't affected by the limitation.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to be called on write completion or error |

#### Callback Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *error* | String | An error message, or `null` in the case of no error |
| *report* | [HIDReport](#hidreport-class) | A read report |

## HIDReport Class ##

This class represents HID Reports. An HID Report is a data packet that can be transferred to or from a device.

### request() ###

This method obtains HID state information from the device through endpoint 0. It but may throw an exception if an error occurs during the transfer or if the
control endpoint is closed.

#### Return Value ####

Nothing.

### send() ###

This method synchronously sends the pre-set output items. The items' values need to be updated prior to the call. It throws an exception if the endpoint is closed or an error occurs during the native USB API call.

#### Return Value ####

Nothing.

### setIdleTimeMs(*millis*) ###

This method issues the `"Set Idle"` command through the associated endpoint. It may throw an exception if endpoint 0 is closed or an error occurs during the native USB API call.

Please refer to section 7.2.4 of the [HID specification](http://www.usb.org/developers/hidpage/HID1_11.pdf) for more details.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *millis* | Integer | The idle time in milliseconds for the report, in the range 4-1020ms |

#### Return Value ####

Nothing.

### getInputItems() ###

This method retrieves input items from the report descriptor.

#### Return Value ####

Array of input items, or `null`.

### getOutputItems() ###

This method retrieves output items from the report descriptor.

#### Return Value ####

Array of output items, or `null`.

### getFeatureItems() ###

This method retrieves feature items from the report descriptor.

#### Return Value ####

Array of feature items, or `null`.

## HIDReport.Item Class ##

The class represents a single report item in an HID Report. It has a number of properties:

| Property | Type | Description |
| --- | --- | --- |
| *attributes* | [HIDReport.Item.Attributes](#hidreportitemattributes-class) | HID report item tags |
| *itemFlags*  | Integer | Defines HID Report Item value attributes (see [HID Constants](#hid-constants)). Should be used by the application for processing the Item's data |
| *collectionPath* | [HIDReport.Collection](#hidreportcollection) | Identifies the collection that the Item belongs to |

### print(*stream*) ###

Debug function, prints the report data to the specified function `stream`, for example, `server.log`.

### get() ###

Returns the present HID report item value.

### set(*value*) ###

Updates HID report item value with the data provided. The parameter should be
convertible to Integer with `tointeger()` function.

## HIDReport.Item.Attributes Class ##

The class that contains the HID report item attributes.

| Class field | Type | Description |
| ----------- | ---- | ----------- |
| *logicalMaximum* | Integer | Maximum value that a variable or array item will report |
| *logicalMinimum* | Integer | Minimum value that a variable or array item will report|
| *physicalMaximum* | Integer | This represents the Logical Maximum with units applied to it |
| *physicalMinimum* | Integer | This represents the Logical Minimum with units applied to it |
| *unitExponent* | Integer | Value of the unit exponent |
| *unitType* | Integer | Item unit |
| *usagePage* | Integer | The item Usage Page |
| *usageUsage* | Integer | The item usage ID|
| *bitSize* | Integer | A number of bits this item occupies in the report|

### print(*stream*) ###

This method is a debug function that prints report data via the specified method, eg, **server.log**.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *stream* | Function | Yes | The Function to handle the output |

#### Example ####

```squirrel
print(server.error);
```

## HIDReport.Collection ##

This class is used to create Items' Collection hierarchies. Collection Paths are constructed as a chain of linked `HIDReport.Collection` instances.

### Constructor: HIDReport.Collection(*parent*) ###

A new Collection is always created as part of a Collection Path and thus should receive the previous element in the chain as an argument. 

If a new Path is to be created, pass in `null`.

### print(*stream*) ###

This method is a debug function that prints report data via the specified method, eg, **server.log**.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *stream* | Function | Yes | The Function to handle the output |
