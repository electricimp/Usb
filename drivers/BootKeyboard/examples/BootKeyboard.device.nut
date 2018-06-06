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

#require "PrettyPrinter.class.nut:1.0.1"
#require "JSONEncoder.class.nut:1.0.0"

// This is an example of bookt keyboard control application

@include __PATH__ +  "/../../../USB.device.lib.nut"
@include __PATH__ +  "/../../../USB.HID.device.lib.nut"
@include __PATH__ +  "/../BootKeyboard.device.lib.nut"


pp <- PrettyPrinter(null, false);
print <- pp.print.bindenv(pp);

kbrDrv <- null;

function keyboardEventListener(status) {
    if (!kbrDrv) {
        return;
    }

    server.log("Keyboard event");
    local error = "error" in status ? status.error : null;

    if (error == null) {
        print(status);
        kbrDrv.getKeyStatusAsync(keyboardEventListener);
    } else {
        server.error("Error received: " + error);
    }
}

function usbDriverListener(event, driver) {
    if (event == USB_DRIVER_STATE_STARTED) {
        server.log("BootKeyboardDriver started");
        kbrDrv = driver;
        // Receive new key state every second
        kbrDrv.getKeyStatusAsync(keyboardEventListener);
    }
}

usbHost <- USB.Host(hardware.usb, [BootKeyboardDriver]);

usbHost.setDriverListener(usbDriverListener);

server.log("USB initialization complete");


