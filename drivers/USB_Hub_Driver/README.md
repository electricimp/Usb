# USB Hub Driver 1.0.0 #

This library provides basic support for USB hubs to Electric Imp’s existing [USB driver framework](https://github.com/electricimp/Usb).

**Important** Though this library supports hubs, it does not yet support the hot-plugging of devices to that hub. Devices **must** be connected to the hub before the hub is connected to the imp. You can use the method [*checkports()*](#checkports) to verify the status of a hub's ports at any time.

For more information on USB driver development, please see [**USB Driver Development Guide**](https://developer.electricimp.com/resources/usb-driver-development-guide).

**To include this library in your project, add** `#require "USB.device.lib.nut:1.1.0"` **and** `#require "USB.hub.device.lib.nut:1.0.0"` **at the top of your device code**

## Class Usage ##

### Dependencies ###

This library requires Electric Imp’s `USB.device.lib.nut` library, as shown in the instantiation example below.

### Instantiation ###

You do not instantiate the Hub Driver class directly. Instead, you register it for possible use when you instantiate the USB.Host class. For example, for the imp005:

```squirrel
#require "USB.device.lib.nut:1.1.0"
#require "USB.hub.device.lib.nut:1.0.0"

local driverClassArray = [HubUsbDriver];
host <- USB.Host(hardware.usb, driverClassArray);
```

Should a hub be connected to the imp’s USB port, the USB.Host instance will automatically load the nominated driver.

You should set up suitable listener functions which can respond to events emitted by the USB.Host and HubUsbDriver instances, including the loading of a driver, and the connection and disconnection of devices:

```squirrel
hubDriver <- null;

function driverStatusListener(eventType, driver) {
    switch (eventType) {
        case USB_DRIVER_STATE_STARTED:
            if (typeof driver == "HubUsbDriver") {
                hubDriver = driver;
            } else {
                // Checks for other driver types can be included here
            }
            break;
        case USB_DRIVER_STATE_STOPPED:
            if (typeof driver == "HubUsbDriver") {
                hubDriver = null;
            }
    }
}

// Listen for driver loads
host.setDriverListener(driverStatusListener);
```

## Class Methods ##

The HubUsbDriver class implements a number of public methods. Two, *match()* and *release()* are required by the USB driver framework and are not documented here (please see [**USB Driver Development Guide**](https://developer.electricimp.com/resources/usb-driver-development-guide) for details).

### checkPorts() ###

This method provides a hub port status update that indicates which, if any, of the hub's ports are occupied.

#### Return Value ####

Table &mdash; keys are integers: the hub's port numbers; values are either `"connected"` or `"empty"`

#### Example ####

For a full example, please see the [`examples` directory](./examples) in this repo.

## License ##

This library is licensed under the terms of the [MIT License](LICENSE). It is copyright &copy; 2019, Electric Imp, Inc.
