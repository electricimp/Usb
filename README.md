# USB Drivers Framework

Usb Drivers Framework is intended to simplify and standardize USB driver creation and adoption by application developer.

**To use this library add the following statement to the top of your device code:**

```
#require "USB.device.lib.nut:0.2.0"
```
USB stack consists of five simple abstractions:
- **[USB.Host](#usbhost-class)** - the main entrance point for an application. Responsible for drivers registration and events handling
- **[USB.Device](#usbdevice-сlass)** - wrapper for USB device description, instantiated for each connected device
- **[USB.Driver](#usbdriver-class)** - base api which should be re-implemented by each USB driver
- **[USB.ControlEndpoint](#usbcontrolendpoint-class)** - provides api for control endpoint
- **[USB.FunctionalEndpoint](#usbfunctionalendpoint-class)** - provides api for bulk or interrupt endpoints

Typical use case for this framework is to help application developer to reuse existed driver like in the following example (NOTE: the code is for demo only)
```
#require "FT232rl.nut:1.0.0"
#require "USB.device.lib.nut:0.2.0"


function driverStatusListener(eventType, eventObject) {
    if (eventType == "started") {
        // start work with FT232rl device
    } else if (eventType == "stopped") {
        // immediately stop all interaction with FT232rl device
    }
}

host <- USB.Host(hardware.usb, [FT232rl]);
host.setEventListener(driverStatusListener);

```

----

## USB.Host class

The main interface to start working with USB devices.
Provides public API for an application to register drivers and assign listeners for important events like device connect/disconnect.

If you have more then one USB port on development board then you should create USB.Host for each of them.

#### USB.Host(*usb, drivers, [, autoConfigPins]*)

Instantiates the USB.Host class.

| Parameter 	 | Data Type | Required/Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb* 		 | Object 	 | required  | The imp API hardware usb object `hardware.usb` |
| *drivers*      | USB.Driver[] | required  | An array of the pre-defined driver classes |
| *autoConfigPins* | Boolean   | `true`  | Whether to configure pin R and W according to [electric imps documentation](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb). These pins must be configured for the usb to work on **imp005**. |

##### Example

```squirrel
#require "MyCustomDriver1.device.lib.nut:1.2.3"
#require "MyCustomDriver2.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2]);
```

#### setEventListener(*callback*)

Assigns listener for device and driver status changes.
The following events are supported:
- device `"connected"`
- device `"disconnected"`
- driver `"started"`
- driver `"stopped"`

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *callback*  | Function  | Yes      | Function to be called on event. See below. |

Setting of *null* clears the previously assigned listener.

##### callback(*eventType,

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *eventType*  | String  |  Name of the event "connected", "disconnected", "started", "stopped" |
| *object* | USB.Device |  The device peer for "connected"/"disconnected" event |
| *object* | USB.Driver |  Driver instance for "started"/"stopped" event |

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

------

## USB.Device class

The class that represents attached device.
It is parsing device description, lookup for a drivers and control drivers lifecycle. All management of configurations, interfaces and endpoints **MUST** go through Device object.

An application does not need to use device object normally.
It is usually used by drivers to acquire required endpoints.


#### getEndpoint(*ifs, type, direction, pollTime*)

Request endpoint of required type and direction, and that are described at given interface.
The function returns cached object or instantiates a new one object (`USB.ControlEndpoint` or `USB.FunctionalEndpoint`) which is corresponding to the requested argument and return null otherwise.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ----------- | ----------- |
| *ifs*      | Any | n/a |interface ID  |
| *type*      | Number | n/a | the type of endpoint |
| *direction*  | Number | n/a | the type of endpoint's direction |
| *pollTime* | Number | 255 | Interval for polling endpoint for data transfers |

**NOTE** Interface ID is delivered to a driver through `USB.Driver.match` function at drivers lookup stage. So far it is just interface descriptor table, but can be changed with future framework updates.


#### getEndpointByAddress(*epAddress, pollTime*)

Request endpoint with given address.
The function searches for the address across all available interface and returns null if there is no endpoint with such address. New endpoint is stored at cache.


| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | --------- | ----------- |
| *epAddress* | Number | n/a | address of the usb endpoint |
| *pollTime* | Number | 255 | Interval for polling endpoint for data transfers |


#### getVendorId()

Return the device vendor ID
Throws exception if the device was detached

#### getProductId()

Return the device product ID

Throws exception if the device was detached

--------

## USB.ControlEndpoint class

Represent control endpoints.
This class is required due to specific EI usb API
This class is managed by USB.Device and should be acquired through USB.Device instance

``` squirrel
// Reset functional endpoint via control endpoint

device
    .getEndpointByAddress(0)
    .transfer(
        USB_SETUP_RECIPIENT_ENDPOINT | USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_STANDARD,
        USB_REQUEST_CLEAR_FEATURE,
        0,
        endpointAddress);
```


#### transfer(reqType, type, value, index, data = null)

Generic function for transferring data over control endpoint.
**Note:** Only vendor specific requires are allowed. For other control operation use USB.Device, USB.ControlEndpoint public API

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *reqType* 		   | Number | n/a 	   |  USB request type |
| *req* 		     | Number 	 | n/a 	   |  The specific USB request |
| *value* 		     | Number 	 | n/a 	   |  A value determined by the specific USB request|
| *index* 		     | Number 	 | n/a 	   | An index value determined by the specific USB request |
| *data* 		     | Blob 	 | null 	   | [optional] Optional storage for incoming or outgoing payload|

#### clearStall()

Reset given endpoint

------------

## USB.FunctionalEndpoint class

The class that represent all non-control endpoints, e.g. bulk, interrupt and isochronous
This class is managed by USB.Device and should be acquired through USB.Device instance api.


#### write(data, onComplete)

Asynchronous write date through the endpoint. Throw and exception if endpoint close or it doesn't support USB_DIRECTION_OUT.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		   | Blob | n/a 	   | payload data blob to be sent through this endpoint |
| *onComplete* 		     | Function 	 | n/a 	   | callback for transfer status notification |


**Callback Function**

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*  | Number  | the usb error type |
| *len*  | Number  | written payload length |


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
Read data through this endpoint.
Throw an exception if EP is closed, has incompatible type or already busy.

Sets an upper limit of five seconds for any command to be processed for the bulk endpoint according to the [electric imps documentation](https://electricimp.com/docs/resources/usberrors/#stq=&stp=0).

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		   | Blob | n/a 	   | blob to read data into |
| *onComplete* 		     | Function 	 | n/a 	   | callback method to get read details |


**Callback Function**

| Parameter   | Data Type | Description |
| ----------- | --------- | ----------- |
| *error*  | Number  | the usb error number |
| *len*  | Number  | read payload length |

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

Make a reset of the current endpoint on stall or any other non-critical issue,

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

-------


## USB.Driver class

The USB.Driver class is used as the base for all drivers that use this library. It contains a set of functions that are expected by [USB.Host](#USBhost) as well as some set up functions. There are a few required functions that must be overwritten.

### Required Functions

These are only two functions must be implemented by usb driver and required for correct operation inside USB framework.


#### match(*deviceObject, interfaces*)

These method checks if current driver could support all the provided interface for the current device or not. Match method could be based on VID, PID, device class, subclass and interfaces. This method is mandatory and it is not possible to register driver without this method. Once the driver is registered with USB.Host, then `match()` method will be called on each device "connected" event. Method returns a driver object or null.

#### release()

Release all instantiate resource before driver close. It is used when device is detached and all resources are going to be released. It is important to note all device resources are released prior to this function call.

##### Example

```squirrel
class MyUsbDriver extends USB.Driver {

    static VID = 0x01f9;
    static PID = 0x1044;

    _interface = null;

    constructor(interface) {
      _interface = interface;
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


## Driver Examples

### [UartOverUsbDriver](./UartOverUsbDriver/)

The UartOverUsbDriver class creates an interface object that exposes methods similar to the uart object to provide compatibility for uart drivers over usb.


### [FtdiUsbDriver](./FtdiUsbDriver/)

The FtdiUsbDriver class exposes methods to interact with a device connected to usb via an FTDI cable.


# License

This library is licensed under the [MIT License](/LICENSE).
