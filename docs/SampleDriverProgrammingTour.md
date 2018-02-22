## introduction

The purpose of this document is to explain step by step how to create a simple usb driver and provide an examples of the USB framework base primitives usage.

As a first experiment you could test the following code in the electricimp IDE:

```squirrel
// include the USB framework
#require "USB.device.lib.nut:1.0.0"

// Create custom diver
class MyCustomDriver extend USB.Driver {

    function match(device, interfaces) {
        server.log("This line should be visible on a new device plug");
        // this driver could no be instantiated
        return null;
    }
}

// Initialize USB framework with a new driver
host <- USB.Host([MyCustomDriver]);

```




## How to create simple driver library

Each USB driver should be implemented as a standard squirrel library and follow to the
device library development guide [REF on license and version](TBD)

Each driver class should implement `match` method which is responsible for the driver class instantiation if it is applicable to the attached device.

There is an example of driver library which will instantiate driver on device attach and release it on device unplug:

```squirrel
class MyCustomDriver extend USB.Driver {

    // The driver version
    static VERSION = "1.0.0";

    constructor() {
      // empty
    }

    function match(device, interfaces) {
        server.log("This line should be visible on a new device plug");
        return MyCustomDriver();
    }

    function release() {
      server.log("This line should be visible on a new device un-plug");
    }

    function _typeof() {
        return "MyCustomDriver";
    }
}

```

The `release` method is called before driver instance destruction. And in the example above it is possible to see message in the log on each device unplug.

The driver library itself should not include USB Framework as dependency

It is responsibility of the application developer to include framework and select the scope of the drivers

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "MyCustomDriver.device.lib.nut:1.0.0"

// USB framework initialization with a corresponding driver
host <- USB.Host([MyCustomDriver]);

```

It is possible to add restrictions or warning for the USB framework version compatibility in match method:

```squirrel
class MyCustomDriver {
    function match(device, interfaces) {
        if (USB.VERSION != "1.0.0")
            server.error("Unknown USB Framework version");

        return null;
    }

    function release() {
      // empty
    }
}
```

As you can see from the example above it is not necessary to extend the `USB.Driver`
but each driver class should implement several methods which described in the next section.

## How to implement base methods of driver

There are four method must be implemented: `constructor`, `match`,  `release` and `\_typeof`.

### match
According to specification [`match()` method]](TBD) should return driver instance or null if driver is not compatible with attached device.

There is no limitation for match method execution time but the major limitation is that driver class should be instantiated for a concrete device only or a concrete device class.

For example, if it is necessary to instantiate driver for a certain device with known product and vendor IDs:

```squirrel
class MyCustomDriver extends USB.Driver {
    static VENDOR_ID = 0x03;
    static PRODUCT_ID = 0xE5;

    constructor() {}

    function match(device, interfaces) {
        if (device.vendorId() == VENDOR_ID
            && device.productId() == PRODUCT_ID)
            return MyCustomDriver();

        // not supported device
        return null;
    }
}
```

For another hand it could be class of devices like keyboard or mouse which should not have vendor specific:

```squirrel
class MyCustomDriver extends USB.Driver {

    constructor() {}

    function match(device, interfaces) {
        foreach (interface in interfaces)
          if (    interface["class"]     == 3 /* HID      */
              &&  interface.subclass     == 1 /* BOOT     */
              &&  interface.protocol     == 1 /* Keyboard */ )
              return MyCustomDriver();

        // not supported device
        return null;
    }
}
```


Please see [HID driver development guide](TBD) for the usb HID devices and [Advanced driver `match`](TBD) section for more complex device capabilities detection.

### constructor
There in no limitations for the constructor's arguments but it is recommended to check that all necessary resources are available before driver creation:

```squirrel

// BAD EXAMPLE of the constructor:

class MyCustomDriver extends USB.Driver {

    constructor(interface) {
        local inEp = interface.find(USB_ENDPOINT_INTERRUPT, USB_DIRECTION_IN);
        if (null == inEp)
            server.error("it is too late to cancel driver creation");
    }

    function match(device, interfaces) {
        return MyCustomDriver(interfaces[0]);
    }

```

```squirrel

// GOOD EXAMPLE of the constructor:

class MyCustomDriver extends USB.Driver {
    _bulkIn = null;
    constructor(inEp) {
        _bulkIn = inEp;
    }

    function match(device, interfaces) {
        local inEp = interface[0].find(USB_ENDPOINT_INTERRUPT, USB_DIRECTION_IN);
        if (null == inEp)
            return null;

        return MyCustomDriver(inEp);
    }

```

All resource which was allocated and cached by the constructor should be free on driver `release`

### release

Release should free all allocated resources. It is call on driver deallocation which could happen on device detach or usb reset.

Driver should free all USB Framework primitives to prevent cross references on object and proper Garbage Collector work:

```squirrel
class MyCustomDriver extends USB.Driver {
    _device = null;
    constructor(device) {
        _device = device;
    }

    function match(device, interfaces) {
        return MyCustomDriver(device);
    }

    function release() {
        _device = null;
    }
}
```

### \_typeof
Return unique identifier for the driver type. Uses to identify driver in runtime.


## Export driver API

Each driver should provide it's own API.


## Getting endpoint zero

Endpoint Zero is a special type of control endpoints that implicitly exists for every device see [USB.ControlEndpoint](#usbcontrolendpoint-class)

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

## Bulk transfer
Asynchronously

## Control transfer
Synchronously

## Error handling

## Hot unplug
it is recommended to set null all primitives on release and add null check for Asynchronously methods


## Advanced driver `match`

### multiple interfaces support
it could be single driver or multiple drivers

### Endpoint Zero access in the match method
For example to read HID descriptor.
