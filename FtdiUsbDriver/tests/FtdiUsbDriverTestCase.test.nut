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
        // Initialize UART
        uart = hardware.uart1;

        // Initialize USB Host & register driver to be tested
        usbHost = USB.Host(hardware.usb);
        usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

        return "Hi from #{__FILE__}!";
    }

    // Testing whether the connection event is emitted on device connection
    // and device driver instantiated is the correct one. 
    // NOTE: Requires manual action from a user to connect correct device before 
    //       or during running the tests.
    function testFtdiConnection() {
        this.info("Connect any Ftdi device to imp");
        return Promise(function(resolve, reject) {

            // Listen for a connection event
            usbHost.on("connected", function(device) {

                // Check the device is an instance of FtdiUsbDriver
                if (typeof device == "FtdiUsbDriver") {

                    // Store the driver for the next test
                    _device = device;
                    return resolve("Device was a valid ftdi device");
                }

                // Wrong device was connected
                reject("Device connected is not a ftdi device");
            }.bindenv(this));
        }.bindenv(this))
    }

    // Test whether a message sent via usb to UART on the same device
    // is successfully received
    function testFtdiUsbSending() {
        return Promise(function(resolve, reject) {

            // Check there is a valid device driver
            if (_device != null) {

                // Set up test vars
                local testString = "I'm a Blob\n";
                local dataString = "";

                // Configure with timing
                uart.configure(115200, 8, PARITY_NONE, 1, 0, function() {
                    dataString += uart.readstring();

                    // New line char means we got a full line
                    if (dataString.find("\n")) {

                        // Check if the correct message was received
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

    // Test whether a message can be successfully received via usb over an
    // ftdi connection
    function testFtdiUsbRecieving() {
        return Promise(function(resolve, reject) {

            // Check there is a valid device driver
            if (_device != null) {

                local testString = "I'm a Blob";
                local dataString = "";

                // Set up a listener for data events
                _device.on("data", function(data) {

                        // Check the data received matches the sent string
                        if (data.tostring() == testString) {
                            resolve("Recieved data on Usb from Uart");
                        }else {
                            reject("Invalid data was received on Usb from Uart")
                        }
                    }.bindenv(this))

                // Configure with timing
                uart.configure(115200, 8, PARITY_NONE, 1, 0);

                // Write the test string from UART to USB
                uart.write(testString);
            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }

    function tearDown() {
        return "#{__FILE__} Test finished";
    }
}
