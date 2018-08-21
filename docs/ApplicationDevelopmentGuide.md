# Application Development Guide #

This guide is intended for those developers who are going to integrate one or more existing USB drivers into their applications.

Before you use a driver, please read carefully its documentation to understand its limitations and requirements.

## Including USB Framework And Driver Libraries ##

To include the USB Drivers Framework library in your application, add `#require "USB.device.lib.nut:1.0.0"` to the top of your device code.

By default, the base USB Drivers Framework itself does not provide any device drivers out of the box. Application developers will therefore need explicitly  to include and manage drivers they need.

Include statements for dependent USB drivers and other libraries, as well as the rest of the application code should follow.

The following code example shows how to include the FT232RL FTDI USB Device Driver in your application code:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"
```

## Initializing The USB Drivers Framework ##

Once the necessary driver libraries are included in your application code, the USB Drivers Framework should be configured to use them.

The main entry point into the USB Drivers Framework is the [USB.Host](DriverDevelopmentGuide.md#usbhost-class-usage) class. This class is responsible for driver registration and instantiation; device and driver event notifications; and driver lifecycle management.

The following code example shows how to initialize the USB Drivers Framework with a single FT232RL FTDI USB driver. It runs on an imp005-based board:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"

ft232Driver <- null;

function driverStatusListener(eventType, driver) {
  if (eventType == USB_DRIVER_STATE_STARTED) {
    if (typeof driver == "FT232RLFtdiUsbDriver") ft232Driver = driver;

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

The example creates an instance of the [USB.Host](DriverDevelopmentGuide.md#usbhost-class-usage) class. The constructor takes two parameters: the imp API USB object representing your board’s USB bus, and an array of device-driver classes &mdash; in this case, an array with a single FT232RLFtdiUsbDriver class.

The final line shows how to register a driver-state listener function by calling the *USB.Host.setDriverListener()* method. Please
refer to the method [documentation](DriverDevelopmentGuide.md#setdriverlistenerlistener) for more details.

## Using Multiple Drivers ##

It is possible to register any number of drivers with the USB Drivers Framework: just add further device-driver class references to the array parameter in the [USB.Host](DriverDevelopmentGuide.md#usbhost-class-usage) constructor.

Whenever a device is plugged or unplugged, the corresponding drivers that match this device will be started or stopped.

Some devices provide multiple interfaces and these interfaces could be implemented via a single or multiple drivers. The USB Drivers Framework instantiates all drivers which match the connected device.

For example, if one of these drivers matches the device being connected, then it will be instantiated:

```
#require "USB.device.lib.nut:1.0.0"

#require "ACustomDriver2.nut:1.2.0"
#require "ACustomDriver1.nut:1.0.0"
#require "ACustomDriver3.nut:0.1.0"

host <- USB.Host(hardware.usb, [ACustomDriver1, ACustomDriver2, ACustomDriver3]);
```

If all the three drivers match device interfaces, then they all are instantiated and started by the USB Drivers Framework.

Application developers are responsible for including required device-driver libraries into the application code.

## Accessing A Driver’s API ###

Public driver APIs are neither limited nor enforced in any way by the USB Drivers Framework. It is the responsibility of the driver developer to decide which APIs to expose to application developers.

Each driver provides its own public API for interaction with USB devices and application code. Application developers should therefore read carefully the driver documentation and follow its instructions.

## Configuring Hardware Pins For USB ##

The reference hardware for the USB Drivers Framework is the [imp005](/hardware/imp/datasheets#imp005). This module requires a special pin configuration in order to enable USB. The USB Driver Framework does this for you by default. Please see documentation on the
USB.Host [constructor](DriverDevelopmentGuide.md#usbhost-class-usage) for more details.

If your application is targeting a custom board based on a different Electric Imp module, you may need to set *autoConfigPins* to `false` in order to prevent configuration issues. You will also need to configure it from within the application according to the module’s specification.

## Working With Attached Devices ##

The recommended way to interact with an attached device is to use one of the drivers that support that device. However, it may be important to access the
device directly, for example, to select an alternative configuration or to change its power state.

To provide such access, the USB Drivers Framework creates a proxy [USB.Device](DriverDevelopmentGuide.md#usbdevice-class-usage) class for every device attached to the USB interface.

You can retrieve the device’s USB.Device instance from the listener registered using [*USB.Host.setDeviceListener()*](DriverDevelopmentGuide.md#setdevicelistenerlistener), which is executed when a device is connected and/or disconnected to/from USB. You can also
retrieve a list of all the attached devices by calling the [*USB.Host.getAttachedDevices()*](DriverDevelopmentGuide.md#getattacheddevices).

The [USB.Device](DriverDevelopmentGuide.md#usbdevice-class-usage) class provides a number of methods you can use to interact and manages devices. For example, [*USB.Device.getEndpointZero()*](DriverDevelopmentGuide.md#getendpointzero) returns a special control [endpoint 0](DriverDevelopmentGuide.md#usbcontrolendpoint-class-usage) that can be used to configure the device by transferring messages in a special format via this endpoint. The format of such messages is out the scope of this document; please refer to the [USB specification](http://www.usb.org/) for more details.

The following example code shows how to retrieve the endpoint 0 to then use it for device configuration:

```
#require "USB.device.lib.nut:1.0.0"

const VID = 0x413C;
const PID = 0x2107;

// Endpoint 0 for the required device
endpoint0 <- null;

// Custom driver class
class MyCustomDriver extends USB.Driver {

  constructor() {
    // constructor
  }

  function match(device, interfaces) {
    return MyCustomDriver();
  }

  function _typeof() {
    return "MyCustomDriver";
  }
}

function deviceStatusListener(eventType, device) {
  server.log(device.getVendorId());
  server.log(device.getProductId());
  if (eventType == USB_DEVICE_STATE_CONNECTED) {
    if (device.getVendorId() == VID && device.getProductId() == PID) {
      endpoint0 = device.getEndpointZero();

      // Do device configuration here
    }
  } else if (eventType == "disconnected") {
    endpoint0 = null;
  }
}

host <- USB.Host(hardware.usb, [MyCustomDriver]);
host.setDeviceListener(deviceStatusListener);
```

## Resetting The USB.Host ##

To reset the USB host, call [*USB.Host.reset()*](DriverDevelopmentGuide.md#reset). This method can be used by an application in response to unrecoverable error, such as a driver not responding. This method should clean up all drivers and devices with corresponding event listener notifications and finally perform a USB reconfiguration.

It is not necessary to configure [*setDriverListener()*](DriverDevelopmentGuide.md#setdriverlistenerlistener) or
[*setDeviceListener()*](DriverDevelopmentGuide.md#setdevicelistenerlistener) again &mdash; the same callback should receive all further notifications about re-attached devices and corresponding driver state changes. Please note that as the drivers and devices are instantiated again, they are may have different addresses.

The following example shows *reset()* being used:

```squirrel
#require "USB.device.lib.nut:1.0.0"

// Custom driver class
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

  // Check that the number of connected devices is the same after reset
  if (event == USB_DEVICE_STATE_CONNECTED && host.getAttachedDevices().len() != 1) {
    server.log("Expected only one attached device");
  }
});

// Reset bus after 2 seconds
imp.wakeup(2, function() {
  host.reset();
}.bindenv(this));
```
