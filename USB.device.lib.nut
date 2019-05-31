// MIT License
//
// Copyright 2017-19 Electric Imp
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

const USB_ENDPOINT_CONTROL                  = 0x00;
const USB_ENDPOINT_ISOCHRONOUS              = 0x01;
const USB_ENDPOINT_BULK                     = 0x02;
const USB_ENDPOINT_INTERRUPT                = 0x03;
const USB_ENDPOINT_TYPE_MASK                = 0x03;

const USB_SETUP_HOST_TO_DEVICE              = 0x00;
const USB_SETUP_DEVICE_TO_HOST              = 0x80;
const USB_SETUP_TYPE_STANDARD               = 0x00;
const USB_SETUP_TYPE_CLASS                  = 0x20;
const USB_SETUP_TYPE_VENDOR                 = 0x40;
const USB_SETUP_TYPE_MASK                   = 0x60;
const USB_SETUP_RECIPIENT_DEVICE            = 0x00;
const USB_SETUP_RECIPIENT_INTERFACE         = 0x01;
const USB_SETUP_RECIPIENT_ENDPOINT          = 0x02;
const USB_SETUP_RECIPIENT_OTHER             = 0x03;

const USB_REQUEST_GET_STATUS                = 0;
const USB_REQUEST_CLEAR_FEATURE             = 1;
const USB_REQUEST_SET_FEATURE               = 3;
const USB_REQUEST_SET_ADDRESS               = 5;
const USB_REQUEST_GET_DESCRIPTOR            = 6;
const USB_REQUEST_SET_DESCRIPTOR            = 7;
const USB_REQUEST_GET_CONFIGURATION         = 8;
const USB_REQUEST_SET_CONFIGURATION         = 9;
const USB_REQUEST_GET_INTERFACE             = 10;
const USB_REQUEST_SET_INTERFACE             = 11;
const USB_REQUEST_SYNCH_FRAME               = 12;

const USB_DEVICE_DESCRIPTOR_LENGTH          = 0x12;
const USB_CONFIGURATION_DESCRIPTOR_LENGTH   = 0x09;

const USB_DESCRIPTOR_DEVICE                 = 0x01;
const USB_DESCRIPTOR_CONFIGURATION          = 0x02;
const USB_DESCRIPTOR_STRING                 = 0x03;
const USB_DESCRIPTOR_INTERFACE              = 0x04;
const USB_DESCRIPTOR_ENDPOINT               = 0x05;
const USB_DESCRIPTOR_DEVICE_QUALIFIER       = 0x06;
const USB_DESCRIPTOR_OTHER_SPEED            = 0x07;
const USB_DESCRIPTOR_INTERFACE_POWER        = 0x08;
const USB_DESCRIPTOR_OTG                    = 0x09;
const USB_DESCRIPTOR_HID                    = 0x21;

const USB_DIRECTION_OUT                     = 0x0;
const USB_DIRECTION_IN                      = 0x80;
const USB_DIRECTION_MASK                    = 0x80;

const OK                                    = 0;
const USB_TYPE_CRC_ERROR                    = 1;
const USB_TYPE_BIT_STUFFING_ERROR           = 2;
const USB_TYPE_DATA_TOGGLE_MISMATCH_ERROR   = 3;
const USB_TYPE_STALL_ERROR                  = 4;
const USB_TYPE_DEVICE_NOT_RESPONDING_ERROR  = 5;
const USB_TYPE_PID_CHECK_FAILURE_ERROR      = 6;
const USB_TYPE_UNEXPECTED_PID_ERROR         = 7;
const USB_TYPE_DATA_OVERRUN_ERROR           = 8;
const USB_TYPE_DATA_UNDERRUN_ERROR          = 9;
const USB_TYPE_UNKNOWN_ERROR                = 10;
const USB_TYPE_UNKNOWN_ERROR                = 11;
const USB_TYPE_BUFFER_OVERRUN_ERROR         = 12;
const USB_TYPE_BUFFER_UNDERRUN_ERROR        = 13;
const USB_TYPE_DISCONNECTED                 = 14;
const USB_TYPE_FREE                         = 15;
const USB_TYPE_IDLE                         = 16;
const USB_TYPE_BUSY                         = 17;
const USB_TYPE_INVALID_ENDPOINT             = 18;
const USB_TYPE_TIMEOUT                      = 19;
const USB_TYPE_INTERNAL_ERROR               = 20;

const USB_DRIVER_STATE_STARTED              = "started";
const USB_DRIVER_STATE_STOPPED              = "stopped";

const USB_DEVICE_STATE_CONNECTED            = "connected";
const USB_DEVICE_STATE_DISCONNECTED         = "disconnected";

// The class that introduces USB namespace and related constants.
// Not intended to use by any developers.
USB <- {

    VERSION = "1.1.0",

    // Debug flag
    debug = true,

    // Information level logger
    log = function(txt) {
        if (debug) {
            server.log("[USB]: " + txt);
        }
    }

    // Error level logger
    err = function(txt) {
        server.error("[USB|ERROR]: " + txt);
    }

    //
    // The main interface to start working with USB devices.
    // Here an application registers drivers and assigns listeners
    // for important events like device connection/detachment.
    Host = class {

        // The list of registered driver classes
        _driverClasses = null;

        // The list of connected devices
        _devices = null;

        // The address available to assign to next device
        _address = 1;

        // USB device pointer
        _usb = null;

        // USB Driver state listener
        // This property is available for device instances, so it's public
        driverListener = null;

        // USB device state listener
        // This property is available for device instances, so it's public
        deviceListener = null;

        // ------------------------ public API -------------------

        //
        // Constructor
        // Parameters:
        //      usb            -
        //      driverList     - a list of special classes that implement USB.Driver API.
        //      autoConfigPins - the table containing the power control pin ("powerPin")
        //                       and the fault indication pint ("faultPin")
        //                       (see https://electricimp.com/docs/hardware/imp/imp005pinmux/#usb)
        //
        constructor(usb, driverList, autoConfigPins = null) {
            try {
                _usb = usb;
            } catch(e) {
                throw "Expected `hardware.usb` interface is not available";
            }

            if (typeof driverList != "array") {
                throw "Driver list must be array";
            }

            if (null == driverList || 0 == driverList.len()) {
                throw "Driver list must not be empty";
            }

            _devices = {};
            _driverClasses = [];

            // checks validity, filters duplicate, append to the list
            foreach (driver in driverList) {
                _checkAndAppend(driver);
            }

            if (autoConfigPins) {
                if ("pinW" in hardware && "pinR" in hardware) {
                    // Configure the pins required for usb
                    hardware.pinW.configure(DIGITAL_IN_PULLUP);
                    hardware.pinR.configure(DIGITAL_OUT, 1);
                } else {
                    throw "Invalid hardware is used";
                }
            }

            _usb.configure(_onUsbEvent.bindenv(this));
        }

        // Reset the USB BUS.
        // Can be used by driver or application in response to unrecoverable error
        // like unending bulk transfer or halt condition during control transfers
        reset = function() {
            _usb.disable();

            // force disconnect for all attached devices
            foreach (address, device in _devices) {
                _onDeviceDetached({"device" : address});
            }

            // re-connect all devices
            _usb.configure(_onUsbEvent.bindenv(this));

            USB.log("USB reset complete");
        }

        // Auxillary function to get list of attached devices.
        // Returns:
        //      an array of USB.Device instances
        getAttachedDevices = function() {
            local devs = [];

            foreach(device in _devices)  devs.append(device);

            return devs;
        }

        // Setter for the driver state listener
        // Parameters:
        //      listener  - null or the function that receives two parameters:
        //                      eventType   - USB_DRIVER_STATE_STARTED - the driver is started
        //                                    USB_DRIVER_STATE_STOPPED - the driver is stopped
        //                      eventObject - instance of USB.Driver
        setDriverListener = function(listener) {
            if (typeof listener != "function" && listener != null) {
                throw "Invalid event listener parameter";
            }
            driverListener = listener;
        }


        // Setter for the device state listener
        // Parameters:
        //      listener  - null or the function that receives two parameters:
        //                      eventType - USB_DEVICE_STATE_CONNECTED      - the device was attached
        //                                  USB_DEVICE_STATE_DISCONNECTED   - the device was detached
        //                      eventObject - depending on event type it could be
        //                                    either USB.Device or USB.Driver instance
        setDeviceListener = function(listener) {
            if (typeof listener != "function" && listener != null) {
                throw "Invalid event listener parameter";
            }

            deviceListener = listener;
       }

        // ------------------------ private API -------------------

        // Checks if given parameter implement USB.Driver API,
        // filters duplicate and append to the driver list
        _checkAndAppend = function(driverClass) {
            if (typeof driverClass == "class" &&
                "match"   in driverClass && typeof driverClass.match   == "function" &&
                "release" in driverClass && typeof driverClass.release == "function")
            {
                if (null == _driverClasses.find(driverClass)) {
                    _driverClasses.append(driverClass);
                }
            } else {
                throw "Invalid driver class";
            }
        }

        // The function that will be called in response to a USB event.
        // Parameters:
        //          eventType       - The type of event that triggered the event
        //          eventDetails    - Event-specific information
        _onUsbEvent = function(eventType, eventDetails) {
            switch (eventType) {
                case USB_DEVICE_CONNECTED:
                    USB.log("USB_DEVICE_CONNECTED event");
                    _onDeviceConnected(eventDetails);
                    break;
                case USB_DEVICE_DISCONNECTED:
                    USB.log("USB_DEVICE_DISCONNECTED event");
                    _onDeviceDetached(eventDetails);
                    break;
                case USB_TRANSFER_COMPLETED:
                    USB.log("USB_TRANSFER_COMPLETED event");
                    _onTransferComplete(eventDetails);
                    break;
                case USB_UNRECOVERABLE_ERROR:
                    USB.err("USB_UNRECOVERABLE_ERROR event");
                    _onError();
                    break;
            }
        }

        // New device processing function
        // Creates new USB.Device instance, notifies application listener
        // with USB_DEVICE_STATE_CONNECTED event
        _onDeviceConnected = function(eventDetails) {
            local speed = eventDetails.speed;
            local descr = eventDetails.descriptors;
            local device = USB.Device(_usb, this, speed, descr, _address);

            // a copy application callback
            _devices[_address] <- device;
            USB.log("New device detected: " + device + ". Assigned address: " + _address);

            // address for next device
            _address++;

            // maintain event sending sequence
            deviceListener && deviceListener(USB_DEVICE_STATE_CONNECTED, device);

            device.selectDrivers(_driverClasses);
        }

        // Device detach processing function.
        // Stops corresponding USB.Device instance, notifies application listener
        // with USB_DEVICE_STATE_DISCONNECTED event
        _onDeviceDetached = function(eventDetails) {
            // TODO: why do we need this check?
            if ("device" in eventDetails) {
                local address = eventDetails.device;
                if (address in _devices) {
                    local device = _devices[address];
                    delete _devices[address];

                    try {
                        device._stop();
                        USB.log("Device " + device + " is removed");
                    } catch (e) {
                        USB.err("Error on device " + device + " release: " + e);
                    }

                    deviceListener && deviceListener(USB_DEVICE_STATE_DISCONNECTED, device);
                } else {
                    USB.err("Detach event for unregistered device: " + address);
                }
            } else {
                USB.err("Detach event occurred for an unknown device");
            }
        }

        // Data transfer status processing function
        // Checks transfer status and either notify USB.Device about event or
        // schedules bus reset if status is critical error
        _onTransferComplete = function(eventDetails) {
            local address = eventDetails.device;
            local state = eventDetails.state;

            // check for UNRECOVERABLE error
            if (_checkError(state)) {
                // all this errors are critical
                USB.err("Critical error received: " + state);
                imp.wakeup(0, _onError.bindenv(this));
                return;
            }

            if (address in _devices) {
                local device = _devices[address];
                device._transferEvent(eventDetails);
            } else {
                USB.err("transfer event for unknown device: " + address);
            }
        }

        // Checks error class
        // Returns  TRUE if error is critical and USB need to be reset
        //          FALSE otherwise
        _checkError = function(error) {
            if ((error > 0  && error < 4)   ||
                (error > 4  && error < 8)   ||
                (error > 9  && error < 12)  ||
                error == 14 || error > 17) {
                return true;
            }
            return false;
        }

        // USB critical error processing function.
        // Stops all registered USB._Devices and schedules bus reset
        _onError = function(eventDetails = null) {
            foreach(device in _devices) {
                try {
                    device._stop();
                } catch (e) {
                    USB.err("Error on device " + device + " release: " + e);
                }
            }
            imp.wakeup(0, reset.bindenv(this));
        }

        // Metafunction to return class name when typeof <instance> is run
        _typeof = function() {
            return "USB.Host";
        }
    } // Host

    // The class that represents attached device.
    // It manages its configuration, interfaces and endpoints.
    // An application does not need such object normally.
    // It is usually used by drivers to acquire required endpoints
    Device = class {

        // Assigned device address
        _address = 0;

        // Device descriptor
        _desc = null;

        // Interfaces descriptor array for current configuration
        _interfaces = null;

        // A list of drivers assigned to this device
        // There can be more than one driver for composite device
        _driverInstances = [];

        // Endpoints instances for this device. Required for quick search from transfer event processor
        _endpoints = {};

        // Device speed
        _speed = null;

        // USB interface
        _usb = null;

        // Instance of the USB host
        _host = null;

        // Constructs device peer.
        // Parameters:
        //      usb              - the native USB interface object
        //      host             - the instance of the usb host
        //      speed            - supported device speed
        //      deviceDescriptor - new device descriptor as specified by ElectricImpl USB API
        //      deviceAddress    - device address reserved (but assigned) for new device
        constructor(usb, host, speed, deviceDescriptor, deviceAddress) {
            _usb = usb;
            _host = host;
            _desc = deviceDescriptor;
            _speed = speed;
            _address = deviceAddress;
            local conf = deviceDescriptor.configurations[0];
            _interfaces = conf.interfaces;
            _driverInstances = [];

            local ep0 = USB.ControlEndpoint(this, 0, _desc["maxpacketsize0"]);
            _endpoints[0] <- ep0;

            // When a device is first connected you can communicate with it at address 0x00.
            // This should be set to a unique value for the device, using a set address control transfer.
            _setAddress(_address);

            // Select default configuration
            _setConfiguration(conf.value);

            // Delegate to bind native endpoint descriptor and the framework
            foreach(ifs in _interfaces) {
                ifs.setdelegate(_ifsDelegate);
                foreach (ep in ifs.endpoints) {
                    ep._device <- this;
                    ep.setdelegate(_epDelegate);
                }
            }
        }

        // Selects the matching drivers from the list of driver classes provided.
        // The matching drivers are initialized and started.
        //
        // Parameters:
        //      drivers          - an array of available USB driver classes to select from
        function selectDrivers(drivers) {
            // test specific behavior: _stop() is called before execution flow yielded
            if (null == _usb) return;

            local devClass = _desc["class"];

            foreach (driver in  drivers) {
                local matchResult = [];
                // if a driver matches, the driver instance is created here
                local result = driver.match(this, _interfaces);
                if (null != result) {
                    if (typeof result != "array") {
                        result = [result];
                    }

                    foreach (instance in result) {
                        _driverInstances.append(instance);
                    }
                    matchResult = result;
                }

                local listener = _host.driverListener;
                if (listener) {
                    foreach (instance in matchResult) {
                        listener(USB_DRIVER_STATE_STARTED, instance);
                    }
                }
            }
        }

        // Returns the device's USB host.
        // Returns:
        //      the host
        function getHost() {
            return _host;
        }

        // Returns device descriptor
        //
        // Throws exception if the device was detached
        //
        function getDescriptor() {
            _checkStopped();

            return _desc;
        }

        // Returns device vendor ID
        //
        // Throws exception if the device was detached
        //
        function getVendorId() {
            _checkStopped();

            return "vendorid" in _desc ? _desc["vendorid"] : null;
        }

        // Returns device product ID
        //
        // Throws exception if the device was detached
        //
        function getProductId() {
            _checkStopped();

            return "productid" in _desc ? _desc["productid"] : null;
        }

        // Returns an array of drivers for the attached device. Throws exception if the device is detached.
        // Each device provide the number of interfaces which could be supported by the different drives
        // (For example keyboard with touchpad could have keyboard driver and a separate touchpad driver).
        function getAssignedDrivers() {
            _checkStopped();

            return _driverInstances;
        }

        // Return Control Endpoint 0 proxy
        // EP0 is special type of endpoints that is implicitly present at device interfaces
        function getEndpointZero() {
            _checkStopped();

            return _endpoints[0];
        }

        // -------------------- Private functions --------------------

        // Delegate for endpoint descriptor
        _epDelegate = {
            // The function to acquire the framework proxy
            get = function(pollTime = 255) {

                if (! ("_proxy" in this) ) {
                    _proxy <- _device._getEndpoint(this, pollTime);
                }

                return _proxy;
            }
        }

        // Delegate for interface descriptor
        _ifsDelegate = {
            // Auxiliary function to search required endpoint
            find = function(type, dir) {
                foreach(ep in endpoints) {
                    if (ep.attributes == type && (ep.address & USB_DIRECTION_MASK) == dir) {
                        return ep.get();
                    }
                }
            }

            // Returns USB.Device instance - owner of this interface
            getDevice = function() {
                return endpoints[0]._device;
            }
        }

        // Request endpoint of required type and direction.
        // The function creates new endpoint if it was not cached.
        // Parameters:
        //      reqEp     - required endpoint descriptor
        //      pollTime  - interval for polling endpoint for data transfers. For Interrupt/Isochronous only.
        //
        //  Returns:
        //      an instance of USB.ControlEndpoint or USB.FunctionEndpoint, depending on type parameter,
        //      or `null` if there is no required endpoint found in provided interface
        //
        // Throws exception if the device was detached
        //
        function _getEndpoint(reqEp, pollTime) {
            _checkStopped();

            foreach (ifs in _interfaces) {
                foreach (ep in ifs.endpoints) {
                    if (ep == reqEp) {
                        local maxSize = ep.maxpacketsize;
                        local address = ep.address;
                        local type = ep.attributes;

                        if (type == USB_ENDPOINT_INTERRUPT) {
                            _usb.openendpoint(_speed, _address, ifs.interfacenumber, type, maxSize, address, pollTime);
                        } else {
                            _usb.openendpoint(_speed, _address, ifs.interfacenumber, type, maxSize, address);
                        }

                        local newEp = (type == USB_ENDPOINT_CONTROL) ?
                                        USB.ControlEndpoint(this, address, maxSize) :
                                        USB.FuncEndpoint(this, address, type, maxSize);

                        _endpoints[address] <- newEp;

                        return newEp;
                    }
                }
            }

            // No endpoint found
            return null;
        }

        // Called by USB.Host when the devices is detached
        // Closes all open endpoint and releases all drivers
        //
        // Throws exception if the device was detached
        //
        function _stop() {
            _checkStopped();

            // Close all endpoints at first
            foreach (ep in _endpoints) {
                ep._close();
            }

            // Release all drivers now
            local listener = _host.driverListener;
            foreach (driver in _driverInstances) {
                try {
                    driver.release();
                } catch (e) {
                    USB.err("Exception occurred on driver release: " + e);
                }

                listener && listener(USB_DRIVER_STATE_STOPPED, driver);
            }

            _usb = null;
            _desc = null;
            _endpoints = null;
            _interfaces = null;
            _driverInstances = null;
        }

        // Selects current device configuration by sending USB_REQUEST_SET_CONFIGURATION request through Endpoint Zero
        //
        // Parameter:
        //      config  - configuration number
        //
        // Returns Nothing
        //
        function _setConfiguration(config) {
            _endpoints[0].transfer(
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
                _desc["maxpacketsize0"]
            );
        }

        // Device run status check
        function _checkStopped() {
            if (null == _usb) throw "Detached";
        }

        // Proxy function for transfer event.
        // Looking up for corresponding endpoint and passes the event if found
        function _transferEvent(eventDetails) {
            // Do nothing for a closed device
            if (null == _usb) return;

            local epAddress = eventDetails.endpoint;
            if (epAddress in _endpoints) {
                local ep    = _endpoints[epAddress];
                local state = eventDetails.state;
                local len   = eventDetails.length;

                ep._onTransferEvent(state, len);

            } else {
                USB.log("Unexpected transfer for unknown endpoint: " + epAddress);
            }
        }

        // Metafunction to return class name when typeof <instance> is run
        function _typeof() {
            return "USB.Device";
        }
    } // Device

    // The class that represent all non-control endpoints, e.g. bulk, interrupt etc
    // This class is managed by USB.Device and should be acquired through USB.Device instance
    FuncEndpoint = class {
        // Owner
        _device = null;

        // EP type
        _type = 0;

        // EP address
        _epAddr = 0;

        // Maximum packet size for this endpoint
        // Should be one from {8, 16, 32, 64} set
        _maxPacketSize = 8;

        // Flag that EP was closed and should not used anymore.
        // Typically EP is closed when device is detached or configuration is changed
        _closed = false;

        // Callback to be called when transfer request is complete.
        // Since the class supports only single request per time,
        // this flags also indicates that EP is busy
        _transferCb = null;

        // Watchdog timer
        _timer = null;

        // Constructor
        // Parameters:
        //      device          - USB.Device instance, owner of this endpoint
        //      endpoint        - unique endpoint address
        //      epType          - endpoint type
        //      maxPacketSize   - maximum packet size for this endpoint
        constructor (device, endpoint, epType, maxPacketSize) {
            _device = device;
            _epAddr = endpoint;
            _maxPacketSize = maxPacketSize;
            _type = epType;
        }

        // Write data through this endpoint.
        // Throws if EP is closed, has incompatible type or already busy
        // Parameter:
        //  data        - data blob to be sent through this endpoint
        //  onComplete  - callback for transfer status notification
        //
        //  Returns nothing
        function write(data, onComplete) {
            if (_epAddr & USB_DIRECTION_MASK) {
                throw "Invalid endpoint direction: " + _epAddr;
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
            if (_epAddr & USB_DIRECTION_MASK) {
                _transfer(data, onComplete);
            } else {
                throw "Invalid endpoint direction: " + _epAddr;
            }
        }

        // Returns maximum packet size for this endpoint
        function getMaxPacketSize() {
            return _maxPacketSize;
        }

        // Returns this endpoint address
        // Typical use case for this function is to get endpoint ID for some of device control operation,
        // performed over Endpoint 0
        function getEndpointAddr() {
            return _epAddr;
        }

        // --------------------- Private functions -----------------

        // Mark this endpoint as closed. All further operation causes exception.
        function _close() {
            _closed = true;
            _transferCb = null;
        }


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
                _epAddr,
                _type,
                data
            );

            _transferCb = function (state, length) {
                onComplete && onComplete(this, state, data, length);
            };
        }

        // Notifies application about data transfer status
        // Parameters:
        //  state  - transfer status code
        //  length - the length of data was transmitted
        function _onTransferEvent(state, length) {
            // Cancel timer because callback happened
            if (_timer) {
                imp.cancelwakeup(_timer);
                _timer = null;
            }

            if (null == _transferCb) {
                USB.err("Unexpected transfer event: there is no listener for it");
                return;
            }

            local cb = _transferCb;
            // ready for next request
            _transferCb = null;

            cb(state, length);
        }

        // Metafunction to return class name when typeof <instance> is run
        function _typeof() {
            return "USB.FuncEndpoint";
        }
    } // FuncEndpoint

    // Represent control endpoints.
    // This class is required due to specific EI usb API
    // This class is managed by USB.Device and should be acquired through USB.Device instance
    ControlEndpoint = class {

        // to keep consistency with functional endpoint
        static _type = USB_ENDPOINT_CONTROL;

        // Owner
        _device = null;

        // EP address
        _epAddr = 0;

        // Maximum packet size for this endpoint
        // Should be one from {8, 16, 32, 64} set
        _maxPacketSize = 8;

        // Flag that EP was closed and should not used anymore.
        // Typically EP is closed when device is detached or configuration is changed
        _closed = false;

        // Constructor
        // Parameters:
        //      device          - USB.Device instance, owner of this endpoint
        //      endpoint        - unique endpoint address
        //      maxPacketSize   - maximum packet size for this endpoint
        constructor (device, endpoint, maxPacketSize) {
            _device = device;
            _epAddr = endpoint;
            _maxPacketSize = maxPacketSize;
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
        function transfer(reqType, req, value, index, data = blob()) {
            _transfer(
                reqType,
                req,
                value,
                index,
                data
            );
        }

        // Returns this endpoint address
        // Typical use case for this function is to get endpoint ID for some of device control operation,
        // performed over Endpoint 0
        function getEndpointAddr() {
            return _epAddr;
        }


        // --------------------- private API -------------------

        // Mark as closed. All further operation causes exception.
        function _close() {
            _closed = true;
        }

        // Generic function for transferring data over control endpoint.
        //
        // Parameters:
        //      reqType     - USB request type
        //      req         - The specific USB request
        //      value       - A value determined by the specific USB request
        //      index       - An index value determined by the specific USB request
        //      data        - [optional] Optional storage for incoming or outgoing data
        //
        function _transfer(reqType, req, value, index, data) {
            if (_closed) throw "Closed";

            _device._usb.controltransfer(
                _device._speed,
                _device._address,
                _epAddr,
                reqType,
                req,
                value,
                index,
                _maxPacketSize,
                data
            );
        }

        // Metafunction to return class name when typeof <instance> is run
        function _typeof() {
            return "USB.ControlEndpoint";
        }
    } // ControlEndpoint

    // Interface class for all drivers.
    // Driver developer is not required to subclass it though.
    // No class hierarchy is verified by any USB.* functions.
    Driver = class {

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
            USB.log("Driver is released");
        }

        // Metafunction to return class name when typeof <instance> is run
        function _typeof() {
            return "UsbDriver";
        }
    } // Driver
}
