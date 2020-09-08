// MIT License
//
// Copyright (c) 2019 Electric Imp, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THEs
// SOFTWARE.


/**
 * Enum for USB hub port commands, etc.
 * @enum {number}
 * @readonly
*/
enum USB_HUB_DRIVER {
    // Device data constants
    DEVICE_ADDRESS           = 0,
    ENDPOINT_ADDRESS         = 0,
    WAIT_DELAY_TIME          = 0.1,
    PWR_UP_DELAY_TIME        = 0.02,
    DEVICE_CLASS             = 9,
    DEVICE_SUB_CLASS         = 0,
    SPEED_LO                 = 1.5,
    SPEED_HI                 = 12.0,
    // Device communication constants
    BASE_PACKET_SIZE         = 8,
    DESCRIPTOR_REQUEST_VALUE = 0,
    DESCRIPTOR_REQUEST_INDEX = 0,
    PORTS_REQUEST_VALUE      = 256,
    PORTS_REQUEST_INDEX      = 0,
    CONFIGS_REQUEST_VALUE    = 512,
    PORT_RESET_REQUEST_VALUE = 4,
    PORT_POWER_REQUEST_VALUE = 8,
    STATUS_REQUEST_VALUE     = 0,
    SPEED_MASK               = 512,
    INTERFACES_DATA_OFFSET   = 9,
    ENDPOINTS_DATA_OFFSET    = 9
}

/**
 * Squirrel class providing hub support to the Electric Imp USB driver framework.
 *
 * Bus          USB
 * Availibility Device
 * Requires     USB.Driver
 * @author      Hugo Fienmes
 * @author      Tony Smith
 * @license     MIT
 *
 * @class
 * @extends USB.Driver
*/
class HubUsbDriver extends USB.Driver {

    /**
     * @property {string} VERSION - The library version.
     *
    */
    static VERSION = "1.0.1";

    // ********** Private instance properties **********
    _host         = null;
    _endPointZero = null;
    _numPorts     = 0;
    _debug        = null;

    /**
     * Instantiate the HubDriver class.
     *
     * @constructor
     *
     * @param {USB.Device} device - A USB.Driver instance as returned by USB.Host.
     * @param {boolean} debug - Whether to enable debug logging.
     *
     * @returns {instance} The instance.
     */
    constructor(device, debug = false) {
        // Configure debug logging
        _debug = debug;

        // Save endpoint 0 to talk to the hub
        _endPointZero = device.getEndpointZero();

        _host = device.getHost(); // Requires USB library 1.1.0

        // Get the hub descriptor to find the number of ports; these are 9 bytes long
        local data = blob(9);
        _endPointZero.transfer(USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_CLASS,
                               USB_REQUEST_GET_DESCRIPTOR,
                               USB_HUB_DRIVER.DESCRIPTOR_REQUEST_VALUE,
                               USB_HUB_DRIVER.DESCRIPTOR_REQUEST_INDEX,
                               data);
        _numPorts = data[2];
        _logDebug(format("%i ports found", _numPorts));

        // Get the hub status
        data = blob(4);
        _endPointZero.transfer(USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_CLASS,
                               USB_REQUEST_GET_STATUS,
                               0,
                               0,
                               data);

        // Check all ports and register devices found
        if (_numPorts > 0) {
            for (local i = 1 ; i <= _numPorts ; i++) _checkPort(i, true);
        }
    }

    /**
     * Get the current status of the hub's ports.
     *
     * @returns {table} An table whose keys are integer port numbers; values are "device connected" or "port empty"
     */
    function checkPorts() {
        local ports = {};

        if (_numPorts > 0) {
            for (local i = 1 ; i <= _numPorts ; i++) ports[i] <- (_checkPort(i) ? "connected" : "empty");
        }

        return ports;
    }

    /**
     * Standard framework method: is the inserted device one that uses this driver?
     *
     * Look for device's class: if it's 9, it's a hub.
     *
     * @required
     *
     * @param {USB.Device} device     - A USB.Device instance as returned by USB.Host.
     * @param {array}      interfaces - The USB interfaces detected by the host.
     *
     * @returns {instance} An instance of the hub driver class, or null.
     */
    function match(device, interfaces) {
        // Hubs are device class 9. They have no subclasses.
        foreach (interface in interfaces) {
            if (interface["class"] == USB_HUB_DRIVER.DEVICE_CLASS && interface["subclass"] == USB_HUB_DRIVER.DEVICE_SUB_CLASS) {
                return HubUsbDriver(device);
            }
        }

        // 'device' is not a hub
        return null;
    }

    /**
     * Standard framework method: release the device?
     *
     * @required
     */
    function release() {
        _host = null;
        _endPointZero = null;
        _numPorts = 0;
    }

    // ********** PRIVATE FUNCTIONS - DO NOT CALL **********

    /**
     * Check a specified hub port for the device connected to it, if any.
     *
     * @param {integer} port        - The port number.
     * @param {integer} initDevices - Should we register any connected devices at initialization?
     *
     * @returns {boolean} If the port is occupied (true) or empty (false).
     *
     * @private
     */
    function _checkPort(portNumber, initDevices = false) {
        _logDebug("Checking port " + portNumber + "... ");

        // Set USB actions
        local hostToDevice     = USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_CLASS    | USB_SETUP_RECIPIENT_OTHER;
        local deviceToHostStnd = USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_DEVICE;
        local deviceToHostClss = USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_CLASS    | USB_SETUP_RECIPIENT_OTHER;

        // Enable power on port
        _endPointZero.transfer(hostToDevice,
                               USB_REQUEST_SET_FEATURE,
                               USB_HUB_DRIVER.PORT_POWER_REQUEST_VALUE,
                               portNumber,
                               blob(0));

        // Power may be switched; need to leave time for the USB 5v on the 
        // hub port to rise before we check device presence in the hub
        imp.sleep(USB_HUB_DRIVER.PWR_UP_DELAY_TIME);

        // Read port status
        local data = blob(4);
        _endPointZero.transfer(deviceToHostClss,
                               USB_REQUEST_GET_STATUS,
                               USB_HUB_DRIVER.STATUS_REQUEST_VALUE,
                               portNumber,
                               data);
        local status = data.readn('w');

        // Is there a device?
        if ((status & 1) == 0) {
            // No device; turn power off
            _endPointZero.transfer(hostToDevice,
                                   USB_REQUEST_CLEAR_FEATURE,
                                   USB_HUB_DRIVER.PORT_POWER_REQUEST_VALUE,
                                   portNumber,
                                   blob(0));

            // Port is not occupied, so return 'false'
            return false;
        }

        // Reset the port
        _endPointZero.transfer(hostToDevice,
                               USB_REQUEST_SET_FEATURE,
                               USB_HUB_DRIVER.PORT_RESET_REQUEST_VALUE,
                               portNumber,
                               blob(0));

        if (initDevices) {
            // Allow time for hub to process previous requests
            imp.sleep(USB_HUB_DRIVER.WAIT_DELAY_TIME);

            // Re-read port status
            data = blob(4);
            _endPointZero.transfer(deviceToHostClss,
                                   USB_REQUEST_GET_STATUS,
                                   USB_HUB_DRIVER.STATUS_REQUEST_VALUE,
                                   portNumber,
                                   data);
            status = data.readn('w');
            _logDebug(format("Port %i status: %04x", portNumber, status));

            // Extract device speed from port status
            local speed = (status & USB_HUB_DRIVER.SPEED_MASK) ? USB_HUB_DRIVER.SPEED_LO : USB_HUB_DRIVER.SPEED_HI;

            // Get descriptor from new device; 8 bytes first and check the length
            data = blob(8);
            _host._usb.controltransfer(speed,
                                       USB_HUB_DRIVER.DEVICE_ADDRESS,
                                       USB_HUB_DRIVER.ENDPOINT_ADDRESS,
                                       deviceToHostStnd,
                                       USB_REQUEST_GET_DESCRIPTOR,
                                       USB_HUB_DRIVER.PORTS_REQUEST_VALUE,
                                       USB_HUB_DRIVER.PORTS_REQUEST_INDEX,
                                       USB_HUB_DRIVER.BASE_PACKET_SIZE,
                                       data);

            // We need this for the longer requests; fetch it now
            local maxPacketSize0 = data[7];

            if (data[0] > 8) {
                // We need to read the whole thing, so re-issue the read with the full length
                data = blob(data[0]);
                _host._usb.controltransfer(speed,
                                           USB_HUB_DRIVER.DEVICE_ADDRESS,
                                           USB_HUB_DRIVER.ENDPOINT_ADDRESS,
                                           deviceToHostStnd,
                                           USB_REQUEST_GET_DESCRIPTOR,
                                           USB_HUB_DRIVER.PORTS_REQUEST_VALUE,
                                           USB_HUB_DRIVER.PORTS_REQUEST_INDEX,
                                           maxPacketSize0,
                                           data);
            }

            // Parse the entire descriptor and build it in the form that impOS returns from a connect event
            local descriptor = { "usb":                 (data[3] << 8 ) | data[2],
                                 "class":               data[4],
                                 "subclass":            data[5],
                                 "protocol":            data[6],
                                 "maxpacketsize0":      maxPacketSize0,
                                 "vendorid":            (data[9] << 8) | data[8],
                                 "productid":           (data[11] << 8) | data[10],
                                 "device":              (data[13] << 8) | data[12],
                                 "manufacturer":        data[14],
                                 "product":             data[15],
                                 "serial":              data[16],
                                 "numofconfigurations": data[17],
                                 "configurations":      [] };

            // Fetch each configuration
            for (local i = 0 ; i < descriptor.numofconfigurations ; i++) {
                // Find length with short read first (9 is minimum length)
                data = blob(9);
                _host._usb.controltransfer(speed,
                                           USB_HUB_DRIVER.DEVICE_ADDRESS,
                                           USB_HUB_DRIVER.ENDPOINT_ADDRESS,
                                           deviceToHostStnd,
                                           USB_REQUEST_GET_DESCRIPTOR,
                                           USB_HUB_DRIVER.CONFIGS_REQUEST_VALUE,
                                           i,
                                           maxPacketSize0,
                                           data);
                local configLength = (data[3] << 8) | data[2];

                // Is the config more than 9 bytes in size? If so, read again with full length
                if (configLength > 9) {
                    data = blob(configLength);
                    _host._usb.controltransfer(speed,
                                               USB_HUB_DRIVER.DEVICE_ADDRESS,
                                               USB_HUB_DRIVER.ENDPOINT_ADDRESS,
                                               deviceToHostStnd,
                                               USB_REQUEST_GET_DESCRIPTOR,
                                               USB_HUB_DRIVER.CONFIGS_REQUEST_VALUE,
                                               i,
                                               maxPacketSize0,
                                               data);
                }

                local configuration = { "value":         data[5],
                                        "configuration": data[6],
                                        "attributes":    data[7],
                                        "maxpower":      data[8],
                                        "interfaces":    [] };

                // Iterate interfaces
                local numOfInterfaces = data[4];
                _logDebug(format("Config %04i has %04i interfaces", i, numOfInterfaces));
                local offset = USB_HUB_DRIVER.INTERFACES_DATA_OFFSET;
                for (local j = 0 ; j < numOfInterfaces ; j++) {
                    local interfaceLength = data[offset];
                    local interface = { "interfacenumber": data[offset + 2],
                                        "altsetting":      data[offset + 3],
                                        "class":           data[offset + 5],
                                        "subclass":        data[offset + 6],
                                        "protocol":        data[offset + 7],
                                        "interface":       data[offset + 8],
                                        "endpoints":       [] };

                    // Iterate endpoints
                    local numOfEndpoints = data[offset + 4];
                    _logDebug(format("Config %04i, interface %04i has %04i endpoints", i, j, numOfEndpoints));
                    offset += USB_HUB_DRIVER.ENDPOINTS_DATA_OFFSET;
                    for (local k = 0 ; k < numOfEndpoints ; k++) {
                        local endpointLen = data[offset];
                        local endpoint = { "address":       data[offset + 2],
                                           "attributes":    data[offset + 3],
                                           "maxpacketsize": (data[offset + 5] << 8) | data[offset + 4],
                                           "interval":      data[offset + 6] };

                        // Append to endpoint to list & bump
                        interface.endpoints.append(endpoint);
                        offset += endpointLen;
                    }

                    // Append interface to list
                    configuration.interfaces.append(interface);
                }

                // Append configuration to list
                descriptor.configurations.append(configuration);
            }

            // Pass to USB class to create the actual device
            _host._onDeviceConnected({"speed": speed, "descriptors": descriptor});
        }

        // Port is occupied, so return 'true'
        return true;
    }

    /**
     * Return a custom string for Squirrel's typeof operator.
     *
     * @returns {string} The name of the type: 'HubDriver'
     *
     * @private
     */
    function _typeof() {
        return "HubUsbDriver";
    }

    /**
     * Issue debug info to the log if debugging info is enabled.
     *
     * @private
     */
    function _logDebug(msg) {
        if (_debug) server.log("[USB.HUB.DRIVER]: " + msg);
    }
}
