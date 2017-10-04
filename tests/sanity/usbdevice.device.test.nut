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
@include __PATH__+"/../DescriptorMock.nut"

// Sanity test for USB.Device
class UsbDeviceSanity extends ImpTestCase {

    _usb = null;

    _drivers = [CorrectDriver];


    function setUp() {
        _usb = UsbMock();
        _usb.configure(callback);
    }


    function testPositive1() {
        local dev = getValidDevice();
        assertEqual(dev.getVendorId(), correctDescriptor.vendorid);
        assertEqual(dev.getProductId(), correctDescriptor.productid);
        dev.setAddress(1);
        dev.getEndpoint(correctInterface, USB_ENDPOINT_BULK, USB_DIRECTION_OUT);
        dev.getEndpointByAddress(correctInterface.endpoints[0].address);
        dev.stop();
    }

    // any state modification functions must throw an exception after stop
    function testNegative1() {
        local dev = getValidDevice();

        dev.stop();
        try {
            dev.setAddress(1);
            assertTrue(false, "setAddress must throw an exception in detached state" );
        } catch (e) {
            // OK
        }
        try {
            dev.setAddress(1);
            assertTrue(false, "setAddress must throw an exception in detached state" );
        } catch (e) {
            // OK
        }
        try {
            dev.getEndpoint(correctInterface, USB_ENDPOINT_BULK, USB_DIRECTION_OUT);
            assertTrue(false, "getEndpoint must throw an exception in detached state" );
        } catch (e) {
            // OK
        }
        try {
            dev.getEndpointByAddress(1);
            assertTrue(false, "getEndpointByAddress must throw an exception in detached state" );
        } catch (e) {
            // OK
        }
        try {
            dev.stop();
            assertTrue(false, "stop must throw an exception when called twice" );
        } catch (e) {
            // OK
        }
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
    }


    function getValidDevice() {
        return USB.Device(_usb, 1.5, correctDescriptor, 1, _drivers);
    }

    function callback(eventType, eventDetails) {

    }
}
