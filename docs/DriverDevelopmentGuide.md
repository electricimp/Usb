# Driver Development Guide #

This document is intended for those developers who are going to create new drivers for USB devices.

Driver development leverages Electric Imp’s USB Driver Framework Library. For more information on the USB Driver Framework’s core classes and data structures, please see the [Specification section](#usb-drivers-framework-api-specification), below. Developers will need to include the USB Driver Framework Library and extend the [USB.Driver](#usbdriver-class-usage) class when creating a new device driver.

## Generic Development Recommendations ##

- When using the USB Drivers Framework, **DO NOT** access the imp API [hardware.usb](https://developer.electricimp.com/api/hardware/usb) object directly.

- Please avoid using the impCentral `#require` directive or the [Builder](https://developer.electricimp.com/tools/builder) statement `@include` within your driver code to avoid compilation issues and to prevent the loading of duplicated code at runtime.

- If you are writing a USB driver that you intend to share with the community, please follow our [guidelines](https://developer.electricimp.com/libraries/submissions) for third-party library submission.

## New Driver Development Step-by-Step Instructions ##

### 1. Extend The Basic USB.Driver Class ###

The USB Drivers Framework includes a basic [USB.Driver](#usbdriver-class-usage) implementation. You create your new driver class by extending USB.Driver as follows:

```squirrel
class MyCustomDriver extends USB.Driver {
    // Your driver code goes here
}
```

### 2. Implement The Standard Device-Driver Matching Procedure ###

Every driver class **must** implement a [*match()*](#matchdeviceobject-interfaces) method which will be called automatically when a device is connected to the host. This method is responsible for checking that the attached device is supported by the driver and, if so, instantiating a suitable driver. If your driver is able to work with the attached device and the interfaces, it should return a new instance of the driver class. The method may also return an array of instances if the driver decides to work with each of the device’s interfaces individually. Once *match()* returns, the USB Drivers Framework will then check any other drivers registered with it.

For example, you might wish to instantiate a driver only for devices with a known product and vendor ID:

```squirrel
class MyCustomDriver extends USB.Driver {

    static VENDOR_ID = 0x46D;
    static PRODUCT_ID = 0xC31C;

    function match(device, interfaces) {

        if (device.getVendorId() == VENDOR_ID && device.getProductId() == PRODUCT_ID) {
            server.log("Device matched, creating the driver instance...");
            return MyCustomDriver();
        }

        // Device not supported
        server.log("Device didn't match");
        return null;
    }

}
```

Alternatively, your driver might support a whole class of devices, such as keyboards and mice, which should not have vendor specific attributes. The following example shows how to match all HID and Boot keyboards:

```squirrel
class MyCustomDriver extends USB.Driver {

    function match(device, interfaces) {
        foreach (interface in interfaces) {
            if (interface["class"] == 3  /* HID      */
             && interface.subclass == 1  /* BOOT     */
             && interface.protocol == 1  /* Keyboard */ ) {
                server.log("Device matched");
                return MyCustomDriver();
            }
        }

        // Device not supported
        server.log("Device didn't match");
        return null;
    }

}
```

**Note** There are no limits placed on the driver’s constructor arguments as it is always called from within the driver’s own *match()* method.

#### Getting Access To USB Interfaces ####

Every driver receives interfaces that it may work with via the second parameter of the [*match()*](#matchdeviceobject-interfaces) method. To start working with these interfaces, the driver needs to select the correct endpoint by parsing information from each [interface descriptor](#interface-descriptor)’s *endpoints* array. When a suitable endpoint is found, the driver should call the [endpoint descriptor](#endpoint-descriptor)’s *get()* function to retrieve the endpoint instance.

**Note** An endpoint’s *get()* function may result in an exception being thrown when the number of open endpoints exceeds certain limits set by the native imp [USB API]((https://developer.electricimp.com/api/hardware/usb)). For example, there currently can be only one Interrupt In endpoint [open](https://developer.electricimp.com/api/hardware/usb/openendpoint) at any one time:

```squirrel
function findEndpont(interfaces) {
    foreach(interface in interfaces) {
        if (interface["class"] == 3) { // HID
            local endpoints = interface.endpoints;
            foreach(endpoint in endpoints) {
                if (endpoint.attributes == USB_ENDPOINT_INTERRUPT) {
                    return endpoint.get();
                }
            }
        }
    }
    return null;
}
```

To simplify new driver code, every [interface descriptor](#interface-descriptor) instance includes a [*find()*](#find) method that searches for the endpoint with the given attributes and returns the one found first. So we can update the above code to:

```squirrel
function findEndpont(interfaces) {
    foreach(interface in interfaces) {
        if (interface["class"] == 3) { // HID
            local endpoint = interface.find(USB_ENDPOINT_INTERRUPT, USB_DIRECTION_IN);
            if (endpoint) return endpoint;
        }
    }

    return null;
}
```

#### Concurrent Access To Resources ####

The USB Drivers Framework does not prevent drivers from accessing any interface resources the driver receives through [*match()*](#matchdeviceobject-interfaces). It is the responsibility of the driver’s author to manage situations where several drivers may be trying to access the same device concurrently.

An example of such a collision is an exception thrown by [*USB.FuncEndpoint.read()*](#readdata-oncomplete) while another driver's call is still pending.

### 3. Support Releasing Driver Resources (Optional) ###

When device resources required by the driver are no longer available, the USB Drivers Framework calls the driver’s [*release()*](#release) method to give the driver a chance to shut down gracefully and release any resources that were allocated during its lifetime.

**Note** All the framework resources should be considered closed at this point and **must not** be accessed in the [*release()*](#release) function.

The *release()* method is optional, so implement it only if you need to release resources.

The following example shows a very simple *release()* implementation:

```squirrel
class MyCustomDriver extends USB.Driver {

    constructor() {
        // Allocating some native resources
        server.log("Allocating resources...");
    }

    function match(device, interfaces) {
        return MyCustomDriver();
    }

    function release() {
        // Deallocating resources
        server.log("Deallocating resources...");
    }

}
```

### 4. Support Accessing Endpoint Zero (Optional) ###

Endpoint 0 is a special type of control endpoint that implicitly exists for every device *(see [USB.ControlEndpoint](#usbcontrolendpoint-class-usage))*.

#### Example ####

```squirrel
class MyCustomDriver {

    _endpoint0 = null;

    constructor(ep0) {
        _endpoint0 = ep0;

        // Get USB descriptor
        local data = blob(16);
        _endpoint0.transfer(
            USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_GET_DESCRIPTOR,
            0x01 << 8,
            0,
            data);

        // Handle data
    }

    function match(device, interfaces) {
        return MyCustomDriver(device.getEndpointZero());
    }

    function release() {
        _endpoint0 = null;
    }

}
```

### 5. Implement The _typeof Metamethod (Optional) ###

The Squirrel `_typeof` metamethod can be used to return a unique identifier for the driver class, and so be used to identify the driver at runtime, eg. for diagnostic and/or debugging purposes.

```squirrel
class MyCustomDriver extends USB.Driver {

    // Other driver code...

    function _typeof() {
        return "MyCustomDriver";
    }

}
```

### 6. Export Public Driver APIs ###

Each driver should expose its own API to applications. Please supply your driver with suitable documentation that describes its public API, details its limitations and requirements, and includes example code.

Driver public APIs are neither limited nor enforced by the USB Drivers Framework in any way. It is the responsibility of the driver developer to decide which APIs to expose to application developers.

## Full Driver Example ##

```squirrel
class MyCustomDriver extends USB.Driver {

    _endpoint0 = null;

    constructor(ep0) {
        _endpoint0 = ep0;

        local data = blob(16);
        _endpoint0.transfer(
            USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_GET_DESCRIPTOR,
            0x01 << 8,
            0,
            data);

        server.log(data);

        // Allocate some native resources
        server.log("Allocating resources...");
    }

    // Required Core Function
    function match(device, interfaces) {
        if (findEndpont(interfaces)) {
            server.log("Driver matches the device");
            return MyCustomDriver(device.getEndpointZero());
        }

        server.log("Driver doesn't match the device");
        return null;
    }

    // Optional Core Function
    function release() {
        // Deallocating resources
        server.log("Deallocating resources...");
    }

    // Optional Core Function
    function _typeof() {
        // Return the name of the driver when the application calls 'typeof driver'
        return "MyCustomDriver";
    }

    // Used by match() to check we support the connected device
    function findEndpont(interfaces) {
        foreach(interface in interfaces) {
            if (interface["class"] == 3) { // HID
                local endpoint = interface.find(USB_ENDPOINT_INTERRUPT, USB_DIRECTION_IN);
                if (endpoint) return endpoint;
            }
        }

        // No endpoints found
        return null;
    }

}
```

## USB Drivers Framework API Specification ##

What follows is a detailed description of the USB Drivers Framework’s core classes and related data structures.

## USB.Host Class Usage ##

This is the main interface to start working with USB devices and drivers.

If you have more then one USB port in your product or development board, you should create a USB.Host instance for each of them.

### USB.Host(*usb, drivers[, autoConfigPins]*) ###

This method instantiates the USB.Host class. USB.Host is a wrapper over the native imp API USB implementation.

It should be instantiated only once per physical port for any application. There are some Electric Imp boards which do not have a USB port, therefore an exception will be thrown on any attempt to instantiate USB.Host in code running on these boards.

**Note** When using the USB Drivers Framework, **DO NOT** access the imp API [hardware.usb](https://developer.electricimp.com/api/hardware/usb) object directly.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *usb* | Object | Yes | The imp API **usb** object representing a Universal Serial Bus (USB) interface |
| *drivers* | Array of [USB.Driver](#usbdriver-class-usage) objects | Yes | An array of pre-defined driver classes |
| *autoConfigPins* | Boolean | No | Indicate whether to configure imp005 pins R and W, which must be configured for USB to work on the imp005. Default: `null` |

#### Example ####

```squirrel
#require "USB.device.lib.nut:1.1.0"

class MyCustomDriver1 extends USB.Driver {
  ...
}

class MyCustomDriver2 extends USB.Driver {
  ...
}

// Instantiate the USB host and register our drivers
usbHost <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2], true);
```

## USB.Host Class Methods ##

### setDriverListener(*listener*) ###

This method instructs the host to begin listening for driver events. The application will then be notified via the supplied listener function if a driver is started or stopped.

Passing in `null` clears any previously assigned listener.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *listener* | Function | Yes | A function to be called when a driver event occurs |

#### Listener Function Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *eventType* | String | The driver event type: *USB_DRIVER_STATE_STARTED* or *USB_DRIVER_STATE_STOPPED* |
| *driver* | [USB.Driver](#usbdriver-class-usage) instance | The driver triggering the event |

#### Return Value ####

Nothing.

#### Example ####

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

### setDeviceListener(*listener*) ###

This method instructs the host to begin listening for runtime device events, such as plugging or unplugging a peripheral. The application will then be notified via the supplied listener function.

Passing in `null` clears any previously assigned listener.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | ---|
| *listener* | Function | Yes | A function to be called when the device or driver status changes |

#### Listener Function Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *eventType* | String | The name of the event type: *USB_DEVICE_STATE_CONNECTED* or *USB_DEVICE_STATE_DISCONNECTED* |
| *device* | Instance of [USB.Device](#usbdevice-class-usage) or [USB.Driver](#usbdriver-class-usage) | Either the device or driver instance, depending on what caused the status change event |

#### Return Value ####

Nothing.

#### Example ####

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

### reset() ###

This method resets the USB host. The effect of this action is similar to the physical reconnection of all connected devices. It disables USB, and cleans up all drivers and devices. This results in the execution of any corresponding driver and device listeners. All devices will have a new device object instances and different addresses after a reset.

It can be used by a driver or application in response to an unrecoverable error, such as a timed out bulk transfer, or a halt condition encountered during control transfers.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
class MyCustomDriver extends USB.Driver {
    ...
}

host <- USB.Host(hardware.usb, [MyCustomDriver], true);

host.setDeviceListener(function(eventName, eventDetails) {
    if (eventName == USB_DEVICE_STATE_CONNECTED && host.getAttachedDevices().len() != 1) {
        server.log("Only one device should be attached");
    }
});

// Reset after two seconds
imp.wakeup(2, function() {
    host.reset();
}.bindenv(this));
```

### getAttachedDevices() ###

This method returns a list of attached devices.

#### Return Value ####

Array of [USB.Device](#usbdevice-class-usage) objects.

## USB.Device Class Usage ##

This class represents attached USB devices. Please refer to the [USB specification](http://www.usb.org/) for details of USB devices' descriptions.

Typically, applications don't use device objects directly, instead they use drivers to acquire required endpoints. Neither applications nor drivers should explicitly create USB.Device objects &mdash; they are instantiated by the USB Drivers Framework automatically.

When using the USB Drivers Framework, all management of USB device configurations, interfaces and endpoints **must** go through the device object rather than via the imp API [**hardware.usb**](https://developer.electricimp.com/api/hardware/usb) object.

## USB.Device Class Methods ##

### getDescriptor() ####

This method returns the device’s descriptor. It throws an exception if the device is not currently connected.

#### Return Value ####

Table &mdash; the [device descriptor](#device-descriptor).

### getVendorId()

This method returns the device vendor ID. It throws an exception if the device is not currently connected.

#### Return Value ####

String &mdash; the device’s vendor ID.

### getProductId() ###

This method returns the device product ID. It throws an exception if the device is not currently connected.

#### Return Value ####

String &mdash; the device’s product ID.

### getAssignedDrivers() ###

This method returns an array of drivers for the attached device. It throws an exception if the device is not currently connected.

Each USB device may provide a number of interfaces which could be supported by a one or more drivers. For example, a keyboard with an integrated touchpad could have keyboard and touchpad drivers assigned.

#### Return Value ####

Array &mdash; a set of [USB.Driver](#usbdriver-class-usage) objects.

### getEndpointZero() ###

This method returns a proxy for the device’s Control Endpoint 0. The endpoint 0 is a special type of endpoint that implicitly exists for every device. The method throws an exception if the device is not currently connected.

#### Return Value ####

[USB.ControlEndpoint](#usbcontrolendpoint-class-usage) &mdash; the zero endpoint.

### getHost() ###

This method returns a reference to the parent USB host.

#### Return Value ####

[USB.Host](#usbhost-class-usage) &mdash; the host to which the device is connected.

## USB.ControlEndpoint Class Usage ##

This class represents USB control endpoints. Class instances are managed by instances of USB.Device and should be acquired by calling [*getEndpointZero()*](#getendpointzero) on a USB.Device instance.

**Note** Neither applications nor drivers should explicitly create USB.ControlEndpoint objects &mdash; they are instantiated by the USB Drivers Framework automatically.

#### Example ####

The following code sends a request to the control endpoint 0 to reset the state (clear error codes) of a functional endpoint specified by *functionalEndpointAddress*:

```squirrel
device
  .getEndpointZero()
  .transfer(USB_SETUP_RECIPIENT_ENDPOINT | USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_STANDARD,
            USB_REQUEST_CLEAR_FEATURE,
            0,
            functionalEndpointAddress);
```

## USB.ControlEndpoint Class Methods ##

### transfer(*requestType, request, value, index[, data]*)

This is a generic method for transferring data over a control endpoint.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *requestType* | Integer | Yes | USB request type. Please see [Control Endpoint Request Types](#control-endpoint-request-types) for more details |
| *request*| Integer | Yes | The specific USB request. Please see [Control Endpoint Requests](#control-endpoint-requests) for more details |
| *value* | Integer | Yes | A value determined by the specific USB request |
| *index* | Integer | Yes | An index value determined by the specific USB request |
| *data* | Blob | No | Optional storage for incoming or outgoing payload. Default: `null` |

#### Return Value ####

Nothing.

### getEndpointAddr() ###

This method returns the endpoint address, which is required by a device control operation performed over control endpoint 0.

#### Return Value ####

Integer &mdash; the endpoint address.

## USB.FuncEndpoint Class Usage ##

This class represents all non-control endpoints, ie. bulk, interrupt and isochronous endpoints. It is managed by the [USB.Device](#usbdevice-class-usage) class and should be acquired only through USB.Device instances.

**Note** Neither applications nor drivers should explicitly create USB.FuncEndpoint objects &mdash; they are instantiated by the USB Drivers Framework automatically.

## USB.FuncEndpoint Class Methods ##

#### write(*data, onComplete*) ###

This method asynchronously writes data through the endpoint. It throws an exception if the endpoint is closed or doesn't support *USB_DIRECTION_OUT*.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *data* | Blob | Yes | Payload data to be sent through this endpoint |
| *onComplete* | Function | Yes | A function to be called when the transfer is complete |

#### onComplete Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *endpoint* | [USB.FuncEndpoint](#usbfuncendpoint-class-usage) instance | The endpoint used |
| *state* | Integer | USB transfer state. Please see [USB Transfer States](#usb-transfer-states) for more details |
| *data* | Blob | The payload data being sent |
| *length* | Integer | The length of the written data |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
class MyCustomDriver extends USB.Driver {
    constructor(device, interfaces) {
        try {
            local payload = blob(16);
            local endpoint = interfaces[0].endpoints[1].get();
            endpoint.write(payload, function(ep, state, data, len) {
                if (len > 0) server.log(len + " bytes sent");
            }.bindenv(this));
        } catch(err) {
            server.error(err);
        }
    } // constructor

    function match(device, interfaces) {
        return MyCustomDriver(device, interfaces);
    }
}
```

### read(*data, onComplete*) ###

This method asynchronously reads data from the endpoint. It throws an exception if the endpoint is closed, has an incompatible type, or is already busy.

According to the Electric Imp [documentation](https://developer.electricimp.com/resources/usberrors), this method sets an upper limit of five seconds for any command for the bulk endpoint to be processed.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *data* | Blob | Yes | Blob to read data into |
| *onComplete* | Function  | Yes | A function to be called when the transfer is complete |

#### onComplete Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *endpoint* | [USB.FuncEndpoint](#usbfuncendpoint-class-usage) instance | The endpoint used |
| *state* | Integer | USB transfer state. Please see [USB Transfer States](#usb-transfer-states) for more details |
| *data* | Blob | The payload data being received |
| *length* | Integer | The length of the written data |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
class MyCustomDriver extends USB.Driver {
    constructor(device, interfaces) {
        try {
            local payload = blob(16);
            local endpoint = interfaces[0].endpoints[0].get();
            endpoint.read(payload, function(ep, state, data, len) {
                if (len > 0) server.log(len + " bytes read");
            }.bindenv(this));
        } catch(err) {
            server.error(err);
        }
    } // constructor

    function match(device, interfaces) {
        return MyCustomDriver(device, interfaces);
    }
}
```

### getEndpointAddr() ###

This method returns the endpoint address, which is required by a device control operation performed over control endpoint 0.

#### Return Value ####

Integer &mdash; the endpoint address.

## USB.Driver Class Usage ##

This class is the base for all drivers that are developed using the USB Drivers Framework. It contains one method, *match()* that **must** be be implemented by every USB driver, and two further methods, *release()* and *_typeof()*, which are optional but recommended.

**Note** Applications should not explicitly create USB.Driver objects &mdash; they are instantiated by the USB Drivers Framework automatically.

## USB.Driver Class Methods ##

### match(*deviceObject, interfaces*) ###

This method is used to check if the driver can support the specified device and its exposed interfaces.

If the driver can support the device, the method should return a new driver instance or an array of driver instances (when multiple interfaces are supported and a driver instance is created for each of them).

If the driver can’t support the device, this method should return `null`.

The driver-device matching procedure can be based on checking Vendor ID, Product ID, device class and/or subclass, and/or interfaces.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *device* | [USB.Device](#usbdevice-class-usage) instance | Yes | The object representing the attached device |
| *interfaces* | Array of tables | Yes | A set of tables each of which describes the [interfaces](#interface-descriptor) supported by the attached device |

#### Return Value ####

[USB.Driver](#usbdriver-class-usage) instance, array of [USB.Driver](#usbdriver-class-usage) instances, or `null`.

### release() ###

This method releases all of the resources instantiated by the driver. It should be used by the driver to clean up its resources and free external resources if necessary.

It is called by the USB Drivers Framework when a USB device is disconnected.

Do not access [USB.Driver](#usbdevice-class-usage) or endpoint instances from any callback once *release()* is called, as they may have already been partially released. Any attempts to access these objects and their members from the callback may therefore throw exceptions.

### _typeof() ###

This metamethod is used to return a class name when `typeof <instance>` is invoked. It can be used to identify the driver instance type in runtime (for example, for debugging purposes).

#### Example ####

```squirrel
local usbHost = USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2], true);

usbHost.setDriverListener(function(eventName, eventDetails) {
    if (eventName == "started" && typeof eventDetails == "MyCustomDriver2") {
        server.log("MyCustomDriver2 initialized");
    }
});
```

## USB Drivers Framework Structures ##

### Endpoint Constants ###

These are constants that may be useful for endpoint search functions.

| Constant Name | Value | Description |
| --- | --- | --- |
| *USB_ENDPOINT_CONTROL* | 0x00 | Control Endpoint type value |
| *USB_ENDPOINT_ISOCHRONOUS* | 0x01 | Isochronous Endpoint type value |
| *USB_ENDPOINT_BULK* | 0x02 | Bulk Endpoint type value |
| *USB_ENDPOINT_INTERRUPT* | 0x03 | Interrupt Endpoint type value |
| *USB_ENDPOINT_TYPE_MASK* | 0x03 | A mask value that covers all endpoint types |
| *USB_DIRECTION_OUT* | 0x00 | A bit value that indicates OUTPUT endpoint direction |
| *USB_DIRECTION_IN* | 0x80 | A bit value that indicates INPUT endpoint direction |
| *USB_DIRECTION_MASK* | 0x80 | A mask to extract the endpoint direction from an endpoint address |

### Control Endpoint Request Types ###

These are possible values for the [*ControlEndpoint.transfer()*](#transferrequesttype-request-value-index-data) method’s parameter *requestType*.

| Constant Name | Value | Description |
| --- | --- | --- |
| *USB_SETUP_HOST_TO_DEVICE* | 0x00  | Transfer direction: host to device |
| *USB_SETUP_DEVICE_TO_HOST* | 0x80  | Transfer direction: device to host |
| *USB_SETUP_TYPE_STANDARD* | 0x00  | Type: standard |
| *USB_SETUP_TYPE_CLASS* | 0x20  | Type: class |
| *USB_SETUP_TYPE_VENDOR* | 0x40  | Type: vendor |
| *USB_SETUP_RECIPIENT_DEVICE* | 0x00  | Recipient: device |
| *USB_SETUP_RECIPIENT_INTERFACE* | 0x01  | Recipient: interface |
| *USB_SETUP_RECIPIENT_ENDPOINT* | 0x02  | Recipient: endpoint |
| *USB_SETUP_RECIPIENT_OTHER* | 0x03  | Recipient: other |

### Control Endpoint Requests ###

These are possible values for the [*ControlEndpoint.transfer()*](#transferrequesttype-request-value-index-data) method’s parameter *request*.

| Constant Name | Value | Description|
| --- | --- | --- |
| *USB_REQUEST_GET_STATUS* | 0 | Get status |
| *USB_REQUEST_CLEAR_FEATURE* | 1 | Clear feature |
| *USB_REQUEST_SET_FEATURE* | 3  | Set feature |
| *USB_REQUEST_SET_ADDRESS* | 5 | Set address |
| *USB_REQUEST_GET_DESCRIPTOR* | 6 | Get descriptor |
| *USB_REQUEST_SET_DESCRIPTOR* | 7 | Set descriptor |
| *USB_REQUEST_GET_CONFIGURATION* | 8 | Get configuration |
| *USB_REQUEST_SET_CONFIGURATION* | 9 | Set configuration |
| *USB_REQUEST_GET_INTERFACE* | 10 | Get interface |
| *USB_REQUEST_SET_INTERFACE* | 11 | Set interface |
| *USB_REQUEST_SYNCH_FRAME* | 12 | Sync frame |

### USB Transfer States ###

These are possible values for the [*ControlEndpoint.transfer()*](#transferrequesttype-request-value-index-data) method’s parameter *state*.

Not all of the non-zero state values indicate errors. For example, *USB_TYPE_FREE* (15) and *USB_TYPE_IDLE* (16) are not errors. The range of possible error values you may encounter will depend on which type of USB device you are connecting. More details [here](https://developer.electricimp.com/api/hardware/usb/configure).

| Constant Name | Value |
| --- | --- |
| *OK* | 0 |
| *USB_TYPE_CRC_ERROR* | 1 |
| *USB_TYPE_BIT_STUFFING_ERROR* | 2 |
| *USB_TYPE_DATA_TOGGLE_MISMATCH_ERROR* | 3 |
| *USB_TYPE_STALL_ERROR* | 4 |
| *USB_TYPE_DEVICE_NOT_RESPONDING_ERROR* | 5 |
| *USB_TYPE_PID_CHECK_FAILURE_ERROR* | 6 |
| *USB_TYPE_UNEXPECTED_PID_ERROR* | 7 |
| *USB_TYPE_DATA_OVERRUN_ERROR* | 8 |
| *USB_TYPE_DATA_UNDERRUN_ERROR* | 9 |
| *USB_TYPE_UNKNOWN_ERROR* | 10 |
| *USB_TYPE_UNKNOWN_ERROR* | 11 |
| *USB_TYPE_BUFFER_OVERRUN_ERROR* | 12 |
| *USB_TYPE_BUFFER_UNDERRUN_ERROR* | 13 |
| *USB_TYPE_DISCONNECTED* | 14 |
| *USB_TYPE_FREE* | 15 |
| *USB_TYPE_IDLE* | 16 |
| *USB_TYPE_BUSY* | 17 |
| *USB_TYPE_INVALID_ENDPOINT* | 18 |
| *USB_TYPE_TIMEOUT* | 19 |
| *USB_TYPE_INTERNAL_ERROR* | 20 |

## USB Drivers Framework Event Structures ##

The USB Drivers Framework uses tables named *descriptors* which contain a description of the attached device, its interfaces and endpoint.
[endpoint](#endpoint-descriptor) and [interface](#interface-descriptor) descriptors are used only at the driver probing stage, while [device](#device-descriptor) descriptors may be acquired from a [USB.Device](#usbdevice-class-usage) instance.

### Device Descriptor ###

A device descriptor contains whole the device specification in addition to the [Vendor ID](#getvendorid) and [Product Id](#getproductid). The descriptor table has the following keys:

| Key | Type | Description |
| --- | --- | --- |
| *usb* | Integer | The USB specification to which the device conforms. It is a binary coded decimal value. For example, 0x0110 is USB 1.1 |
| *class* | Integer | The USB class assigned by the [USB-IF](http://www.usb.org). If 0x00, each interface specifies its own class. If 0xFF, the class is vendor specific |
| *subclass* | Integer | The USB subclass (assigned by the [USB-IF](http://www.usb.org)) |
| *protocol* | Integer | The USB protocol (assigned by the [USB-IF](http://www.usb.org)) |
| *vendorid* | Integer | The vendor ID (assigned by the [USB-IF](http://www.usb.org)) |
| *productid* | Integer | The product ID (assigned by the vendor) |
| *device* | Integer | The device version number as BCD |
| *manufacturer* | Integer | Index to a string descriptor containing the manufacturer string |
| *product* | Integer | Index to a string descriptor containing the product string |
| *serial* | Integer | Index to a string descriptor containing the serial number string |
| *numofconfigurations* | Integer | The number of possible configurations |

### Interface Descriptor ###

When probed, a driver’s [*match()*](#matchdeviceobject-interfaces) method receives two objects: a [USB.Device](#usbdevice-class-usage) instance and an array of the interfaces exposed by this device. Each interface is presented as a descriptor table with the following keys:

| Key | Type | Description |
| --- | --- | --- |
| *interfacenumber* | Integer | The number representing this interface |
| *altsetting* | Integer | The alternative setting of this interface |
| *class* | Integer | The interface class |
| *subclass* | Integer | The interface subclass |
| *protocol* | Integer | The interface class protocol |
| *interface* | Integer | The index of the string descriptor describing this interface |
| *endpoints* | Array of table | The endpoint [descriptors](#endpoint-descriptor) |
| *find* | Function | Auxiliary function to search for endpoints with specified attributes |
| *getDevice* | Function | Returns the USB.Device instance that is the owner of this interface |

#### find() ####

The interface descriptor’s *find()* function signature is as follows:

| Parameter | Type | Accepted Values |
| --- | --- | --- |
| *endpointType* | Integer | *USB_ENDPOINT_CONTROL, USB_ENDPOINT_BULK, USB_ENDPOINT_INTERRUPT* |
| *endpointDirection* | Integer | *USB_DIRECTION_IN, USB_DIRECTION_OUT* |

It returns an instance of either the [ControlEndpoint](#usbcontrolendpoint-class-usage) class or the  [FuncEndpoint](#usbfuncendpoint-class-usage) class, or `null` if no endpoints were found.

### Endpoint Descriptor ###

Each endpoints table contains the following keys:

| Key | Type | Description |
| --- | --- | --- |
| *address* | Integer bitfield | The endpoint address:<br />D0-3: Endpoint number<br />D4-6: Reserved<br />D7: Direction (0 out, 1 in) |
| *attributes* | Integer bitfield | Transfer type:<br />00: control<br />01: isochronous<br />10: bulk<br />11: interrupt |
| *maxpacketsize* | Integer | The maximum size of packet this endpoint can send or receive |
| *interval* | Integer | Only relevant for Interrupt In endpoints |
| *get* | Function | A function that returns an instance of either [USB.FuncEndpoint](#usbfuncendpoint-class-usage) or [USB.ControlEndpoint](#usbcontrolendpoint-class-usage) depending on information stored in the *attributes* and *address* fields |

## USB Driver Examples ##

- [Generic HID device](./../drivers/GenericHID_Driver)
- [Brother QL720NW label printer](./../drivers/QL720NW_UART_USB_Driver)
- [FTDI USB-to-UART converter](./../drivers/FT232RL_FTDI_USB_Driver)
- [Keyboard using the HID protocol](./../drivers/HIDKeyboard)
- [Keyboard using the Boot porotocol](./../drivers/BootKeyboard)
