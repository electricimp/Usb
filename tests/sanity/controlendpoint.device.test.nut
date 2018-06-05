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

@include __PATH__+"/../../USB.device.lib.nut"
@include __PATH__+"/../UsbMock.nut"
@include __PATH__+"/../CorrectDriver.nut"
@include __PATH__+"/../DescriptorMock.nut"

// Sanity test for USB.ControlEndpoint
class UsbFunctionalEndpointSanity extends ImpTestCase {
    _device = null;
    _usb = null;
    _drivers = [CorrectDriver];

    function setUp() {
        _usb = UsbMock();
        _usb.configure(function(evt, evd){});
        _device = USB._Device(_usb, 1.5, correctDescriptor, 1);
    }

    function testPositive1() {
        getEp();
    }

    function testPositive2() {
        getEp().transfer(USB_SETUP_TYPE_VENDOR, 1, 2, 3);
    }

    function testPositive4() {
        local ep = getEp();
        ep.transfer(USB_SETUP_TYPE_VENDOR, 1, 2, 3);
        ep.transfer(USB_SETUP_TYPE_VENDOR, 1, 2, 3);
    }

    function testNegative1() {
        try {
            local ep = getEp();
            ep._close()
            ep.transfer(USB_SETUP_TYPE_VENDOR, 1, 2, 3);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    function testNegative4() {
        try {
            local ep = getEp();
            // only vendor is accepted
            ep.transfer(USB_SETUP_TYPE_STANDARD, 1, 2, 3);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    // -------------------- service functions ----------------

    function getEp() {
        return USB._ControlEndpoint(_device, 0, 8);
    }

}