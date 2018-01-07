## Keyboard driver

This class is an example of [USB.Driver](../../DriverDevelopmentGuide.md#usbdriver-classHID_Driver.md) implementation. It exposes very simple API that allows to work with any devices that implements [boot keyboard protocol](http://www.usb.org/developers/hidpage/HID1_11.pdf)


### Include the driver and dependencies

The driver depends on some constants and classes of [USB Framework](../../README.md) so that required files has to be included by application developer. Please follow [Application Developer Guide](../../ApplicationDevelopmentGuide.md#include-the-framework-and-drivers) about how to start using of required classes.

**To add HID driver to your project, add** `#require "Keyboard.nut:1.0.0"` **to the top of your device code.**

In the example below keyboard driver is included into an application:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "Keyboard.nut:1.0.0"
```

### Complete example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "Keyboard.nut:1.0.0"
#require "PrettyPrinter.class.nut:1.0.1"
#require "JSONEncoder.class.nut:1.0.0"

pp <- PrettyPrinter(null, false);
print <- pp.print.bindenv(pp);

kbrDrv < - null;

function keyboardEventListener(error, status) {
    server.log("Keyboard event");

    if (null != null) {
        print(status);
        kbrDrv.getKeyStatusAsync(keyboardEventListener);
    } else {
        server.error("Error received: " + error);
    }
}

function usbEventListener(event, data) {
    if (event == "started") {
        local kbrDrv = data;

        // Receive new key state every second
        kbrDrv.getKeyStatusAsync(keyboardEventListener);
    }
}

host <- USB.Host([Keyboard]);

host.setEventListener(usbEventListener);

server.log("USB initialization complete");

```

### Custom matching procedure

This driver matches only devices interfaces which `class` is 3, `subclass` is 1 and `protocol` is 1.

### Driver API

This driver exposes following function for application usage.


#### getKeyStatusAsync(callback)

Function sends read request through Interrupt In endpoint, that gets data and notifies the caller asynchronously.

The function signature is following:
| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *callback* | Function | A function to receive the keyboard status |

The signature of callback function is following:
| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *error*   | Any | error description if any |
| *status* | Table | A table with a fields named after modifiers keys </br> and set of Key0...Key5 fields with pressed key scancodes  |

#### getKeyStatus()

Function read keyboard report  through control endpoint 0 and thus synchronously.

It returns keyboard status [table](#table) or throws if an error happens during transfer

#### setLeds(leds)

Changes Keyboard LED status. It returns error description (if any) or NULL.

The function signature is following:
| Parameter | Type | Description |
| --------- | ---- | ----------- |
| *leds* | Integer/Bitfield | 8-bit field:</br>bit 0 - NUM LOCK</br>bit 1 - CAPS LOCK</br>bit 2 - SCROLL LOCK</br>bit 3 - COMPOSE</br>bit 4 - KANA |


#### Keyboard status table

Both [getKeyStatusAsync]() and [getKeyStatus]() notifies about keyboard state with special table. The table format is following

| Field | Type | Description |
| --------- | ---- | ----------- |
| *error* | Any | This field is resent when any error happens |
| *LEFT_CTRL* | Integer|  Left Ctrl status (1/0) |
| *LEFT_SHIFT* | Integer | Left Shift status (1/0) |
| *LEFT_ALT*  | Integer| Left Alt status (1/0) |
| *LEFT_GUI*  | Integer| Left Gui status (1/0) |
| *RIGHT_CTRL*  | Integer| Right Ctrl status (1/0) |
| *RIGHT_SHIFT*  | Integer| Right Shift status (1/0) |
| *RIGHT_ALT* | Integer| Right Alt status (1/0) |
| *RIGHT_GUI* | Integer| Right Gui status (1/0) |
| *Key0* | Integer| First scan code or 0 |
| *Key1* | Integer| Second scan code or 0 |
| *Key2* | Integer| Third scan code or 0 |
| *Key3* | Integer| Fourth scan code or 0 |
| *Key4* | Integer| Fifth scan code or 0 |
| *Key5* | Integer| Sixth scan code or 0 |