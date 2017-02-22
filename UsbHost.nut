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


class ControlEndpoint {
    _usb = null;
    _deviceAddress = null;
    _speed = null;
    _maxPacketSize = null;

    constructor(usb, deviceAddress, speed, maxPacketSize) {
        _usb = usb;
        _deviceAddress = deviceAddress;
        _speed = speed;
        _maxPacketSize = maxPacketSize;
    }

    function setConfiguration(value) {
        _usb.setConfiguration(_deviceAddress, _speed, _maxPacketSize, value);
    }

    function getStringDescriptor(index) {
        return _usb._getStringDescriptor(_deviceAddress, _speed, _maxPacketSize, index);
    }

    function send(requestType, request, value, index) {
        return _usb.controlTransfer(_speed, _deviceAddress, requestType, request, value, index, _maxPacketSize)
    }
}

class BulkEndpoint {

    static VERSION = "1.0.0";

    _usb = null;
    _deviceAddress = null;
    _endpointAddress = null;

    constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize) {
        server.log(format("Opening bulk endpoint 0x%02x", endpointAddress));
        _usb = usb;
        _deviceAddress = deviceAddress;
        _endpointAddress = endpointAddress;
        _usb.openEndpoint(speed, _deviceAddress, interfaceNumber, USB_ENDPOINT_BULK, maxPacketSize, _endpointAddress);
    }
}

class BulkInEndpoint extends BulkEndpoint {

    static VERSION = "1.0.0";

    _data = null;

    constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize) {
        assert((endpointAddress & 0x80) >> 7 == USB_DIRECTION_IN);
        base.constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize);
    }

    function read(data) {
        _data = data;
        _usb.bulkTransfer(_deviceAddress, _endpointAddress, USB_ENDPOINT_BULK, data);
    }

    function done(details) {
        assert(details["endpoint"] == _endpointAddress);
        _data.resize(details["length"]);
        local data = _data;
        _data = null;
        return data;
    }
}

class BulkOutEndpoint extends BulkEndpoint {

    static VERSION = "1.0.0";

    _data = null;

    constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize) {
        assert((endpointAddress & 0x80) >> 7 == USB_DIRECTION_OUT);
        base.constructor(usb, speed, deviceAddress, interfaceNumber, endpointAddress, maxPacketSize);
    }

    function write(data) {
        _data = data;
        _usb.bulkTransfer(_deviceAddress, _endpointAddress, USB_ENDPOINT_BULK, data);
    }

    function done(details) {
        assert(details["endpoint"] == _endpointAddress);
        _data = null;

    }
}

class DriverBase {

    static VERSION = "1.0.0";

    static isUSBDriver = true;

    _usb = null;
    _controlEndpoint = null;
    _eventHandlers = {};

    constructor(usb) {
        _usb = usb;
    }

    function connect(deviceAddress, speed, descriptors) {
        _setupEndpoints(deviceAddress, speed, descriptors);
        _configure(descriptors["device"]);
        _start();
    }

    function getIdentifiers() {
        throw "Method not implemented";
    }

    function transferComplete(eventdetails) {
        throw "Method not implemented";
    }

    function on(eventType, cb) {
        _eventHandlers[eventType] <- cb;
    }

    function off(eventName) {
        if (eventName in _eventHandlers) {
            delete _eventHandlers[eventName];
        }
    }

    function onEvent(eventType, eventdetails) {
        if (eventType in _eventHandlers) {
            _eventHandlers[eventType](eventdetails);
        }
    }

    function _configure(device) {
        server.log(format("Configuring for device version 0x%04x", device));

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
                baudValue = 0; /* special case for maximum baud rate */
            }

        } else {
            local divfrac = [0, 3, 2, 0, 1, 1, 2, 3];
            local divindex = [0, 0, 0, 1, 0, 1, 1, 1];

            baudValue = divisor3 >> 3;
            baudValue = baudValue | (divfrac[divisor3 & 0x7] << 14);

            baudIndex = divindex[divisor3 & 0x7];

            /* Deal with special cases for highest baud rates. */
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

    // Initialize and set up all required endpoints
    function _setupEndpoints(deviceAddress, speed, descriptors) {
        server.log(format("Driver connecting at address 0x%02x", deviceAddress));
        _deviceAddress = deviceAddress;
        _controlEndpoint = ControlEndpoint(_usb, deviceAddress, speed, descriptors["maxpacketsize0"]);

        // Select configuration
        local configuration = descriptors["configurations"][0];
        server.log(format("Setting configuration 0x%02x (%s)", configuration["value"], _controlEndpoint.getStringDescriptor(configuration["configuration"])));
        _controlEndpoint.setConfiguration(configuration["value"]);

        // Select interface
        local interface = configuration["interfaces"][0];
        local interfacenumber = interface["interfacenumber"];

        foreach (endpoint in interface["endpoints"]) {
            local address = endpoint["address"];
            local maxPacketSize = endpoint["maxpacketsize"];
            if ((endpoint["attributes"] & 0x3) == 2) {
                if ((address & 0x80) >> 7 == USB_DIRECTION_OUT) {
                    _bulkOut = BulkOutEndpoint(_usb, speed, _deviceAddress, interfacenumber, address, maxPacketSize);
                } else {
                    _bulkIn = BulkInEndpoint(_usb, speed, _deviceAddress, interfacenumber, address, maxPacketSize);
                }
            }
        }
    }

};

class UsbHost {

    static VERSION = "1.0.0";

    _eventHandlers = {};
    _customEventHandlers = {};
    _driver = null;
    _bulkTransferQueue = null;
    _address = 1;
    _registeredDrivers = null;
    _usb = null
    _driverCallback = null;
    _DEBUG = false;
    _busy = false;

    constructor(usb) {
        _usb = usb;
        _bulkTransferQueue = [];
        _registeredDrivers = {};
        _eventHandlers[USB_DEVICE_CONNECTED] <- _onDeviceConnected.bindenv(this);
        _eventHandlers[USB_DEVICE_DISCONNECTED] <- _onDeviceDisconnected.bindenv(this);
        _eventHandlers[USB_TRANSFER_COMPLETED] <- _onTransferCompleted.bindenv(this);
        _eventHandlers[USB_UNRECOVERABLE_ERROR] <- _onHardwareError.bindenv(this);
        _usb.configure(_onEvent.bindenv(this));
        server.log("UsbHost instantiated")
    }

    function _typeof() {
        return "UsbHost";
    }

    // Registers a driver with usb host
    function registerDriver(driverClass, identifiers) {

        if (!(driverClass.isUSBDriver == true)) {
            server.error("This driver is not a valid usb driver.");
            return;
        }

        if (typeof identifiers != "array") {
            server.error("Identifiers for driver must be of type array.")
            return;
        }

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

    function getDriver() {
        return _driver;
    }

    // Subscribe callback to call on "eventName" event
    function on(eventName, cb) {
        _customEventHandlers[eventName] <- cb;
    }

    // Clear callback from "eventName" event
    function off(eventName) {
        if (eventName in _customEventHandlers) {
            delete _customEventHandlers[eventName];
        }
    }

    function openEndpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress) {
        _usb.openendpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress);
    }


    // Bulk transfer data blob
    function bulkTransfer(address, endpoint, type, data) {
        // Push to the end of the queue
        _pushBulkTransferQueue([_usb, address, endpoint, type, data]);

        // Process request at the front of the queue
        _popBulkTransferQueue();
    }

    // Control transfer wrapper method
    function controlTransfer(speed, deviceAddress, requestType, request, value, index, maxPacketSize) {
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

    // Set control transfer USB_REQUEST_SET_ADDRESS device address
    function setAddress(address, speed, maxPacketSize) {
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

    // Set control transfer USB_REQUEST_SET_CONFIGURATION value
    function setConfiguration(deviceAddress, speed, maxPacketSize, value) {
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

    // Creates a USB driver instance if vid/pid combo matches registered devices
    function _create(identifiers) {
        local vid = identifiers["vendorid"];
        local pid = identifiers["productid"];
        local vpid = format("%04x%04x", vid, pid);

        if ((vpid in _registeredDrivers) && _registeredDrivers[vpid] != null) {
            return _registeredDrivers[vpid](this);
        }
        return null;
    }

    // Usb connected callback
    function _onDeviceConnected(eventdetails) {
        if (_driver != null) {
            server.log("Device already connected");
            return;
        }

        local speed = eventdetails["speed"];
        local descriptors = eventdetails["descriptors"];
        local maxPacketSize = descriptors["maxpacketsize0"];
        if (_DEBUG) {
            logDescriptors(speed, descriptors);
        }
        // Try to create the driver for connected device
        _driver = _create(descriptors);

        if (_driver == null) {
            server.log("No driver found for device");
            return;
        }

        server.log("Found driver for " + typeof _driver);
        setAddress(_address, speed, maxPacketSize);
        _driver.connect(_address, speed, descriptors);
        // Emit connected event that user can subscribe to
        _onEvent("connected", _driver);

    }

    // Device disconnected callback
    function _onDeviceDisconnected(eventdetails) {
        if (_driver != null) {
            server.log("Device:" + typeof _driver + " disconnected");
            // Emit disconnected event
            _onEvent("disconnected", typeof _driver);
            _driver = null;
        }
    }

    // Callback when a Usb transfer successfully completed
    function _onTransferCompleted(eventdetails) {
        _busy = false;
        if (_driver) {
            // Pass complete event to driver
            _driver.transferComplete(eventdetails);
        }
        // Process any queued requests
        _popBulkTransferQueue();
    }

    // Callback on hardware error
    function _onHardwareError(eventdetails) {
        server.error("Internal unrecoverable usb error. Resetting the bus.");
        usb.disable();
        _usb.configure(_onEvent.bindenv(this));
    }

    // Push bulk transfer request to back of queue
    function _pushBulkTransferQueue(request) {
        _bulkTransferQueue.push(request);
    }

    // Pop bulk transfer request to front of queue
    function _popBulkTransferQueue() {
        if (!_busy && _bulkTransferQueue.len() > 0) {
            _usb.generaltransfer.acall(_bulkTransferQueue.remove(0));
            _busy = true;
        }
    }

    // Emit event "eventtype" with eventdetails
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

    // Extract the direction from and endpoint address
    function _directionString(direction) {
        if (direction == USB_DIRECTION_IN) {
            return "IN";
        } else if (direction == USB_DIRECTION_OUT) {
            return "OUT";
        } else {
            return "UNKNOWN";
        }
    }


    // Extract the endpoint type from attributes byte
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
