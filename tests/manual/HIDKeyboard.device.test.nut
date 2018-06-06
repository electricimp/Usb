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

// Setup
// ---------------------------------------------------------------------

// Test Hardware
//  - Imp005 Breakout Board
//  - Any USB keyboard


// Tests
// ---------------------------------------------------------------------


@include __PATH__+"/../../USB.device.lib.nut"
@include __PATH__+"/../../USB.HID.device.lib.nut"
@include __PATH__+"/../../drivers/HIDKeyboard/HIDKeyboard.device.lib.nut"

// HIDKeyboard driver test
// NOTE: The keyboard MUST support IDLE time setting, e.g. generate reports periodically
//       Otherwise the will fail with
class HIDKeyboardTest extends ImpTestCase {

    _host = null;


    function setUp() {
        _host = USB.Host(hardware.usb, [HIDKeyboardDriver]);

        return "USB setup complete";
    }

    function test1() {
        local infoFunc = this.info.bindenv(this);

        return _setUpHost().then(function(kdbDrv) {

            return Promise(function(resolve, reject) {
                local numberOfPoll = 0;

                // read data timeout
                imp.wakeup(0.3, function() {

                    kdbDrv.stopPoll();

                    // As we set timeout to 300ms and poll time to 100ms,
                    // the test is considered as passed if read event were more than 1 but less then 4.
                    // if there was more then 4 events, that may mean Set IDLE time command is not actually supported by device.
                    if (numberOfPoll > 4) resolve("Too may report events. Is device support IDLE time");
                    else if (numberOfPoll > 1) resolve();
                    else reject("Invalid HID device poll period. Is the device real keyboard?");
                });

                infoFunc("Start keyboard polling.");

                kdbDrv.startPoll(100, function(keys) {
                    numberOfPoll++;
                });
            });

        });

    }

    function test2() {

        local infoFunc = this.info.bindenv(this);

        return _setUpHost().then(function(kdbDrv) {
            kdbDrv.setLEDs([HID_LED_NUMLOCK, HID_LED_CAPSLOCK, HID_LED_SCROLLLOCK]);
            return "Check if keyboard leds have changed their status";
        });
    }

    function tearDown() {
        hardware.usb.disable();

        _host = null;
    }

    // Setup USB.Host and wait to driver start
    function _setUpHost() {
        local usbHost = _host;
        local infoFunc = this.info.bindenv(this);

        return Promise(function(resolve, reject) {

            // report error if no device is attached
            local timer = imp.wakeup(1, function() {
                reject("No keyboard is attached");
            });

            usbHost.setDriverListener(function(event, data) {
                if (event == USB_DRIVER_STATE_STARTED) {

                    imp.cancelwakeup(timer);

                    if (typeof data == "HIDKeyboard") {
                        resolve(data);
                    } else {
                        reject("Invalid driver is started: " + (typeof data));
                    }
                }
            });

            usbHost.reset();

        });

    }

}
