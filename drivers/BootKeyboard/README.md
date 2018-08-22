# Boot Keyboard Driver Example #

This class is an example of a USB Devices Framework [USB.Driver](../../docs/DriverDevelopmentGuide.md#usbdriver-class-usage) implementation. It exposes a very simple API that allows it to work with any device that implements the [Boot Keyboard Protocol](http://www.usb.org/developers/hidpage/HID1_11.pdf).

**Note** Please use this driver for reference only. It was tested with a limited number of devices and may not support all devices of that type.

## Include The Driver And Its Dependencies ##

The driver depends on constants and classes within the [USB Drivers Framework](../../docs/DriverDevelopmentGuide.md). Please
see the [Application Developer Guide](../../docs/ApplicationDevelopmentGuide.md#including-usb-framework-and-driver-libraries) to learn how to include the generic USB framework library.

**Note** To add the Boot Keyboard driver into your project, add the following statement on top of you application code:

```
#require "USB.device.lib.nut:1.0.0"
```

and then either include the Boot Keyboard driver in you application by pasting its code into yours or by using [Builder's @include statement](https://github.com/electricimp/builder#include):

```squirrel
#require "USB.device.lib.nut:1.0.0"
@include "github:electricimp/usb/drivers/BootKeyboard/BootKeyboard.device.lib.nut"
```

## Custom Matching Procedure ##

This driver matches only devices [interfaces](../../docs/DriverDevelopmentGuide.md#interface-descriptor) of *class* 3 (HID), *subclass* 1 (Boot) and *protocol* 1 (keyboard).

## Keyboard Status Table ##

Both [*getKeyStatusAsync()*](#getkeystatusasynccallback) and [*getKeyStatus()*](#getkeystatus) return the keyboard state as a table containing some or all of the following keys:

| Table Key | Type | Description |
| --- | --- | --- |
| *error* | String | The field is present if any error occurred |
| *LEFT_CTRL* | Integer | Left Ctrl status (1/0) |
| *LEFT_SHIFT* | Integer | Left Shift status (1/0) |
| *LEFT_ALT* | Integer| Left Alt status (1/0) |
| *LEFT_GUI* | Integer| Left Gui status (1/0) |
| *RIGHT_CTRL* | Integer| Right Ctrl status (1/0) |
| *RIGHT_SHIFT* | Integer| Right Shift status (1/0) |
| *RIGHT_ALT* | Integer | Right Alt status (1/0) |
| *RIGHT_GUI* | Integer | Right Gui status (1/0) |
| *Key0* | Integer | First scan code or 0 |
| *Key1* | Integer | Second scan code or 0 |
| *Key2* | Integer | Third scan code or 0 |
| *Key3* | Integer | Fourth scan code or 0 |
| *Key4* | Integer | Fifth scan code or 0 |
| *Key5* | Integer | Sixth scan code or 0 |

## Complete Example ##

```squirrel
#require "PrettyPrinter.class.nut:1.0.1"
#require "JSONEncoder.class.nut:1.0.0"

// Include the USB framework and the BootKeyboard library
#require "USB.device.lib.nut:1.0.0"
@include "github:electricimp/usb/drivers/BootKeyboard/BootKeyboard.device.lib.nut"

// Debug print setup
pp     <- PrettyPrinter(null, false);
print  <- pp.print.bindenv(pp);

kbrDrv <- null;
leds   <- KBD_NUM_LOCK;

function blink() {
  if (!kbrDrv) return;

  kbrDrv.setLeds(leds);
  leds = leds << 1;
  if (leds > KBD_SCROLL_LOCK) leds = KBD_NUM_LOCK;
  imp.wakeup(1, blink);
}

function keyboardEventListener(status) {
  if (!kbrDrv) return;

  server.log("[App] Keyboard event");
  local error = "error" in status ? status.error : null;

  if (error == null) {
    print(status);
    kbrDrv.getKeyStatusAsync(keyboardEventListener);
  } else {
    server.error("[App] Error received: " + error);
  }
}

function usbDriverListener(event, driver) {
  if (event == USB_DRIVER_STATE_STARTED) {
    server.log("[App] BootKeyboardDriver started");
    kbrDrv = driver;

    // Report only when key status is changed
    kbrDrv.setIdleTimeMs(0);

    // Receive new key state every second
    kbrDrv.getKeyStatusAsync(keyboardEventListener);

    // Start keyboard leds blinking
    imp.wakeup(1, blink);
  }
}

usbHost <- USB.Host(hardware.usb, [BootKeyboardDriver]);
usbHost.setDriverListener(usbDriverListener);
server.log("[App] USB initialization complete");
```

## The Driver API ##

This driver exposes following API for application usage.

### getKeyStatusAsync(*callback*) ###

This method sends a request through an Interrupt In endpoint that gets data and notifies the caller asynchronously.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to receive the keyboard status |

#### Callback Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *status* | Table | A [Keyboard Status Table](#keyboard-status-table) |

#### Return Value ####

Nothing.

### getKeyStatus() ###

A synchronous method that reads the keyboard's report through the control endpoint 0. It throws a runtime error if an error occurs during transfer.

#### Return Value ####

[Table](#keyboard-status-table) &mdash; the keyboard status record.

### setIdleTimeMs(*timeout*) ###

This method is used to limit the reporting frequency.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *timeout* | Integer | Yes | Poll duration in milliseconds, range: 0 (indefinite)-1020 |

#### Return Value ####

Nothing.

### setLeds(*leds*) ###

This method changes the keyboard LED status.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *leds* | Integer Bitfield | Yes | 8-bit field:</br>bit 0 - NUM LOCK</br>bit 1 - CAPS LOCK</br>bit 2 - SCROLL LOCK</br>bit 3 - COMPOSE</br>bit 4 - KANA |

#### Return Value ####

Nothing, or an error description if an error occurred.
