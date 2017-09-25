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

    }
}


//
// Usb wrapper class.
//
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

    // ------------------------ public API -------------------

    //
    // Constructor
    //
    // @param  {Boolean} flag to specify whether to configure pins for usb usage (see https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb)
    //
    constructor(usb, autoConfPins = true) {
        // TODO: check hardware
        if (autoConfPins) {
            // Configure the pins required for usb
            hardware.pinW.configure(DIGITAL_IN_PULLUP);
            hardware.pinR.configure(DIGITAL_OUT, 1);
        }

        _usb = usb;
        // TODO: check for singleton
        _usb.configure(_onUsbEvent.bindenv(this));
    }


    // Add the driver to driver lookup table
    //
    // @param {Class} driverClass Class to be instantiated when a matched device is connected
    //
    function registerDriver(driverClass) {
        if ("match" in driverClass &&
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

    //
    //
    // @param {Class} driverClass Class to be removed from the supported driver list
    //
    function unregisterDriver(driverClass) {
        local index = _drivers.find(driverClass);
        if (null != index) _drivers.remove(index);
    }

    //
    // Method for debug purpose to list device descriptions
    // for all connected devices/configs/interfaces/endpoints.
    //
    function printDevices(printer) {
        foreach (device in _devices) {
            printer(device._deviceDescriptor);
        }
    }

    // ------------------------ private API -------------------

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
    function _onDeviceConnected(eventDetails) {
        local speed = eventDetails.speed;
        local descr = eventDetails.descriptors;

        try {
            local device = USB.Device(_usb, speed, descr, _address, _drivers);

            _devices[_address] <- device;

            _log("New device detected: " + device + ". Assigned address: " + _address);

            // address for next device
            _address++;
        } catch (e) {
            _error("Error driver instantiation: " + e);
        }
    }

    // Device detach processing function
    function _onDeviceDetached(eventDetails) {
        local address = eventDetails.device;
        if (address in _devices) {
            local device = _devices[address];
            delete _devices[address];

            try {
                device.stop();
                _log("Device " + device + " is removed");
            } catch (e) {
                _error("Error on device " + device + " release: " + e);
            }
        } else {
            _log("Detach event for unregistered device: " + address);
        }
    }

    // Data transfer status processing function
    function _onTransferComplete(eventDetails) {
        local address = eventDetails.device;
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

    // USB critical error processing function
    function _onError(eventDetails) {
        foreach(device in _devices) {
            try {
                device.stop();
            } catch (e) {
                _error("Error on device " + device + " release: " + e);
            }
        }

        imp.wakeup(0, _reset.bindenv(this));
    }

    // USB reset function
    function _reset() {
        usb.disable();
        usb.configure(_onUsbEvent.bindenv(this));

        _log("USB reset complete");
    }

    function _log(txt) {
        if (_debug) {
            server.log("[Usb.Host] " + txt);
        }
    }

    function _error(txt) {
        server.error("[Usb.Host] " + txt);
    }
};



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

        local ep0 = USB.ControlEndpoint(this, _address, 0, _deviceDescriptor["maxpacketsize0"]);
        _endpoints[0] <- ep0;

        //When a device is first connected you can communicate with it at address 0x00.
        // This should be set to a unique value for the device, using a set address control transfer.
        setAddress(_address);

        imp.wakeup(0, (function() {_selectDrivers(drivers);}).bindenv(this));
    }


    // Helper function for device address assignment.
    // Note: the function uses 0 as device address therefore can be used only one
    function setAddress(address) {
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

    // Request endpoint of required type. Creates if not cached.
    function getEndpoint(ifs, type, direction) {
       foreach ( epAddress, ep  in _endpoints) {
            if (ep._type == type &&
                ep._if == ifs &&
                (ep._address & USB_DIRECTION_MASK) == direction) {
                    return ep;
            }
        }

        // TODO: track active interfaces and theirs alternate settings
        foreach (dif in _deviceDescriptor.configurations[0].interfaces) {
            if (dif == ifs) {
                foreach (ep in dif.endpoints) {
                    if ( ep.attributes == type &&
                         (ep.address & USB_DIRECTION_MASK) == direction) {
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
            else {
                server.log("CCCCCCCCCCUNNNNNNNNNNNNNNNNNNNT");
            }
        }

        // No EP found
        return null;
    }

    // Request endpoint with given address. Creates if not cached.
    function getEndpointByAddress(epAddress) {
        if (epAddress in _endpoints) return _endpoints.epAddress;

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
                    _endpoints[epAddress.toString()] <- newEp;
                    return newEp;
                }
            }
        }

        // No EP found
        return null;
    }

    // Called by USB.Host when the devices is detached
    function stop() {
        // Close all endpoints at first
        foreach (epAddress, ep in _endpoints) ep.close();

        foreach ( driver in _drivers ) {
            try {
                driver.release();
            } catch (e) {
                _error("Driver.release exception: " + e);
            }
        }

        _drivers = null;
        _endpoints = null;
        _deviceDescriptor = null;
    }

    // Prints device information
    function toString() {

    }

    function getVendorId() {
        return _deviceDescriptor["vendorid"];
    }

    function getProductId() {
        return _deviceDescriptor["productid"];
    }

    // -------------------- Private functions --------------------

    // Select and setup drivers
    function _selectDrivers(drivers) {
        local devClass      = _deviceDescriptor["class"];
        local devSubClass   = _deviceDescriptor.subclass;
        local devProtocol   = _deviceDescriptor.protocol;
        local ifs = _deviceDescriptor.configurations[0].interfaces;

        // if this is not composite device
        if ( 0 !=  devClass &&  0 != devSubClass && 0 != devProtocol) {

            foreach (driver in  drivers) {
                try {
                    local instance;
                    if (null != (instance = driver.match(this, ifs))) {
                        _drivers.append(instance);
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
                            break;
                        }
                    } catch (e) {
                      _log("Error driver initialization: " + e);
                    }
                }
            }

        }
    }

    function _transferEvent(eventDetails) {
        local epAddress = eventDetails.endpoint;

        if (epAddress in _endpoints) {
            // TODO: check relation of ep with interface and ep type
            local ep = _endpoints[epAddress];
            local error = (eventDetails.state != 0) ? eventDetails.state : null;
            local len = eventDetails.length;

            ep._onTransferComplete(error, len, eventDetails.endpoint);
        } else {
            _log("Unexpected transfer for unknown endpoint: " + epAddress);
        }
    }

    function _log(txt) {
        if (_debug) {
            server.log("[Usb.Device] " + txt);
        }
    }

    function _error(txt) {
        server.error("[Usb.Device] " + txt);
    }
}


// Represent all non-control endpoints
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

    // Constructor
    constructor (device, ifs, epAddress, epType, maxPacketSize) {
        _device = device;
        _address = epAddress;
        _maxPacketSize = maxPacketSize;
        _type = epType;
        _if = ifs;
    }

    // Write data through this endpoint.
    // Throws if EP is closed of has incompatible type
    function write(data, onComplete) {
        if (_address & USB_DIRECTION_MASK) {
            throw "Invalid endpoint direction: " + _address;
        } else {
            _transfer(data, onComplete);
        }
    }

    // Read data through this endpoint.
    // Throws if EP is closed or has incompatible type
    function read(data, onComplete) {
        if (_address & USB_DIRECTION_MASK) {
            _transfer(data, onComplete);
        } else {
            throw "Invalid endpoint direction: " + _address;
        }
    }

    // Mark as closed. All further operation causes exception.
    function close() {
        _closed = true;
    }

    // --------------------- Private functions -----------------

    // Transfer initiator
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
                // TODO: introduce USB generic logger
                _device._error(e);
            }
        };
    }

    // Notifies application about data transfer status
    function _onTransferComplete(error, length, endpoint) {
        _transferCb(error, length);

        // ready for next request
        _transferCb = null;

        if (error == USB_TYPE_STALL_ERROR)
            imp.wakeup(0, (function() {
                this.clearStall(endpoint);
            }).bindenv(this));
    }

    function clearStall(endpoint) {
        // Attempt to clear the stall
        try {
            _device._usb.controltransfer(
                _device._speed,
                _device._address,
                0,
                USB_SETUP_RECIPIENT_ENDPOINT | USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_STANDARD,
                USB_REQUEST_CLEAR_FEATURE,
                0,    // Feature selector: 0 = ENDPOINT_HALT
                endpoint,
               _maxPacketSize);
        } catch(error) {
            // Attempt failed
            server.error("Control transfer failed. Error: " + error);
               return false;
        }

        // Attempt successful
        return true;
    }
}

// Represent control endpoints.
// This class is required due to specific EI usb API
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
    constructor (device, ifs, epAddress, maxPacketSize) {
        _device = device;
        _address = epAddress;
        _maxPacketSize = maxPacketSize;
        _if = ifs;
    }

    // Generic function for transferring data over control endpoint.
    // Note! This operation is synchronous.
    function transfer(reqType, type, value, index, data = null) {
        if (_closed) throw "Closed";

        if ((reqType & USB_SETUP_TYPE_MASK) != USB_SETUP_TYPE_VENDOR) throw "Only vendor request is allowed";

        _device._usb.controltransfer(
            device._speed,
            device._address,
            _address,
            reqType,
            type,
            value,
            index,
            _maxPacketSize,
            data
        );
    }

    // Mark as closed. All further operation causes exception.
    function close() {
        _closed = true;
    }
}


class USB.DriverBase {

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
