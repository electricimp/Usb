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

// This is an example of keyboard control application
// NOTE: The code below should be built with Builder preprocessor, https://github.com/electricimp/builder

// Hardware connected via a USB cable: 
//      imp005 breakout board
//      Keyboard (Tested with Logitech K120)

#require "USB.device.lib.nut:1.1.0"

// The ASCII table definition should precede the HIDKeyboard driver implementation
@include "github:electricimp/usb/drivers/HIDKeyboard/US-ASCII.table.nut"
@include "github:electricimp/usb/drivers/GenericHID_Driver/USB.HID.device.nut"
@include "github:electricimp/usb/drivers/HIDKeyboard/HIDKeyboard.device.nut"


log <- server.log.bindenv(server);
kbdDrv <- null;

function kdbEventListener(keys) {
    local txt = "[App]: Keys received: ";
    foreach (key in keys) {
        txt += key.tochar() + " ";
    }
    log(txt);
}

function usbDriverListener(event, data) {
    log("[App]: USB event: " + event);

    if (event == USB_DRIVER_STATE_STARTED) {
        kbdDrv = data;
        log("[App]: Start polling");
        kbdDrv.startPoll(0, kdbEventListener);
    }
}

usbHost <- USB.Host(hardware.usb, [HIDKeyboardDriver], true);
log("[App]: USB.Host initialized");

usbHost.setDriverListener(usbDriverListener);
log("[App]: USB.Host setEventListener complete");

log("[App]: Waiting for attach event");
