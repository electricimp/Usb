# Usb Drivers

The USB libary acts as a wrapper around the Imp API `hardware.usb` object and manages USB device connections, disconnections, transfers and driver selection.

**To use this library add the following statement to the top of your device code:**

```
#require "USB.device.lib.nut:0.2.0"
```

## USB.Host

The USB.Host class has methods to encapsulate the `hardware.usb` configuration api and register drivers (see [USB.DriverBase](#USBDriver) for more details on USB drivers).

### Class Usage

#### Constructor: USB.Host(*usb[, autoConfigPins]*)

Instantiates the USB.Host class. It takes `hardware.usb` as a required parameter and an optional boolean flag.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb* 		 | Object 	 | n/a 	   | The imp API hardware usb object `hardware.usb` |
| *autoConfPins* | Boolean   | `true`  | Whether to configure pin R and W according to [electric imps docs](https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb). These pins must be configured for the usb to work on an imp005. |

##### Example

```squirrel
usbHost <- USB.Host(hardware.usb);
```

### Class Methods

#### registerDriver(*driverClass*)

Registers a driver to a devices list. Driver class should be inherited from the USB.DriverBase class and re-implement `USB.DriverBase.match` method. When a device is connected via usb then static method "match" will be called for each driver. The `match` method could check device VID/PID combination or it could implement more complex solution based on device class, subclass and interfaces.

| Parameter 	| Data Type | Required | Description |
| ------------- | --------- | -------- | ----------- |
| *driverClass* | Class 	| Yes 	   | A reference to the class to be instantiated when a device with matching identifiers is connected. Must be a valid usb driver class that extends the *USB.DriverBase* class. |

##### Example

```squirrel
// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiUsbDriver);
```

#### unregisterDriver(*driverClass*)

Unregister driver to do not instantiate it anymore on device connect/disconnect.

| Parameter 	| Data Type | Required | Description |
| ------------- | --------- | -------- | ----------- |
| *driverClass* | Class 	| Yes 	   | A reference to the driver class. Must be a valid usb driver class that extends the *USB.DriverBase* class. |


#### addEventListener(*eventName, callback*)

Subscribe a callback function to a specific event. There are currently 2 events that you can subscribe to `"connected"` and `"disconnected"`.


| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *eventName* | String 	  | Yes 	 | The string name of the event to subscribe to |
| *callback*  | Function  | Yes 	 | Function to be called on event |

##### Example

```squirrel
// Subscribe to usb connection events
usbHost.addEventListener("connected",function (driver) {
    server.log(typeof device + " was connected!");
    switch (typeof driver) {
        case "FtdiUsbDriver":
            // device is a ftdi device. Handle it here.
            break;
    }
});

// Subscribe to usb disconnection events
usbHost.addEventListener("disconnected",function(deviceName) {
    server.log(deviceName + " disconnected");
});

```

#### removeEventListener(*eventName*)

Clears a subscribed callback function from a specific event.

| Parameter   | Data Type | Required | Description |
| ----------- | --------- | -------- | ----------- |
| *eventName* | String    | Yes      | The string name of the event to unsubscribe from |

##### Example

```squirrel
// Subscribe to usb connection events
usbHost.addEventListener("connected",function (device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case "FtdiUsbDriver":
            // device is a ftdi device. Handle it here.
            break;
    }
});

// Unsubscribe from usb connection events after 30 seconds
imp.wakeup(30,function(){
	usbHost.removeEventListener("connected");
}.bindenv(this))
```

## USB.DeviceClass

The USB.DeviceClass is an internal abstraction which allow us to wrap USB device
descriptor and device driver instances. There is no way to extend or change this structure.

### Public methods

#### constructor(*usb, speed, deviceDescriptor, deviceAddress, drivers*)

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *usb* 		     | Object 	 | n/a 	   | The imp API hardware usb object `hardware.usb` |
| *speed* | Number   | n/a  | Usb device speed. |
| *deviceDescriptor* | desviceDescriptor   | n/a  | Usb device descriptor. |
| *deviceAddress* | Number   | n/a  | Usb device descriptor. |
| *drivers* | USB.DriverBase[] | n/a  | the list of registered `USB.DeviceDriver` classes. |


#### setAddress(*address*)

Set up custom device address. throw an exception if device address busy.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *address* 		     | Number 	 | n/a 	   | a new usb device address |

#### getEndpoint(*ifs, type, direction*)


Return cached object or instantiate a new one `USB.Endpoint` object which is corresponding to the requested argument. And return null otherwise.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *ifs* 		     | Interface 	 | n/a 	   | usb device interface descriptor |
| *type* 		     | Number 	 | n/a 	   | endpoint type |
| *direction* 		     | Number 	 | n/a 	   | endpoint direction |

#### getEndpointByAddress(*epAddress*)

Return cached endpoint by the address

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *epAddress* 		     | Number 	 | n/a 	   | address of the usb endpoint |


#### stop()

Stop all drivers. Happens on device disconnected.

#### toString()

Helper method to print device details.

#### getVendorId()

Get the device vendor ID

#### getProductId()

Get the device product ID

### Internal methods

#### `_selectDrivers(drivers)`

Implement driver match mechanism. TBD: describe driver match algorithm

#### `_transferEvent(eventDetails)`

Handle transfer complete event for a concrete device

#### `_log(txt)`

USB namespace common logging

#### `_error(txt)`

handle errors


## USB.ControlEndpoint

Control endpoint is an abstraction over the USB endpoints.

TBD: control transfer description

Note: Each endpoint object should be allocated via `UBS.Device.getEndpoint` API.

### Public API

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

Constructor is public API but it is not recommended to use it for end point allocation.
Please, use `USB.Device.getEndpoint` for endpoint allocation

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *device* 		   | USB.Device| n/a 	   | device object see `USB.Device` |
| *ifs* 		     | Interface 	 | n/a 	   | usb device interface descriptor |
| *epAddress* 		     | Number 	 | n/a 	   | address of the usb endpoint |
| *maxPacketSize* 		     | Number 	 | n/a 	   | max packet size which could be send via transfer |


#### transfer(reqType, type, value, index, data = null)

Generic function for transferring data over control endpoint.
Note: This operation is synchronous.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *reqType* 		   | Number | n/a 	   |  |
| *type* 		     | Number 	 | n/a 	   |  |
| *value* 		     | Number 	 | n/a 	   |  |
| *index* 		     | Number 	 | n/a 	   |  |
| *data* 		     | Blob 	 | null 	   | data to transfer |

#### close()

Close current endpoint for data transfer. Uses for a device safe disconnect.


## USB.FunctionalEndpoint
Functional endpoint is an abstraction over the USB endpoints. It is uses for a
BULK and Interrupt endpoints.

TBD: bulk transfer description

Note: Each endpoint object should be allocated via `UBS.Device.getEndpoint` API.


#### constructor (device, ifs, epAddress, epType, maxPacketSize)

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *device* 		   | USB.Device| n/a 	   | device object see `USB.Device` |
| *ifs* 		     | Interface 	 | n/a 	   | usb device interface descriptor |
| *epAddress* 		     | Number 	 | n/a 	   | address of the usb endpoint |
| *epType* 		     | Number 	 | n/a 	   | type of the endpoint: USB_ENDPOINT_ISCHRONOUS, USB_ENDPOINT_BULK or USB_ENDPOINT_INTERRUPT |
| *maxPacketSize* 		     | Number 	 | n/a 	   | max packet size which could be send via transfer |

#### write(data, onComplete)

Asynchronous write date to the endpoint. Throw and exception if endpoint doesn't support USB_DIRECTION_OUT.

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		   | Blob | n/a 	   | payload to write to the endpoint |
| *onComplete* 		     | Function 	 | n/a 	   | callback method to get write details |

```squirrel

TBD: write example goes here

```

#### read(data, onComplete)

| Parameter 	 | Data Type | Default | Description |
| -------------- | --------- | ------- | ----------- |
| *data* 		   | Blob | n/a 	   | blob to read data into |
| *onComplete* 		     | Function 	 | n/a 	   | callback method to get read details |


#### reset()

Make a reset of the current endpoint on stall or any other non-critical issues

#### close()

Close current endpoint and block read and write operations. Uses on safe device disconnection.


## USB.DriverBase

The USB.DriverBase class is used as the base for all drivers that use this library. It contains a set of functions that are expected by [USB.Host](#USBhost) as well as some set up functions. There are a few required functions that must be overwritten. All other functions will be documented and can be overwritten only as needed.

### Required Functions

These are the functions your usb driver class must override. The default behavior for most of these function is to throw an error.

#### Constructor: USB.DriverBase(*device, interfaces*)

By default the constructor should be private and takes an instance of the USB.Device class and list of Interfaces as parameters. Instantiation of the driver object should happen in the `match` method only.
It is possible to get an access to the working `usb` object via `device._usb` but it is not recommended.
All initialization of endpoints should happen in constructor. There is no extra methods for a lazy initialization of the driver.

##### Example

```squirrel
class MyUsbDriver extends USB.DriverBase {

    _device = null;
    _bulkIn = null;
    _bulkOut = null;

    constructor(device, interfaces) {
      _device = device;
      _bulkIn = device.getEndpoint(0, USB_ENDPOINT_BULK, USB_DIRECTION_IN);
      _bulkOut = device.getEndpoint(0, USB_ENDPOINT_BULK, USB_DIRECTION_OUT);
      this.start();
    }

    function match(device, interfaces) {
      if (_checkMatch(device, interfaces))
        return new MyUsbDriver(deivce,interfaces);
      return null;
    }

    function _checkMatch(device, interfaces) {
      // Implement device match here
      return true;
    }

    function start() {
      imp.wakeup(0, (function(action, error, payload, length) {
          if (_bulkIn != null) {
            _bulkIn.read(blob(64), function() {

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

Method that returns a driver object or null. These method checks if current driver could support all the provided interface for the current device or not. Match method could be based on VID, PID, device class, subclass and interfaces. This method is mandatory and it is not possible to register driver withou this method, [see registerDriver()](#registerdriverdriverclassidentifiers). Once the driver is registered with USB.Host, then `match()` method will be called  on each device "connected" event.

##### Example

```squirrel
class MyUsbDriver extends USB.DriverBase {

    static VID = 0x01f9;
    static PID = 0x1044;

    _device = null;

    constructor(device) {
      _device = device;
    }
    // Returns an array of VID PID combinations
    function match(device, interface) {
        if (device._vid == VID && device._pid == PID)
          return new MyUsbDriver(device);
        return null;
    }
}

usbHost <- USB.Host(hardware.usb);

// Register the Usb driver with usb host
usbHost.registerDriver(MyUsbDriver);
```

#### `_typeof()``

The *_typeof()* method is a squirrel metamethod that returns the class name. See [metamethods documenation](https://electricimp.com/docs/resources/metamethods/)

##### Example
```squirrel
class MyUsbDriver extends USB.DriverBase {
    // Metamethod returns class name when - typeof <instance> - is called
    function _typeof() {
        return "MyUsbDriver";
    }
}

myDriver <- MyUsbDriver();

// This will log "MyUsbDriver"
server.log(typeof myDriver);
```


#### release()

Release all instantiate resource before driver close. Uses for a driver disconnection.

## Driver Examples

### [UartOverUsbDriver](./UartOverUsbDriver/)

The UartOverUsbDriver class creates an interface object that exposes methods similar to the uart object to provide compatability for uart drivers over usb.


### [FtdiUsbDriver](./FtdiUsbDriver/)

The FtdiUsbDriver class exposes methods to interact with a device connected to usb via an FTDI cable.


# License

This library is licensed under the [MIT License](/LICENSE).
