## Driver Development Guide

This section is intended for those developers who is going to create new driver for a USB device.

### Generic Recommendations

Please avoid using `#include` or `@require`
[Builder](https://developer.electricimp.com/tools/builder/)
statements in your driver code to prevent any compilation
or loaded code duplication issues at runtime.

If you are writing a USB driver that's going to be shared with the community,
please follow requirements for the  third-party library submission
[guidelines](https://developer.electricimp.com/libraries/submissions).

### New Driver Step-by-Step Instruction

#### 1. Extend the basic `USB.Driver` Class

For developer convenience the USB framework comes with a
basic [USB.Driver](#usbdriver-class) implementation.
Make your new driver class extending it.

###### Example

```squirrel
class MyCustomDriver extends USB.Driver {
    // Driver code goes here
}
```

#### 2. Implement the Device-Driver Matching Procedure

Each driver class should implement [match](#matchdeviceobject-interfaces)
method which is responsible for the driver
class instantiation if it is applicable to the attached device.

If the driver can work with this device and the interfaces, it should return
new instance of the driver class. The method can also return an array of instances
if the driver decides to work with each interface individually.
After that the USB framework keeps on
probing of other drivers if there is any on the list.

For example, if it is necessary to instantiate driver for a certain device with
known product and vendor IDs:

###### Example 1
```squirrel
class MyCustomDriver extends USB.Driver {
    static VENDOR_ID = 0x46D;
    static PRODUCT_ID = 0xC31C;

    function match(device, interfaces) {
        print(device.getDescriptor());
        if (device.getVendorId() == VENDOR_ID && device.getProductId() == PRODUCT_ID) {
            server.log("Device matched, creating the driver instance...");
            return MyCustomDriver();
        }
        server.log("Device didn't match");
        // not supported device
        return null;
    }
}
```

On the other hand it could be class of devices like keyboard or mouse which should
not have vendor specific attributes. The following examples shows how to match all the HID and Boot keyboards.

###### Example 2
```squirrel
class MyCustomDriver extends USB.Driver {

    function match(device, interfaces) {
        foreach (interface in interfaces) {
            if (  interface["class"]  == 3 /* HID      */
              &&  interface.subclass  == 1 /* BOOT     */
              &&  interface.protocol  == 1 /* Keyboard */ ) {
                server.log("Device matched");
                return MyCustomDriver();
            }
        }

        server.log("Device didn't match");
        // not supported device
        return null;
    }
}
```
Please refer to the HID Device Driver [Guide](./HIDDriverGuide.md) for the USB HID driver implementation.

**NOTE:** there are no limitation on the driver constructor
arguments as it's being called by the driver's own method `match`.

##### Getting Access to USB Interfaces

Every driver receives [interfaces](#interface-descriptor) it may work
with as a parameter of the [match](#matchdeviceobject-interfaces) function. To start working with
this interface the driver needs to get right endpoint by parsing information from
`endpoints` array of the interface [descriptor](#interface-descriptor). When a necessary endpoint descriptor is found, to retrieve the endpoint instance the driver needs to call `get()`
function provided by every endpoint [descriptor](#endpoint-descriptor).

**NOTE:** due to limits applied by native [USB API](https://developer.electricimp.com/api/hardware/usb)
endpoints `get()` function may result in exception when a number of open
endpoint exceeds some limits, e.g. there can be only one interrupt In endpoint [open](https://developer.electricimp.com/api/hardware/usb/openendpoint).

###### Example 1

```
    function findEndpont(interfaces) {
        foreach(interface in interfaces) {
            if (interface["class"] == 3) { // HID
                local endpoints = interface.endpoints;
                foreach(ep in endpoints) {
                    if (ep.attributes == USB_ENDPOINT_INTERRUPT) {
                        return ep.get();
                    }
                }
            }
        }
        return null;
    }
```

To simplify new driver code every interface descriptor comes with [`find`](#find)
function that searches for endpoint with given attributes and return found first.

###### Example 2
```
    function findEndpont(interfaces) {
        foreach(interface in interfaces) {
            if (interface["class"] == 3) { // HID
                local ep = interface.find(USB_ENDPOINT_INTERRUPT, USB_DIRECTION_IN);
                if (ep) {
                    return ep;
                }
            }
        }
        return null;
    }
```


##### Concurrent Access to Resources

The framework doesn't prevent drivers from accessing any
interface resources the driver receives through the
[match](#matchdeviceobject-interfaces)
function. It is up to driver author to create it in a safe way and to address
situation when several drivers try to concurrently access the same device.
An example of such collision is an exception thrown by
[USB.FuncEndpoint.read()](#readdata-oncomplete) while another driver's
call is still pending.

#### 3. (Optional) Release Driver Resources

When device resources required for the driver functionality were gone,
USB framework calls drivers [release](#release) function to give it
a chance to shutdown gracefully and release any resources were allocated during its lifetime.

Please note that all the framework resources should be considered as
closed by this moment and `MUST NOT` be used from [release](#release) function.

The `release` function is optional, so implement it only if need to release any resources.

The following example shows a simple `release` function implementation.

###### Example

```squirrel
class MyCustomDriver extends USB.Driver {
    constructor() {
        // Allocating some native resources
        server.log("Allocating resources...")
    }

    function match(device, interfaces) {
        return MyCustomDriver();
    }

    function release() {
        // Deallocating resources
        server.log("Deallocating resources...")
    }
}
```

#### 4. (Optional) Accessing the Endpoint Zero

Endpoint Zero is a special type of control endpoints that implicitly exists
for every device see [USB.ControlEndpoint](#usbcontrolendpoint-class).

###### Example

```squirrel
class MyCustomDriver {
    _ep0 = null;

    constructor(ep0) {
        _ep0 = ep0;

        // get USB descriptor
        local data = blob(16);
        _ep0.transfer(
           USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_DEVICE,
           USB_REQUEST_GET_DESCRIPTOR,
           0x01 << 8, 0, data);

        // Handle data
    }

    function match(device, interfaces) {
        return MyCustomDriver(device.getEndpointZero());
    }

    function release() {
        _ep0 = null;
    }
}
```

#### 5. (Optional) Implement `_typeof` Metamethods
`_typeof` returns a unique identifier for the driver type.
Can be used to identify driver in runtime for diagnostic/debug purposes.

###### Example

```squirrel
class MyCustomDriver extends USB.Driver {

    // Other driver code...

    function _typeof() {
        return "MyCustomDriver";
    }
}

```

#### 6. Export public Driver APIs

Each driver should provide it's own API to applications. Please supply it with an extensive and sufficient documentation
that covers its limitations, requirements and examples with code snippets.

### Full Driver Example

```squirrel
class MyCustomDriver extends USB.Driver {
    _ep0 = null;

    constructor(ep0) {
        _ep0 = ep0;

        local data = blob(16);
        _ep0.transfer(
           USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_DEVICE,
           USB_REQUEST_GET_DESCRIPTOR,
           0x01 << 8, 0, data);
        server.log(data);

        // Allocating some native resources
        server.log("Allocating resources...")
    }

    function match(device, interfaces) {
        if (findEndpont(interfaces)) {
            server.log("Driver matches the device");
            return MyCustomDriver(device.getEndpointZero());
        }
        server.log("Driver doesn't match the device");
        return null;
    }

    function release() {
        // Deallocating resources
        server.log("Deallocating resources...")
    }

    function findEndpont(interfaces) {
        foreach(interface in interfaces) {
            if (interface["class"] == 3) { // HID
                local ep = interface.find(USB_ENDPOINT_INTERRUPT, USB_DIRECTION_IN);
                if (ep) {
                    return ep;
                }
            }
        }
        return null;
    }

    function _typeof() {
        return "MyCustomDriver";
    }
}
```

## USB Drivers Framework API Specification

### USB.Host Class

The main interface to start working with USB devices and drivers.

If you have more then one USB port on development board then you should create
USB.Host instance for each of them.

#### USB.Host(usb, drivers, [, autoConfigPins]*)

Instantiates the `USB.Host` class. `USB.Host` is an abstraction over
the native USB port platform implementation.

It should be instantiated only once per physical port for any application.
There are some Electric Imp boards which do not have a USB port, therefore a exception
will be thrown on an attempt to instantiate `USB.Host` in such case.

**NOTE:** when using the USB framework you shouldn't access the
[`hardware.usb`](https://developer.electricimp.com/api/hardware/usb) directly.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb*      | object | required  | The native platform `usb` object representing a Universal Serial Bus (USB) interface |
| *drivers*      | USB.Driver[] | required  | An array of the pre-defined driver classes |
| *autoConfigPins* | Boolean   | `true`  | Whether to configure pin R and W according to [electric imps documentation](https://developer.electricimp.com/hardware/imp/imp005pinmux#usb). These pins must be configured for the USB to work on **imp005**. |

##### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "MyCustomDriver1.device.lib.nut:1.2.3"
#require "MyCustomDriver2.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2]);
```

#### setDriverListener(*callback*)

Sets listener for driver events. Application can get notified if a driver was stopped or started. See the
callback [definition](#callbackeventtype-driver) for more details.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *callback*  | Function  | Yes      | Function to be called on event. See below. |

Setting of *null* clears the previously assigned listener.

##### callback(*eventType, driver*)

This callback is happen on driver status change
therefore the second argument is an instance of [USB.Driver](#usbdriver-class).

The following event types are supported:
- driver `USB_DRIVER_STATE_STARTED` (`"started"`)
- driver `USB_DRIVER_STATE_STOPPED` (`"stopped"`)

| Parameter   | Data Type  | Description |
| ----------- | -----------| ----------- |
| *eventType* | String     | Driver event type: `USB_DRIVER_STATE_STARTED` or `USB_DRIVER_STATE_STOPPED` |
| *driver*    | USB.Driver | Instance of the USB.Driver class. |

##### Example (subscribe)

```squirrel
usbHost.setDriverListener(function (eventType, driver) {
    switch (eventType) {
        case USB_DRIVER_STATE_STARTED:
            server.log("Driver found and started " + (typeof driver));
            break;
        case USB_DRIVER_STATE_STOPPED:
            server.log("Driver stopped " + (typeof driver));
            break;
    }
});
```

#### setDeviceListener(*callback*)

Assign listener for runtime device events. User could plug an
unplug device in runtime and application should get the corresponding events.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *callback*  | Function  | Yes      | Function to be called on event. See below. |

Setting of *null* clears the previously assigned listener.

##### callback(*eventType, device*)

This callback is happen on the device or driver status change
therefore the second argument is variable and could be instance
of the [USB.Device](#usbdevice-class) or [USB.Driver](#usbdriver-class).

The following event types are supported:
- device `USB_DEVICE_STATE_CONNECTED`       (`"connected"`)
- device `USB_DEVICE_STATE_DISCONNECTED`    (`"disconnected"`)

| Parameter   | Data Type  | Description |
| ----------- | ---------- | ----------- |
| *eventType* | String     |  Name of the event `USB_DEVICE_STATE_CONNECTED`, `USB_DEVICE_STATE_DISCONNECTED` |
| *device*    | USB.Device |  Instance of the USB.Device class. |

##### Example (subscribe)

```squirrel
// Subscribe to USB connection events
usbHost.setDeviceListener(function (eventType, device) {
    switch (eventType) {
        case USB_DEVICE_STATE_CONNECTED:
            server.log("New device found");
            break;
        case USB_DEVICE_STATE_DISCONNECTED:
            server.log("Device detached");
            break;
    }
});

```

#### reset()

Resets the USB host. The effect of this action is similar to
physical reconnection of all the devices.
Can be used by a driver or application in response
to unrecoverable error like a timeing out bulk transfer or a halt condition
during control transfers.

`reset` method disables USB, cleans up all drivers and devices, which results
in execution of the corresponding driver and device listeners.
All devices will have a new device object instances and different addresses
after `reset`.

##### Example

```squirrel
#include "MyCustomDriver.device.lib.nut" // some custom driver library

host <- USB.Host(hardware.usb, [MyCustomDriver]);

host.setDeviceListener(function(eventName, eventDetails) {
    if (eventName == USB_DEVICE_STATE_CONNECTED && host.getAttachedDevices().len() != 1)
        server.log("Only one device could be attached");
});

imp.wakeup(2, function() {
    host.reset();
}.bindenv(this));

```

#### getAttachedDevices()

This is a helper function to get list of attached devices. Returns an
array of **[USB.Device](#usbdevice-class)** objects.


## USB.Device Class

Represents attached USB devices. Please refer to
[USB specification](http://www.usb.org/) for details on USB devices description.

Normally, applications don't need to use a device object directly.
It is mostly utilized by drivers to acquire required endpoints.
All management of USB device configurations, interfaces and
endpoints **MUST** go through the device object rather than
via the platform native `hardware.usb` object.

**NOTE:** neither applications nor drivers should explicitly create
`USB.Device` objects. They are instantiated by the USB framework automatically.

#### getDescriptor()

Returns the device descriptor. Throws exception if the device is
not attached at this moment.

#### getVendorId()

Returns the device vendor id. Throws exception if the device
is not attached at this moment.

#### getProductId()

Returns the device product id. Throws exception if the device
is not attached at this moment.

#### getAssignedDrivers()

Returns an array of drivers for the attached device. Throws exception if
the device is not attached.

Each USB device could provide a number of interfaces which could be
supported by a one or more drivers.
For example, keyboard with touchpad could have a keyboard and a
touchpad drivers assigned.

#### getEndpointZero()

Returns a procy for the Control Endpoint 0 for the device.
The endpoint 0 is a special type of endpoints that implicitly exists
for every device.
Throws exception if the device is not connected.

Return type is [USB.ControlEndpoint](#usbcontrolendpoint-class)

## USB.ControlEndpoint Class

Represents USB control endpoints.
This class is managed by USB.Device and should be acquired
by calling `USB.Device.getEndpointZero()`.

The following code is making reset of the functional
endpoint via a control endpoint:

**NOTE:** neither applications nor drivers should explicitly create
`USB.ControlEndpoint` objects. They are instantiated by the USB framework automatically.

##### Example

``` squirrel
device
    .getEndpointZero()
    .transfer(
        USB_SETUP_RECIPIENT_ENDPOINT | USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_STANDARD,
        USB_REQUEST_CLEAR_FEATURE,
        0,
        endpointAddress);
```

#### transfer(reqType, req, value, index, data = null)

Generic method for transferring data over a control endpoint.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *reqType*      | Number    | n/a 	   | USB request type. See Control Endpoint Request Type [definitions](#control-endpoint-request-types) for more details |
| *req* 		 | Number 	 | n/a 	   | The specific USB request. See the Control Endpoint Request [constants](#control-endpoint-requests) |
| *value* 		 | Number 	 | n/a 	   | A value determined by the specific USB request|
| *index* 		 | Number 	 | n/a 	   | An index value determined by the specific USB request |
| *data* 		 | Blob 	 | null    | [optional] Optional storage for incoming or outgoing payload|

Please see Control Endpoint Request [Types](#control-endpoint-request-types) and
Control Endpoint [Request](#control-endpoint-requests) constants definitions.

#### getEndpointAddr()

Returns the endpoint address. Typical use case for this function is to get
endpoint address, which is required by a of device control operation performed over the endpoint 0.

## USB.FuncEndpoint Class

Represents all non-control endpoints, e.g. bulk, interrupt and isochronous.
This class is managed by USB.Device and should be acquired through USB.Device instance.

**NOTE:** neither applications nor drivers should explicitly create
`USB.FuncEndpoint` objects. They are instantiated by the USB framework automatically.

#### write(data, onComplete)

Asynchronously writes data through the endpoint. Throws exception if the endpoint
is closed or it doesn't support USB_DIRECTION_OUT.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		 | Blob      | n/a 	   | payload data blob to be sent through this endpoint |
| *onComplete* 	 | Function  | n/a 	   | callback for transfer status notification |

Callback **onComplete(error, len)**:

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *ep*        | Endpoint  | instance of the endpoint [FuncEndpoint](#usbfuncendpoint-class) |
| *state*     | Number    | USB transfer state, see Transfer States [table](#usb-transfer-states) for more details |
| *data*      | Blob      | the payload data being sent |
| *len*       | Number    | length of the written payload data |

##### Example

```squirrel
class MyCustomDriver extends USB.Driver {
  constructor(device, interfaces) {
    try {
        local payload = blob(16);
        local ep = interfaces[0].endpoints[1].get();
        ep.write(payload, function(ep, state, data, len) {
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
}
```

#### read(data, onComplete)

Asynchronously reads data through the endpoint. Throws exception if the endpoint
is closed, or has incompatible type, or already busy.

The method sets an upper limit of five seconds for any command to be processed
for the bulk endpoint according to the
Electric Imp [documentation](https://developer.electricimp.com/resources/usberrors).

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		 | Blob      | n/a 	   | blob to read data into |
| *onComplete* 	 | Function  | n/a 	   | callback method to get the details of the completed operation |

Callback **onComplete(error, len)**:

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *ep*        | Endpoint  | instance of the endpoint [FuncEndpoint](#usbfuncendpoint-class) |
| *state*     | Number    | USB transfer state, see Transfer States [table](#usb-transfer-states) for more details |
| *data*      | Blob      | the payload data read |
| *len*       | Number    | length of the read data  |

##### Example

```squirrel
class MyCustomDriver extends USB.Driver {
  constructor(device, interfaces) {
    try {
        local payload = blob(16);
        local ep = interfaces[0].endpoints[0].get();
        ep.read(payload, function(ep, state, payload, len) {
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

#### getEndpointAddr()

Returns the endpoint address. Typical use case for this function is to get endpoint
ID for some of device control operation performed over Endpoint 0.

## USB.Driver Class

This class is the base for all drivers that are developed for the USB Drivers Framework.
It contains three methods to be implemented by every USB driver.

**NOTE:** applications should not explicitly create
`USB.Driver` objects. They are instantiated by the USB framework automatically.

### match(*deviceObject, interfaces*)

Checks if the driver can support the specified device and its interfaces exposed. If the driver can support the device, the method should return the new driver instance object, array of driver objects (in case of multiple interfaces supported and driver instances created for each of them) or *null*, if the driver doesn't support the device.

The driver-device matching procedure can be based on checking, VID, PID, device class, subclass and interfaces.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *device* 		 | USB.Device 	 | required  | an instance of the USB.Device for the attached device |
| *interfaces*      | Array of tables | required  | An array of tables which describe [interfaces](#interface-descriptor) for the attached device |

### release()

Releases all resources instantiated by the driver.

It is called by USB Drivers Framework when USB device
is detached and all resources should be released.

It is important to note all device resources are released
prior to this function call and attempts to access Device or Endpoint members
may result in an exception being thrown.

The methos should be used by the drivers to clean up the driver related resources and free an external resource if necessary.

### _typeof()

Meta-function to return class name when `typeof <instance>` is invoked.
Uses to identify the driver instance type in runtime 
(for example, for debugging purposes).

##### Example

```squirrel
local usbHost = USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2]);

usbHost.setDriverListener(function(eventName, eventDetails) {
    if (eventName == "started" && typeof eventDetails == "MyCustomDriver2") {
        server.log("MyCustomDriver2 initialized");
    }
});

```

## USB Framework Structures

### Endpoint Constants

Constants that may be useful for endpoint search functions.

| Constant Name | Value | Description |
| ------------- | ----- | ----------- |
| USB_ENDPOINT_CONTROL | 0x00 | Control Endpoint type value |
| USB_ENDPOINT_ISOCHRONOUS | 0x01 | Isochronous Endpoint type value |
| USB_ENDPOINT_BULK | 0x02 | Bulk Endpoint type value |
| USB_ENDPOINT_INTERRUPT | 0x03 | Interrupt Endpoint type value |
| USB_ENDPOINT_TYPE_MASK | 0x03 | A mask value that covers all endpoint types|
| USB_DIRECTION_OUT | 0x00 | A bit value that indicates OUTPUT endpoint direction|
| USB_DIRECTION_IN | 0x80 | A bit value that indicates INPUT endpoint direction |
| USB_DIRECTION_MASK | 0x80 | A mask to extract endpoint direction from endpoint address |

### Control Endpoint Request Types

Possible `reqType` values of the `ControlEndpoint.transfer` method’s parameter are as follows:

| Constant Name                   | Value | Description |
| ------------------------------- | ----- | ----------- |
| USB_SETUP_HOST_TO_DEVICE        | 0x00  | Transfer direction: host to device |
| USB_SETUP_DEVICE_TO_HOST        | 0x80  | Transfer direction: device to host |
| USB_SETUP_TYPE_STANDARD         | 0x00  | Type: standard |
| USB_SETUP_TYPE_CLASS            | 0x20  | Type: class |
| USB_SETUP_TYPE_VENDOR           | 0x40  | Type: vendor |
| USB_SETUP_RECIPIENT_DEVICE      | 0x00  | Recipient: device |
| USB_SETUP_RECIPIENT_INTERFACE   | 0x01  | Recipient: interface |
| USB_SETUP_RECIPIENT_ENDPOINT    | 0x02  | Recipient: endpoint |
| USB_SETUP_RECIPIENT_OTHER       | 0x03  | Recipient: other |

### Control Endpoint Requests

Possible values of the request parameter are as follows.

| Constant Name                 | Value | Description        |
| ----------------------------- | ----- | ------------------ |
| USB_REQUEST_GET_STATUS        |   0   | Get status         |
| USB_REQUEST_CLEAR_FEATURE     |   1   | Clear feature      |
| USB_REQUEST_SET_FEATURE       |   3   | Set feature        |
| USB_REQUEST_SET_ADDRESS       |   5   | Set address        |
| USB_REQUEST_GET_DESCRIPTOR    |   6   | Get descriptor     |
| USB_REQUEST_SET_DESCRIPTOR    |   7   | Set descriptor     |
| USB_REQUEST_GET_CONFIGURATION |   8   | Get configuration  |
| USB_REQUEST_SET_CONFIGURATION |   9   | Set configuration  |
| USB_REQUEST_GET_INTERFACE     |   10  | Get interface      |
| USB_REQUEST_SET_INTERFACE     |   11  | Set interface      |
| USB_REQUEST_SYNCH_FRAME       |   12  | Sync frame         |

###  USB Transfer States

The following table lists the meaning of the possible values
to which `state` may be set.

| Constant Name                 | Value |
| ----------------------------- | ----- |
| OK | 0 |
| USB_TYPE_CRC_ERROR | 1 |
| USB_TYPE_BIT_STUFFING_ERROR | 2 |
| USB_TYPE_DATA_TOGGLE_MISMATCH_ERROR | 3 |
| USB_TYPE_STALL_ERROR | 4 |
| USB_TYPE_DEVICE_NOT_RESPONDING_ERROR | 5 |
| USB_TYPE_PID_CHECK_FAILURE_ERROR | 6 |
| USB_TYPE_UNEXPECTED_PID_ERROR | 7 |
| USB_TYPE_DATA_OVERRUN_ERROR | 8 |
| USB_TYPE_DATA_UNDERRUN_ERROR | 9 |
| USB_TYPE_UNKNOWN_ERROR | 10 |
| USB_TYPE_UNKNOWN_ERROR | 11 |
| USB_TYPE_BUFFER_OVERRUN_ERROR | 12 |
| USB_TYPE_BUFFER_UNDERRUN_ERROR | 13 |
| USB_TYPE_DISCONNECTED | 14 |
| USB_TYPE_FREE | 15 |
| USB_TYPE_IDLE | 16 |
| USB_TYPE_BUSY | 17 |
| USB_TYPE_INVALID_ENDPOINT | 18 |
| USB_TYPE_TIMEOUT | 19 |
| USB_TYPE_INTERNAL_ERROR | 20 |

Not all of the non-zero state values indicate errors. For example, USB_TYPE_FREE (15) and USB_TYPE_IDLE (16) are not errors. The range of possible error values you may encounter will depend on which type of USB device you are connecting.

Please see the [article](https://developer.electricimp.com/api/hardware/usb/configure) for more details.

### USB Framework Event Structures

USB framework uses a few special structures named `descriptors` and which
contain description of attached device, its interfaces and endpoint.
[Endpoint](#endpoint-descriptor) and [Interface](#interface-descriptor)
descriptors are used only at driver probing stage, while [Device](#device-descriptor)
descriptor could be acquired from [USB.Device](#usbdevice-class) instance.

#### Device Descriptor

Device descriptor contains whole device specification in addition to
[Vendor ID](#getvendorid) and [Product Id](#getproductid) acquired through
corresponding functions. The descriptor is a table with a set of fields:

| Descriptor key | Type | Description |
| -------------- | ---- | ----------- |
| usb | Integer | The USB specification to which the device conforms. <br /> It is a binary coded decimal value. For example, 0x0110 is USB 1.1 |
| class | Integer | The USB class assigned by [USB-IF](http://www.usb.org). If 0x00, each interface specifies its own class. If 0xFF, the class is vendor specific. |
| subclass | Integer | The USB subclass (assigned by the [USB-IF](http://www.usb.org)) |
| protocol | Integer | The USB protocol (assigned by the [USB-IF](http://www.usb.org)) |
| vendorid | Integer | The vendor ID (assigned by the [USB-IF](http://www.usb.org)) |
| productid| Integer | The product ID (assigned by the vendor) |
| device |Integer | The device version number as BCD |
| manufacturer | Integer | Index to string descriptor containing the manufacturer string |
| product | Integer | Index to string descriptor containing the product string |
| serial |Integer | Index to string descriptor containing the serial number string |
| numofconfigurations |Integer | The number of possible configurations |


#### Interface Descriptor

As it is described at driver selection section [match function](#matchdeviceobject-interfaces)
of probed driver receives two objects: [USB.Device](#usbdevice-class) instance and array of
interfaces exposed by this device. Interface descriptor is a table with a set of fields:

| Interface Key | Type | Description |
| ------------- | ---- | ----------- |
| interfacenumber | Integer | The number representing this interface |
| altsetting | Integer | The alternative setting of this interface |
| class | Integer | The interface class |
| subclass | Integer | The interface subclass |
| protocol | Integer | The interface class protocol |
| interface | Integer | The index of the string descriptor describing this interface |
| endpoints | Array of table |The endpoint [descriptors](#endpoint-descriptor) |
| find | function | Auxiliary function to search endpoint with required attributes |
| getDevice | function | Returns USB.Device instance - owner of this interface |

##### find

Interface descriptors `find` function signature is following:

| Parameter | Type | Accepted values |
| ------------- | ---- | ----------- |
| Endpoint type | Integer | USB_ENDPOINT_CONTROL, USB_ENDPOINT_BULK, USB_ENDPOINT_INTERRUPT |
| Endpoint direction | Integer | USB_DIRECTION_IN, USB_DIRECTION_OUT |

This function returns an instance of either [ControlEndpoint](#usbcontrolendpoint-class)
or [FuncEndpoint](#usbfuncendpoint-class) or null if no endpoints were found.


#### Endpoint Descriptor

Each endpoints table contains the following keys:

| Endpoints Key | Type | Description |
| ------------- | ---- | ----------- |
| address | Integer bitfield | The endpoint address:<br />D0-3 — Endpoint number<br />D4-6 — Reserved<br />D7 — Direction (0 out, 1 in) |
| attributes | Integer bitfield | D0-1 — Transfer type:<br />00: control<br />01: isochronous<br />10: bulk<br />11: interrupt |
| maxpacketsize | Integer | The maximum size of packet this endpoint can send or receive |
| interval | Integer | Only relevant for Interrupt In endpoints |
| get | function | The function that returns instance of either [USB.FuncEndpoint](#usbfuncendpoint-class) or [USB.ControlEndpoint](#usbcontrolendpoint-class) depending on information stored at `attributes` and `address` fields. |

-------------------

# USB Driver Examples

- [Generic HID device](./HIDDriverGuide.md)
- [QL720NW printer](./../drivers/QL720NW_UART_USB_Driver)
- [FTDI usb-to-uart Converter](./../drivers/FT232RL_FTDI_USB_Driver)
- [Keyboard with HID Protocol](./../drivers/HIDKeyboard)
- [Keyboard with Boot Protocol](./../drivers/BootKeyboard)