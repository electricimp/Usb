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

// Mock driver with correct functionality

@include __PATH__ + "/./DescriptorMock.nut"

deviceDescriptor1 <- {
    "usb": 0x0110,
    "class": 0xFF,
    "subclass": 0xFF,
    "protocol": 0xFF,
    "maxpacketsize0": 8,
    "vendorid": 0xE1,
    "productid": 0xC1,
    "device": 0x1231,
    "manufacturer": 0,
    "product": 0,
    "serial": 0,
    "numofconfigurations": 1,
    "configurations": [correctConfig]
};

class TestDriver1 extends USB.Driver {

    deviceInfo = {
        "speed": 1.5,
        "descriptors": deviceDescriptor1
    };

    function device() {
        return deviceInfo;
    }

    function match(device, interfaces) {
        if (device.getVendorId() == deviceInfo.descriptors.vendorid &&
            device.getProductId() == deviceInfo.descriptors.productid)
            return TestDriver1();
        return null;
    }

}

deviceDescriptor2 <- {
    "usb": 0x0110,
    "class": 0xFF,
    "subclass": 0xFF,
    "protocol": 0xFF,
    "maxpacketsize0": 8,
    "vendorid": 0xE9,
    "productid": 0xC2,
    "device": 0x1232,
    "manufacturer": 0,
    "product": 0,
    "serial": 0,
    "numofconfigurations": 1,
    "configurations": [correctConfig]
};

class TestDriver2 extends USB.Driver {

    deviceInfo = {
        "speed": 1.5,
        "descriptors": deviceDescriptor2
    }

    function device() {
        return deviceInfo;
    }

    function match(device, interfaces) {
        if (device.getVendorId() == deviceInfo.descriptors.vendorid &&
            device.getProductId() == deviceInfo.descriptors.productid)
            return TestDriver2();
        return null;
    }

}

deviceDescriptor3 <- {
    "usb": 0x0110,
    "class": 0xFF,
    "subclass": 0xFF,
    "protocol": 0xFF,
    "maxpacketsize0": 8,
    "vendorid": 0xEE,
    "productid": 0xC3,
    "device": 0x1233,
    "manufacturer": 0,
    "product": 0,
    "serial": 0,
    "numofconfigurations": 1,
    "configurations": [correctConfig]
};

class TestDriver3 extends USB.Driver {
    deviceInfo = {
        "speed": 2,
        "descriptors": deviceDescriptor3
    }

    function device() {
        return deviceInfo;
    }

    function match(device, interfaces) {
        if (device.getVendorId() == deviceInfo.descriptors.vendorid &&
            device.getProductId() == deviceInfo.descriptors.productid)
            return TestDriver3();
        return null;
    }
}
