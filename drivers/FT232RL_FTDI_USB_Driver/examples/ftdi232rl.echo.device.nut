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

@include "../../../../USB.device.lib.nut"
@include "../../FT232RLFtdiUsbDriver.device.lib.nut"

log <- server.log.bindenv(server);

ftdi <- null;

function deviceReadCb(error, data, len) {
    if (error != null) {
        log("Read timeout!");
    } else {
        log("Received. Sending back..");
        ftdi.write(data.readblob(len), deviceWriteCb);
    }

    ftdi.read(data, deviceReadCb);
}

function deviceWriteCb(error, data, len) {
    log("Data has been written");
}

function usbEventListener(event, data) {
    log("USB event: " + event);

    if (event == USB_DRIVER_STATE_STARTED) {
        ftdi = data;

        log("Starting reading");

        local buffer = blob(10);
        ftdi.read(buffer, deviceReadCb);
    }
}

usbHost <- USB.Host(hardware.usb, [FT232RLFtdiUsbDriver]);
log("USB.Host setup complete");

usbHost.setEventListener(usbEventListener);
log("USB.Host setEventListener complete");

log("Waiting for a \"device connected\" event");
