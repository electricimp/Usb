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

@include "github:electricimp/QL720NW/QL720NW.device.lib.nut"
@include __PATH__+"/../../USB.device.lib.nut"
@include __PATH__ + "/../UsbMock.nut"
@include __PATH__ + "/../../drivers/QL720NW_UART_USB_Driver/QL720NWUsbToUartDriver.device.nut"

// Below data is not real printer config, we only need VID/PID pair and interface with BulkOut

bulkOut <- {
    "address"       : 0x2,
    "attributes"    : 0x2,
    "maxpacketsize" : 32,
    "interval"      : 0
}


bulkIn <- {
    "address"       : 0x81,
    "attributes"    : 0x2,
    "maxpacketsize" : 32,
    "interval"      : 0
}

printerInterface <- {
    "interfacenumber" : 0,
    "altsetting"      : 0,
    "class"           : 0xFF,
    "subclass"        : 0xFF,
    "protocol"        : 0xFF,
    "interface"       : 0,
    "endpoints"       : [bulkIn, bulkOut]
}

printerConfig <- {
    "value"         : 1,
    "configuration" : 0,
    "attributes"    : 0,
    "maxpower"      : 100,
    "interfaces"    : [printerInterface]
}

printerDescriptor <- {
    "usb"                 : 0x0110,
    "class"               : 0xFF,
    "subclass"            : 0xFF,
    "protocol"            : 0xFF,
    "maxpacketsize0"      : 8,
    "vendorid"            : 0x04f9,
    "productid"           : 0x2044,
    "device"              : 0x1234,
    "manufacturer"        : 0,
    "product"             : 0,
    "serial"              : 0,
    "numofconfigurations" : 1,
    "configurations"      : [printerConfig]
}

printerDevice <- {
    "speed"       : 1.5,
    "descriptors" : printerDescriptor
}


// Sanity test for USB.Host
class QL720Sanity extends ImpTestCase {

    _usb        = null;
    _drivers    = [QL720NWUsbToUartDriver];

    function setUp() {
        _usb = UsbMock();
    }

    function test1Init() {
        local host = _getUsbHost();
        return Promise(function(resolve, reject) {
            host.setDriverListener(function(eventType, eventObject) {

                if (eventType == USB_DRIVER_STATE_STARTED) {
                    if (typeof eventObject != "QL720NWUsbToUartDriver") {
                        reject("Invalid event object: " + typeof eventObject);
                    } else {
                        _usb.triggerEvent(USB_DEVICE_DISCONNECTED, {"device" : 1});
                    }
                }

                if (eventType == USB_DRIVER_STATE_STOPPED) {
                    if (typeof eventObject == "QL720NWUsbToUartDriver") {
                        resolve();
                    } else {
                        reject();
                    }
                }
            });

            _usb.triggerEvent(USB_DEVICE_CONNECTED, _clone(printerDevice));
        }.bindenv(this));

    }

    function test2SetOrientation() {
        return _configureDriver().then(function(drvInstance){
           drvInstance.setOrientation("ORIENTATION");
        }, null);
    }

    function test3SetMargin() {
        return _configureDriver().then(function(drvInstance){
           drvInstance.setRightMargin(1);
           drvInstance.setLeftMargin(1);
        }, null);
    }

    function test4SetFont() {
        return _configureDriver().then(function(drvInstance){
           drvInstance.setFont(1);
           drvInstance.setFontSize(24);
        }, null);
    }

    function test5Write() {
        return _configureDriver().then(function(drvInstance){
           drvInstance.write("Write test", QL720NW_ITALIC);
           drvInstance.writen("Writen test");
           drvInstance.newline();
        }, null);
    }

    function test6WriteBarcode() {
        return _configureDriver().then(function(drvInstance){
           drvInstance.writeBarcode("Write barcode test");
        }, null);
    }

    function test7Write2DBarcode() {
       return  _configureDriver().then(function(drvInstance){
           drvInstance.write2dBarcode("Write 2D barcode test");
        }, null);
    }

    function test8WPrint() {
        return _configureDriver().then(function(drvInstance){
           drvInstance.print();
        }, null);
    }


    function _getUsbHost() {
        return USB.Host(_usb, _drivers, false);

    }

    function _configureDriver() {
        return Promise(function(resolve, reject) {
            _getUsbHost().setDriverListener(function(eventType, eventObject) {

                if (eventType == USB_DRIVER_STATE_STARTED &&
                    typeof eventObject == "QL720NWUsbToUartDriver") {
                        resolve(QL720NW(eventObject));
                } else {
                    reject("Unexpected event or object");
                }

            });

            _usb.triggerEvent(USB_DEVICE_CONNECTED, _clone(printerDevice));

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