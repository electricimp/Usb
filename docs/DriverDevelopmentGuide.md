## Driver Development Guide

This section is intended for those developers who is going to create new driver for a USB device.

### Generic Recommendations

Please avoid using `#include` or `@require`
[Builder](https://electricimp.com/docs/tools/builder/)
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
    // TODO: the driver code goes here
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
probing of other drivers if there is any in the list.

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
not have vendor specific.

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
Please refer to the HID Device Driver [Guide](./HIDDriverGuide.md) for the usb HID driver implementation.

**Note:** there are no limitation on the driver constructor
arguments as it's being called by the driver's own method `match`.

#### 3. (Optional) Release Driver Resources

When device resources required for the driver functionality were gone,
USB framework calls drivers [release](#release) function to give it
a change to shutdown gracefully and release any resources were allocated during its lifetime.

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

#### 4. Implement the Driver Logic

TODO: add references/description to setDriverListener/setDeviceListener to get access to Device and Driver APIs.

##### Working with Endpoint Zero

Endpoint Zero is a special type of control endpoints that implicitly exists
for every device see [USB.ControlEndpoint](#usbcontrolendpoint-class).

###### Example

```squirrel

class MyCustomDriver {
    _ep0 = null;

    constructor(ep0) {
        _ep0 = ep0;

        // get usb descriptor
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

##### Concurrent Access to Resources

The framework doesn't prevent drivers from accessing to any
interface resources the driver receives through the [match](#matchdeviceobject-interfaces)
function. It is up to driver author to create it in safe way and to address
situation when several drivers try to concurrently access the same device. 
An example of such collision is an exception that may be thrown by
[USB.FunctionalEndpoint.read()](#readdata-oncomplete) while another driver's
call is still pending.

##### Getting Access to exposed Device Interfaces

Every driver receives [interfaces](#interface-descriptor) it may work
with at [match](#matchdeviceobject-interfaces) function. To start working with
this interface the driver need to get right endpoint by parsing information from
`endpoints` array of the interface descriptor. When necessary endpoint descriptor
is found, to retrieve the endpoint instance the driver needs to call `get()` function provided by every
[endpoint](#endpoint-descriptor) descriptor.

**Note:** due to limits applied by native [USB API](https://electricimp.com/docs/api/hardware/usb/)
endpoints `get()` function may result in exception when a number of open
endpoint exceeds some limits, e.g. there can be only one open interrupt in endpoint.

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

```

## USB Drivers Framework API specification

### USB.Host class

The main interface to start working with USB devices and drivers.

If you have more then one USB port on development board then you should create
USB.Host instance for each of them.

#### USB.Host(usb, drivers, [, autoConfigPins]*)

Instantiates the USB.Host class. USB.Host is an abstraction for USB port. It
should be instantiated only once per physical port for any application.

There are some imp boards which does not have usb port, therefore exception
will be thrown in that case.

USB framework suppose that developer will not use [`hardware.usb`](https://electricimp.com/docs/api/hardware/usb/)  api in parallel.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb*      | object | required  | The usb object represents a Universal Serial Bus (USB) interface |
| *drivers*      | USB.Driver[] | required  | An array of the pre-defined driver classes |
| *autoConfigPins* | Boolean   | `true`  | Whether to configure pin R and W according to [electric imps documentation](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb). These pins must be configured for the usb to work on **imp005**. |

##### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "MyCustomDriver1.device.lib.nut:1.2.3"
#require "MyCustomDriver2.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2]);
```

#### setDriverListener(*callback*)

Sets listener for the driver events. Application can get notified if a driver was stopped or started. See the
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

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *eventType*  | String  |  Name of the event `USB_DRIVER_STATE_STARTED`, `USB_DRIVER_STATE_STOPPED` |
| *object* | USB.Driver | Instance of the USB.Driver class. |

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

Assign listener for runtime device and driver events. User could plug an
unplug device in runtime and application should get the corresponding events.

Callback could provide driver related events if some driver match to the
device only otherwise an application will get device related events only
[see](#callbackeventtype-eventobject)

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *callback*  | Function  | Yes      | Function to be called on event. See below. |

Setting of *null* clears the previously assigned listener.

##### callback(*eventType, driver*)

This callback is happen on the device or driver status change
therefore the second argument is variable and could be instance
of the [USB.Device](#usbdevice-class) or [USB.Driver](#usbdriver-class).

The following event types are supported:
- device `"connected"`
- device `"disconnected"`
- driver `"started"`
- driver `"stopped"`

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *eventType*  | String  |  Name of the event `"connected"`, `"disconnected"`, `"started"`, `"stopped"` |
| *object* | USB.Device or USB.Driver |  In case of `"connected"`/`"disconnected"` event is USB.Device instance. In case of `"started"`/`"stopped"` event is USB.Driver instance. |

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

Resets the USB host. The effect of this action is analogous to
unplugging the device.  Can be used by driver or application in response
to unrecoverable error like unending bulk transfer or halt condition during control transfers.

This method disable usb, clean up all drivers and devices with
corresponding event listener notifications and reconfigure usb from scratch.
All devices will have a new device object instances and different address.

```squirrel

#include "MyCustomDriver.nut" // some custom driver

host <- USB.Host([MyCustomDriver]);

host.setEventListener(function(eventName, eventDetails) {
    if (eventName == "connected" && host.getAttachedDevices().len() != 1)
        server.log("Only one device could be attached");
});

imp.wakeup(2, function() {
    host.reset();
}.bindenv(this));

```

#### getAttachedDevices()

Auxiliary function to get list of attached devices. Returns an
array of **[USB.Device](#usbdevice-class)** objects.


## USB.Device class

Represents an attached USB device. Please refer to
[USB specification](http://www.usb.org/) for details of a USB device description.

Normally, an application does not need to use a device object.
It is usually used by drivers to acquire required endpoints.
All management of USB device configurations, interfaces and
endpoints **MUST** go through the device object.

#### getDescriptor()

Returns the device descriptor. Throws exception if the device is detached.

#### getVendorId()

Returns the device vendor ID. Throws exception if the device is detached.

#### getProductId()

Returns the device product ID. Throws exception if the device is detached.

#### getAssignedDrivers()

Returns an array of drivers for the attached device. Throws exception if the device is detached.
Each USB device could provide the number of interfaces which could be
supported by a single driver or by the number of different drives
(For example keyboard with touch pad could have keyboard driver and a separate touch pad driver).

#### getEndpointZero()

Returns Control Endpoint 0 proxy for the device. EP0 is a special
type of endpoints that implicitly exists for every device.
Throws exception if the device is detached.

Return type is [USB.ControlEndpoint](#usbcontrolendpoint-class)

## USB.ControlEndpoint class

Represents USB control endpoints.
This class is managed by USB.Device and should be acquired through USB.Device instance.

For exmaple: The following code is making reset of the functional endpoint via control endpoint

``` squirrel
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

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *reqType*      | Number    | n/a 	   | USB request type [see](https://electricimp.com/docs/api/hardware/usb/controltransfer/) |
| *req* 		 | Number 	 | n/a 	   | The specific USB request [see](https://electricimp.com/docs/api/hardware/usb/controltransfer/) |
| *value* 		 | Number 	 | n/a 	   | A value determined by the specific USB request|
| *index* 		 | Number 	 | n/a 	   | An index value determined by the specific USB request |
| *data* 		 | Blob 	 | null    | [optional] Optional storage for incoming or outgoing payload|


#### getEndpoint()

Returns the endpoint address. Typical use case for this function is to get
endpoint ID for some of device control operation performed over Endpoint 0.

## USB.FunctionalEndpoint class

Represents all non-control endpoints, e.g. bulk, interrupt and isochronous.
This class is managed by USB.Device and should be acquired through USB.Device instance.

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

**NOTE** Not all error codes indicate actual error status. However the USB
framework doesn't filter out such error code to provide full information for
device driver. See more information [here](https://electricimp.com/docs/resources/usberrors/).

#### read(data, onComplete)

Asynchronously reads data through the endpoint. Throws exception if the endpoint
is closed, or has incompatible type, or already busy.

The method set an upper limit of five seconds for any command to be processed
for the bulk endpoint according to the
[Electric Imp documentation](https://electricimp.com/docs/resources/usberrors/#stq=&stp=0).

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

**NOTE** Not all error codes indicate actual error status. However
the USB framework doesn't filter out such error code to provide full
information for device driver. See more information
[here](https://electricimp.com/docs/resources/usberrors/).


#### getEndpoint()

Returns the endpoint address. Typical use case for this function is to get endpoint
ID for some of device control operation performed over Endpoint 0.

## USB.Driver class

This class is the base for all drivers that are developed for USB Drivers Framework.
It contains three mandatory methods which must be implemented by every USB driver.

### match(*deviceObject, interfaces*)

Checks if the driver can support all the specified interfaces for the specified device.
Returns the driver object (if it can support), array of driver objects
(if few interfaces are supported by this driver) or *null* (if it can not support).

The method's implementation can be based on VID, PID, device class, subclass and interfaces.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *deviceObject* 		 | USB.Device 	 | required  | an instance of the USB.Device for the attached device |
| *interfaces*      | Array of tables | required  | An array of tables which describe [interfaces](d#interface-descriptor) for the attached device |

### release()

Releases all resources instantiated by the driver.

It is called by USB Drivers Framework when USB device
is detached and all resources should be released.

It is important to note all device resources are released
prior to this function call and all Device/Endpoint methods
calls result in throwing of an exception. It means that it is
not possible to perform read, write or transfer for the detached
device and this method uses to release all driver related resources
and free an external resource if necessary.

### _typeof()

Meta-function to return class name when typeof <instance> is run.
Uses to identify the driver instance type in runtime.

```squirrel

// For example:

host <- USB.Host(["MyCustomDriver1", "MyCustomDriver2", "FT232RLFtdiUsbDriver"]);

host.setEventListener(function(eventName, eventDetails) {
    if (eventName == "started" && typeof eventDetails == "FT232RLFtdiUsbDriver")
        server.log("FT232RLFtdiUsbDriver initialized");
});

```

## USB framework constants.

A set of constants that may be useful for endpoint search functions.

| Constant name | Value | Description |
| ------------- | ----- | ----------- |
| USB_ENDPOINT_CONTROL | 0 | Control Endpoint type value |
| USB_ENDPOINT_ISOCHRONOUS | 1 | Isochronous Endpoint type value |
| USB_ENDPOINT_BULK | 2 | Bulk Endpoint type value |
| USB_ENDPOINT_INTERRUPT | 3 | Interrupt Endpoint type value |
| USB_ENDPOINT_TYPE_MASK | 3 | A mask value that covers all endpoint types|
| USB_DIRECTION_OUT | 0 | A bit value that indicates OUTPUT endpoint direction|
| USB_DIRECTION_IN | 0x80 | A bit value that indicates INPUT endpoint direction |
| USB_DIRECTION_MASK | 0x80 | A mask to extract endpoint direction from endpoint address |

### USB framework events structures

USB framework uses a few special structures named `descriptors` and which
contain description of attached device, its interfaces and endpoint.
[Endpoint](#endpoint-descriptor) and [Interface](#interface-descriptor)
descriptors are used only at driver probing stage, while [Device](#device-descriptor)
descriptor could be acquired from [USB.Device](#usbdevice-class) instance.

#### Device descriptor

Device descriptor contains whole device specification in addition to
[Vendor ID](#getvendorid) and [Product ID](#getproductid) acquired through
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


#### Interface descriptor

As it is described at driver selection section [match function](#matchdeviceobject-interfaces)
of probed driver receives two objects: [USB.Device](#usbdevice-class) instance and array of
interfaces exposed by this device. Interface descriptor is a table with a set of fields:

| Interface Key | Type | Description |
| ------------- | ---- | ----------- |
| interfacenumber | Integer | The number representing this interface |
| altsetting | Integer | The alternative setting of this interface |
| class | Integer | The interface class. |
| subclass | Integer | The interface subclass |
| protocol | Integer | The interface class protocol |
| interface | Integer | The index of the string descriptor describing this interface |
| endpoints | Array of table |The endpoint [descriptors](#endpoint-descriptor) |
| find | function | Auxiliary function to search endpoint with required attributes |

##### find

Interface descriptors `find` function signature is following:

| Parameter | Type | Accepted values |
| ------------- | ---- | ----------- |
| Endpoint type | Integer | USB_ENDPOINT_CONTROL, USB_ENDPOINT_BULK, USB_ENDPOINT_INTERRUPT |
| Endpoint direction | Integer | USB_DIRECTION_IN, USB_DIRECTION_OUT |

This function returns an instance of either [ControlEndpoint](#usbcontrolendpoint-class)
or [FunctionalEndpoint](#usbfunctionalendpoint-class) or null if no endpoints were found.


#### Endpoint descriptor

Each endpoints table contains the following keys:

| Endpoints Key | Type | Description |
| ------------- | ---- | ----------- |
| address | Integer bitfield | The endpoint address:<br />D0-3 — Endpoint number<br />D4-6 — Reserved<br />D7 — Direction (0 out, 1 in) |
| attributes | Integer bitfield | D0-1 — Transfer type:<br />00: control<br />01: isochronous<br />10: bulk<br />11: interrupt |
| maxpacketsize | Integer | The maximum size of packet this endpoint can send or receive |
| interval | Integer | Only relevant for Interrupt In endpoints |
| get | function | The function that returns instance of either [USB.FunctionalEndpoint](#usbfunctionalendpoint-class) or [USB.ControlEndpoint](#usbcontrolendpoint-class) depending on information stored at `attributes` and `address` fields. |

-------------------

# USB Driver Examples

- [Generic HID device](./HID_Driver.md/)
- [QL720NW printer](./examples/QL720NW_UART_USB_Driver/)
- [FTDI usb-to-uart converter](./examples/FT232RL_FTDI_USB_Driver/)
- [Keyboard with HID protocol](./examples/HID_Keyboard/)
- [Keyboard with boot protocol](./examples/Keyboard/)
