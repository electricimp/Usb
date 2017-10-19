// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//


// The class that introduces USB namespace and related constants.
// Not intended to use by any developers.
class USB {

    static VERSION = "0.2.0";

    constructor() {
        const USB_ENDPOINT_CONTROL = 0x00;
        const USB_ENDPOINT_ISCHRONOUS = 0x01;
        const USB_ENDPOINT_BULK = 0x02;
        const USB_ENDPOINT_INTERRUPT = 0x03;
        const USB_ENDPOINT_TYPE_MASK = 0x03;

        const USB_SETUP_HOST_TO_DEVICE = 0x00;
        const USB_SETUP_DEVICE_TO_HOST = 0x80;
        const USB_SETUP_TYPE_STANDARD = 0x00;
        const USB_SETUP_TYPE_CLASS = 0x20;
        const USB_SETUP_TYPE_VENDOR = 0x40;
        const USB_SETUP_TYPE_MASK   = 0x60;
        const USB_SETUP_RECIPIENT_DEVICE = 0x00;
        const USB_SETUP_RECIPIENT_INTERFACE = 0x01;
        const USB_SETUP_RECIPIENT_ENDPOINT = 0x02;
        const USB_SETUP_RECIPIENT_OTHER = 0x03;

        const USB_REQUEST_GET_STATUS = 0;
        const USB_REQUEST_CLEAR_FEATURE = 1;
        const USB_REQUEST_SET_FEATURE = 3;
        const USB_REQUEST_SET_ADDRESS = 5;
        const USB_REQUEST_GET_DESCRIPTOR = 6;
        const USB_REQUEST_SET_DESCRIPTOR = 7;
        const USB_REQUEST_GET_CONFIGURATION = 8;
        const USB_REQUEST_SET_CONFIGURATION = 9;
        const USB_REQUEST_GET_INTERFACE = 10;
        const USB_REQUEST_SET_INTERFACE = 11;
        const USB_REQUEST_SYNCH_FRAME = 12;

        const USB_DEVICE_DESCRIPTOR_LENGTH = 0x12;
        const USB_CONFIGURATION_DESCRIPTOR_LENGTH = 0x09;

        const USB_DESCRIPTOR_DEVICE = 0x01;
        const USB_DESCRIPTOR_CONFIGURATION = 0x02;
        const USB_DESCRIPTOR_STRING = 0x03;
        const USB_DESCRIPTOR_INTERFACE = 0x04;
        const USB_DESCRIPTOR_ENDPOINT = 0x05;
        const USB_DESCRIPTOR_DEVICE_QUALIFIER = 0x06;
        const USB_DESCRIPTOR_OTHER_SPEED = 0x07;
        const USB_DESCRIPTOR_INTERFACE_POWER = 0x08;
        const USB_DESCRIPTOR_OTG = 0x09;
        const USB_DESCRIPTOR_HID = 0x21;

        const USB_DIRECTION_OUT = 0x0;
        const USB_DIRECTION_IN = 0x80;
        const USB_DIRECTION_MASK = 0x80;

        const USB_TYPE_STALL_ERROR = 4;
        const USB_TYPE_TIMEOUT = 19;

    }
}


//
// The main interface to start working with USB devices.
// Here an application registers drivers and assigns listeners
// for important events like device connection/detachment.
class USB.Host {

    // The list of registered drivers
    _drivers = [];

    // The list of connected devices
    _devices = {};

    // The address available to assign to next device
    _address = 1;

    // Debug flag
    _debug = true; //false;

    // USB device pointer
    _usb = null;

    // Listener for some USB events
    _listener = null;

    // ------------------------ public API -------------------

    //
    // Constructor
    // Parameters:
    //      usb          - an instance of object that implements hardware.usb API
    //      driverList   - a list of special classes that implement USB.Driver API.
    //      autoConfPins - flag to specify whether to configure pins for usb usage
    //                     (see https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb)
    //
    constructor(usb, driverList, autoConfPins = true) {

        if (null == driverList) driverList = [];

        foreach (driver in driverList) _checkDriver(driver);

        if (autoConfPins) {
            if ("pinW" in hardware &&
                "pinR" in hardware) {
                // Configure the pins required for usb
                hardware.pinW.configure(DIGITAL_IN_PULLUP);
                hardware.pinR.configure(DIGITAL_OUT, 1);
            } else {
                throw "Invalid hardware is used";
            }
        }

        _usb = usb;
        _usb.configure(_onUsbEvent.bindenv(this));

        _drivers = driverList;
    }

    // Reset the USB BUS.
    // Can be used by driver or application in response to unrecoverable error
    // like unending bulk transfer or halt condition during control transfers
    function reset() {
        _usb.disable();
        _usb.configure(_onUsbEvent.bindenv(this));

        _log("USB reset complete");
    }

    // Auxillary function to get list of attached devices.
    // Returns:
    //      an array of USB.Device instances
    function getAttachedDevices() {
        return _devices;
    }

    // Assign listener about device and  driver status changes.
    // Parameters:
    //      listener  - null or the function that receives two parameters:
    //                      eventType - "connected",  "disconnected",
    //                                 "started", "stopped"
    //                      eventObject - depending on event type it could be
    //                                    either USB.Device or USB.Driver instance
    function setEventListener(listener) {
        if (typeof listener != "function" && listener != null) throw "Invalid paramter";

        _listener = listener;

        foreach(device in _devices) device._listener = listener;
    }

    // ------------------------ private API -------------------


    // Checks if given parameter implement USB.Driver API
    function _checkDriver(driverClass) {
        if (typeof driverClass == "class" &&
            "match" in driverClass &&
            typeof driverClass.match == "function" &&
            "release" in driverClass &&
            typeof driverClass.release == "function") {
                if (null == _drivers.find(driverClass)) {
                    _drivers.append(driverClass);
                }
        } else {
            throw "Invalid driver class";
        }
    }

    // The function that will be called in response to a USB event.
    // Parameters:
    //          eventType       - The type of event that triggered the event
    //          eventDetails    - Event-specific information
    function _onUsbEvent(eventType, eventDetails) {
        _log("usb event " + eventType);

        switch (eventType) {
            case USB_DEVICE_CONNECTED:
                _onDeviceConnected(eventDetails);
                break;
            case USB_DEVICE_DISCONNECTED:
                _onDeviceDetached(eventDetails);
                break;
            case USB_TRANSFER_COMPLETED:
                _onTransferComplete(eventDetails);
                break;
            case USB_UNRECOVERABLE_ERROR:
                _onError();
                break;
        }
    }

    // New device processing function
    // Creates new USB.Device instance, notifies application listener
    // with "connected" event
    function _onDeviceConnected(eventDetails) {
        try {
            local speed = eventDetails.speed;
            local descr = eventDetails.descriptors;

            local device = USB.Device(_usb, speed, descr, _address, _drivers);

            // a copy application callback
            device._listener = _listener;

            _devices[_address] <- device;

            _log("New device detected: " + device + ". Assigned address: " + _address);

            // address for next device
            _address++;

            if (null != _listener) _listener("connected", device);

        } catch (e) {
            _error("Error driver instantiation: " + e);
        }
    }

    // Device detach processing function.
    // Stops corresponding USB.Device instance, notifies application listener
    // with "disconnected" event
    function _onDeviceDetached(eventDetails) {
        local address = eventDetails.device;
        if (address in _devices) {
            local device = _devices[address];
            delete _devices[address];

            try {
                device.stop();
                _log("Device " + device + " is removed");

                if (null != _listener) _listener("disconnected", device);

            } catch (e) {
                _error("Error on device " + device + " release: " + e);
            }
        } else {
            _log("Detach event for unregistered device: " + address);
        }
    }

    // Data transfer status processing function
    // Checks transfer status and either notify USB.Device about event or
    // schedules bus reset if status is critical error
    function _onTransferComplete(eventDetails) {
        local address = eventDetails.device;
        local error = eventDetails.state;

        // check for UNRECOVERABLE error
        if (_checkError(error)) {
            // all this errors are critical
            _error("Critical error received: " + error);
            imp.wakeup(0, _onError.bindenv(this));
            return;
        }

        if (address in _devices) {
            local device = _devices[address];
            try {
                device._transferEvent(eventDetails);
            } catch(e) {
                _error("Device.transferEvent error: " + e);
            }
        } else {
            _log("transfer event for unknown device: "+ address);
        }
    }

    // Checks error class
    // Returns  TRUE if error is critical and USB need to be reset
    //          FALSE otherwise
    function _checkError(error) {
        if ((error > 0  && error < 4)   ||
            (error > 4  && error < 8)   ||
            (error > 9 && error < 12)  ||
            error == 14 || error > 17) {
            return true;
        }

        return false;
    }

    // USB critical error processing function.
    // Stops all registered USB.Devices and schedules bus reset
    function _onError(eventDetails = null) {
        foreach(device in _devices) {
            try {
                device.stop();
            } catch (e) {
                _error("Error on device " + device + " release: " + e);
            }
        }

        imp.wakeup(0, reset.bindenv(this));
    }

    // Information level logger
    function _log(txt) {
        if (_debug) {
            server.log("[Usb.Host] " + txt);
        }
    }

    // Error level logger
    function _error(txt) {
        server.error("[Usb.Host] " + txt);
    }
};


// The class that represents attached device.
// It manages its configuration, interfaces and endpoints.
// An application does not need such object normally.
// It is usually used by drivers to acquire required endpoints
class USB.Device {

    // Assigned device address
    _address = 0;

    // Device descriptor (without configuration descriptor)
    _deviceDescriptor = null;

    // A list of drivers assigned to this device
    // There can be more than one driver for composite device
    _drivers = [];

    // Endpoints for this device
    _endpoints = {};

    // Device speed
    _speed = null;

    // USB interface
    _usb = null;

    // debug flag
    _debug = true;

    // Listener callback of USB events
    _listener = null;

    // Constructs device peer.
    // Parameters:
    //      speed            - supported device speed
    //      deviceDescriptor - new device descriptor as specified by ElectricImpl USB API
    //      deviceAddress    - device address reserved (but assigned) for new device
    //      drivers          - an array of available USB drives
    constructor(usb, speed, deviceDescriptor, deviceAddress, drivers) {
        _speed = speed;
        _deviceDescriptor = deviceDescriptor;
        _address = deviceAddress;
        _usb = usb;
        _drivers = [];

        local ep0 = USB.ControlEndpoint(this, _address, 0, _deviceDescriptor["maxpacketsize0"]);
        _endpoints[0] <- ep0;

        // When a device is first connected you can communicate with it at address 0x00.
        // This should be set to a unique value for the device, using a set address control transfer.
        _setAddress(_address);

        // Select default configuration
        _setConfiguration(deviceDescriptor["configurations"][0].value);

        imp.wakeup(0, (function() {_selectDrivers(drivers);}).bindenv(this));
    }


    // Request endpoint of required type and direction.
    // The function creates new endpoint if it was not cached.
    // Parameters:
    //      ifs     - array of interface descriptors
    //      type    - the type of endpoint
    //      dir     - endpoint direction
    //
    //  Returns:
    //      an instance of USB.ControlEndpoint or USB.FunctionEndpoint, depending on type parameter,
    //      or `null` if there is no required endpoint found in provided interface
    //
    // Throws exception if the device was detached
    //
    function getEndpoint(ifs, type, dir) {
        _checkStopped();

        foreach ( epAddress, ep  in _endpoints) {
            if (ep._type == type &&
                ep._if == ifs &&
                (ep._address & USB_DIRECTION_MASK) == dir) {
                    return ep;
            }
        }

        // TODO: track active interfaces and theirs alternate settings
        foreach (dif in _deviceDescriptor.configurations[0].interfaces) {
            if (dif == ifs) {
                foreach (ep in dif.endpoints) {
                    if ( ep.attributes == type &&
                         (ep.address & USB_DIRECTION_MASK) == dir) {
                        local maxSize = ep.maxpacketsize;
                        local address = ep.address;

                        _usb.openendpoint(_speed, this._address, dif.interfacenumber,
                                          type, maxSize, address, 255);

                        local newEp = (type == USB_ENDPOINT_CONTROL) ?
                                        USB.ControlEndpoint(this, dif, address, maxSize) :
                                        USB.FunctionalEndpoint(this, dif, address, type, maxSize);
                        _endpoints[address] <- newEp;
                        return newEp;
                    }
                }
            }
        }

        // No endpoint found
        return null;
    }

    // Request endpoint with given address. Creates if not cached.
    // The function creates new a endpoint if it was not cached.
    // Parameters:
    //      epAddress - required endpoint address
    //
    //  Returns:
    //      an instance of USB.ControlEndpoint or USB.FunctionEndpoint,
    //      or NULL if no required endpoint found in the device configuration
    //
    // Throws exception if the device was detached
    //
    function getEndpointByAddress(epAddress) {
        _checkStopped();

        if (epAddress in _endpoints) return _endpoints[epAddress];

        // TODO: track active interfaces and theirs alternate settings
        foreach (dif in _deviceDescriptor.configurations[0].interfaces) {
            foreach (ep in dif.endpoints) {
                if (ep.address == epAddress) {
                    local maxSize = ep.maxpacketsize;
                    local type = ep.attributes;

                    _usb.openendpoint(_speed, _address, dif,
                                        type, maxSize, epAddress, 1);

                    local newEp = (type == USB_ENDPOINT_CONTROL) ?
                                        USB.ControlEndpoint(this, dif, epAddress, maxSize) :
                                        USB.FunctionalEndpoint(this, dif, epAddress, type, maxSize);
                    _endpoints[epAddress] <- newEp;
                    return newEp;
                }
            }
        }

        // No EP found
        return null;
    }

    // Called by USB.Host when the devices is detached
    // Closes all open endpoint and releases all drivers
    //
    // Throws exception if the device was detached
    //
    function stop() {
        _checkStopped();

        // Close all endpoints at first
        foreach (epAddress, ep in _endpoints) ep.close();

        foreach ( driver in _drivers ) {
            try {
                driver.release();

                if (_listener) _listener("stopped", driver);

            } catch (e) {
                _error("Driver.release exception: " + e);
            }
        }

        _drivers = null;
        _endpoints = null;
        _deviceDescriptor = null;
        _listener = null;
        _usb = null;
    }

    // Returns device vendor ID
    //
    // Throws exception if the device was detached
    //
    function getVendorId() {
        _checkStopped();

        return _deviceDescriptor["vendorid"];
    }

    // Returns device product ID
    //
    // Throws exception if the device was detached
    //
    function getProductId() {
        _checkStopped();

        return _deviceDescriptor["productid"];
    }

    // -------------------- Private functions --------------------


    // Selects current device configuration by sending USB_REQUEST_SET_CONFIGURATION request through Endpoint Zero
    //
    // Parameter:
    //      config  - configuration number
    //
    // Returns Nothing
    //
    function _setConfiguration(config) {
        _endpoints[0]._transfer(
            USB_SETUP_HOST_TO_DEVICE | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_SET_CONFIGURATION,
            config,
            0
        );
    }

    // Helper function for device address assignment.
    //
    // Parameters:
    //      address - new device address to assign
    //
    // Throws exception if the device was detached
    //
    // Note: the function uses 0 as device address therefore can be used only once
    function _setAddress(address) {
        _usb.controltransfer(
            _speed,
            0,
            0,
            USB_SETUP_HOST_TO_DEVICE | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_SET_ADDRESS,
            address,
            0,
            _deviceDescriptor["maxpacketsize0"]
        );
    }

    // Device run status check
    function _checkStopped() {
        if (null == _usb) throw "Detached";
    }

    // Selects and starts matched drivers from provided list.
    function _selectDrivers(drivers) {
        local devClass      = _deviceDescriptor["class"];
        local ifs = _deviceDescriptor.configurations[0].interfaces;

        // if this is not composite device
        if ( 0 !=  devClass) {

            foreach (driver in  drivers) {
                try {
                    local instance;
                    if (null != (instance = driver.match(this, ifs))) {
                        _drivers.append(instance);

                        if (_listener) _listener("started", instance);

                        return;
                    }
                } catch (e) {
                    _log("Error driver initialization: " + e);
                }
            }

        } else {

            // Class information should be determined from the Interface Descriptors
            // TODO: find and parse IAD (Interface Association Descriptor), then group interfaces
            foreach (dif in ifs) {
                foreach (driver in  drivers) {
                    local ifArr = [dif];
                    try {
                        local instance;
                        if (null != (instance = driver.match(this, ifArr))) {
                            _drivers.append(instance);

                            if (_listener) _listener("started", instance);

                            break;
                        }
                    } catch (e) {
                        _log("Error driver initialization: " + e);
                    }
                }
            }

        }
    }

    // Proxy function for transfer event.
    // Looking up for corresponding endpoint and passes the event if found
    function _transferEvent(eventDetails) {
        // Do nothing for a closed device
        if (null == _usb)
          return;

        local epAddress = eventDetails.endpoint;
        if (epAddress in _endpoints) {
            // TODO: check relation of ep with interface and ep type
            local ep = _endpoints[epAddress];
            local error = (eventDetails.state != 0) ? eventDetails.state : null;
            local len = eventDetails.length;

            ep._onTransferComplete(error, len);

        } else {
            _log("Unexpected transfer for unknown endpoint: " + epAddress);
        }
    }

    // Information level logger
    function _log(txt) {
        if (_debug) {
            server.log("[Usb.Device] " + txt);
        }
    }

    // Error level logger
    function _error(txt) {
        server.error("[Usb.Device] " + txt);
    }
}


// The class that represent all non-control endpoints, e.g. bulk, interrupt etc
// This class is managed by USB.Device and should be acquired through USB.Device instance
class USB.FunctionalEndpoint {
    // Owner
    _device = null;

    // EP type
    _type = 0;

    // EP address
    _address = 0;

    // Maximum packet size for this endpoint
    // Should be one from {8, 16, 32, 64} set
    _maxPacketSize = 8;

    // Flag that EP was closed and should not used anymore.
    // Typically EP is closed when device is detached or configuration is changed
    _closed = false;

    // Endpoint's interface
    _if = null;

    // Callback to be called when transfer request is complete.
    // Since the class supports only single request per time,
    // this flags also indicates that EP is busy
    _transferCb = null;

    // Watchdog timer
    _timer = null;

    // Constructor
    // Parameters:
    //      device          - USB.Device instance, owner of this endpoint
    //      ifs             - interface descriptor this endpoint servers for
    //      epAddress       - unique endpoint address
    //      epType          - endpoint type
    //      maxPacketSize   - maximum packet size for this endpoint
    constructor (device, ifs, epAddress, epType, maxPacketSize) {
        _device = device;
        _address = epAddress;
        _maxPacketSize = maxPacketSize;
        _type = epType;
        _if = ifs;
    }

    // Write data through this endpoint.
    // Throws if EP is closed, has incompatible type or already busy
    // Parameter:
    //  data        - data blob to be sent through this endpoint
    //  onComplete  - callback for transfer status notification
    //
    //  Returns nothing
    function write(data, onComplete) {
        if (_address & USB_DIRECTION_MASK) {
            throw "Invalid endpoint direction: " + _address;
        } else {
            _transfer(data, onComplete);
        }
    }

    // Read data through this endpoint.
    // Throws if EP is closed, has incompatible type or already busy
    // Parameter:
    //  data        - data blob where received data to be stored
    //  onComplete  - callback for transfer status notification
    //
    //  Returns nothing
    function read(data, onComplete) {
        if (_address & USB_DIRECTION_MASK) {
            _transfer(data, onComplete);
        } else {
            throw "Invalid endpoint direction: " + _address;
        }
    }

    // Clear stall status of this pipe
    // Return
    //      TRUE if pipe was reset
    //      FALSE if device rejects reset request
    function reset() {
        _transferCb = null;
        return _device.getEndpointByAddress(0).clearStall(_address);
    }

    // Mark this endpoint as closed. All further operation causes exception.
    function close() {
        _closed = true;
        _transferCb = null;
    }

    // --------------------- Private functions -----------------

    // Transfer initiator
    // Throws if EP is closed or already busy
    // Parameter:
    //  data        - data blob to be sent/received
    //  onComplete  - callback for transfer status notification
    //
    //  Returns nothing
    function _transfer(data, onComplete) {
        if (_closed) throw "Closed";

        if (_transferCb) throw "Busy";

        _device._usb.generaltransfer(
            _device._address,
            _address,
            _type,
            data
        );

        _transferCb = function (error, length) {
            try {
                if (onComplete != null) onComplete(this, error, data, length);
            } catch (e) {
                _device._error(e);
            }
        };

        // Disable 5 seconds time limit for an interrupt endpoint
        if (_type != USB_ENDPOINT_INTERRUPT)
            _timer = imp.wakeup(5, _onTimeout.bindenv(this));

    }

    // Notifies application about data transfer status
    // Parameters:
    //  error  - transfer status code
    //  length - the length of data was transmitted
    function _onTransferComplete(error, length) {
        // Cancel timer because callback happened
        if (_timer) {
            imp.cancelwakeup(_timer);
            _timer = null;
        }

        if (null == _transferCb) {
            _device.error("Unexpected transfer event: there is no listener for it");
            return;
        }

        local cb = _transferCb;
        // ready for next request
        _transferCb = null;

        cb(error, length);

    }

    // Auxillary function to handle transfer timeout state
    function _onTimeout() {
        _timer = null;
        _onTransferComplete(USB_TYPE_TIMEOUT, 0);
    }
}

// Represent control endpoints.
// This class is required due to specific EI usb API
// This class is managed by USB.Device and should be acquired through USB.Device instance
class USB.ControlEndpoint {

    // to keep consistency with functional endpoint
    static _type = USB_ENDPOINT_CONTROL;

    // Owner
    _device = null;

    // EP address
    _address = 0;

    // Maximum packet size for this endpoint
    // Should be one from {8, 16, 32, 64} set
    _maxPacketSize = 8;

    // Flag that EP was closed and should not used anymore.
    // Typically EP is closed when device is detached or configuration is changed
    _closed = false;

    // Endpoints interface
    _if = null;

    // Constructor
    // Parameters:
    //      device          - USB.Device instance, owner of this endpoint
    //      ifs             - interface descriptor this enpoint servers for
    //      epAddress       - unique endpoint address
    //      maxPacketSize   - maximum packet size for this endpoint
    constructor (device, ifs, epAddress, maxPacketSize) {
        _device = device;
        _address = epAddress;
        _maxPacketSize = maxPacketSize;
        _if = ifs;
    }

    // Generic function for transferring data over control endpoint.
    // Note! Only vendor specific requires are allowed.
    // For other control operation use USB.Device, USB.ControlEndpoint public API
    //
    // Parameters:
    //      reqType     - USB request type
    //      req         - The specific USB request
    //      value       - A value determined by the specific USB request
    //      index       - An index value determined by the specific USB request
    //      data        - [optional] Optional storage for incoming or outgoing data
    //
    // Note! This operation is synchronous.
    function transfer(reqType, req, value, index, data = null) {
        if ((reqType & USB_SETUP_TYPE_MASK) != USB_SETUP_TYPE_VENDOR) throw "Only vendor request is allowed";

        _transfer(
            reqType,
            req,
            value,
            index,
            data
        );
    }

    // Reset given endpoint
    function clearStall(address) {
        // Attempt to clear the stall
        try {
            _transfer(
                USB_SETUP_RECIPIENT_ENDPOINT | USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_STANDARD,
                USB_REQUEST_CLEAR_FEATURE,
                0,
                address);
        } catch(error) {
            // Attempt failed
            return false;
        }

        // Attempt successful
        return true;
    }

    // Mark as closed. All further operation causes exception.
    function close() {
        _closed = true;
    }

    // --------------------- private API -------------------

    // Generic function for transferring data over control endpoint.
    //
    // Parameters:
    //      reqType     - USB request type
    //      req         - The specific USB request
    //      value       - A value determined by the specific USB request
    //      index       - An index value determined by the specific USB request
    //      data        - [optional] Optional storage for incoming or outgoing data
    //
    function _transfer(reqType, req, value, index, data = blob()) {
        if (_closed) throw "Closed";

        _device._usb.controltransfer(
            _device._speed,
            _device._address,
            _address,
            reqType,
            req,
            value,
            index,
            _maxPacketSize,
            data
        );
    }
}

// Interface class for all drivers.
// Driver developer is not required to subclass it though.
// No class hierarchy is verified by any USB.* functions.
class USB.Driver {

    // Queried by USB.Host if this driver supports
    // given interface function of the device.
    // Should return new instance of the driver object if
    // driver matches
    function match(device, interfaces) {
        return null;
    }

    // Notify that driver is going to be released
    // No endpoint operation should be performed at this function.
    function release() {

    }
}
