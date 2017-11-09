# USB Drivers Framework

USB Drivers Framework is intended to simplify and standardize USB driver creation, integration and usage in your IMP device code. It consists of several abstractions and can be used by two types of developers:
- if you want to utilize the existing USB drivers in your application, see [Application Development Guide](#application-development-guide) below;
- if you want to create and add a new USB driver, see [Driver Development Guide](#driver-development-guide) below.

## Application Development Guide

This guide is intended for those developers who is going to integrate one or more existing USB drivers into their applications.

### Include the framework and drivers

By default USB Drivers Framework does not provide any drivers. Therefore, a scope of the required device drivers should be identified and controlled by an application developer.

**To add USB Driver Framework library to your project, add** `#require "USB.device.lib.nut:1.0.0"` **to the top of your device code.**

After that, include into your device code the libraries with all USB drivers needed for your application.

In the example below FT232RLFtdi USB driver is included into an application:

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0" // driver example
```

### Initialize the framework

Next, it is necessary to initialize USB Drivers Framework with a scope of drivers.

The main entrance to USB Drivers Framework is **[USB.Host](#usbhost-class)** class. This class is responsible for a driver registration and notification of an application when the required device is attached and ready to operate through the provided driver.

The below example shows typical steps of the framework initialization. In this example the application creates instance of [USB.Host](#usbhost-class) class for [hardware.usb](https://electricimp.com/docs/api/hardware/usb/) object with an array of the pre-defined driver classes (one FT232RLFtdi USB driver in this example). To get notification when the required device is connected and the corresponding driver is started and ready to use, the application assigns a [callback function](#callbackeventtype-eventobject) that receives USB event type and event object. In simple case it is enough to listen for `"started"` and `"stopped"` events, where event object is the driver instance.

```
#require "USB.device.lib.nut:1.0.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0" // driver example

ft232DriverInstance <- null;

function driverStatusListener(eventType, eventObject) {
    if (eventType == "started") {

        ft232DriverInstance = eventObject;

        // start work with FT232rl driver API here

    } else if (eventType == "stopped") {

        // immediately stop all interaction with FT232rl driver API
        // and reset driver reference
        ft232DriverInstance = null;
    }
}

host <- USB.Host(hardware.usb, [FT232rl]);
host.setEventListener(driverStatusListener);
```

### Driver selection priority

It is possible to register several drivers in USB Drivers Framework. Thus you can plug/unplug devices in runtime and corresponding drivers will be instantiated.

If several drivers are matching to one attached device, only the first matched driver from the array of the pre-defined driver classes is instantiated.

For example, if all three drivers below are matching to the attached device, only "MyCustomDriver1" is instantiated:

```
#require "USB.device.lib.nut:1.0.0"
#require "MyCustomDriver2.nut:1.2.0"
#require "MyCustomDriver1.nut:1.0.0"
#require "MyCustomDriver3.nut:0.1.0"

host <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2, MyCustomDriver3]); // a place in the array defines the selection priority
```

### Driver API access

**Please note**: *API exposed by a particular driver is not a subject of USB Driver Framework.*

Each driver provides it's own custom API for interactions with a USB device. Therefore an application developer should read the documentation provided for the concrete driver.

### Hardware pins configuration for USB

The reference hardware for USB Drivers Framework is *[imp005](https://electricimp.com/docs/hardware/imp/imp005_hardware_guide/)* board. It's schematic requires special pin configuration in order to make USB hardware functional. USB Driver Framework does such configuration when *[USB.Host](#usbhostusb-drivers--autoconfigpins)* class is instantiated with *autoConfigPins=true*.

If your application is intended for a custom board, you may need to set *autoConfigPins=false* to prevent unrelated pin be improperly configured.

### How to get control of an attached device

A primary way to interact with an attached device is to use one of the drivers that support that device.

However it may be important to access the device directly, e.g. to select alternative configuration or change it's power state. To provide such access USB Driver Framework creates a proxy **[USB.Device](#usbdevice-class)** class for every device attached to the USB interface. To get correct instance the application needs to either listen `connected` events at the callback function assigned by [`USB.Host.setListener`](#seteventlistenercallback) method or get a list of the attached devices by [`USB.Host.getAttachedDevices`](#getattacheddevices) method and filter out the required one. Than it is possible to use one of the **[USB.Device](#usbdevice-class)** class methods or to get access to the special [control endpoint 0](#usbcontrolendpoint-class) and send custom messages through this channel. The format of such messages is out the scope of this document. Please refer to [USB specification](http://www.usb.org/) for more details.

Example below shows how to get control endpoint 0 for the required device:

```
#require "USB.device.lib.nut:1.0.0"

const VID = 1;
const PID = 2;

// endpoint 0 for the required device
ep0 <- null;

function driverStatusListener(eventType, eventObject) {
    if (eventType == "connected") {
        local device = eventObject;
        if (device.getVendorId() == VID &&
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

host <- USB.Host(hardware.usb);
host.setEventListener(driverStatusListener);
```

### USB.Host reset

Resets the USB host see [USB.Host.reset API](#reset) . Can be used by application in response to unrecoverable error like driver pending or not responding.

This method should clean up all drivers and devices with corresponding event listener notifications and and finally make usb reconfigure.

It is not necessary to setup [setEventListener](#setEventListener) again, the same callback should get all notifications about re-attached devices and corresponding drivers allocation. Please note that newly created drivers and devices instances will be different and all devices will have a new addresses.

```squirrel

#include "MyCustomDriver.nut" // some custom driver

host <- USB.Host(hardware.usb, [MyCustomDriver]);

host.setEventListener(function(eventName, eventDetails) {
    // print all events
    server.log("Event: " + eventName);
    // Check that the number of connected devices
    // is the same after reset
    if (eventName == "connected" && host.getAttachedDevices().len() != 1)
        server.log("Only one device could be attached");
});

imp.wakeup(2, function() {
    host.reset();
}.bindenv(this));

```

--------


## Driver Development Guide

It consists of five simple abstractions:

- **[USB.Host](#usbhost-class)**
- **[USB.Device](#usbdevice-сlass)**
- **[USB.Driver](#usbdriver-class)**
- **[USB.ControlEndpoint](#usbcontrolendpoint-class)**
- **[USB.FunctionalEndpoint](#usbfunctionalendpoint-class)**

--------

## USB Drivers Framework API specification

### USB.Host class

The main interface to start working with USB devices and drivers.

If you have more then one USB port on development board then you should create USB.Host instance for each of them.

#### USB.Host(*usb, drivers, [, autoConfigPins]*)

Instantiates the USB.Host class. USB.Host is an abstraction for USB port. It should be instantiated only once for any application.

There are some imp boards which does not have usb port, therefore `hardware.usb`  should be provided on instantiation.

USB framework suppose that developer will not use `hardware.usb` in parallel.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb* 		 | Object 	 | required  | The imp API hardware usb object [`hardware.usb`](https://electricimp.com/docs/api/hardware/usb/) |
| *drivers*      | USB.Driver[] | required  | An array of the pre-defined driver classes |
| *autoConfigPins* | Boolean   | `true`  | Whether to configure pin R and W according to [electric imps documentation](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb). These pins must be configured for the usb to work on **imp005**. |

##### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "MyCustomDriver1.device.lib.nut:1.2.3"
#require "MyCustomDriver2.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2]);
```

#### setEventListener(*callback*)

Assign listener for runtime device and driver events. User could plug an unplug device in runtime and application should get the corresponding events.

For the device which was attached before the `USB.Host` instantiation all events will be triggered on this listener registration call.

Callback could provide driver related events if some driver match to the device only otherwise an application will get device related events only [see](https://github.com/nobitlost/Usb/tree/CSE-433/#callbackeventtype-eventobject)

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *callback*  | Function  | Yes      | Function to be called on event. See below. |

Setting of *null* clears the previously assigned listener.

##### callback(*eventType, eventObject*)

This callback is happen on the device or driver status change therefore the second argument is variable and could be instance of the [USB.Device](#usbdevice-сlass) or [USB.Driver](#usbdriver-class) .

The following event types are supported:
- device `"connected"`
- device `"disconnected"`
- driver `"started"`
- driver `"stopped"`

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *eventType*  | String  |  Name of the event `"connected"`, `"disconnected"`, `"started"`, `"stopped"` |
| *object* | USB.Device or USB.Driver |  In case of `"connected"`/`"disconnected"` event - USB.Device instance. In case of `"started"`/`"stopped"` event USB.Driver instance. |

##### Example (subscribe)

```squirrel
// Subscribe to usb connection events
usbHost.setEventListener(function (eventType, eventObject) {
    switch (eventType) {
        case "connected":
            server.log("New device found");
            break;
        case "disconnected":
            server.log("Device detached");
            break;
        case "started":
            server.log("Driver found and started " + (typeof eventObject));
            break;
        case "stopped":
            server.log("Driver stopped " + (typeof eventObject));
            break;
    }
});

```

#### reset()

Resets the USB host. Can be used by driver or application in response to unrecoverable error like unending bulk transfer or halt condition during control transfers.

This method disable usb, clean up all drivers and devices with corresponding event listener notifications and reconfigure usb from scratch. All devices will have a new device object instances and different address.

```squirrel

#include "MyCustomDriver.nut" // some custom driver

host <- USB.Host(hardware.usb, [MyCustomDriver]);

host.setEventListener(function(eventName, eventDetails) {
    if (eventName == "connected" && host.getAttachedDevices().len() != 1)
        server.log("Only one device could be attached");
});

imp.wakeup(2, function() {
    host.reset();
}.bindenv(this));

```

#### getAttachedDevices()

Auxiliary function to get list of attached devices. Returns an array of **[USB.Device](#usbdevice-сlass)** objects.


## USB.Device class

Represents an attached USB device. Please refer to [USB specification](http://www.usb.org/) for details of a USB device description.

Normally, an application does not need to use a device object. It is usually used by drivers to acquire required endpoints.
All management of USB device configurations, interfaces and endpoints **MUST** go through the device object.

#### getDescriptor()

Returns the device descriptor. Throws exception if the device is detached.

#### getVendorId()

Returns the device vendor ID. Throws exception if the device is detached.

#### getProductId()

Returns the device product ID. Throws exception if the device is detached.

#### getAssignedDrivers()

Returns an array of drivers for the attached device. Throws exception if the device is detached.
Each device provide the number of interfaces which could be supported by the different drives (For example keyboard with touchpad could have keyboard driver and a separate touchpad driver).

#### getEndpointZero()

Returns Control Endpoint 0 proxy for the device. EP0 is a special type of endpoints that implicitly exists for every device. Throws exception if the device is detached.

## USB.ControlEndpoint class

Represents USB control endpoints.
This class is required due to specific EI usb API
This class is managed by USB.Device and should be acquired through USB.Device instance.

``` squirrel
// Reset functional endpoint via control endpoint

device
    .getEndpointZero()
    .transfer(
        USB_SETUP_RECIPIENT_ENDPOINT | USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_STANDARD,
        USB_REQUEST_CLEAR_FEATURE,
        0,
        endpointAddress);
```

#### transfer(reqType, type, value, index, data = null)

Generic method for transferring data over control endpoint.
**Note:** Only vendor specific requires are allowed. For other control operation use USB.Device, USB.ControlEndpoint public API

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *reqType*      | Number    | n/a 	   | USB request type [see](https://electricimp.com/docs/api/hardware/usb/controltransfer/) |
| *req* 		 | Number 	 | n/a 	   | The specific USB request [see](https://electricimp.com/docs/api/hardware/usb/controltransfer/) |
| *value* 		 | Number 	 | n/a 	   | A value determined by the specific USB request|
| *index* 		 | Number 	 | n/a 	   | An index value determined by the specific USB request |
| *data* 		 | Blob 	 | null    | [optional] Optional storage for incoming or outgoing payload|

#### clearStall(epAddress)

Resets the given endpoint.


## USB.FunctionalEndpoint class

Represents all non-control endpoints, e.g. bulk, interrupt and isochronous.
This class is managed by USB.Device and should be acquired through USB.Device instance.

#### write(data, onComplete)

Asynchronously writes data through the endpoint. Throws exception if the endpoint is closed or it doesn't support USB_DIRECTION_OUT.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		 | Blob      | n/a 	   | payload data blob to be sent through this endpoint |
| *onComplete* 	 | Function  | n/a 	   | callback for transfer status notification |

Callback **onComplete(error, len)**:

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*     | Number    | the usb error type |
| *len*       | Number    | length of the written payload data |

```squirrel
class MyCustomDriver imptements USB.Driver {
  constructor(device, interfaces) {
    try {
        local payload = blob(16);
        local ep = interfaces[0].endpoints[1].get();
        ep.write(payload, function(error, len) {
            if (len > 0) {
                server.log("Payload: " + len);
            }
       }.bindenv(this));
    }
    catch(e) {
      server.error(e);
    }
  } // constructor

  function match(device, interfaces) {
      return MyCustomDriver(device, interfaces);
  }
} // class
```

#### read(data, onComplete)

Asynchronously reads data through the endpoint. Throws exception if the endpoint is closed, or has incompatible type, or already busy.

The method set an upper limit of five seconds for any command to be processed for the bulk endpoint according to the [Electric Imp documentation](https://electricimp.com/docs/resources/usberrors/#stq=&stp=0).

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		 | Blob      | n/a 	   | blob to read data into |
| *onComplete* 	 | Function  | n/a 	   | callback method to get the details of the completed operation |

Callback **onComplete(error, len)**:

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*     | Number    | the usb error number |
| *len*       | Number    | length of the read data  |

```squirrel
class MyCustomDriver imptements USB.Driver {
  constructor(device, interfaces) {
    try {
        local payload = blob(16);
        local ep = interfaces[0].endpoints[1].get();
        ep.read(payload, function(error, len) {
            if (len > 0) {
                server.log("Payload: " + payload);
            }
        }.bindenv(this));
    }
    catch(e) {
      server.error(e);
    }
  } // constructor

  function match(device, interfaces) {
      return MyCustomDriver(device, interfaces);
  }
} // class
```

#### reset()

Resets the endpoint on stall or any other non-critical issue.

```squirrel
class MyCustomDriver imptements USB.Driver {
  constructor(device, interfaces) {
    try {
        local payload = blob(16);
        local endpoint = interfaces[0].endpoints[1].get();
        endpoint.read(payload, function(error, len) {
            if (error == USB_TYPE_STALL_ERROR) {
                server.log("Reset endpoint on stall");
                try {
                    endpoint.reset();
                } catch (e) {
                    // device is not responding.
                    // need to reset the host
                }
            }
        }.bindenv(this));
    }
    catch(e) {
      server.error(e);
    }
  } // constructor

  function match(device, interfaces) {
      return MyCustomDriver(device, interfaces);
  }
} // class
```


## USB.Driver class

This class is the base for all drivers that are developed for USB Drivers Framework. It contains two mandatory methods which must be implemented by every USB driver.

### match(*deviceObject, interfaces*)

Checks if the driver can support all the specified interfaces for the specified device. Returns the driver object (if it can support) or *null* (if it can not support).

The method may be called many times by USB Drivers Framework. The method's implementation can be based on VID, PID, device class, subclass and interfaces.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *deviceObject* 		 | USB.Device 	 | required  | an instance of the USB.Device for the attached device |
| *interfaces*      | Array of tables | required  | An array of tables which describe interfaces for the attached device [see](https://electricimp.com/docs/api/hardware/usb/configure/) |

### release()

Releases all resources instantiated by the driver.

It is called by USB Drivers Framework when USB device is detached and all resources should be released.

It is important to note all device resources are released prior to this function call and all methods should throw an exception. It means that it is not possible to perform read, write or transfer for the detached device and this method uses to release all driver related resources and free an external resource if necessary.

### Example

```squirrel
class MyUsbDriver extends USB.Driver {

    static VID = 0x01f9;
    static PID = 0x1044;

    _epControl = null;
    _epBulkIn = null;

    constructor(interface) {
        _epControl = interface.endpoints[0].get();

        // Check that endpoint is BULK and direction is IN
        if (interface.endpoints[1].attributes == USB_ENDPOINT_BULK &&
            interface.endpoints[1].address & USB_DIRECTION_MASK == USB_DIRECTION_IN) {

            // get USB.FunctionalEndpoint object for this endpoint
            _epBulkIn = interface.endpoints[1].get();
        }
    }

    //
    // Returns an instance of driver
    // if device is match to the driver
    //
    function match(device, interfaces) {
        if (device.getVendorId() == VID
            && device.getProductId() == PID)
          return MyUsbDriver(interfaces[0]);
        return null;
    }

    function release() {
        try {
            local pl = blob(16);
            _epBulkIn.read(pl, function(error, len) {
                // this method should never call
            });
        }
        catch (e) {
           server.error("No way to use disconnected device");
        }
    }
}

// instantiate host with a single driver
usbHost <- USB.Host(hardware.usb, [MyUsbDriver]);
```
-------------------

# USB Driver Examples

- [UartOverUsbDriver](./examples/QL720NW_UART_USB_Driver/)
- [FtdiUsbDriver](./examples/FT232RL_FTDI_USB_Driver/)


# License

This library is licensed under the [MIT License](/LICENSE).
