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

@include __PATH__+"/../../USB.device.lib.nut"
@include __PATH__ + "/../CorrectDriver.nut"
@include __PATH__ + "/../DescriptorMock.nut"
@include __PATH__ + "/../UsbMock.nut"

// Sanity test for USB.Host
class UsbHostEventsSanity extends ImpTestCase {

    _usb = null;

    _drivers = [CorrectDriver];

    function setUp() {
        _usb = UsbMock();
    }

    function testGetAttachedOneDevice() {
        local host = getUsbHost();

        _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

        return Promise(function(resolve, reject) {
            imp.wakeup(0, function() {
                local devices = host.getAttachedDevices();
                assertTrue(devices.len() == 1, "Expected one device item");
                assertEqual("USB._Device", typeof(devices[0]), "Unexpected driver");
                resolve();
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetAttachedTwoDevices() {
        local host = getUsbHost();

        _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);
        _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

        return Promise(function(resolve, reject) {
            imp.wakeup(0, function() {
                local devices = host.getAttachedDevices();
                assertTrue(devices.len() == 2, "Expected two device attached");
                assertEqual("USB._Device", typeof(devices[0]), "Unexpected driver");
                assertEqual("USB._Device", typeof(devices[1]), "Unexpected driver");
                resolve();
            }.bindenv(this));
        }.bindenv(this));
    }


    function testSetDeviceListenerOnConnect() {
        return Promise(function(resolve, reject) {
            local host = getUsbHost();
            local counter = 0;
            host.setDeviceListener(function(type, payload) {
                counter++;

                if (type != USB_DEVICE_STATE_CONNECTED &&
                    type != USB_DEVICE_STATE_DISCONNECTED) {
                        reject("Invalid event type: " + type);
                        return;
                }
                if ("USB._Device" !=  typeof payload) {
                    reject("Unexpected device type");
                    return;
                }

                if (counter != 1) reject("Unexpected event.");

            }.bindenv(this));

            _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

            // reject this test on failure
            imp.wakeup(2, function() {
                host.setDeviceListener(null);
                if (counter == 1)
                    resolve()
                else
                    reject("Unexpected number of events received: " + counter);
            }.bindenv(this));

        }.bindenv(this));
    }

    function testSetDriverListenerOnConnect() {
        return Promise(function(resolve, reject) {
            local host = getUsbHost();
            local counter = 0;
            host.setDriverListener(function(type, payload) {
                counter++;

                if (type != USB_DRIVER_STATE_STARTED &&
                    type != USB_DRIVER_STATE_STOPPED) {
                        reject("Invalid event type: " + type);
                        return;
                }
                if ("CorrectDriver" !=  typeof payload) {
                    reject("Unexpected driver type: " + (typeof payload));
                    return;
                }

                if (counter != 1) reject("Unexpected event.");

            }.bindenv(this));

            _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

            // reject this test on failure
            imp.wakeup(2, function() {
                host.setDriverListener(null);
                if (counter == 1)
                    resolve()
                else
                    reject("Unexpected number of events received: " + counter);
            }.bindenv(this));

        }.bindenv(this));
    }


    function testSetDeviceListenerDisconnect() {
        local counter = 0;
        local host = getUsbHost();

        return Promise.resolve(null)
        .then( function(prevRes) {
            _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);
        }.bindenv(this)).then(function(prevRes) {
            return Promise(function(resolve, reject) {
                host.setDeviceListener(function(type, payload) {
                    counter++;

                    if(USB_DEVICE_STATE_DISCONNECTED != type) {
                        reject("Unexpected type of event:" + type + ". Need " + USB_DEVICE_STATE_DISCONNECTED) ;
                        return;
                    }
                    // payload is description
                    if ("USB._Device" !=  typeof payload) {
                        reject("Unexpected device type: " + (typeof payload));
                        return;
                    }
                }.bindenv(this));

                // Trigger disconnect event
                _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {
                    "device": 1
                });

                // wait a bit for unexpected events
                imp.wakeup(2, function() {
                    host.setDeviceListener(null);
                    if (counter == 1)
                        resolve()
                    else
                        reject("Unexpected number of events " + counter);
                });

            }.bindenv(this));
        }.bindenv(this));
    }

    function testDriverSetListenerDisconnect() {
        local counter = 0;
        local host = getUsbHost();

        return Promise.resolve(null)
        .then( function(prevRes) {
            _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);
        }.bindenv(this)).then(function(prevRes) {
            return Promise(function(resolve, reject) {
                host.setDriverListener(function(type, payload) {
                    counter++;

                    if(USB_DRIVER_STATE_STOPPED != type) {
                        reject("Unexpected type of event:" + type + ". Need " + USB_DRIVER_STATE_STOPPED) ;
                        return;
                    }
                    // payload is description
                    if ("CorrectDriver" !=  typeof payload) {
                        reject("Unexpected device type: " + (typeof payload));
                        return;
                    }
                }.bindenv(this));

                // Trigger disconnect event
                _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {
                    "device": 1
                });

                // wait a bit for unexpected events
                imp.wakeup(2, function() {
                    host.setDriverListener(null);
                    if (counter == 1)
                        resolve()
                    else
                        reject("Unexpected number of events " + counter);
                });

            }.bindenv(this));
        }.bindenv(this));
    }


    function getUsbHost() {
        return USB.Host(_usb, _drivers, false);
    }
}
