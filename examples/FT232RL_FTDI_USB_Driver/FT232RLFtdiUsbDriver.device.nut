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

// ----------------------------------------------------------------------

// Hardware used in this example
//  - Imp005
//  - FT232RL FTDI USB to TTL Serial Adapter Module

// Driver for FT232RL FTDI USB to TTL Serial Adapter Module
class FT232RLFtdiUsbDriver extends USB.DriverBase {
    // the driver version
    static VERSION = "1.0.0";

    // FTDI vid and pid
    static VID = 0x0403;
    static PID = 0x6001;

    // FTDI driver
    static FTDI_REQUEST_FTDI_OUT = 0x40;
    static FTDI_SIO_SET_BAUD_RATE = 3;
    static FTDI_SIO_SET_FLOW_CTRL = 2;
    static FTDI_SIO_DISABLE_FLOW_CTRL = 0;

    _bulkIn = null;
    _bulkOut = null;

    constructor(interface) {

        _bulkIn  = USB.Device.getEndpoint(interface, USB_ENDPOINT_BULK, USB_DIRECTION_IN);
        _bulkOut = USB.Device.getEndpoint(interface, USB_ENDPOINT_BULK, USB_DIRECTION_OUT);

        if (null == _bulkIn || null == _bulkOut) throw "Can't get required endpoints";
    }

    function match(device, interfaces) {
        if (device.getVendorId()  == VID &&
            device.getProductId() == PID) {
                return FT232RLFtdiUsbDriver(interfaces[0]);
        }
        return null;
    }

    // Notify that driver is going to be released
    // No endpoint operation should be performed at this function.
    function release() {
        _bulkIn = null;
        _bulkOut = null;
    }

    //
    // Metafunction to return class name when typeof <instance> is run
    //
    function _typeof() {
        return "FT232RLFtdiUsbDriver";
    }

    //
    // Write string or blob to usb
    //
    // @param  {String/Blob} data data to be sent via usb
    //
    function write(data, onComplete) {
        local _data = null;

        // Convert strings to blobs
        if (typeof data == "string") {
            _data = blob();
            _data.writestring(data);
        } else if (typeof data == "blob") {
            _data = data;
        } else {
            throw "Write data must of type string or blob";
            return;
        }

        // Write data via bulk transfer
        _bulkOut.write(_data, function(ep, error, data, length) {
            if (onComplete)
              onComplete(error, data, lenght);
        }.bindenv(this));
    }

    function read(data, onComplete) {

        if (typeof data != "blob") {
            throw "Read data must of type blob";
        }

        // Write data via bulk transfer
        _bulkIn.read(data,  function(ep, error, data, length) {
            if (onComplete)
              onComplete(error, data, lenght);
        }.bindenv(this));
    }
}
