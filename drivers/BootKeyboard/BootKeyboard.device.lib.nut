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

const KBD_NUM_LOCK      = 1;
const KBD_CAPS_LOCK     = 2;
const KBD_SCROLL_LOCK   = 4;
const KBD_COMPOSE       = 8;
const KBD_KANA          = 16;

// This is an example of Keyboard driver.
// This driver matches only keyboards that support Boot Report Descriptor
// (see http://www.usb.org/developers/hidpage/HID1_11.pdf for more details)
class BootKeyboardDriver extends USB.Driver {

    // the driver version
    static VERSION = "0.1.0";

    // ---------------- private variables ---------------------------
    // Interrupt In endpoint
    _inEp = null;
    // Control Endpoint 0
    _ep0  = null;
    // Interface number this driver is bound with
    _ifs  = null;
    // Callback for async uperations
    _asyncCb = null;

    // ----------------  USB framework related functions  -------------

    // Constructor accepts single Interrupt In for endpoint for receiving Input Report asynchronously,
    // Ep0 for sending Output Report (change LED state) and synchronous Input Report,
    // and change protocol
    constructor(inEp, ep0, ifs) {
        // USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_CLASS | USB_SETUP_RECIPIENT_INTERFACE;
        const HID_DEVICE_TO_HOST    = 161;
        // USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_CLASS | USB_SETUP_RECIPIENT_INTERFACE;
        const HID_HOST_TO_DEVICE    = 33;
        const HID_GET_REPORT_CMD    = 0x01;
        const HID_SET_PROTOCOL_CMD  = 0x0B;
        const HID_SET_REPORT_CMD    = 0x09;
        const HID_SET_IDLE_CMD      = 0x0A;

        // 2 << 8
        const HID_REPORT_OUT        = 512;
        // 1 << 8
        const HID_REPORT_IN         = 256;

        _inEp = inEp;
        _ep0  = ep0;
        _ifs  = ifs;

        // force boot protocol
        _ep0.transfer(HID_HOST_TO_DEVICE, HID_SET_PROTOCOL_CMD, 0, ifs);
    }

    // The function searches for HID class interfaces with Boot Interface Subclass
    // and Keyboard protocol. We intentionally ignores Device class (that should be 0 by spec)
    // to be more flexible in support of custom devices.
    // For parameters specification see USB.Driver description.
    function match(device, interfaces) {
        foreach (interface in interfaces) {
            local iClass    = interface["class"];
            local iSubClass = interface.subclass;
            local iProtocol = interface.protocol;
            local number    = interface.interfacenumber;

            if (   iClass     == 3 // HID
                && iSubClass  == 1 // BOOT
                && iProtocol  == 1 // Keyboard
            ) {
                 local inEp = interface.find(USB_ENDPOINT_INTERRUPT, USB_DIRECTION_IN);
                 if (null != inEp) {
                    return BootKeyboardDriver(inEp, device.getEndpointZero(), number);
                }
            }
        }

        // nothing found
        return null;
    }

    // Releases all allocated resources
    function release() {
        _ep0  = null;
        _inEp = null;
    }

    // -------------  public functions ------------------

    // Function sends read request through Interrupt In endpoint,
    // that gets data and notifies the caller asynchronously.
    // Parameters:
    //      callback - a function to receive the keyboard status
    //                 Its signature is following:
    //                  callback(status), where
    //                    status - a table with a fields named after modifiers keys and
    //                             set of Key0...Key5 fields with pressed key scancodes
    //                             Example: status = {
    //                                          error : null,
    //                                          LEFT_CTRL  : 1,
    //                                          LEFT_SHIFT : 0,
    //                                          Key0       : 32
    //                                          Key1       : 55
    //                                       }
    function getKeyStatusAsync(callback) {
        try {
            _asyncCb = callback;
            _inEp.read(blob(8), _receiveCallback.bindenv(this));
        } catch (e) {
            local st = {"error" : e};
            callback(st);
        }
    }

    // Function read keyboard report  through control endpoint 0 and thus synchronously
    //
    // Returns:
    //     a table with following fields:
    //           error       - if any error happens
    //           LEFT_CTRL   - 1 or 0
    //           LEFT_SHIFT  - 1 or 0
    //           LEFT_ALT    - 1 or 0
    //           LEFT_GUI    - 1 or 0
    //           RIGHT_CTRL  - 1 or 0
    //           RIGHT_SHIFT - 1 or 0
    //           RIGHT_ALT   - 1 or 0
    //           RIGHT_GUI   - 1 or 0
    //           Key0        - scan code or 0
    //           Key1        - scan code or 0
    //           Key2        - scan code or 0
    //           Key3        - scan code or 0
    //           Key4        - scan code or 0
    //           Key5        - scan code or 0
    //
    //  Note: in case of error no other fields are present
    function getKeyStatus() {
        local data = blob(8);

        try {
            _ep0.transfer(HID_DEVICE_TO_HOST, HID_GET_REPORT_CMD, HID_REPORT_IN, _ifs, data);
            return _generateReport(data, 8);
        } catch (e) {
            return {"error": "USB error: " + e};
        }
    }

    // Changes Keyboard LED status.
    // Parameters:
    //      leds   - 8-bit field:
    //                   bit 0 - NUM LOCK
    //                   bit 1 - CAPS LOCK
    //                   bit 2 - SCROLL LOCK
    //                   bit 3 - COMPOSE
    //                   bit 4 - KANA
    // Returns: error description or NULL
    function setLeds(leds) {
        local data = blob(1);
        data.writen(leds, 'b');
        try {
            _ep0.transfer(HID_HOST_TO_DEVICE, HID_SET_REPORT_CMD, HID_REPORT_OUT, _ifs, data);
        } catch (e) {
            return "USB error: " + e;
        }
    }


    // This request is used to limit the reporting frequency.
    // Parameters:
    //  timeout - poll duration in milliseconds [0...1020]. Zero means the duration is indefinite.
    //
    // Returns: error description or null
    function setIdleTime(timeout) {
        local ticks = (timeout / 4) & 0xFF;
        try {
            _ep0.transfer(HID_HOST_TO_DEVICE, HID_SET_IDLE_CMD, ticks << 8, _ifs);
        } catch (e) {
            return "USB error: " + e;
        }
    }


    // ------------- private functions ------------------

    // Callback function to receive data from Interrupt In endpoint
    // Parameters:
    //      ep      - source endpoint
    //      error   - error code
    //      data    - data blob
    //      len     - a nu,ber of read bytes
    function _receiveCallback(ep, error, data, len) {
        if (error !=  USB_TYPE_FREE && error != USB_TYPE_IDLE) {
            if (null != _asyncCb) {
                local result = {"error" : "USB error " + error};
                _asyncCb(error);
            }
        } else {
            _asyncCb(_generateReport(data, len));
        }
    }

    // Parses received data and generates report table
    function _generateReport(data, len) {

        // TODO: update the constants
        const LEFT_CTRL     = 1;
        const LEFT_SHIFT    = 2;
        const LEFT_ALT      = 4;
        const LEFT_GUI      = 8;
        const RIGHT_CTRL    = 16;
        const RIGHT_SHIFT   = 32;
        const RIGHT_ALT     = 64;
        const RIGHT_GUI     = 128;

        local report = {};

        if (data[2] == 1) {
            // special code ErrorRollOver
            report["error"] <- "Keyboard reported error: ErrorRollOver";
            return report;
        }

        local modifiers = data[0];
        if (modifiers & LEFT_CTRL)      report["LEFT_CTRL"]   <- 1;
        if (modifiers & LEFT_SHIFT)     report["LEFT_SHIFT"]  <- 1;
        if (modifiers & LEFT_ALT)       report["LEFT_ALT"]    <- 1;
        if (modifiers & LEFT_GUI)       report["LEFT_GUI"]    <- 1;
        if (modifiers & RIGHT_CTRL)     report["RIGHT_CTRL"]  <- 1;
        if (modifiers & RIGHT_SHIFT)    report["RIGHT_SHIFT"] <- 1;
        if (modifiers & RIGHT_ALT)      report["RIGHT_ALT"]   <- 1;
        if (modifiers & RIGHT_GUI)      report["RIGHT_GUI"]   <- 1;

        local i = 2;
        for (; i < len; i++) {
            local key = data[i];

            if (0 != key) report["Key" + (i - 2)] <- key;
        }
        return report;
    }

    // Metafunction to return class name when typeof <instance> is run
    function _typeof() {
        return "BootKeyboardDriver";
    }
}
