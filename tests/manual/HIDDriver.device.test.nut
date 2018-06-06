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
//  - Any HID device (mouse, keyboard, joystick)


// Tests
// ---------------------------------------------------------------------

@include "USB.HID.device.lib.nut"

//
class HIDDriverTest extends ImpTestCase {

    _host = null;
    _hid = null;
    _keyboard = null;

    function setUp() {
        _host = USB.Host([HIDDriver]);
        return "USB setup complete";
    }

    // Test HIDReport.setIdleTime
    function test1() {
        return _setUpHost().then(function(driverInstance) {
            foreach (report in driverInstance.getReports()) {
                report.setIdleTime(55);
            }
        });
    }

    // Test HIDReport.request
    function test2() {
        return _setUpHost().then(function(driverInstance) {
            foreach (report in driverInstance.getReports()) {
                report.request();
            }
        });
    }

    // Test HIDReport.send
    function test3() {
        return _setUpHost().then(function(driverInstance) {
            foreach (report in driverInstance.getReports()) {
                report.send();
            }
        });
    }

    // Test if is up and ready
    function test4() {
        local infoFunc = this.info.bindenv(this);
        return _setUpHost().then(function(driverInstance) {
            return Promise(function(resolve, reject) {
                imp.wakeup(10, function() {
                   resolve("No reports from getAsync().  May be there was no action at device?");
                });
                infoFunc("Calling HIDDriver.getAsync. Make any action with HID device");
                driverInstance.getAsync(function(error, report) {
                    if (error) {
                        reject("HIDDriver.getAsync notifies error:" + error);
                    } else {
                        foreach (knownReports in driverInstance.getReports()) {
                            if (knownReports == report) {
                                resolve();
                                return;
                            }
                        }
                        reject("getAsync return unknown report");
                    }
                });
            });

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
            usbHost.setEventListener(function(event, data) {
                if (event == USB_DRIVER_STATE_STARTED) {
                    if (typeof data == "HIDDriver") {
                        if (data.getReports().len() == 0) {
                            reject("Invalid reports number");
                            return;
                        }
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
