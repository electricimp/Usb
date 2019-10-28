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
//  - Brother QL-720NW label printer


// Driver for QL720NW label printer use via USB
class QL720NWUsbToUartDriver extends USB.Driver {
    
    // Brother QL720
    static VID = 0x04f9;
    static PID = 0x2044;
    
    // Print actions queue
    _actions   = null; 
    // USB output stream
    _bulkOut   = null;
    // No more methods calls
    _released  = false;

    // =======================================
    // ======= USB Framework API =============
    // =======================================

    constructor(interface) {
        _bulkOut = interface.find(USB_ENDPOINT_BULK, USB_DIRECTION_OUT);
        if (null == _bulkOut) throw "Can't get required endpoints";
        _actions = [];
    }

    function match(device, interfaces) {
        if (device.getVendorId() != this.VID
            || device.getProductId() != this.PID)
            return null;
        return QL720NWUsbDriver(interfaces[0]);
    }

    function release() {
        // disable more actions handling
        _released = true;

        // Free usb framwork's resources
        _bulkOut = null;
    }
    
    // Update "uart" write to usb write
    function write(data) {
        _actions.push(data);
        _actionHandler(true);
    }

    //
    // Metafunction to return class name when typeof <instance> is run
    //
    function _typeof() {
        return "QL720NWUsbToUartDriver";
    }

    // ==================================================
    // ============== Private functions =================
    // ==================================================


    // Action queue processor: pops next command string and sends to printer.
    function _actionHandler(user = false) {
        // there is no actions to perform
        if (_actions.len() == 0) return;

        // Pop the next action
        local action = _actions.top();

        try {
            _sendToPrinter(action, _actionHandler.bindenv(this));

            _actions.pop();
        } catch (e) {
            if (null == e.find("Busy")) {
                _actions = [];

                if (user) throw e;
                else server.error(e);
            }
        }
    }

    //
    // Start bulk transfer to Usb Device
    //
    // Parameters:
    //      data        -   data to be sent via usb (string or blob)
    //      callback    -   a function to be notified about transfer status
    //
    //
    function _sendToPrinter(data, callback = null) {

        if (_released) throw "No printer is available";

        local _data = null;

        if (typeof data == "string") {
            _data = blob();
            _data.writestring(data);
        } else if (typeof data == "blob") {
            _data = data;
        } else {
            throw "Write data must of type string or blob";
            return;
        }

        local env = {"callback" : callback};
        _bulkOut.write(_data, _onComplete.bindenv(env));
    }

    // USB transfer complete callback
    function _onComplete(ep, error, data, len) {
        if (error == USB_TYPE_FREE || error == USB_TYPE_IDLE) error = null;
        if (callback) callback();

    }
}
