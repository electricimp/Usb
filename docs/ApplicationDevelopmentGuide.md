## Application Development Guide

This guide is intended for those developers who is going to integrate one or more of
the existing USB drivers into their applications.

Before you use a driver, please carefully read it's documentation, limitations and requirements.

### Including USB Framework and Driver Libraries

By default the base USB Drivers Framework itself does not provide any device
drivers out of the box. So application developers should explicitly include
and manage drivers they need.

**NOTE:** to include the USB Driver Framework library into your project,
add `#require "USB.device.lib.nut:1.0.0"` to the top of your device code.

Include statements for dependent USB drivers and other libraries,
as well as the rest of the application code should follow.

In the example below shows how to include the FT232RL FTDI USB Device Driver
into your applicatin code:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"
```

### Initializing the USB Framework

Once the necessary driver libraries are included in the application code,
the USB frameworks should be configured to use them.

The main entry point into the USB Drivers Framework is
**[USB.Host](DriverDevelopmentGuide.md#usbhost-class)** class.

This class is responsible for driver registration, instantiation,
device and driver event notification handling, driver lifecycle management.

The code snippet below shows how to initialize the USB framework
with a single FT232RL FTDI USB driver as an example.

```
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"

ft232Driver <- null;

function driverStatusListener(eventType, driver) {
    if (eventType == USB_DRIVER_STATE_STARTED) {

        if (typeof driver == "FT232RLFtdiUsbDriver")
            ft232Driver = driver;

        // Start work with FT232RL driver API here

    } else if (eventType == USB_DRIVER_STATE_STOPPED) {

        // Immediately stop all interaction with FT232RL driver API
        // and cleanup the driver reference
        ft232Driver = null;
    }
}

host <- USB.Host(hardware.usb, [FT232RLFtdiUsbDriver]);
host.setDriverListener(driverStatusListener);
```

The examples creates an instance of the [USB.Host](DriverDevelopmentGuide.md#usbhost-class) class. The constructor takes two parameters: the native USB object and an array of driver classes,
an array with a single FT232RLFtdiUsbDriver class in this case. Next line shows how to register
a driver state listener by calling the `USB.Host.setDriverListener` method. Please,
refer to callback function [documentation](DriverDevelopmentGuide.md#callbackeventtype-driver)
for more details.

### Using Multiple Drivers

It is possible to register several drivers in the USB Framework.
Whenever a device is plugged or unplugged the corresponding drivers
that match this deviceare going to be started or stopped.
There are some devices which provide multiple interfaces and these interfaces
could be implemented via one or several drivers.
USB Framework instantiate all drivers which match the plugged device.
Application developer is responsible of which drivers need to be included in the application
based on its needs.

For example, if one of these drivers matches the device being connected,
then it will be instantiated:

```
#require "USB.device.lib.nut:1.0.0"

#require "MyCustomDriver2.nut:1.2.0"
#require "MyCustomDriver1.nut:1.0.0"
#require "MyCustomDriver3.nut:0.1.0"

host <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2, MyCustomDriver3]);
```
But if all the three drivers match device interfaces they all
are instantiated and started by the USB framework.

### Accessing Driver API

**NOTE:** public driver API neither are limited nor enforced in any way by the USB framework.
It's up to the driver developer to decide which APIs to expose.

Each driver provides it's own public API for interaction with USB devices and application code. So appliaction developer should carefully read the driver documentation and follow the instructions.

### Configuring Hardware Pins for USB

The reference hardware for the USB Drivers Framework is [imp005](https://developer.electricimp.com/hardware/imp/imp005_hardware_guide) board. It's schematic requires special pin configuration in order to enable USB. USB Driver Framework does this for you by default. Please see documentation on the
USB.Host [constructor](DriverDevelopmentGuide.md#usbhostusb-drivers--autoconfigpins) for more details.

If your application is targetting a custom board based on a different Electric Imp module,
you may need to set *autoConfigPins=false* to prevent configuration issues and
configure it on the application side according to the module specificaion.

### Working with attached Devices

A recommended way to interact with an attached device is to use one of
the drivers that support that device. However it may be important to access the
device directly, e.g. to select alternative configuration or change it's power state.
To provide such access USB Driver Framework creates a proxy [USB.Device](DriverDevelopmentGuide.md#usbdevice-class) class for every device attached to the USB interface.

You can retrieve an instance of the `USB.Device` from the callback
[`USB.Host.setDeviceListener`](DriverDevelopmentGuide.md#setdevicelistenercallback),
which is executed when a device is connected/disconnected to/from the USB bus. You can also
retrieve a list of all the attached devices by calling the
[`USB.Host.getAttachedDevices`](DriverDevelopmentGuide.md#getattacheddevices).

[USB.Device](DriverDevelopmentGuide.md#usbdevice-class) class provides a number of APIs
to interact and manages devices. For example, `USB.Device.getEndpointZero` returns a special
control [endpoint 0](DriverDevelopmentGuide.md#usbcontrolendpoint-class) that can be used to configure
the device by trasfering messages of a special format through this endpoint.
The format of such messages is out the scope of this document.
Please refer to [USB specification](http://www.usb.org/) for more details.

Example below shows how to get retrieve the endpoint 0 to then use it for device configuration:

```
#require "USB.device.lib.nut:1.0.0"

const VID = 0x413C;
const PID = 0x2107;

// endpoint 0 for the required device
ep0 <- null;

class MyCustomDriver extends USB.Driver {
    constructor() {
    } // constructor

    function match(device, interfaces) {
        return MyCustomDriver();
    }

    function _typeof() {
        return "MyCustomDriver";
    }
} // class


function deviceStatusListener(eventType, device) {
    server.log(device.getVendorId())
    server.log(device.getProductId())
    if (eventType == USB_DEVICE_STATE_CONNECTED) {
        if (device.getVendorId()  == VID &&
            device.getProductId() == PID) {
                ep0 = device.getEndpointZero();
                //
                // Do device configuration here
                //
        }
    } else if (eventType == "disconnected") {
        ep0 = null;
    }
}

host <- USB.Host(hardware.usb, [MyCustomDriver]);
host.setDeviceListener(deviceStatusListener);
```

### Resetting the `USB.Host`

Resets the USB host see [USB.Host.reset API](DriverDevelopmentGuide.md#reset) . Can be used by application in response to unrecoverable error like driver not responding.

This method should clean up all drivers and devices with corresponding event listener notifications and finally make USB reconfiguration.

It is not necessary to setup [setDriverListener](DriverDevelopmentGuide.md#setdriverlistenercallback) or
[setDeviceListener](DriverDevelopmentGuide.md#setdevicelistenercallback) again, the same callback should get all notifications about re-attached devices and corresponding drivers state changes. Please note that as
the drivers and devices are created again, they are going to be have addresses.

```squirrel
#require "USB.device.lib.nut:1.0.0"

class MyCustomDriver extends USB.Driver {
    function match(device, interfaces) {
        return MyCustomDriver();
    }

    function _typeof() {
        return "MyCustomDriver";
    }
}

host <- USB.Host(hardware.usb, [MyCustomDriver]);

host.setDeviceListener(function(event, device) {
    // print all events
    server.log("[APP]: Event: " + event + ", number of connected " + host.getAttachedDevices().len());
    // Check that the number of connected devices
    // is the same after reset
    if (event == USB_DEVICE_STATE_CONNECTED && host.getAttachedDevices().len() != 1) {
        server.log("Expected only one attached device");
    }
});

imp.wakeup(2, function() {
    host.reset();
}.bindenv(this));
```
