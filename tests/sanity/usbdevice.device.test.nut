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
@include __PATH__+"/../UsbMock.nut"
@include __PATH__+"/../CorrectDriver.nut"
@include __PATH__+"/../DescriptorMock.nut"

// Sanity test for USB.Device
class UsbDeviceSanity extends ImpTestCase {

    _usb = null;

    _drivers = [CorrectDriver];


    function setUp() {
        _usb = UsbMock();
    }


    function testPositive1() {
        local dev = getValidDevice();
        assertEqual(dev.getVendorId(), correctDescriptor.vendorid);
        assertEqual(dev.getProductId(), correctDescriptor.productid);
        dev.getAssignedDrivers();
        dev.getEndpointZero();
        assertEqual(dev.getEndpointZero(), dev.getEndpointZero());
    }

    // any state modification functions must throw an exception after stop
    function testNegative1() {
        local dev = getValidDevice();

        dev._stop();

        try {
            dev.getVendorId();
            assertTrue(false, "getVendorIds must throw an exception in detached state" );
        } catch (e) {
            // OK
        }
        try {
            dev.getProductId();
            assertTrue(false, "getProductId must throw an exception in detached state" );
        } catch (e) {
            // OK
        }

        try {
            dev.getAssignedDrivers();
            assertTrue(false, "getVendorIds must throw an exception in detached state" );
        } catch (e) {
            // OK
        }
        try {
            dev.getEndpointZero();
            assertTrue(false, "getProductId must throw an exception in detached state" );
        } catch (e) {
            // OK
        }
    }


    function getValidDevice() {
        local host = USB.Host(_usb, _drivers);
        return USB._Device(_usb, host, 1.5, correctDescriptor, 1);
    }

    function callback(eventType, eventDetails) {

    }
}
