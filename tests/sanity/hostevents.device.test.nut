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

@include __PATH__ + "/../CorrectDriver.nut"
@include __PATH__ + "/../DescriptorMock.nut"
@include __PATH__ + "/../UsbMock.nut"
@include __PATH__+"/../UsbHostWrapper.nut"

// Sanity test for USB.Host
class UsbHostEventsSanity extends ImpTestCase {

    _usb = null;

    _drivers = [CorrectDriver];

    function setUp() {
        _usb = UsbMock();
    }

    function getUsbHost(drivers, autoConf) {
        return UsbHostWrapper(_usb, drivers, autoConf);
    }

    function testGetAttachedOneDevice() {
        local host = getUsbHost(_drivers, false);

        _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

        return Promise(function(resolve, reject) {
            imp.wakeup(0, function() {
                local devices = host.getAttachedDevices();
                assertTrue(devices.len() == 1, "Expected one device item");
                assertEqual("instance", typeof(devices[0]), "Unexpected driver");
                resolve();
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetAttachedTwoDevices() {
        local host = getUsbHost(_drivers, false);

        _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);
        _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

        return Promise(function(resolve, reject) {
            imp.wakeup(0, function() {
                local devices = host.getAttachedDevices();
                assertTrue(devices.len() == 2, "Expected two device attached");
                assertEqual("instance", typeof(devices[0]), "Unexpected driver");
                assertEqual("instance", typeof(devices[1]), "Unexpected driver");
                resolve();
            }.bindenv(this));
        }.bindenv(this));
    }


    function testSetListenerOnConnect() {
        return Promise(function(resolve, reject) {
            local host = getUsbHost(_drivers, true);
            local counter = 0;
            host.setEventListener(function(type, payload) {
                counter++;
                if (counter == 1) {
                    assertEqual("connected", type, "Unexpected type of event.");
                    // payload is description
                    assertEqual("instance", typeof payload, "Unextepced device type")
                } else if (counter == 2) {
                    assertEqual("started", type, "Unexpected type of event.");
                    // payload is driver instance
                    assertEqual("CorrectDriver", typeof payload, "Unextepced driver type")
                } else {
                    // no more events expected
                    assertTrue(false, "Unextepced event.");
                }
            }.bindenv(this));

            _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

            // reject this test on failure
            imp.wakeup(1, function() {
                host.setEventListener(null);
                if (counter == 2)
                    resolve()
                else
                    reject("Unexpected number of events received: " + counter);
            }.bindenv(this));

        }.bindenv(this));
    }

    function testSetListenerDisconnect() {
        return Promise(function(resolve, reject) {
            local host = getUsbHost(_drivers, true);

            _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

            imp.wakeup(0, function() {
                local counter = 0;
                host.setEventListener(function(type, payload) {
                    if (counter == 1) {
                        assertEqual("disconnected", type, "Unexpected type of event:" + type + ". Need disconnected");
                        // payload is description
                        assertEqual("instance", typeof payload, "Unexpected device type")
                    } else if (counter == 0) {
                        assertEqual("stopped", type, "Unexpected type of event: " + type + ". Need stopped");
                        // payload is driver instance
                        assertEqual("instance", typeof payload, "Unexpected driver type")
                    } else {
                        // no more events expected
                        assertTrue(false, "Unexpected event.");
                    }
                    counter++;
                }.bindenv(this));

                // Trigger disconnect event
                _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {
                    "device": 1
                });

                // reject this test on failure
                imp.wakeup(0, function() {
                    host.setEventListener(null);
                    if (counter == 2)
                        resolve()
                    else
                        reject();

                }.bindenv(this));
            }.bindenv(this));

        }.bindenv(this));
    }
}
