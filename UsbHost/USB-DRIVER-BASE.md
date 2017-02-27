# UsbDriverBase

The UsbDriverBase Class is used as the base class for all usb drivers that make use of the UsbHost. It contains a set of functions that you must override that are expected by the UsbHost class and set up functions.

### Setup

**To use your driver the UsbHost must be required before the driver class at the top of the device code.**
#### Example

```squirrel
#require "usbhost.device.nut:1.0.0"
#require "yourusbdriver.device.nut:1.0.0"

usbHost <- UsbHost(hardware.usb);
```
## Set-up Functions
This is a set of functions that are called during the set up process of the usb driver by the UsbHost. They are already implemented within the UsbDriverBase class and should not require changes. 

### Constructor: UsbHost(*usb*)
 It takes `hardware.usb` as its only parameter and assigns it to internal `_usb` variable accessible within the class scope.
If custom initialization is required override the constructor as shown below but ensure to call the base.constructor() method. If no initialization is required let the parent class handle constructor. 

#### Example

```squirrel
class YourUsbDriver {

    _customOpt = null;

    constructor(usb, customOpt) {
        _customOpt = customOpt;
        base.constructor(usb);
    }
    ...
}

```

### connect(deviceAddress, speed, descriptors) 
 This method is called by the UsbHost after instantiation of the usb driver class. It makes calls to internal functions to set up the various endpoints (control and bulk transfer endpoints), configures the usb parameters like the baud rate and sets up the buffers.

## Required Functions
These are the functions you usb driver class must override. 

### _typeof()

Metamethod that returns the class name. See https://electricimp.com/docs/resources/metamethods/

#### Example

```squirrel
class YourUsbDriver {

   // Metafunction to return class name when typeof <instance> is run
    function _typeof() {
        return "YourUsbDriver";
    }
    ...
}

```

### getIdentifiers()

Method that returns an array of tables containing VID PID pairs. The identifiers are used to register the driver with the UsbHost class. When a device with a matching VID PID combo is connected the UsbHost class will intatiated and pass this driver back to the user via the onConnected event called back.


#### Example

```squirrel
#require "usbhost.device.nut:1.0.0"

class YourUsbDriver {

    static VID = 0x01f9;
    static PID = 0x1044;

   // Returns an array of VID PID combinations
    function getIdentifiers() {
        local identifiers = {};
        identifiers[VID] <-[PID];
        return [identifiers];
    }
    ...
}

usbHost <- UsbHost(hardware.usb);

// Register the Usb driver with usb host
usbHost.registerDriver(YourUsbDriver, YourUsbDriver.getIdentifiers());

```

### transferComplete(eventDetails)

Called when a usb transfer is completed. Below is an example of the transferComplete method for the FtdiUsbDriver class.

#### Example

```squirrel
#require "usbhost.device.nut:1.0.0"

class YourUsbDriver {

    // Called when a Usb request is succesfully completed
    function transferComplete(eventdetails) {
        local direction = (eventdetails["endpoint"] & 0x80) >> 7;
        if (direction == USB_DIRECTION_IN) {
            local readData = _bulkIn.done(eventdetails);
            if (readData.len() >= 3) {
                // skip first two bytes
                readData.seek(2);
                // emit data event that the user can subscribe to.
                _onEvent("data", readData.readblob(readData.len()));
            }
            // Blank the buffer
            _bulkIn.read(blob(64 + 2));
        } else if (direction == USB_DIRECTION_OUT) {
            _bulkOut.done(eventdetails);
        }
    }
    ...
}


```


## Public Functions

These are publicly exposed functions that are contained within the UsbDriverBase class.

### on(*eventName, callback*)

Subscribe a callback function to a specific event.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to subscribe to. There are currently 2 events that you can subscibe to connected and disconnected|
| *callback* | Function | Yes | Function to be called on event |


### off(*eventName*)

Clears a subscribed callback function from a specific event.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to unsubscribe from.|

## Private Functions

### _onEvent(eventName, eventdetails) 

This is used internal to your class to emit events. The user is able to subscribe to these events using the on method defined in the public functions above.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to subscribe to.|
| *eventdetails* | Any | Yes | if a callback is subscribed to the corresponding eventName the callback is called with eventDetails as the arguement. |


## License

The Conctr library is licensed under [MIT License](./LICENSE).