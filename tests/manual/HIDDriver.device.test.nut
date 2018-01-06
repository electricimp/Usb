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

@include "../../USB.HID.device.lib.nut"

//
class HIDDriverTest extends ImpTestCase {

    _host = null;

    _hid = null;

    _keyboard = null;

    function setUp() {
        _host = USB.Host(HIDDriver);

        return "USB setup complete";
    }

    // Test if is up and ready
    function test1() {
        return _setUpHost().then(function(driverInstance) {

            return Promise(function(resolve, reject) {
                local newTimer = imp.wakeup(1000, function() {
                    reject("getAsync() timeout");
                });

                data.getAsync(function(error, report) {

                    imp.cancelwakeup(newTimer);

                    if (error) reject("HIDDriver.getAsync notifies error:" + error);
                    else {
                        foreach (knownReports in data.getReports()) {
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

    // Test HIDReport.setIdleTime
    function test2() {
        return _setUpHost().then(function(driverInstance) {

            foreach (report in driverInstance.getReports()) {
                report.setIdleTime(55);
            }

        });
    }

    // Test HIDReport.request
    function test3() {
        return _setUpHost().then(function(driverInstance) {

            foreach (report in driverInstance.getReports()) {
                report.request();
            }

        });
    }

    // Test HIDReport.send
    function test4() {
        return _setUpHost().then(function(driverInstance) {

            foreach (report in driverInstance.getReports()) {
                report.send();
            }

        });
    }

    function tearDown() {
        usb.disable();

        _host = null;
    }

    // Setup USB.Host and wait to driver start
    function _setUpHost() {
        return Promise(function(resolve, reject) {

            // report error if no device is attached
            local timer = imp.wakeup(1000, function() {
                reject("No HID device is attached");
            });


            _host.setEventListener(function(event, data) {
                if (event == "started") {
                    if (typeof data == "HIDDriver") {

                        imp.cancelwakeup(timer);

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

            _host.reset();

            this.info("HIDDriver setup  complete");

        });

    }

}
