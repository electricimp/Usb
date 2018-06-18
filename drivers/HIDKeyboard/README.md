## HID Keyboard Driver

This class is an example of HID Driver [Guide](../../docs/HIDDriverGuide.md) application.
It exposes very simple API that allows to work with any devices that implement
keyboard function: receive pressed key IDs and update the keyboard LED indicator.

### Include the Driver and Dependencies

The driver depends on some constants and classes of the
[USB Framework](../../docs/DriverDevelopmentGuide.md) so that required files has
to be included by application developer. Please follow
[Application Developer Guide](../../docs/ApplicationDevelopmentGuide.md#including-usb-framework-and-driver-libraries)
on how to include the generic USB framework library.

**NOTE:** to add the Boot Keyboard driver into your project, use the following statement
on top of you application code:
```
#require "USB.device.lib.nut:1.0.0"
#require "USB.HID.device.lib.nut:1.0.0"
```
and then either include the HI Keyboard into you application
by copy-pasting the HID Keyboard Driver code
or use the Builder's [include statements](https://github.com/electricimp/builder#include).

In the example below, the HID keyboard driver is included into an application:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "USB.HID.device.lib.nut:1.0.0"
@include "github:electricimp/usb/drivers/HIDKeyboard/HIDKeyboard.device.lib.nut"
@include "github:electricimp/usb/drivers/HIDKeyboard/US-ASCII.table.nut"
```

The code above includes the [US-ASCII.table.nut](./US-ASCII.table.nut) file, which defines the
default keyboard [layout](#setlayoutnewlayout) for the driver.

### Complete Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "USB.HID.device.lib.nut:1.0.0"
@include "github:electricimp/usb/drivers/HIDKeyboard/HIDKeyboard.device.lib.nut"
@include "github:electricimp/usb/drivers/HIDKeyboard/US-ASCII.table.nut"

kbrDrv <- null;

function keyboardEventListener(keys) {
    server.log("[APP] Keyboard event");
    local txt = "[APP] Keys: ";
    foreach (key in keys) {
        txt += key + " ";
    }
    txt += " are pressed";
    server.log(txt);
}

function usbDriverListener(event, driver) {
    if (event == USB_DRIVER_STATE_STARTED) {
        local kbrDrv = driver;

        // Receive new key state every second
        kbrDrv.startPoll(1000, keyboardEventListener);
    }
}

host <- USB.Host(hardware.usb, [HIDKeyboardDriver]);
host.setDriverListener(usbDriverListener);

server.log("[APP] USB initialization complete");
```

**NOTE:** Please note, the code above should be built
with the [Builder](https://github.com/electricimp/builder) preprocessor.

For more examples please refer to the [examples](./examples) folder.

### Custom Matching Procedure

This class extends all [HIDDriver](./../../docs/HIDDriverGuide.md#public-api) APIs.
To accept only those HID interfaces that represent physical keyboard devices,
this class overrides internal method `_filter` of the parent class. This allows
this driver to be initialized only when at least one input report contain at
least single input item with the `KEYBOARD` Usage Page.

### Driver API

This driver exposes the following API to applications.

#### startPoll(millis, cb)

Starts keyboard polling with the provided period. The function returns nothing
but may throw an exception if there is a polling that is running already.

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *millis* | Integer| Poll time in a range of [4 .. 1020] ms |
| *cb* | Function |user callback function that receive keyboard state |

The signature of callback *callback(keyset)*:

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *keyset* | Array of Integers | An array of pressed keys |


**NOTE:** the function tries to issue "Set Idle" USB HID command that requests
the keyboard hardware to setup key matrix poll time. If the command was issued
successfully this class implementation expects `HIDReport.getAsync()` to
generate a next keyboard state event after the desired amount of time. If the hardware
doesn't support the command, the implementation expects to receive response
from `HIDReport.getAsync()` immediately and will use a timer to implement the `IDLE` time function.

#### stopPoll()

Stops polling the keyboard events.

#### setLEDs(ledList)

Update Keyboard LED status. The function accepts an array of
integers with LED indicator IDs, declared at
[HID usage table](http://www.usb.org/developers/hidpage/Hut1_12v2.pdf) chap.8.

The function may throw an exception if the argument is not array or due to a USB issue.

**NOTE:** the function returns error string if the device doesn't have any LEDs indicators.

#### setLayout(newLayout)

Changes the keyboard layout. Receives keycode processor - the function that is used
to convert native scancodes to desired values.
Setting `NULL` makes the driver reporting the native key codes.

The class tries to use the [US_ASCII_LAYOUT](./US-ASCII.table.nut)
which is a default layout for the driver.

##### Layout processor

This class uses special function that processes native keyboard scan codes to application specific values.

The [example](./US-ASCII.table.nut) of this processor can be a function that
converts the native key codes to language specific codes.

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *keyArray* | Array of Integers | the array of scancodes (integers) |

Returns the converted code values.

