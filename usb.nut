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

// FTDI driver 
const FTDI_REQUEST_FTDI_OUT = 0x40;
const FTDI_SIO_SET_BAUD_RATE = 3;
const FTDI_SIO_SET_FLOW_CTRL = 2;
const FTDI_SIO_DISABLE_FLOW_CTRL = 0;


// Extract the direction from and endpoint address
function directionString(direction) {
    if (direction == USB_DIRECTION_IN) {
        return "IN";
    } else if (direction == USB_DIRECTION_OUT) {
        return "OUT";
    } else {
        return "UNKNOWN";
    }
}

// Extract the endpoint type from attributes byte
function endpointTypeString(attributes) {
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
        return _usb.getStringDescriptor(_deviceAddress, _speed, _maxPacketSize, index);
    }

    function send(requestType, request, value, index) {
        return _usb.controlTransfer(_speed, _deviceAddress, requestType, request, value, index, _maxPacketSize)
    }
}

class BulkEndpoint {
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
    function connect(address, speed, descriptors) {}

    function transferComplete(eventdetails) {}

    function getDeviceType() {}
};

class FtdiDriver extends DriverBase {
    _usb = null;
    _deviceAddress = null;
    _controlEndpoint = null;
    _bulkIn = null;
    _bulkOut = null;

    constructor(usb) {
        _usb = usb;
    }

    function getDeviceType() {
        return "Ftdi";
    }

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

        local xon = 0x11;
        local xoff = 0x13;

        _controlEndpoint.send(FTDI_REQUEST_FTDI_OUT, FTDI_SIO_SET_FLOW_CTRL, xon | (xoff << 8), FTDI_SIO_DISABLE_FLOW_CTRL << 8);
    }

    function _start() {
        _bulkIn.read(blob(64 + 2));
    }

    function write(data) {
        _bulkOut.write(data);
    }

    function connect(deviceAddress, speed, descriptors) {
        _setupEndpoints(deviceAddress, speed, descriptors);
        _configure(descriptors["device"]);
        _start();
    }

    function transferComplete(eventdetails) {
        local direction = (eventdetails["endpoint"] & 0x80) >> 7;
        if (direction == USB_DIRECTION_IN) {
            local readData = _bulkIn.done(eventdetails);
            if (readData.len() < 3) {
                _bulkIn.read(blob(64 + 2));
            } else {
                readData.seek(2);
                local writeData = blob(readData.len() + 3);
                writeData.writestring("ACK: ");
                writeData.writeblob(readData);
                // local writeData = readData.readblob(readData.len()-2);
                _bulkOut.write(writeData);
                readData.seek(0);
                _bulkIn.read(blob(64 + 2));
            }
        } else if (direction == USB_DIRECTION_OUT) {
            _bulkOut.done(eventdetails);
        }
    }
};

class DriverFactory {
    _usb = null;

    constructor(usb) {
        _usb = usb;
    }

    function create(descriptors) {
        // FTDI vid and pid
        local vid = 0x0403;
        local pid = 0x6001;
        if ((descriptors["vendorid"] == vid) && (descriptors["productid"] == pid)) {
            return FtdiDriver(_usb);
        }
        return null;
    }
}

// Supports only one device at the moment.
class UsbHost {
    _eventHandlers = {};
    _driver = null;
    _address = 1;
    _factory = null;
    _usb = null
    _driverCallback = null;
    _onConnectedCb = null;
    _onDisconnectedCb = null;
    _DEBUG = false;


    constructor(usb, onConnected = null, onDisconnected = null) {
        _usb = usb;
        _onConnectedCb = onConnected;
        _onDisconnectedCb = onDisconnected;
        _factory = DriverFactory(this);
        _eventHandlers[USB_DEVICE_CONNECTED] <- UsbHost.onDeviceConnected.bindenv(this);
        _eventHandlers[USB_DEVICE_DISCONNECTED] <- UsbHost.onDeviceDisconnected.bindenv(this);
        _eventHandlers[USB_TRANSFER_COMPLETED] <- UsbHost.onTransferCompleted.bindenv(this);
        _usb.configure(UsbHost.onEvent.bindenv(this));
    }

    function logDescriptors(speed, descriptor) {
        local maxPacketSize = descriptor["maxpacketsize0"];
        server.log("USB Device Connected, speed=" + speed + " Mbit/s");
        server.log(format("usb = 0x%04x", descriptor["usb"]));
        server.log(format("class = 0x%02x", descriptor["class"]));
        server.log(format("subclass = 0x%02x", descriptor["subclass"]));
        server.log(format("protocol = 0x%02x", descriptor["protocol"]));
        server.log(format("maxpacketsize0 = 0x%02x", maxPacketSize));
        local manufacturer = getStringDescriptor(0, speed, maxPacketSize, descriptor["manufacturer"]);
        server.log(format("VID = 0x%04x (%s)", descriptor["vendorid"], manufacturer));
        local product = getStringDescriptor(0, speed, maxPacketSize, descriptor["product"]);
        server.log(format("PID = 0x%04x (%s)", descriptor["productid"], product));
        local serial = getStringDescriptor(0, speed, maxPacketSize, descriptor["serial"]);
        server.log(format("device = 0x%04x (%s)", descriptor["device"], serial));

        local configuration = descriptor["configurations"][0];
        local configurationString = getStringDescriptor(0, speed, maxPacketSize, configuration["configuration"]);
        server.log(format("Configuration: 0x%02x (%s)", configuration["value"], configurationString));
        server.log(format("  attributes = 0x%02x", configuration["attributes"]));
        server.log(format("  maxpower = 0x%02x", configuration["maxpower"]));

        foreach (interface in configuration["interfaces"]) {
            local interfaceDescription = getStringDescriptor(0, speed, maxPacketSize, interface["interface"]);
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
                local type = endpointTypeString(attributes);
                server.log(format("    Endpoint: 0x%02x (ENDPOINT %d %s %s)", address, endpointNumber, type, directionString(direction)));
                server.log(format("      attributes = 0x%02x", attributes));
                server.log(format("      maxpacketsize = 0x%02x", endpoint["maxpacketsize"]));
                server.log(format("      interval = 0x%02x", endpoint["interval"]));
            }
        }
    }

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

    function getStringDescriptor(deviceAddress, speed, maxPacketSize, index) {
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

    function bulkTransfer(address, endpoint, type, data) {
        _usb.generaltransfer(address, endpoint, type, data);
    }

    function openEndpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress) {
        _usb.openendpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress);
    }

    function onDeviceConnected(eventdetails) {
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

        _driver = _factory.create(descriptors);
        if (_driver == null) {
            server.log("No driver found for device");
            return;
        }

        server.log("Found driver");
        setAddress(_address, speed, maxPacketSize);
        _driver.connect(_address, speed, descriptors);

        if (_onConnectedCb != null) {
            _onConnectedCb(_driver);
        }
    }

    function onDeviceDisconnected(eventdetails) {
        server.log("Device:" + _driver.getDeviceType + " gone");
        if (_onDisconnectedCb != null) {
            _onDisconnectedCb(_driver.getDriverType);
        }
        _driver = null;
    }

    function onTransferCompleted(eventdetails) {
        _driver.transferComplete(eventdetails);
    }

    function onEvent(eventtype, eventdetails) {
        _eventHandlers[eventtype](eventdetails);
    }
};
