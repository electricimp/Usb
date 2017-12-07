## Driver Development Guide

This section is intended for those developers who is going to create new driver for a USB device.

### Generic rules

Each driver can be interpreted as special type of library that should follow  all rules about including of any libraries new driver may depends on. Particularly it is recommended to avoid use of `#include` or `@require` [Builder](https://electricimp.com/docs/tools/builder/) instruction to prevent code duplication at an application that may utilize the driver.

### Basic driver implementation

For developer convenient USB framework comes with basic [driver class](#usbdriver-class) implementation. A developer need only to create its own class as extension of this class and override [match](#matchdeviceobject-interfaces) function which used by framework to probe each driver about driver ability to work with certain set of attached device interfaces.

```squirrel
class MyUsbDriver extends USB.Driver {
    // Just dupe driver
    function match(device, interfaces) {
        return null;
    }
}
```

### Driver probing procedure

To get information whether the driver can deal with attached device, USB framework probes every registered device with [match](#matchdeviceobject-interfaces) function where  [USB.Device](#usbdevice-class) instance (attached device peer) and device exposed [interfaces](#Interface-descriptor) are provided. If the driver can work with this device and the interfaces, it should return new instance of the driver class. After that USB framework keep on probing of other drivers if there is any in the list.

#### Composite device drivers

From the USB framework point of view attached USB device consists of set of functional interfaces, and each interface `may` have individually assigned driver. USB specification distinguishes composite type device ( where every interface acts individually) and regular devices (where interfaces are only parts of the device function). In case of composite device USB framework split up device interfaces according to [Interface Association Descriptor](http://www.usb.org/developers/docs/InterfaceAssociationDescriptor_ecn.pdf) (or individually if no IAD is provided) and try to find driver for every interface (or group of interfaces).  Thus there is possible situation when a single driver is probed and instantiated several times for the same device.

### Getting access to device exposed interfaces

Every driver receives [interfaces](#Interface-descritptor) it may work with at [match](#matchdeviceobject-interfaces) function. To start working with this interface the driver need to get right endpoint by parsing information from `endpoints` array of the interface descriptor. When necessary endpoint descriptor is found, the driver need to call `get()` function provided by every [endpoint](#Endpoint-descriptor) descriptor.

```
    function findEndpont(interfaces) {
        foreach(interface in interfaces) {

            if (interface["class"] == REQUIRED_CLASS) {

                local endpoints = interface.endpoints;

                foreach(ep in endpoints) {
                    if (ep.attributes == USB_ENDPOINT_BULK &&
                        (ep.address & USB_DIRECTION_MASK) == USB_DIRECTION_IN)

                        return ep.get();
                }
            }
        }

        return null;
    }
```

To simplify new driver code every interface descriptor comes with `find` function that searches for endpoint with given attributes and return found first.
```
    function initializeDriver(interface) {
        _bulkIn = interface.find(USB_ENDPOINT_BULK, USB_DIRECTION_IN);
    }
```

### Driver release procedure

When device resources required for the driver functionality were gone, USB framework call drivers [release](#release) function to give it a change to shutdown gracefully and release any resources were allocated during its lifetime.


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

```

--------

## USB Drivers Framework API specification

### USB.Host class

The main interface to start working with USB devices and drivers.

If you have more then one USB port on development board then you should create USB.Host instance for each of them.

#### USB.Host(drivers, [, autoConfigPins]*)

Instantiates the USB.Host class. USB.Host is an abstraction for USB port. It should be instantiated only once for any application.

There are some imp boards which does not have usb port, therefore exception will be thrown in that case.

USB framework suppose that developer will not use [`hardware.usb`](https://electricimp.com/docs/api/hardware/usb/)  api in parallel.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *drivers*      | USB.Driver[] | required  | An array of the pre-defined driver classes |
| *autoConfigPins* | Boolean   | `true`  | Whether to configure pin R and W according to [electric imps documentation](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb). These pins must be configured for the usb to work on **imp005**. |

##### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "MyCustomDriver1.device.lib.nut:1.2.3"
#require "MyCustomDriver2.device.lib.nut:1.0.0"

usbHost <- USB.Host([MyCustomDriver1, MyCustomDriver2]);
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

Resets the USB host. The effect of this action is analogous to unplugging the device.  Can be used by driver or application in response to unrecoverable error like unending bulk transfer or halt condition during control transfers.

This method disable usb, clean up all drivers and devices with corresponding event listener notifications and reconfigure usb from scratch. All devices will have a new device object instances and different address.

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
Each device USB device could provide the number of interfaces which could be supported by a single driver or by the number of different drives (For example keyboard with touch pad could have keyboard driver and a separate touch pad driver).

#### getEndpointZero()

Returns Control Endpoint 0 proxy for the device. EP0 is a special type of endpoints that implicitly exists for every device. Throws exception if the device is detached.

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
**Note:** Only vendor specific requests are allowed for now. For other control operation use USB.Device or USB.ControlEndpoint public API

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *reqType*      | Number    | n/a 	   | USB request type [see](https://electricimp.com/docs/api/hardware/usb/controltransfer/) |
| *req* 		 | Number 	 | n/a 	   | The specific USB request [see](https://electricimp.com/docs/api/hardware/usb/controltransfer/) |
| *value* 		 | Number 	 | n/a 	   | A value determined by the specific USB request|
| *index* 		 | Number 	 | n/a 	   | An index value determined by the specific USB request |
| *data* 		 | Blob 	 | null    | [optional] Optional storage for incoming or outgoing payload|


#### getAddress()

Returns the endpoint address. Typical use case for this function is to get endpoint ID for some of device control operation performed over Endpoint 0.

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

#### getAddress()

Returns the endpoint address. Typical use case for this function is to get endpoint ID for some of device control operation performed over Endpoint 0.


## USB.Driver class

This class is the base for all drivers that are developed for USB Drivers Framework. It contains three mandatory methods which must be implemented by every USB driver.

### match(*deviceObject, interfaces*)

Checks if the driver can support all the specified interfaces for the specified device. Returns the driver object (if it can support) or *null* (if it can not support).

The method may be called many times by USB Drivers Framework. The method's implementation can be based on VID, PID, device class, subclass and interfaces.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *deviceObject* 		 | USB.Device 	 | required  | an instance of the USB.Device for the attached device |
| *interfaces*      | Array of tables | required  | An array of tables which describe [interfaces](#Interface-descriptor) for the attached device |

### release()

Releases all resources instantiated by the driver.

It is called by USB Drivers Framework when USB device is detached and all resources should be released.

It is important to note all device resources are released prior to this function call and all Device/Endpoint methods calls result in throwing of an exception. It means that it is not possible to perform read, write or transfer for the detached device and this method uses to release all driver related resources and free an external resource if necessary.

### \_typeof()

Meta-function to return class name when typeof <instance> is run. Uses to identify the driver instance type in runtime.

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

USB framework uses a few special structures named `descriptors` and which contain description of attached device, its interfaces and endpoint. [Endpoint](#Endpoint-descriptor) and [Interface](#Interface-descriptor) descriptors are used only at driver probing stage, while [Device](#Device-descriptor) descriptor could be acquired from [USB.Device](#usbdevice-class) instance.

#### Device descriptor

Device descriptor contains whole device specification in addition to [Vendor ID](#getvendorid) and [Product ID](#getproductid) acquired through corresponding functions. The descriptor is a table with a set of fields:

| Descriptor key | Type | Description |
| -------------- | ---- | ----------- |
| usb | Integer | The USB specification to which the device conforms. \n It is a binary coded decimal value. For example, 0x0110 is USB 1.1 |
| class | Integer | The USB class assigned by [USB-IF](www.usb.org). If 0x00, each interface specifies its own class. If 0xFF, the class is vendor specific. |
| subclass | Integer | The USB subclass (assigned by the [USB-IF](www.usb.org)) |
| protocol | Integer | The USB protocol (assigned by the [USB-IF](www.usb.org)) |
| vendorid | Integer | The vendor ID (assigned by the [USB-IF](www.usb.org)) |
| productid| Integer | The product ID (assigned by the vendor) |
| device |Integer | The device version number as BCD |
| manufacturer | Integer | Index to string descriptor containing the manufacturer string |
| product | Integer | Index to string descriptor containing the product string |
| serial |Integer | Index to string descriptor containing the serial number string |
| numofconfigurations |Integer	The number of possible configurations |


#### Interface descriptor

As it is described at driver selection section [match function](#matchdeviceobject-interfaces) of probed driver receives two objects: [USB.Device](#usbdevice-class) instance and array of interfaces exposed by this device. Interface descriptor is a table with a set of fields:

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

- [UartOverUsbDriver](./examples/QL720NW_UART_USB_Driver/)
- [FtdiUsbDriver](./examples/FT232RL_FTDI_USB_Driver/)
