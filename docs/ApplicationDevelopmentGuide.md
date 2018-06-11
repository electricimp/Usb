## Application Development Guide

This guide is intended for those developers who is going to integrate one or more of
the existing USB drivers into their applications.

Before you use a driver, please carefully read it's documentation, limitations and requirements.

### Include the framework and drivers

By default the base USB Drivers Framework itself does not provide any device
drivers out of the box. So application developers should explicitly include
and manage the drivers they need.

**Note:** to include the base USB Driver Framework library to your project,
add `#require "USB.device.lib.nut:1.0.0"` to the top of your device code.

Include statements for dependent USB drivers and other libraries,
as well as the rest of the application code should follow.

In the example below FT232RL FTDI USB Device Driver is included into an application:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"
```

### Initializing the framework

Once the necessary driver libraries are included in the application code,
the USB frameworks should be configured to be using them.

The main entrance point into the USB Drivers Framework is
**[USB.Host](DriverDevelopmentGuide.md#usbhost-class)** class.

This class is responsible for driver registration, instantiation,
device and driver event notification handling, driver lifecycle management.

The below example shows typical steps of the framework initialization.
In this example the application creates an instance of
[USB.Host](DriverDevelopmentGuide.md#usbhost-class) class for an array of
the pre-defined driver classes (an FT232RL FTDI USB driver in this example).
To get notification when the required device is connected and the corresponding
driver is started and ready to use, the application assigns a
[callback function](DriverDevelopmentGuide.md#callbackeventtype-eventobject)
that receives USB event type and event object. In simple case it is enough to
listen for `USB_DRIVER_STATE_STARTED` and `USB_DRIVER_STATE_STOPPED`
events, where event object is the driver instance.

```
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0" // driver example

ft232DriverInstance <- null;

function driverStatusListener(eventType, eventObject) {
    if (eventType == USB_DRIVER_STATE_STARTED) {

        if (typeof eventObject == "FT232RLFtdiUsbDriver")
            ft232DriverInstance = eventObject;

        // start work with FT232rl driver API here

    } else if (eventType == USB_DRIVER_STATE_STOPPED) {

        // immediately stop all interaction with FT232rl driver API
        // and reset driver reference
        ft232DriverInstance = null;
    }
}

host <- USB.Host([FT232RLFtdiUsbDriver]);
host.setEventListener(driverStatusListener);
```

### Multiple drivers support

It is possible to register several drivers in USB Drivers Framework. Thus you can plug/unplug devices in runtime and corresponding drivers will be instantiated. There are some devices which provide several interfaces and that interfaces could be implemented via one or several drivers.
USB Framework instantiate all drivers which could match to the plugged device therefore it is up to the application developer which drivers needs to be included in the application.

For example, if one of these drivers is matching to the attached device, then driver will be instantiated:

```
#require "USB.device.lib.nut:1.0.0"
#require "MyCustomDriver2.nut:1.2.0"
#require "MyCustomDriver1.nut:1.0.0"
#require "MyCustomDriver3.nut:0.1.0"

host <- USB.Host([MyCustomDriver1, MyCustomDriver2, MyCustomDriver3]);
```
But if all tree drivers are matching to the device interfaces then all three drivers will be instantiated.

### Driver API access

**Please note**: *API exposed by a particular driver is not a regulated by the USB Driver Framework and is solely the USB driver developer decision.*

Each driver provides it's own custom API for interaction with USB devices. Appliaction developer should refere to the specific driver documentation for more details.

### Hardware pins configuration for USB

The reference hardware for USB Drivers Framework is *[imp005](https://electricimp.com/docs/hardware/imp/imp005_hardware_guide/)* board. It's schematic requires special pin configuration in order to make USB hardware functional. USB Driver Framework does such configuration when *[USB.Host](DriverDevelopmentGuide.md#usbhostusb-drivers--autoconfigpins)* class is instantiated with *autoConfigPins=true*.

If your application is intended for a custom board, you may need to set *autoConfigPins=false* to prevent unrelated pin be improperly configured.

### How to get control of an attached device

A primary way to interact with an attached device is to use one of the drivers that support that device.

However it may be important to access the device directly, e.g. to select alternative configuration or change it's power state. To provide such access USB Driver Framework creates a proxy **[USB.Device](DriverDevelopmentGuide.md#usbdevice-class)** class for every device attached to the USB interface. To get correct instance the application needs to either listen to the `USB_DEVICE_STATE_CONNECTED` events at the callback function assigned by [`USB.Host.setListener`](DriverDevelopmentGuide.md#seteventlistenercallback) method or get a list of the attached devices by calling the [`USB.Host.getAttachedDevices`](DriverDevelopmentGuide.md#getattacheddevices) method and filter out the required one. Than it is possible to use one of the **[USB.Device](DriverDevelopmentGuide.md#usbdevice-class)** class methods or to get access to the special [control endpoint 0](DriverDevelopmentGuide.md#usbcontrolendpoint-class) and send custom messages through this channel. The format of such messages is out the scope of this document. Please refer to [USB specification](http://www.usb.org/) for more details.

Example below shows how to get control over the endpoint 0 for a device:

```
#require "USB.device.lib.nut:1.0.0"

const VID = 1;
const PID = 2;

// endpoint 0 for the required device
ep0 <- null;

function driverStatusListener(eventType, eventObject) {
    if (eventType == "connected") {
        local device = eventObject;
        if (device.getVendorId()  == VID &&
            device.getProductId() == PID) {
                ep0 = device.getEndpointZero();
                //
                // make device configuration
                //
        }
    } else if (eventType == "disconnected") {
        ep0 = null;
    }
}

host <- USB.Host([]);
host.setEventListener(driverStatusListener);
```

### USB.Host reset

Resets the USB host see [USB.Host.reset API](DriverDevelopmentGuide.md#reset) . Can be used by application in response to unrecoverable error like driver pending or not responding.

This method should clean up all drivers and devices with corresponding event listener notifications and finally make usb reconfiguration.

It is not necessary to setup [setEventListener](DriverDevelopmentGuide.md#setEventListener) again, the same callback should get all notifications about re-attached devices and corresponding drivers allocation. Please note that newly created drivers and devices instances will be different and all devices will have a new addresses.

```squirrel

#include "MyCustomDriver.nut" // some custom driver

host <- USB.Host([MyCustomDriver]);

host.setEventListener(function(eventName, eventDetails) {
    // print all events
    server.log("Event: " + eventName);
    // Check that the number of connected devices
    // is the same after reset
    if (eventName == "connected" && host.getAttachedDevices().len() != 1)
        server.log("Expected only one attached device");
});

imp.wakeup(2, function() {
    host.reset();
}.bindenv(this));

```
