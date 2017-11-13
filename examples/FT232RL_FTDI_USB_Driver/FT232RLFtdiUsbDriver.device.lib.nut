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
class FT232RLFtdiUsbDriver extends USB.Driver {
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
    static FTDI_SIO_SET_DATA_REQUEST = 4;

    // FTDI UART configuration types
    static FTDI_PARITY_NONE = 0;
    static FTDI_PARITY_ODD = 1;
    static FTDI_PARITY_EVEN = 2;
    static FTDI_PARITY_MARK = 3;
    static FTDI_PARITY_SPACE = 4;
    static FTDI_STOP_BIT_1 = 0;
    static FTDI_STOP_BIT_15 = 1;
    static FTDI_STOP_BIT_2 = 2;

    _bulkIn = null;
    _bulkOut = null;
    _ep0 = null;
    _devType = null;

    constructor(ep0, interface, deviceVersion = 0x0200) {

        _bulkIn  = interface.find(USB_ENDPOINT_BULK, USB_DIRECTION_IN);
        _bulkOut = interface.find(USB_ENDPOINT_BULK, USB_DIRECTION_OUT);
        _ep0 = ep0;
        _devType = deviceVersion;

        if (null == _bulkIn || null == _bulkOut) throw "Can't get required endpoints";

        configure();
    }

    // Driver probe function
    // Return Class instance if the driver can handle given device/interfaces
    function match(device, interfaces) {
        if (device.getVendorId()  == VID &&
            device.getProductId() == PID) {
                local devType = device.getDescriptor()[device];
                return FT232RLFtdiUsbDriver(device.getEndpointZero(), interfaces[0], devType);
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
            if (onComplete) {
                if (error == USB_ERROR_FREE || error == USB_ERROR_IDLE) error = null;
                onComplete(error, data, length);
            }
        }.bindenv(this));
    }

    // Fill provided buffer with a data read from device
    function read(data, onComplete) {

        if (typeof data != "blob") {
            throw "Read data must of type blob";
        }

        // Write data via bulk transfer
        _bulkIn.read(data,  function(ep, error, data, length) {
            if (onComplete) {
                if (error == USB_ERROR_FREE || error == USB_ERROR_IDLE) error = null;
                onComplete(error, data, length);
            }
        }.bindenv(this));
    }

    // Device UART configuration
    function configure(baud = 115200, databits = 8, parity = FTDI_PARITY_NONE, stopbits = FTDI_STOP_BIT_1) {

            // Set Baud Rate
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

           _ep0.transfer(FTDI_REQUEST_FTDI_OUT, FTDI_SIO_SET_BAUD_RATE, baudValue, baudIndex);

           local value = databits;
           switch (parity)
           {
               case FTDI_PARITY_NONE:
                   value |= (0x00 << 8);
                   break;
               case FTDI_PARITY_ODD:
                   value |= (0x01 << 8);
                   break;
               case FTDI_PARITY_EVEN:
                   value |= (0x02 << 8);
                   break;
               case FTDI_PARITY_MARK:
                   value |= (0x03 << 8);
                   break;
               case FTDI_PARITY_SPACE:
                   value |= (0x04 << 8);
                   break;
           }

           switch (stopbits)
           {
               case FTDI_STOP_BIT_1:
                   value |= (0x00 << 11);
                   break;
               case FTDI_STOP_BIT_15:
                   value |= (0x01 << 11);
                   break;
               case FTDI_STOP_BIT_2:
                   value |= (0x02 << 11);
                   break;
           }

           _ep0.transfer(FTDI_REQUEST_FTDI_OUT, FTDI_SIO_SET_DATA_REQUEST, value, 0);


           // disable flow control
           _ep0.transfer(FTDI_REQUEST_FTDI_OUT, FTDI_SIO_SET_FLOW_CTRL, 0, FTDI_SIO_DISABLE_FLOW_CTRL << 8);
        }
}
