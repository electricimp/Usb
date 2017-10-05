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
@include __PATH__ + "/../StubbedDrivers.nut"

// Sanity test for USB.Host
class UsbHostMultipleDriversSanity extends ImpTestCase {

    _usb = null;

    _drivers = [TestDriver1, TestDriver2, TestDriver3];

    function setUp() {
        _usb = UsbMock();
    }

    function testGetAttachedOneDevice() {
        local host = USB.Host(_usb, _drivers, true);
        local counter = {
           "connected": 0,
           "disconnected": 0,
           "started": 0,
           "stopped": 0
        };
        // count all events
        host.setEventListener(function(type, payload) {
            counter[type]++;
            if (type == "connected")
              assertTrue(payload._address == counter[type], "Unexpected device address: " + payload._address)
        }.bindenv(this));

        _usb.triggerEvent(USB_DEVICE_CONNECTED, TestDriver1.device());
        _usb.triggerEvent(USB_DEVICE_CONNECTED, TestDriver2.device());
        _usb.triggerEvent(USB_DEVICE_CONNECTED, TestDriver3.device());

        return Promise(function(resolve, reject) {
            imp.wakeup(0, function() {
                local devices = host.getAttachedDevices();
                assertTrue(devices.len() == 3, "Expected three device items");
                assertDeepEqual({"connected":3,"started":3,"disconnected":0,"stopped":0},
                    counter, "Wrong number of events on connect");

                _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {"device":1});
                _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {"device":2});
                _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {"device":3});

                imp.wakeup(0, function() {
                  local devices = host.getAttachedDevices();
                  assertTrue(devices.len() == 0, "Expected three device items");
                  assertDeepEqual({"connected":3,"started":3,"disconnected":3,"stopped":3},
                      counter, "Wrong number of events on disconnect");
                  resolve();
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }
}
