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

class UsbHostTestCase extends ImpTestCase {
    // UART on imp005
    dataString = "";
    usbHost = null;
    loadPin = null;

    function setUp() {

        hardware.pinW.configure(DIGITAL_OUT, 1);
        hardware.pinR.configure(DIGITAL_OUT, 1);

        usbHost = UsbHost(hardware.usb);
        usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());
        usbHost.registerDriver(UartOverUsbDriver, UartOverUsbDriver.getIdentifiers());

        return "Hi from #{__FILE__}!";
    }

    function testUsbConnection() {
        this.info("Connect any registered usb device to imp");
        return Promise(function(resolve, reject) {
            usbHost.on("connected", function(device) {
                if (device != null) {
                    resolve("Device Connected");
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    function testUsbDisconnection() {
        this.info("Disconnect the usb device from imp");
        return Promise(function(resolve, reject) {
            usbHost.on("disconnected", function(device) {
                if (device != null) {
                    resolve("Device Disconnected");
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    function tearDown() {
        return "Test finished";
    }
}
