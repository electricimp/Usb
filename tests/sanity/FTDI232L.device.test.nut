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

@include __PATH__+"/../../USB.device.lib.nut"
@include __PATH__ + "/../UsbMock.nut"
@include __PATH__ + "/../../drivers/FT232RL_FTDI_USB_Driver/FT232RLFtdiUsbDriver.device.lib.nut"

// Below data is not real ftdi config, we only need VID/PID pair and interface with BulkOut

bulkOut <- {
    "address" : 0x2,
    "attributes" : 0x2,
    "maxpacketsize" : 32,
    "interval" : 0
}


bulkIn <- {
    "address" : 0x81,
    "attributes" : 0x2,
    "maxpacketsize" : 32,
    "interval" : 0
}

ftdiInterface <- {
    "interfacenumber" : 0,
    "altsetting" : 0,
    "class" : 0xFF,
    "subclass" : 0xFF,
    "protocol" : 0xFF,
    "interface" : 0,
    "endpoints" : [bulkIn, bulkOut]
}

ftdiConfig <- {
    "value" : 1,
    "configuration" : 0,
    "attributes" : 0,
    "maxpower" : 100,
    "interfaces" : [ftdiInterface]
}

ftdiDescriptor <- {
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
    "configurations" : [ftdiConfig]
}

ftdiDevice <- {
    "speed" : 1.5,
    "descriptors" : ftdiDescriptor
}


// Sanity test for USB.Host
class FTDI232RLSanity extends ImpTestCase {

    _usb        = null;
    _drivers    = [FT232RLFtdiUsbDriver];

    function setUp() {
        _usb = UsbMock();
        USB.Host.init(_drivers);
        USB.Host._usb = _usb;
        USB.Host.reset();
    }

    function test1Init() {
        local host = _getUsbHost();
        return Promise(function(resolve, reject) {
            host.setDriverListener(function(eventType, eventObject) {

                if (eventType == USB_DRIVER_STATE_STARTED) {
                    if (typeof eventObject != "FT232RLFtdiUsbDriver") {
                        reject("Invalid event object: " + typeof eventObject);
                    } else {
                        _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {"device" : 1});
                    }
                }

                if (eventType == USB_DRIVER_STATE_STOPPED) {
                    if (typeof eventObject == "FT232RLFtdiUsbDriver") {
                        resolve();
                    } else {
                        reject();
                    }
                }
            });

            _usb.triggerEvent(USB_DEVICE_CONNECTED, _clone(ftdiDevice));
        }.bindenv(this));

    }

    function test2write() {
        return _configureDriver().then(function(drvInstance){
           local data = blob(10);
           drvInstance.write(data, function(err, data, len){});
        }, null);
    }

    function test3read() {
        return _configureDriver().then(function(drvInstance){
            local data = blob(10);
            drvInstance.read(data, function(err, data, len){});
         }, null);
    }

    function test4config() {
        return _configureDriver().then(function(drvInstance){
           drvInstance.configure();
        }, null);
    }

    function _getUsbHost() {
        return USB.Host;

    }

    function _configureDriver() {
        return Promise(function(resolve, reject) {
            _getUsbHost().setDriverListener(function(eventType, eventObject) {

                if (eventType == USB_DRIVER_STATE_STARTED &&
                    typeof eventObject == "FT232RLFtdiUsbDriver") {
                        resolve(eventObject);
                }

            });

            _usb.triggerEvent(USB_DEVICE_CONNECTED, _clone(ftdiDevice));

        }.bindenv(this));
    }

    function _clone(obj) {
        local newObj = clone(obj);
        foreach(k,v in newObj) {
            if (typeof v == "table" ||
                typeof v == "array") {
                newObj[k] = _clone(v);
            }
        }

        return newObj;
    }
}
