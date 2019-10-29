// MIT License
//
// Copyright 2018 Electric Imp
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
@include __PATH__+"/../../drivers/BootKeyboard/BootKeyboard.device.nut"
@include __PATH__+"/../UsbMock.nut"



intIn <- {
    "address" : 0x81,
    "attributes" : 0x3,
    "maxpacketsize" :8,
    "interval" : 0
}

bootInterface <- {
    "interfacenumber" : 0,
    "altsetting" : 0,
    "class" : 3,
    "subclass" : 1,
    "protocol" : 1,
    "interface" : 0,
    "endpoints" : [intIn]
}

bootConfig <- {
    "value" : 1,
    "configuration" : 0,
    "attributes" : 0,
    "maxpower" : 100,
    "interfaces" : [bootInterface]
}

bootDescriptor <- {
    "usb" : 0x0110,
    "class" : 0xFF,
    "subclass" : 0xFF,
    "protocol" : 0xFF,
    "maxpacketsize0" : 8,
    "vendorid" : 0x0403,
    "productid" : 0x6001,
    "device" : 0x1234,
    "manufacturer" : 0,
    "product" : 0,
    "serial" : 0,
    "numofconfigurations" : 1,
    "configurations" : [bootConfig]
}

// Sanity test for BootKeyboardDriver
class UsbFunctionalEndpointSanity extends ImpTestCase {
    _usb        = null;
    _drivers    = [BootKeyboardDriver];

    function setUp() {
        _usb = UsbMock();
    }

    function testGetKeyStatus() {
        getDriver().then(function(drvInstance){
            return Promise(function(resolve, reject) {
                local status = drvInstance.getKeyStatus();
                if ("error" in status) reject("Received error: " + status["error"]);
                else resolve();
            });
         }, null);
    }

    function testGetKeyStatusAsync() {
        getDriver().then(function(drvInstance){
            return Promise(function(resolve, reject) {

                _usb.triggerEvent(USB_TRANSFER_COMPLETED, {"device" : 1, "state" : 16});

                drvInstance.getKeyStatusAsync( function(status) {
                    if ("error" in status) reject("Received error: " + status["error"]);
                    else resolve();
                });
            }.bindenv(this));
         }, null);
    }

    function testSetLed() {
        getDriver().then(function(drvInstance){

            return Promise(function(resolve, reject) {
                local status = drvInstance.setLeds();
                if ("error" in status) reject("Received error: " + status["error"]);
                else resolve();
            });
         }, null);
    }

    function testSetIdle() {
        getDriver().then(function(drvInstance){

            return Promise(function(resolve, reject) {
                local status = drvInstance.setIdleTimeMs(10);
                if ("error" in status) reject("Received error: " + status["error"]);
                else resolve();
            });
         }, null);
    }

    function getDriver() {
        return Promise(function(resolve, reject) {
            _getUsbHost().setDriverListener(function(eventType, eventObject) {

                if (eventType == USB_DRIVER_STATE_STARTED &&
                    typeof eventObject == "BootKeyboardDriver") {
                        resolve(eventObject);
                } else {
                    reject("Unexpected event or object");
                }

            });

            _usb.triggerEvent(USB_DEVICE_CONNECTED, _clone(bootDescriptor));

        }.bindenv(this));
    }

    function _getUsbHost() {
        local host = USB.Host(_usb, _drivers);
    }

}
