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


// Setup
// ---------------------------------------------------------------------

// Test Hardware
//  - Imp005 Breakout Board
//  - FT232RL FTDI USB to TTL Serial Adapter Module
//      - USB wired to USB
//      - TX & RX wired to UART1


// Tests
// ---------------------------------------------------------------------

class FtdiUsbTestCase extends ImpTestCase {
    // UART on imp005
    uart = null;
    dataString = "";
    usbHost = null;
    loadPin = null;
    _device = null;

    function setUp() {

        uart = hardware.uart1;
        usbHost = UsbHost(hardware.usb);
        usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());
        usbHost.registerDriver(UartOverUsbDriver, UartOverUsbDriver.getIdentifiers());


        return "Hi from #{__FILE__}!";
    }

    function testFtdiConnection() {
        this.info("Connect any Ftdi device to imp");
        return Promise(function(resolve, reject) {
            usbHost.on("connected", function(device) {
                if (typeof device == "FtdiUsbDriver") {
                    _device = device;
                    return resolve("Device was a Ftdi device");
                }
                reject("Device connected is not a ftdi device");
            }.bindenv(this));
        }.bindenv(this))
    }


    function testFtdiUsbSending() {
        return Promise(function(resolve, reject) {
            if (_device != null) {

                local testString = "I'm a Blob\n";
                local dataString = "";

                // Configure with timing
                uart.configure(115200, 8, PARITY_NONE, 1, 0, function() {
                    dataString += uart.readstring();
                    if (dataString.find("\n")) {
                        if (testString == dataString) {
                            resolve("Recieved sent message on Uart");
                        } else {
                            reject("Data recieved did not match");
                        }
                        dataString = "";
                    }
                }.bindenv(this));

                _device.write(testString);

            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }

    function testFtdiUsbRecieving() {
        return Promise(function(resolve, reject) {
            if (_device != null) {

                local testString = "I'm a Blob";
                local dataString = "";

                _device.on("data", function(data) {
                        if (data.tostring() == testString) {
                            resolve("Recieved data on Usb from Uart");
                        }
                    }.bindenv(this))
                    // Configure with timing
                uart.configure(115200, 8, PARITY_NONE, 1, 0);
                // Configure with timing
                uart.write(testString);


            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }

    // missing test for

    function tearDown() {
        return "#{__FILE__} Test finished";
    }
}
