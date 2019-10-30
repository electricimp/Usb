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

@include __PATH__+"/../UsbMock.nut"
@include __PATH__+"/../CorrectDriver.nut"

// Sanity test for USB.Host
class UsbHostSanity extends ImpTestCase {

    _usb = null;

    _drivers = [CorrectDriver];

    function setUp() {
        _usb = UsbMock();
    }

    function testSimpleSetup1() {
        local host = getUsbHost(_drivers, true);
    }

    function testSimpleSetup2() {
        local host = getUsbHost(_drivers, false);
    }

    function testSimpleSetup3() {
        local host = getUsbHost(_drivers);
    }

    function testNegativeSetup1() {
        try {
            local host = getUsbHost([UsbMock], true);
            assertTrue(false, "Exception expected in case of wrong driver");
        } catch (e) {
            // expected behavior
        }
    }

    function testNegativeSetup2() {
        try {
            local host = getUsbHost([CorrectDriver, UsbMock], true);
            assertTrue(false, "Exception expected in case of wrong driver");
        } catch (e) {
           // expected behavior
        }
    }

    function testNegativeSetup3() {
        try {
            local host = getUsbHost([]);
            assertTrue(false, "Exception expected in case of wrong driver");
        } catch (e) {
           // expected behavior
        }
    }


    function testReset1() {
        local host = getValidHost();
        host.reset();
    }

    function testGetAttachedDevices() {
        local host = getValidHost();
        assertTrue(host.getAttachedDevices().len() == 0, " Attached devices list is not empy");;
    }

    function testSetListener() {
        local host = getValidHost();
        host.setDriverListener(getValidHost);
        host.setDriverListener(null);
    }

    function testSetListenerNegative() {
        local host = getValidHost();
        try {
            host.setDriverListener("");
            assertTrue(false, "setEventListener must throw ex");
        } catch(e) {
            // OK
        }
    }

    function getUsbHost(drivers, autoConf = null) {
        // USB.Host is looking for hardware.usb and throw an exception otherwise
        local hardware = {};
        hardware.usb <- _usb;
        // instantiate usb host with mock _usb
        local usbHost = null;
        if (autoConf == null) {
            usbHost = USB.Host(_usb, drivers);
        } else {
            usbHost = USB.Host(_usb, drivers, autoConf);
        }
        return usbHost;
    }

    function getValidHost() {
        return USB.Host(_usb, _drivers, true);
    }
}
