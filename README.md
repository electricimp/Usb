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

ft232Device <- null;

function driverStatusListener(eventType, eventObject) {
    if (eventType == "started") {

        ft232Device = eventObject;

        // start work with FT232rl device here

    } else if (eventType == "stopped") {

        // immediately stop all interaction with FT232rl device
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

Instantiates the USB.Host class.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb* 		 | Object 	 | required  | The imp API hardware usb object `hardware.usb` |
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

Assigns listener for [USB.Device](#usbdevice-сlass) and [USB.Driver](#usbdriver-class) status changes.
The following events are supported:
- device `"connected"`
- device `"disconnected"`
- driver `"started"`
- driver `"stopped"`

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *callback*  | Function  | Yes      | Function to be called on event. See below. |

Setting of *null* clears the previously assigned listener.

##### callback(*eventType, eventObject*)

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

Resets the USB. Can be used by driver or application in response to unrecoverable error like unending bulk transfer or halt condition during control transfers.

#### getAttachedDevices()

Auxillary function to get list of attached devices. Returns an array of **[USB.Device](#usbdevice-сlass)** objects.


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

Returns an array of drivers operating with interfaces this device. Throws exception if the device is detached.

#### getEndpointZero()

Returns Control Endpoint 0 proxy for the device. EP0 is a special type of endpoints that implicitly exists for every device. Throws exception if the device is detached.

#### getEndpoint(*interface, type, dir [, pollTime]*)

Static auxillary function that searches an endpoint with the given parameter at the given interface and returns new instance if found.

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *interface*  | Any  |  interface descriptor, received by drivers match function |
| *type* | Number |  required endpoint attribute |
| *dir* | Number |   required endpoint direction |
| *pollTime* | Number |   [optional] required polling time (where applicable) |

The function doesn't depend on any internal object structures and just do following code

``` squirrel
foreach (ep in interface.endpoints) {
    if ( ep.attributes == type &&
         (ep.address & USB_DIRECTION_MASK) == dir) {
             return ep.get(pollTime);
    }
}
```

**NOTE!** This function executes without any exception only if received __interface__ was provided by framework through drivers *match* function.

``` squirrel

class MyCustomDriver extends USB.Driver {

    _bulkIn = null;

    constructor(interface) {
        _bulkIn = USB.Device.getEndpoint(interface, USB_ENDPOINT_BULK, USB_DIRECTION_IN);
    }

    function match(device, interfaces) {
        return MyCustomDriver(interface);
    }
}
```

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
| *reqType*      | Number    | n/a 	   | USB request type |
| *req* 		 | Number 	 | n/a 	   | The specific USB request |
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
try {
    local payload = blob(16);
    device.getEndpointByAddress(epAddress).write(payload, function(error, len) {
      if (len > 0) {
        server.log("Payload: " + len);
      }
    }.bindenv(this));
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
try {
    local payload = blob(16);
    device.getEndpointByAddress(epAddress).read(payload, function(error, len) {
        if (len > 0) {
            server.log("Payload: " + payload);
        }
    }.bindenv(this));
}
catch (e) {
}
```

#### reset()

Resets the endpoint on stall or any other non-critical issue.

```squirrel
try {
    local payload = blob(16);
    local endpoint = device.getEndpointByAddress(epAddress);
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
catch (e) {
  server.log("Endpoint is closed");
}
```


## USB.Driver class

This class is the base for all drivers that are developed for USB Drivers Framework. It contains two mandatory methods which must be implemented by every USB driver.

### match(*deviceObject, interfaces*)

Checks if the driver can support all the specified interfaces for the specified device. Returns the driver object (if it can support) or *null* (if it can not support).

The method may be called many times by USB Drivers Framework. The method's implementation can be based on VID, PID, device class, subclass and interfaces.

### release()

Releases all resources instantiated by the driver.

It is called by USB Drivers Framework when USB device is detached and all resources should be released.

It is important to note all device resources are released prior to this function call.

### Example

```squirrel
class MyUsbDriver extends USB.Driver {

    static VID = 0x01f9;
    static PID = 0x1044;

    _ep = null;

    constructor(interface) {
      _ep = interface.endpoints[0].get();
    }
    // Returns an array of VID PID combinations
    function match(device, interfaces) {
        if (device._vid == VID && device._pid == PID)
          return MyUsbDriver(interfaces[0]);
        return null;
    }
}

usbHost <- USB.Host(hardware.usb, [MyUsbDriver]);
```
-------------------

# USB Driver Examples

- [UartOverUsbDriver](./examples/QL720NW_UART_USB_Driver/)
- [FtdiUsbDriver](./examples/FT232RL_FTDI_USB_Driver/)


# License

This library is licensed under the [MIT License](/LICENSE).
