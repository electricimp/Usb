# HID Keyboard Driver Example #

This driver is an example of an HID [Driver](../GenericHID_Driver/README.md) application. It exposes a very simple API that allows working with any devices that implement the keyboard function: receive pressed key IDs and update the keyboard LED indicator.

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

### Include The Driver And Its Dependencies ###

The driver depends on constants and classes within the [USB Drivers Framework](../../docs/DriverDevelopmentGuide.md#usb-drivers-framework-api-specification).

To add the HID Keyboard driver to your project, add `#require "USB.device.lib.nut:1.1.0"` top of you application code and then either include the HID Keyboard driver in your application by pasting its code into yours or by using [Builder's @include statement](https://github.com/electricimp/builder#include):

```squirrel
#require "USB.device.lib.nut:1.1.0"

@include "github:electricimp/usb/drivers/GenericHID_Driver/USB.HID.device.lib.nut"
@include "github:electricimp/usb/drivers/HIDKeyboard/HIDKeyboard.device.lib.nut"
@include "github:electricimp/usb/drivers/HIDKeyboard/US-ASCII.table.nut"
```

**Note** The file [`US-ASCII.table.nut`](./US-ASCII.table.nut) defines the default keyboard [layout](#setlayoutnewlayout) for the driver.

## Custom Matching Procedure ##

This class extends all [HIDDriver](../GenericHID_Driver/README.md#hiddriver-class) APIs. To accept only those HID interfaces that represent physical keyboard devices, this class overrides the private method *_filter()* of the parent class. This allows this driver to be initialized only when at least one input report contains at least single input item with the `KEYBOARD` Usage Page.

## Driver Class Custom API ##

This driver exposes the following API to applications.

### startPoll(*pollTime, callback*) ###

This method starts keyboard polling with the specified period. It may throw an exception if polling is already taking place.

The method tries to issue the `"Set Idle"` USB HID command, which requests the keyboard hardware to set the key matrix poll time. If the command was issued successfully, this class implementation expects *HIDReport.getAsync()* to generate the next keyboard state event after the desired amount of time. If the hardware doesn't support the command, the implementation expects to receive a response from *HIDReport.getAsync()* immediately and will use a timer to implement the `IDLE` function.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *pollTime* | Integer| Yes | Poll time in milliseconds in the range 4-1020ms |
| *callback* | Function | Yes | A function to be called on write completion or error |

#### Callback Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *keyset* | Array of integers | The pressed keys |

#### Return Value ####

Nothing.

### stopPoll() ###

This method stops polling the keyboard.

#### Return Value ####

Nothing.

### setLEDs(*ledList*) ###

This method updates the Keyboard LED status. It accepts an array of integers as LED indicator IDs, as declared in Chapter 8 of the [HID usage table](https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf) chap.8.

The method may throw an exception if the argument is not an array or due to a USB issue.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *ledList* | Array of integers | Yes | LED indicator IDs |

#### Return Value ####

Nothing, or an error message if the device has no LEDs indicators.

### setLayout(*newLayout*) ###

This method changes the keyboard layout. It receives a keycode processor &mdash; a function that is used to convert native scancodes to desired values. Passing in `null` causes the driver to report native key codes.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *newLayout* | Function | Yes | A keycode processing function |

#### Layout Processor ####

This driver uses a special function to processes native keyboard scan codes to application-specific values.

An [example](./US-ASCII.table.nut) of this processor converts the native key codes to language-specific codes.

##### Parameters #####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *keyArray* | Array of integers | Yes | Array of scencode integers |

##### Return Value #####

It returns the converted code values

## Complete Example ##

**Note** The code below should be built with the [Builder](https://github.com/electricimp/builder) preprocessor.

```squirrel
#require "USB.device.lib.nut:1.1.0"
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
    txt += " pressed";
    server.log(txt);
}

function usbDriverListener(event, driver) {
    if (event == USB_DRIVER_STATE_STARTED) {
        local kbrDrv = driver;

        // Receive new key state every second
        kbrDrv.startPoll(1000, keyboardEventListener);
    }
}

host <- USB.Host(hardware.usb, [HIDKeyboardDriver], true);
host.setDriverListener(usbDriverListener);
server.log("[APP] USB initialization complete");
```

For more examples please refer to the [examples](./examples) folder.