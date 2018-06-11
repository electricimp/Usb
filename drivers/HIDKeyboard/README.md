## HID keyboard driver

This class is an example of [HIDDriver](../../HID_Driver.md) application. It exposes very simple API that allows to work with any devices that implements keyboard function: receive pressed key IDs and update keyboard LED indicator.


### Include the driver and dependencies

The driver depends on some constants and classes of [USB Framework](../../README.md), [HIDDriver](../../HID_Driver.md) so that required files has to be included by application developer. Please follow [Application Developer Guide](../../ApplicationDevelopmentGuide.md#include-the-framework-and-drivers) and [Generic HID driver](../../HID_Driver.md#include-the-driver-and-dependencies) instructions about how to start using of required classes.

**To add HID driver to your project, add** `#require "HIDKeyboard.nut:1.0.0"` **to the top of your device code.**

In the example below keyboard driver is included into an application:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "USB.HID.device.lib.nut:1.0.0"
#require "HIDKeyboard.nut:1.0.0"
```


### Complete example

```squirrel

kbrDrv < - null;

function keyboardEventListener(keys) {
    server.log("Keyboard event");

    local txt = "Keys: ";

    foreach (key in keys) txt += key + " ";

    txt += " are pressed".

    server.log(txt);
}

function usbEventListener(event, data) {
    if (event == "started") {
        local kbrDrv = data;

        // Receive new key state every second
        kbrDrv.startPoll(1000, keyboardEventListener);
    }
}

host <- USB.Host([HIDKeyboard]);

host.setEventListener(usbEventListener);

server.log("USB initialization complete");

```

### Custom matching procedure

This class  inherits all [HIDDriver](../HID_Driver.md) functions. To accept only those HID interfaces that represent physical keyboard devices, this class overrides internal function of parent class `_filter`. This allow this driver to be initialized only when at least one input report contain at least single input item with KEYBOARD Usage Page.

### Driver API

This driver exposes following function for application usage.

#### startPoll(time_ms, cb)

Starts keyboard polling with provided frequency. The function returns nothing but may throws if active polling is ongoing

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *time_ms* | Integer| Poll time in a range of [4 .. 1020] ms |
| *cb* | Function |user callback function that receive keyboard state |

The signature of callback *callback(keyset)*:

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *keyset* | Array of Integers | An array of pressed keys |


**Note** the function tries to issue "Set Idle" USB HID command that request keyboard hardware to setup key matrix poll time. If the command was issued successfully this class implementation expects HIDReport.getAsync() will generate next keyboard state event after desired amount of time. If the hardware doesn't support the command, the implementation expects to receive response from HIDReport.getAsync() immediately and will use timer to implement IDLE time  function.

#### stopPoll()

Stops keyboard polling.

#### setLEDs(ledList)

Update Keyboard LED status. The function accepts an array of integers with LED indicator IDs, declared at [HID usage table](http://www.usb.org/developers/hidpage/Hut1_12v2.pdf) chap.8.

The function may throw if argument is not array or due to USB issue.

**Note:** the function returns error string if the device doesn't have any LEDs indicators.

#### setLayout(newLayout)

Change keyboard layout. Receives keycode processor - the function that is used to convert native scancodes to desired values.
Setting NULL force the class to report native HID usage ID.

The class tries to use the [US_ASCII_LAYOUT](./US-ASCII.table.nut) function defined at [US-ASCII.table.nut](././US-ASCII.table.nut) as default layout if it is included by application developer.

##### Layout processor

This class uses special function that processes native keyboard scan codes to application specific values.

The [example](./US-ASCII.table.nut) of this processor may be a function that converts native code to language specific codes.

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *keyArray* | Array of Integers | the array of scancodes (integers) |

