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

    static VERSION = "1.0.0";

    constructor() {
        const USB_ENDPOINT_CONTROL = 0x00;
        const USB_ENDPOINT_ISCHRONOUS = 0x01;
        const USB_ENDPOINT_BULK = 0x02;
        const USB_ENDPOINT_INTERRUPT = 0x03;

        const USB_SETUP_HOST_TO_DEVICE = 0x00;
        const USB_SETUP_DEVICE_TO_HOST = 0x80;
        const USB_SETUP_TYPE_STANDARD = 0x00;
        const USB_SETUP_TYPE_CLASS = 0x20;
        const USB_SETUP_TYPE_VENDOR = 0x40;
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
        const USB_DIRECTION_IN = 0x1;
    }
}


// 
// Usb wrapper class.
// 
class USB.Host {

    _eventHandlers = null;
    _customEventHandlers = null;
    _driver = null;
    _autoConfiguredPins = false;
    _bulkTransferQueue = null;
    _address = 1;
    _registeredDrivers = null;
    _usb = null
    _driverCallback = null;
    _DEBUG = false;
    _busy = false;

    // 
    // Constructor
    // 
    // @param  {Object} usb Internal `hardware.usb` object
    // @param  {Boolean} flag to specify whether to configure pins for usb usage (see https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb)
    // 
    constructor(usb, autoConfPins = true) {
        _usb = usb;
        _bulkTransferQueue = [];
        _registeredDrivers = {};
        _eventHandlers = {};
        _customEventHandlers = {};

        if (autoConfPins) {
            _autoConfiguredPins = true;
            // Configure the pins required for usb
            hardware.pinW.configure(DIGITAL_IN_PULLUP);
            hardware.pinR.configure(DIGITAL_OUT, 1);
        }


        _eventHandlers[USB_DEVICE_CONNECTED] <- _onDeviceConnected.bindenv(this);
        _eventHandlers[USB_DEVICE_DISCONNECTED] <- _onDeviceDisconnected.bindenv(this);
        _eventHandlers[USB_TRANSFER_COMPLETED] <- _onTransferCompleted.bindenv(this);
        _eventHandlers[USB_UNRECOVERABLE_ERROR] <- _onHardwareError.bindenv(this);
        _usb.configure(_onEvent.bindenv(this));
    }


    // 
    // Meta method to overrride typeof instance
    // 
    // @return {String} typeof instance of class
    // 
    function _typeof() {
        return "USB.Host";
    }


    // 
    // Registers a list of VID PID pairs to a driver class with usb host. This driver will be instantiated
    // when a matching VID PID device is connected via usb
    // 
    // @param {Class} driverClass Class to be instantiated when a matching VID PID device is connected
    // @param {Array of Tables} Array of VID PID tables
    // 
    function registerDriver(driverClass, identifiers) {

        // Check the driver class is using the correct base class
        if (!(driverClass.isUSBDriver == true)) {
            throw "This driver is not a valid usb driver.";
            return;
        }

        // identifiers must be an array
        if (typeof identifiers != "array") {
            throw "Identifiers for driver must be of type array.";
            return;
        }

        // Register all indentifiers to corresponding class
        foreach (k, identifier in identifiers) {
            foreach (VID, PIDS in identifier) {
                if (typeof PIDS != "array") {
                    PIDS = [PIDS];
                }

                foreach (vidIndex, PID in PIDS) {
                    local vpid = format("%04x%04x", VID, PID);
                    // store all VID PID combos
                    _registeredDrivers[vpid] <- driverClass;
                }
            }
        }
    }


    // 
    // Returns currently active driver object. Will be null if no driver found.
    // 
    function getDriver() {
        return _driver;
    }


    // 
    // Subscribe callback to call on "eventName" event
    // 
    // @param  {String}   eventName The event name to subscribe callback to
    // @param  {Function} cb        Function to call when event emitted
    // 
    function on(eventName, cb) {
        _customEventHandlers[eventName] <- cb;
    }


    // 
    // Clear callback from "eventName" event
    // 
    // @param eventName The event name to unsubsribe from
    // 
    function off(eventName) {
        if (eventName in _customEventHandlers) {
            delete _customEventHandlers[eventName];
        }
    }


    // 
    // Opens a specific endpoint based on params
    // 
    // @param  {Float}        speed             The speed in Mb/s. Must be either 1.5 or 12
    // @param  {Integer}      deviceAddress     The address of the device
    // @param  {Integer}      interfaceNumber   The endpoint’s interface number
    // @param  {Integer}      type              The type of the endpoint
    // @param  {Integer}      maxPacketSize     The maximum size of packet that can be written or read on this endpoint
    // @param  {Integer}      endpointAddress   The address of the endpoint
    // 
    function _openEndpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress) {
        _usb.openendpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress);
    }


    // 
    // Set control transfer USB_REQUEST_SET_ADDRESS device address
    // 
    // @param {Integer}    address          An index value determined by the specific USB request (range 0x0000-0xFFFF)
    // @param {Float}      speed            The speed in Mb/s. Must be either 1.5 or 12
    // @param {Integer}    maxPacketSize    The maximum size of packet that can be written or read on this endpoint
    // 
    function _setAddress(address, speed, maxPacketSize) {
        _usb.controltransfer(
            speed,
            0,
            0,
            USB_SETUP_HOST_TO_DEVICE | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_SET_ADDRESS,
            address,
            0,
            maxPacketSize
        );
    }


    // 
    // Set control transfer USB_REQUEST_SET_CONFIGURATION value
    // 
    // @param {Integer}    deviceAddress    The address of the device
    // @param {Float}      speed            The speed in Mb/s. Must be either 1.5 or 12
    // @param {Integer}    maxPacketSize    The maximum size of packet that can be written or read on this endpoint
    // @param {Integer}    value          An index value determined by the specific USB request (range 0x0000-0xFFFF)
    // 
    function _setConfiguration(deviceAddress, speed, maxPacketSize, value) {
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            USB_SETUP_HOST_TO_DEVICE | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_SET_CONFIGURATION,
            value,
            0,
            maxPacketSize
        );
    }


    // 
    // Creates a USB driver instance if vid/pid combo matches registered devices
    // 
    // @param {Tables} Table with keys "vendorid" and "productid" of the device
    // 
    function _create(identifiers) {
        local vid = identifiers["vendorid"];
        local pid = identifiers["productid"];
        local vpid = format("%04x%04x", vid, pid);

        if ((vpid in _registeredDrivers) && _registeredDrivers[vpid] != null) {
            return _registeredDrivers[vpid](this);
        }
        return null;
    }


    // 
    // Usb connected callback
    // 
    // @param {Table} eventdetails  Table containing the details of the connection event
    // 
    function _onDeviceConnected(eventdetails) {
        if (_driver != null) {
            server.error("UsbHost: Device already connected");
            return;
        }

        local speed = eventdetails["speed"];
        local descriptors = eventdetails["descriptors"];
        local maxPacketSize = descriptors["maxpacketsize0"];
        if (_DEBUG) {
            _logDescriptors(speed, descriptors);
        }

        // Try to create the driver for connected device
        _driver = _create(descriptors);

        if (_driver == null) {
            server.error("UsbHost: No driver found for device");
            return;
        }

        _setAddress(_address, speed, maxPacketSize);
        _driver.connect(_address, speed, descriptors);
        // Emit connected event that user can subscribe to
        _onEvent("connected", _driver);
    }


    // 
    // Device disconnected callback
    // 
    // @param {Table}  eventDetails  Table containing details about the disconnection event
    function _onDeviceDisconnected(eventdetails) {
        if (_driver != null) {
            // Emit disconnected event
            _onEvent("disconnected", typeof _driver);
            _driver = null;
        }
    }


    // 
    // Bulk transfer data blob
    // 
    // @param {Integer}    address          The address of the device
    // @param {Integer}    endpoint         The address of the endpoint
    // @param {Integer}    type             Integer
    // @param {Blob}       data             The data to be transferred
    // 
    function _bulkTransfer(address, endpoint, type, data) {
        // Push to the end of the queue
        _pushBulkTransferQueue([_usb, address, endpoint, type, data]);
        // Process request at the front of the queue
        _popBulkTransferQueue();
    }


    // 
    // Control transfer wrapper method
    // 
    // @param {Float}               speed            The speed in Mb/s. Must be either 1.5 or 12
    // @param {Integer}             deviceAddress    The address of the device
    // @param {Integer (bitfield)}  requestType      The type of the endpoint
    // @param {Integer}             request          The specific USB request
    // @param {Integer}             value            A value determined by the specific USB request (range 0x0000-0xFFFF)
    // @param {Integer}             index            An index value determined by the specific USB request (range 0x0000-0xFFFF)
    // @param {Integer}             maxPacketSize    The maximum size of packet that can be written or read on this endpoint
    // 
    function _controlTransfer(speed, deviceAddress, requestType, request, value, index, maxPacketSize) {
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            requestType,
            request,
            value,
            index,
            maxPacketSize
        );
    }


    // 
    // Called when a Usb request is succesfully completed
    // 
    // @param  {Table} eventdetails Table with the transfer event details
    // 
    function _onTransferCompleted(eventdetails) {

        _busy = false;
        if (_driver) {
            // Pass complete event to driver
            _driver._transferComplete(eventdetails);
        }
        // Process any queued requests
        _popBulkTransferQueue();
    }


    // 
    // Callback on hardware error
    // 
    // @param  {Table} eventdetails  Table with the hardware event details
    // 
    function _onHardwareError(eventdetails) {
        server.error("UsbHost: Internal unrecoverable usb error. Resetting the bus.");
        usb.disable();
        _usb.configure(_onEvent.bindenv(this));
    }


    // 
    // Push bulk transfer request to back of queue
    // 
    // @params {Array} request  bulktransfer params to be passed via the .acall function in format [_usb, address, endpoint, type, data].
    // 
    function _pushBulkTransferQueue(request) {
        _bulkTransferQueue.push(request);
    }


    // 
    // Pop bulk transfer request to front of queue
    // 
    function _popBulkTransferQueue() {
        if (!_busy && _bulkTransferQueue.len() > 0) {
            _usb.generaltransfer.acall(_bulkTransferQueue.remove(0));
            _busy = true;
        }
    }


    // Emit event "eventtype" with eventdetails
    // 
    // @param {String}  Event name to emit
    // @param {any}     Data to pass to event listener callback
    // 
    function _onEvent(eventtype, eventdetails) {
        // Handle event internally first
        if (eventtype in _eventHandlers) {
            _eventHandlers[eventtype](eventdetails);
        }
        // Pass event to any subscribers
        if (eventtype in _customEventHandlers) {
            _customEventHandlers[eventtype](eventdetails);
        }
    }


    // 
    // Parses and returns descriptors for a device as a string
    // 
    // @param  {Integer}    deviceAddress  The address of the device
    // @param  {Float}      speed          The speed in Mb/s. Must be either 1.5 or 12
    // @param  {Integer}    maxPacketSize  The maximum size of packet that can be written or read on this endpoint
    // @param  {Integer}    index          An index value determined by the specific USB request (range 0x0000-0xFFFF)
    // @return {String}                    Descriptors for a device as a string
    // 
    function _getStringDescriptor(deviceAddress, speed, maxPacketSize, index) {
        if (index == 0) {
            return "";
        }
        local buffer = blob(2);
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            USB_SETUP_DEVICE_TO_HOST | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_GET_DESCRIPTOR,
            (USB_DESCRIPTOR_STRING << 8) | index,
            0,
            maxPacketSize,
            buffer
        );

        local stringSize = buffer[0];
        buffer = blob(stringSize);
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            USB_SETUP_DEVICE_TO_HOST | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_GET_DESCRIPTOR,
            (USB_DESCRIPTOR_STRING << 8) | index,
            0,
            maxPacketSize,
            buffer
        );

        // String descriptors are zero-terminated, unicode.
        // This could be done better.
        buffer.seek(2, 'b');
        local description = blob();
        while (!buffer.eos()) {
            local char = buffer.readn('b');
            if (char != 0) {
                description.writen(char, 'b');
            }
            buffer.readn('b');
        }
        return description.tostring();
    }


    // 
    // Prints the descriptors for a device
    // 
    // @param  {Float}  speed       The speed in Mb/s. Must be either 1.5 or 12
    // @param  {Table}  descriptor  The descriptors received from the device
    // 
    function _logDescriptors(speed, descriptor) {
        local maxPacketSize = descriptor["maxpacketsize0"];
        server.log("USB Device Connected, speed=" + speed + " Mbit/s");
        server.log(format("usb = 0x%04x", descriptor["usb"]));
        server.log(format("class = 0x%02x", descriptor["class"]));
        server.log(format("subclass = 0x%02x", descriptor["subclass"]));
        server.log(format("protocol = 0x%02x", descriptor["protocol"]));
        server.log(format("maxpacketsize0 = 0x%02x", maxPacketSize));
        local manufacturer = _getStringDescriptor(0, speed, maxPacketSize, descriptor["manufacturer"]);
        server.log(format("VID = 0x%04x (%s)", descriptor["vendorid"], manufacturer));
        local product = _getStringDescriptor(0, speed, maxPacketSize, descriptor["product"]);
        server.log(format("PID = 0x%04x (%s)", descriptor["productid"], product));
        local serial = _getStringDescriptor(0, speed, maxPacketSize, descriptor["serial"]);
        server.log(format("device = 0x%04x (%s)", descriptor["device"], serial));

        local configuration = descriptor["configurations"][0];
        local configurationString = _getStringDescriptor(0, speed, maxPacketSize, configuration["configuration"]);
        server.log(format("Configuration: 0x%02x (%s)", configuration["value"], configurationString));
        server.log(format("  attributes = 0x%02x", configuration["attributes"]));
        server.log(format("  maxpower = 0x%02x", configuration["maxpower"]));

        foreach (interface in configuration["interfaces"]) {
            local interfaceDescription = _getStringDescriptor(0, speed, maxPacketSize, interface["interface"]);
            server.log(format("  Interface: 0x%02x (%s)", interface["interfacenumber"], interfaceDescription));
            server.log(format("    altsetting = 0x%02x", interface["altsetting"]));
            server.log(format("    class=0x%02x", interface["class"]));
            server.log(format("    subclass = 0x%02x", interface["subclass"]));
            server.log(format("    protocol = 0x%02x", interface["protocol"]));

            foreach (endpoint in interface["endpoints"]) {
                local address = endpoint["address"];
                local endpointNumber = address & 0x3;
                local direction = (address & 0x80) >> 7;
                local attributes = endpoint["attributes"];
                local type = _endpointTypeString(attributes);
                server.log(format("    Endpoint: 0x%02x (ENDPOINT %d %s %s)", address, endpointNumber, type, _directionString(direction)));
                server.log(format("      attributes = 0x%02x", attributes));
                server.log(format("      maxpacketsize = 0x%02x", endpoint["maxpacketsize"]));
                server.log(format("      interval = 0x%02x", endpoint["interval"]));
            }
        }
    }


    // 
    // Extract the direction from and endpoint address
    // 
    // @param  {Integer} direction  Direction of data as an Integer
    // @return {String}             Direction of data as a String
    // 
    function _directionString(direction) {
        if (direction == USB_DIRECTION_IN) {
            return "IN";
        } else if (direction == USB_DIRECTION_OUT) {
            return "OUT";
        } else {
            return "UNKNOWN";
        }
    }


    // 
    // Extract the endpoint type from attributes byte
    // 
    // @param {Integer} attributes  Transfer attributes retrived from device descriptors
    // @return {String}             String representing type of transfer
    // 
    function _endpointTypeString(attributes) {
        local type = attributes & 0x3;
        if (type == 0) {
            return "CONTROL";
        } else if (type == 1) {
            return "ISOCHRONOUS";
        } else if (type == 2) {
            return "BULK";
        } else if (type == 3) {
            return "INTERRUPT";
        }
    }
};


// 
// Usb control tranfer wrapper class
// 
class USB.ControlEndpoint {

    _usb = null;
    _deviceAddress = null;
    _speed = null;
    _maxPacketSize = null;

    // 
    // Contructor
    // 
    // @param  {UsbHostClass} usb       Instance of the UsbHostClass
    // @param  {Integer} deviceAddress  The address of the device
    // @param  {Float} speed            The speed in Mb/s. Must be either 1.5 or 12
    // @param  {Integer} maxPacketSize  The maximum size of packet that can be written or read on this endpoint
    // 
    constructor(usb, deviceAddress, speed, maxPacketSize) {
        _usb = usb;
        _deviceAddress = deviceAddress;
        _speed = speed;
        _maxPacketSize = maxPacketSize;
    }


    // 
    // Configures the control endpoint
    // 
    // @param {Integer} value   A value determined by the specific USB request (range 0x0000-0xFFFF)
    // 
    function _setConfiguration(value) {
        _usb._setConfiguration(_deviceAddress, _speed, _maxPacketSize, value);
    }


    // 
    // Retrieves and returns the string descriptors from the UsbHost.
    // 
    // @param {Integer} index   An index value determined by the specific USB request (range 0x0000-0xFFFF)
    // @return {String}         String of device descriptors
    // 
    function getStringDescriptor(index) {
        return _usb._getStringDescriptor(_deviceAddress, _speed, _maxPacketSize, index);
    }


    // 
    // Makes a control transfer
    // 
    // @param  {Integer (bitfield)} requestType  The type of the endpoint
    // @param  {Integer}            request      The specific USB request
    // @param  {Integer}            value        A value determined by the specific USB request (range 0x0000-0xFFFF)
    // @param  {Integer}            index        An index value determined by the specific USB request (range 0x0000-0xFFFF)
    // 
    function send(requestType, request, value, index) {
        return _usb._controlTransfer(_speed, _deviceAddress, requestType, request, value, index, _maxPacketSize)
    }
}


// 
// Usb bulk transfer wrapper super class
// 
class USB.BulkEndpoint {

    _usb = null;
    _deviceAddress = null;
    _endpointAddress = null;


    // 
    // Constructor
    // 
    // @param  {UsbHostClass} usb               Instance of the UsbHostClass
    // @param  {Float}        speed             The speed in Mb/s. Must be either 1.5 or 12
    // @param  {Integer}      deviceAddress     The address of the device
    // @param  {Integer}      interfaceNumber   The endpoint’s interface number
    // @param  {Integer}      endpointAddress   The address of the endpoint
    // @param  {Integer}       maxPacketSize    The maximum size of packet that can be written or read on this endpoint
    // 
    constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize) {
        _usb = usb;
        if (_usb._DEBUG) server.log(format("Opening bulk endpoint 0x%02x", endpointAddress));

        _deviceAddress = deviceAddress;
        _endpointAddress = endpointAddress;
        _usb._openEndpoint(speed, _deviceAddress, interfaceNumber, USB_ENDPOINT_BULK, maxPacketSize, _endpointAddress);
    }
}

// 
// Usb bulk in transfer wrapper class
// 
class USB.BulkInEndpoint extends USB.BulkEndpoint {

    _data = null;

    // 
    // Constructor
    // 
    // @param  {UsbHostClass} usb               Instance of the UsbHostClass
    // @param  {Float}        speed             The speed in Mb/s. Must be either 1.5 or 12
    // @param  {Integer}      deviceAddress     The address of the device
    // @param  {Integer}      interfaceNumber   The endpoint’s interface number
    // @param  {Integer}      endpointAddress   The address of the endpoint
    // @param  {Integer}       maxPacketSize    The maximum size of packet that can be written or read on this endpoint
    // 
    constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize) {
        assert((endpointAddress & 0x80) >> 7 == USB_DIRECTION_IN);
        base.constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize);
    }

    // 
    // Reads incoming data
    // 
    // @param {String/Blob} data to be read
    // 
    function read(data) {
        _data = data;
        _usb._bulkTransfer(_deviceAddress, _endpointAddress, USB_ENDPOINT_BULK, data);
    }


    // 
    // Mark transfer as complete
    // 
    // @param {Table} details  detials of the transfer
    // @return result of bulkin transfer
    function done(details) {
        assert(details["endpoint"] == _endpointAddress);
        _data.resize(details["length"]);
        // assign locally
        local data = _data;
        // blank current data
        _data = null;
        return data;
    }


}


// 
// Usb bulk out transfer wrapper classs
// 
class USB.BulkOutEndpoint extends USB.BulkEndpoint {

    _data = null;

    // 
    // Constructor
    // 
    // @param  {UsbHostClass} usb               Instance of the UsbHostClass
    // @param  {Float}        speed             The speed in Mb/s. Must be either 1.5 or 12
    // @param  {Integer}      deviceAddress     The address of the device
    // @param  {Integer}      interfaceNumber   The endpoint’s interface number
    // @param  {Integer}      endpointAddress   The address of the endpoint
    // @param  {Integer}       maxPacketSize    The maximum size of packet that can be written or read on this endpoint
    // 
    constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize) {
        assert((endpointAddress & 0x80) >> 7 == USB_DIRECTION_OUT);
        base.constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize);
    }


    // 
    // Writes data to usb via bulk transfer
    // 
    // @param {String/Blob} data to be written
    // 
    function write(data) {
        _data = data;
        _usb._bulkTransfer(_deviceAddress, _endpointAddress, USB_ENDPOINT_BULK, data);
    }


    // 
    // Called when transfer is complete
    // 
    // @param  {Table}   details    detials of the transfer
    // 
    function done(details) {
        assert(details["endpoint"] == _endpointAddress);
        _data = null;
    }


}


// 
// Super class for Usb driver classes.
// 
class USB.DriverBase {

    static VERSION = "1.0.0";

    static isUSBDriver = true;

    _usb = null;
    _controlEndpoint = null;
    _eventHandlers = {};

    constructor(usb) {
        _usb = usb;
    }


    // 
    // Set up the usb to connect to this device
    // 
    // @param  {Integer} deviceAddress The address of the device
    // @param  {Float}   speed         The speed in Mb/s. Must be either 1.5 or 12
    // @param  {String}  descriptors   The descriptors received from device
    // 
    function connect(deviceAddress, speed, descriptors) {
        _setupEndpoints(deviceAddress, speed, descriptors);
        _configure(descriptors["device"]);
        _start();
    }


    // 
    // Should return an array of VID PID combination tables.
    // 
    function getIdentifiers() {
        throw "Method not implemented";
    }


    // 
    // Registers a callback to a specific event
    // 
    // @param  {String}   eventType The event name to subscribe callback to
    // @param  {Function} cb        Function to call when event emitted
    // 
    function on(eventType, cb) {
        _eventHandlers[eventType] <- cb;
    }


    // 
    // Clears event listener on specific event
    // 
    // @param  {String}   eventName The event name to unsubscribe from
    // 
    function off(eventName) {
        if (eventName in _eventHandlers) {
            delete _eventHandlers[eventName];
        }
    }


    // 
    // Handle case when a Usb request is succesfully completed
    // 
    function _transferComplete(eventdetails) {
        throw "Method not implemented";
    }


    // 
    // Initialize and set up all required endpoints
    // 
    // @param  {Integer} deviceAddress The address of the device
    // @param  {Float}   speed         The speed in Mb/s. Must be either 1.5 or 12
    // @param  {String}  descriptors   The descriptors received from device
    // 
    function _setupEndpoints(deviceAddress, speed, descriptors) {
        if (_usb._DEBUG) server.log(format("Driver connecting at address 0x%02x", deviceAddress));
        _deviceAddress = deviceAddress;
        _controlEndpoint = USB.ControlEndpoint(_usb, deviceAddress, speed, descriptors["maxpacketsize0"]);

        // Select configuration
        local configuration = descriptors["configurations"][0];

        if (_usb._DEBUG) server.log(format("Setting configuration 0x%02x (%s)", configuration["value"], _controlEndpoint.getStringDescriptor(configuration["configuration"])));
        _controlEndpoint._setConfiguration(configuration["value"]);

        // Select interface
        local interface = configuration["interfaces"][0];
        local interfacenumber = interface["interfacenumber"];

        foreach (endpoint in interface["endpoints"]) {
            local address = endpoint["address"];
            local maxPacketSize = endpoint["maxpacketsize"];
            if ((endpoint["attributes"] & 0x3) == 2) {
                if ((address & 0x80) >> 7 == USB_DIRECTION_OUT) {
                    _bulkOut = USB.BulkOutEndpoint(_usb, speed, _deviceAddress, interfacenumber, address, maxPacketSize);
                } else {
                    _bulkIn = USB.BulkInEndpoint(_usb, speed, _deviceAddress, interfacenumber, address, maxPacketSize);
                }
            }
        }
    }


    // 
    // Set up basic parameters using control transfer
    // 
    // @param {Integer} device key receieved in descriptors
    // 
    function _configure(device) {

        if (_usb._DEBUG) server.log(format("Configuring for device version 0x%04x", device));

        // Set Baud Rate
        local baud = 115200;
        local baudValue;
        local baudIndex = 0;
        local divisor3 = 48000000 / 2 / baud; // divisor shifted 3 bits to the left

        if (device == 0x0200) { // FT232AM
            if ((divisor3 & 0x07) == 0x07) {
                divisor3++; // round x.7/8 up to x+1
            }

            baudValue = divisor3 >> 3;
            divisor3 = divisor3 & 0x7;

            if (divisor3 == 1) {
                baudValue = baudValue | 0xc000; // 0.125
            } else if (divisor3 >= 4) {
                baudValue = baudValue | 0x4000; // 0.5
            } else if (divisor3 != 0) {
                baudValue = baudValue | 0x8000; // 0.25
            }

            if (baudValue == 1) {
                baudValue = 0; // special case for maximum baud rate
            }

        } else {
            local divfrac = [0, 3, 2, 0, 1, 1, 2, 3];
            local divindex = [0, 0, 0, 1, 0, 1, 1, 1];

            baudValue = divisor3 >> 3;
            baudValue = baudValue | (divfrac[divisor3 & 0x7] << 14);

            baudIndex = divindex[divisor3 & 0x7];

            // Deal with special cases for highest baud rates.
            if (baudValue == 1) {
                baudValue = 0; // 1.0
            } else if (baudValue == 0x4001) {
                baudValue = 1; // 1.5
            }
        }

        _controlEndpoint.send(FTDI_REQUEST_FTDI_OUT, FTDI_SIO_SET_BAUD_RATE, baudValue, baudIndex);

        const xon = 0x11;
        const xoff = 0x13;

        _controlEndpoint.send(FTDI_REQUEST_FTDI_OUT, FTDI_SIO_SET_FLOW_CTRL, xon | (xoff << 8), FTDI_SIO_DISABLE_FLOW_CTRL << 8);
    }


    // Emit event "eventtype" with eventdetails
    // 
    // @param {String}  Event name to emit
    // @param {any}     Data to pass to event listener callback
    // 
    function _onEvent(eventtype, eventdetails) {
        // Handle event internally first
        if (eventtype in _eventHandlers) {
            _eventHandlers[eventtype](eventdetails);
        }
    }


    // 
    // Instantiate the buffer
    // 
    function _start() {
        _bulkIn.read(blob(1));
    }
};
