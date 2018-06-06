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

// Sanity test for USB.FunctionalEndpoint
class UsbFunctionalEndpointSanity extends ImpTestCase {
    _device = null;
    _usb = null;
    _drivers = [CorrectDriver];

    function setUp() {
        _usb = UsbMock();
        local host = USB.Host(_usb, _drivers);
        _device = USB.Device(_usb, host, 1.5, correctDescriptor, 1);
    }

    function testPositive1() {
        getInEp();
    }

    function testPositive2() {
        getInEp().read(blob(5), readCallback);
    }

    function testPositive3() {
        getOutEp().write(blob(5), writeCallback);
    }

    function testPositive3() {
        getInEp().getEndpoint();
    }

    function testNegative1() {
        try {
            local ep = getInEp();
            ep.read(blob(5), readCallback);
            ep.read(blob(5), readCallback);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    function testNegative2() {
        try {
            local ep = getOutEp();
            ep.write(blob(5), writeCallback);
            ep.write(blob(5), writeCallback);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    function testNegative3() {
        try {
            local ep = getOutEp();
            ep._close();
            ep.write(blob(5), writeCallback);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    function testNegative4() {
        try {
            local ep = getIntEp();
            ep._close();
            ep.read(blob(5), readCallback);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    function testNegative5() {
        try {
            local ep = getOutEp();
            // wrong direction
            ep.read(blob(5), readCallback);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    function testNegative6() {
        try {
            local ep = getInEp();
            // wrong direction
            ep.write(blob(5), writeCallback);
            assertTrue(false);
        } catch(e) {
            // OK
        }
    }

    // -------------------- service functions ----------------

    function readCallback(ep, error, data, len) {
    }

    function writeCallback(ep, error, data, len) {

    }

    function getInEp() {
        return USB.FuncEndpoint(_device, bulkIn.address, USB_ENDPOINT_BULK, 32);
    }

    function getOutEp() {
        return USB.FuncEndpoint(_device, bulkOut.address, USB_ENDPOINT_BULK, 32);
    }

}