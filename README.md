# Usb Drivers Framework

Usb Drivers Framework was intended to simplify and standardize USB driver creation and handling.

**To use this library add the following statement to the top of your device code:**

```
#require "USB.device.lib.nut:0.2.0"
```
USB stack consists of five simple abstractions:
- **[USB.Host](#usbhost-class)** - the main entrance point for an application. Responsible for drivers registration and events handling
- **[USB.Device](#usbdevice-сlass)** - wrapper for USB device description, instantiated for each connected device
- **[USB.Driver](#usbdriver)** - base api which should re-implement each USB driver
- **[USB.ControlEndpoint](#usbcontrolendpoint-class)** - provides api for control endpoint
- **[USB.FunctionalEndpoint](#usbfunctionalendpoint)** - provides api for bulk or interrupt endpoints

```squirrel
class MyUsbDriver extends USB.Driver {

    static VID = 0x01f9;
    static PID = 0x1044;

    _device = null;  /* USB.Device */
    _bulk = null;    /* USB.FunctionalEndpoint */
    _control = null; /* USB.ControlEndpoint */

    constructor(device, interfaces) {
      _device = device;
      _bulk = _device.getEndpoint(interfaces[0], USB_ENDPOINT_BULK, USB_DIRECTION_IN);
      _control = _device.getEndpointByAddress(0);
    }

    // Returns driver instance if matched
    function match(device, interfaces) {
        if (device.getVendorId() == VID && device.getProductId() == PID)
          return MyUsbDriver(device, interfaces);
        return null;
    }
}

usbHost <- USB.Host(hardware.usb, [MyUsbDriver]);
```

----

## USB.Host class

The main interface to start working with USB devices.
Provides public API for an application to registers drivers and assigns listeners
for important events like device connect/disconnect.

If you have more then on USB port on development board then you should create USB.Host for each of them.

#### USB.Host(*usb, drivers, [, autoConfigPins]*)

Instantiates the USB.Host class. It takes `hardware.usb` as a required parameter and an optional boolean flag.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb* 		 | Object 	 | n/a 	   | The imp API hardware usb object `hardware.usb` |
| *drivers* 		 | USB.Driver[] 	 | n/a 	   | An array of the pre-defined drivers |
| *autoConfPins* | Boolean   | `true`  | Whether to configure pin R and W according to [electric imps docs](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb). These pins must be configured for the usb to work on an **imp005**. |

##### Example

```squirrel
#require "MyCustomDriver1.device.lib.nut:1.2.3"
#require "MyCustomDriver2.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb, [MyCustomDriver1, MyCustomDriver2]);
```

#### setEventListener(*callback*)

Assign listener about device and  driver status changes.
There are four events could be generated: `"connected"`/`"disconnected"` for device status and `"started"`/`"stopped"` for driver status.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *callback*  | Function  | Yes      | Function to be called on event |

Setting of **NULL** clears previously assigned listener.

##### Callback function

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

#### constructor(*usb, speed, deviceDescriptor, deviceAddress, drivers*)
Constructs device peer

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb* 		     | Object 	 | n/a 	   | The imp API hardware usb object `hardware.usb` |
| *speed* | Number   | n/a  | Usb device speed (Mb/s). |
| *deviceDescriptor* | deviceDescriptor   | n/a  | Usb device descriptor. |
| *deviceAddress* | Number   | n/a  | Usb device logical address assigned by [USB.Host](#usbhost-class). |
| *drivers* | USB.Driver[] | n/a  | An array of known drivers |


#### setAddress(*address*)

Assigns new logical device address. Throws an exception if device was disconnected or the address was assigned already.

| Parameter Data | Type | Description |
| -------------- | --------- | ----------- |
| *address* | Number | a new usb device address |

#### getEndpoint(*ifs, type, direction*)

Request endpoint of required type and direction, and that are described at given interface.
The function returns cached object or instantiates a new one object (`USB.ControlEndpoint` or `USB.FunctionalEndpoint`) which is corresponding to the requested argument and return null otherwise.

| Parameter 	 | Data Type | Description |
| -------------- | --------- | ----------- |
| *ifs*      | Any | interface ID  |
| *type*      | Number | the type of endpoint |
| *direction*  | Number | the type of endpoint's direction |

**NOTE** Interface ID is delivered to an driver through `USB.Driver.match` function at drivers lookup stage. So far it is just interface descriptor table, but can be changed with future framework updates.


#### getEndpointByAddress(*epAddress*)

Request endpoint with given address.
The function searches for the address across all available interface and returns null if there is no endpoint with such address. New endpoint is stored at cache.


| Parameter 	 | Data Type | Description |
| -------------- | --------- | ----------- |
| *epAddress* | Number | address of the usb endpoint |


#### stop()

Called by USB.Host when the devices is detached
Closes all open endpoint and releases all drivers

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

#### constructor (device, ifs, epAddress, maxPacketSize)

Constructor is public API but it is not recommended to use it for end point creation.
Please, use `USB.Device.getEndpoint` for endpoint allocation

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *device* 		   | USB.Device| n/a 	   | device object see `USB.Device` |
| *ifs* 		     | Interface 	 | n/a 	   | usb device interface descriptor |
| *epAddress* 		     | Number 	 | n/a 	   | address of the usb endpoint |
| *maxPacketSize* 		     | Number 	 | n/a 	   | max packet size which could be send via transfer |


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

#### close()

Close current endpoint for all operations.
All further operation causes exception.
Uses for a device safe disconnect.

------------

## USB.FunctionalEndpoint

The class that represent all non-control endpoints, e.g. bulk, interrupt and isochronous
This class is managed by USB.Device and should be acquired through USB.Device instance api.


#### constructor (device, ifs, epAddress, epType, maxPacketSize)

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *device* 		   | USB.Device| n/a 	   | device object see `USB.Device` |
| *ifs* 		     | Interface 	 | n/a 	   | usb device interface descriptor |
| *epAddress* 		     | Number 	 | n/a 	   | address of the usb endpoint |
| *epType* 		     | Number 	 | n/a 	   | type of the endpoint: USB_ENDPOINT_ISCHRONOUS, USB_ENDPOINT_BULK or USB_ENDPOINT_INTERRUPT |
| *maxPacketSize* 		     | Number 	 | n/a 	   | max packet size which could be send via transfer |

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
Throw an exception if EP is closed, has incompatible type or already busy

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
            endpoint.reset();
        }
    }.bindenv(this));
}
catch (e) {
  server.log("Endpoint is closed");
}

```

#### close()

Mark this endpoint as closed. All further operation causes exception.


```squirrel
try {
    local payload = blob(16);
    local endpoint = device.getEndpointByAddress(epAddress);
    // Close endpoint
    endpoint.close();
    // This method should throw an exception now:
    endpoint.read(payload, function(error, len) {
        // empty
    }.bindenv(this));
}
catch (e) {
  server.log("Endpoint is closed");
}

```

-------


## USB.Driver

The USB.Driver class is used as the base for all drivers that use this library. It contains a set of functions that are expected by [USB.Host](#USBhost) as well as some set up functions. There are a few required functions that must be overwritten.

### Required Functions

These are three functions must be implemented for usb drive.

#### constructor(*device, interfaces*)

By default the constructor should be private and takes an instance of the USB.Device class and list of Interfaces as parameters. Instantiation of the driver object should happen in the `match` method only.
It is possible to get an access to the working `usb` object via `device._usb` but it is not recommended.
All initialization of endpoints should happen in constructor. There is no extra methods for a lazy initialization of the driver.

##### Example

```squirrel
class MyUsbDriver extends USB.Driver {

    _device = null;
    _bulkIn = null;
    _bulkOut = null;

    constructor(device, interfaces) {
      _device = device;
      _bulkIn = device.getEndpoint(interfaces[0], USB_ENDPOINT_BULK, USB_DIRECTION_IN);
      _bulkOut = device.getEndpoint(interfaces[0], USB_ENDPOINT_BULK, USB_DIRECTION_OUT);
      this.start();
    }

    function match(device, interfaces) {
      if (_checkMatch(device, interfaces))
        return MyUsbDriver(device, interfaces);
      return null;
    }

    function _checkMatch(device, interfaces) {
      // Implement device match here
      return true;
    }

    function start() {
      imp.wakeup(0, (function(action, error, payload, length) {
          if (_bulkIn != null) {
            _bulkIn.read(blob(64), function(endp, error, data, len) {

            });
          }
      }).bindenv(this));
    }

    function release() {
        _bulkIn = null;
        _bulkOut = null;
    }
}
```


#### match(*deviceObject, interfaces*)

Method that returns a driver object or null. These method checks if current driver could support all the provided interface for the current device or not. Match method could be based on VID, PID, device class, subclass and interfaces. This method is mandatory and it is not possible to register driver without this method. Once the driver is registered with USB.Host, then `match()` method will be called on each device "connected" event.

#### release()

Release all instantiate resource before driver close. Uses for a driver disconnection.

##### Example

```squirrel
class MyUsbDriver extends USB.Driver {

    static VID = 0x01f9;
    static PID = 0x1044;

    _device = null;

    constructor(device) {
      _device = device;
    }
    // Returns an array of VID PID combinations
    function match(device, interface) {
        if (device._vid == VID && device._pid == PID)
          return MyUsbDriver(device);
        return null;
    }
}

usbHost <- USB.Host(hardware.usb);

// Register the Usb driver with usb host
usbHost.registerDriver(MyUsbDriver);
```

#### ``_typeof() [optional]``

The *_typeof()* method is a squirrel metamethod that returns the class name. See [metamethods documentation](https://electricimp.com/docs/resources/metamethods/)

##### Example
```squirrel
class MyUsbDriver extends USB.Driver {
    // Metamethod returns class name when - typeof <instance> - is called
    function _typeof() {
        return "MyUsbDriver";
    }
}

myDriver <- MyUsbDriver();

// This will log "MyUsbDriver"
server.log(typeof myDriver);
```


## Driver Examples

### [UartOverUsbDriver](./UartOverUsbDriver/)

The UartOverUsbDriver class creates an interface object that exposes methods similar to the uart object to provide compatibility for uart drivers over usb.


### [FtdiUsbDriver](./FtdiUsbDriver/)

The FtdiUsbDriver class exposes methods to interact with a device connected to usb via an FTDI cable.


# License

This library is licensed under the [MIT License](/LICENSE).
