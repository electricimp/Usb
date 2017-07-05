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

class FtdiUsbDriver extends USB.DriverBase {

    static VERSION = "0.1.0";

    // FTDI vid and pid
    static VID = 0x0403;
    static PID = 0x6001;

    // FTDI driver
    static FTDI_REQUEST_FTDI_OUT = 0x40;
    static FTDI_SIO_SET_BAUD_RATE = 3;
    static FTDI_SIO_SET_FLOW_CTRL = 2;
    static FTDI_SIO_DISABLE_FLOW_CTRL = 0;

    _deviceAddress = null;
    _bulkIn = null;
    _bulkOut = null;


    //
    // Metafunction to return class name when typeof <instance> is run
    //
    function _typeof() {
        return "FtdiUsbDriver";
    }


    //
    // Returns an array of VID PID combination tables.
    //
    // @return {Array of Tables} Array of VID PID Tables
    //
    function getIdentifiers() {
        local identifiers = {};
        identifiers[VID] <-[PID];
        return [identifiers];
    }


    //
    // Write string or blob to usb
    //
    // @param  {String/Blob} data data to be sent via usb
    //
    function write(data) {
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
        _bulkOut.write(_data);
    }


    //
    // Handle a transfer complete event
    //
    // @param  {Table} eventdetails Table with the transfer event details
    //
    function _transferComplete(eventdetails) {
        local direction = (eventdetails["endpoint"] & 0x80) >> 7;
        if (direction == USB_DIRECTION_IN) {
            local readData = _bulkIn.done(eventdetails);
            if (readData.len() >= 3) {
                readData.seek(2);
                _onEvent("data", readData.readblob(readData.len()));
            }
            // Blank the buffer
            _bulkIn.read(blob(64 + 2));
        } else if (direction == USB_DIRECTION_OUT) {
            _bulkOut.done(eventdetails);
        }
    }


    //
    // Initialize the buffer.
    //
    function _start() {
        _bulkIn.read(blob(64 + 2));
    }
};
