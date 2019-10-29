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

// This is an example of FT232RL driver usage with loopback connection

// This code also demonstrates how to make custom driver with small midification of basic one.
// Since CH340 differs from FT232RL  mostly by configuration protocol,
// it is possible to use FT232RL driver for CH340 by changing VID/PID and block configuration call.

// Hardware used in this example:
//  - imp005 breakout board
//  - CH340 USB to TTL Serial Adapter Module
//  - Jumper wire that connects adapter's TXD and RXD

#require "USB.device.lib.nut:1.1.0"

@include "github:electricimp/Usb/drivers/FT232RL_FTDI_USB_Driver/FT232RLFtdiUsbDriver.device.nut"

log <- server.log.bindenv(server);

const PING = "ping";
const PONG = "pong";

ch340 <- null;

class CH340 extends FT232RLFtdiUsbDriver {
    // CH340 vid and pid -
    static VID = 0x1A86;
    static PID = 0x7523;

    function configure(baud = 115200, databits = 8, parity = FTDI_PARITY_NONE, stopbits = FTDI_STOP_BIT_1) {
        // Do nothing
    }

    // Fill provided buffer with a data read from device
    function read(data, onComplete) {

        if (typeof data != "blob") {
            throw "Read data must of type blob";
        }

        // Write data via bulk transfer
        _bulkIn.read(data,  function(ep, error, data, length) {
            if (onComplete) {
                if (error == USB_TYPE_FREE || error == USB_TYPE_IDLE) error = null;
                onComplete(error, data, length);
            }
        }.bindenv(this));
    }

    // The function that help to create the driver extentions
    function _createInstance(p0, interface, deviceVersion = 0x0200) {
        return CH340(p0, interface, deviceVersion);
    }
}

function deviceReadCb(error, data, len) {
    if (error != null) {
        log("Read timeout! Check loopback connection.");
        return;
    }

    data.seek(0, 'b');
    local str = data.readstring(len);
    local txt = "Data received: " + str;
    log(txt);

    if (str == PING) {
        ch340.write(PONG, deviceWriteCb);
        local buffer = blob(10);
        ch340.read(buffer, deviceReadCb);
    }
}

function deviceWriteCb(error, data, len) {
    data.seek(0, 'b');
    local txt = "Data written: " + data.readstring(len);
    log(txt);
}

function usbEventListener(event, data) {
    log("USB event: " + event);

    if (event == USB_DRIVER_STATE_STARTED) {
        ch340 = data;

        log("Starting ping-pong");
        ch340.write(PING, deviceWriteCb);

        local buffer = blob(10);
        ch340.read(buffer, deviceReadCb);
    }
}

usbHost <- USB.Host(hardware.usb, [CH340], true);
log("USB.Host setup complete");

usbHost.setDriverListener(usbEventListener);
log("USB.Host setEventListener complete");

log("Waiting for a \"device connected\" event");
