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

// This is an example of FT232RL driver usage. The application echoes all read data back to sender.

@include __PATH__ + "/../../../USB.device.lib.nut"
@include __PATH__ + "/../FT232RLFtdiUsbDriver.device.lib.nut"

log  <- server.log.bindenv(server);
ftdi <- null;

const PING = "ping";
const PONG = "pong";

function deviceReadCb(error, data, len) {
    if (error != null) {
        log("Read timeout! Check loopback connection.");
        return;
    }

    local str = data.readstring(len);
    local txt = "Data received: " + str;
    log(txt);

    if (str == PING) {
        ftdi.write(PONG, deviceWriteCb);
        local buffer = blob(10);
        ftdi.read(buffer, deviceReadCb);
    }
}

function deviceWriteCb(error, data, len) {
    data.seek(0, 'b');
    local txt = "Data written: " + data.readstring(len);
    log(txt);
}

function usbDriverListener(event, driver) {
    log("USB event: " + event);

    if (event == USB_DRIVER_STATE_STARTED) {
        ftdi = driver;

        log("Starting ping-pong");
        ftdi.write(PING, deviceWriteCb);

        log("Starting reading");

        local buffer = blob(10);
        ftdi.read(buffer, deviceReadCb);
    }
}

usbHost <- USB.Host(hardware.usb, [FT232RLFtdiUsbDriver]);
log("USB.Host setup complete");

usbHost.setDriverListener(usbDriverListener);
log("USB.Host setEventListener complete");

log("Waiting for a \"device connected\" event");
