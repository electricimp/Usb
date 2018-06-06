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

class FT232RLFtdiUsbDriverTestCase extends ImpTestCase {
    // UART on imp005
    _uart = null;
    _usbHost = null;
    _driver = null;

    function setUp() {
        // Initialize UART
        uart = hardware.uart1;
    }

    // Testing whether the connection event is emitted on device connection
    // and device driver instantiated is the correct one.
    // NOTE: Requires manual action from a user to connect correct device before
    //       or during running the tests.
    function test1_FtdiConnection() {
        this.info("Connect any Ftdi device to imp");
        return Promise(function(resolve, reject) {

            // Initialize USB Host & register driver to be tested
            _usbHost = USB.Host(hardware.usb, [FT232RLFtdiUsbDriver]);

            // Listen for a connection event
            _usbHost.setEventListener(function(eventName, eventDetails) {

                // Check the device is an instance of FT232RLFtdiUsbDriver
                if (eventName == USB_DRIVER_STATE_STARTED) {
                    if (typeof eventDetails == "FT232RLFtdiUsbDriver") {

                        // Store the driver for the next test
                        _driver = eventDetails;
                        return resolve("Device was a valid ftdi device");
                    }
                    // Wrong device was connected
                    reject("Device connected is not a ftdi device");
                }

            }.bindenv(this));
        }.bindenv(this))
    }

    // Test whether a message sent via usb to UART on the same device
    // is successfully received
    function test2_FtdiUsbSending() {
        return Promise(function(resolve, reject) {

            // Check there is a valid device driver
            if (_driver != null) {

                // Set up test vars
                local testString = "I'm a Blob\n";
                local dataString = "";

                // Configure with timing
                _uart.configure(115200, 8, PARITY_NONE, 1, 0, function() {
                    dataString += _uart.readstring();

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

                _driver.write(testString, function(error, payload, length) {
                    // Handle write completion
                    if (error != USB_ERROR_IDLE && error != USB_ERROR_FREE) {
                        reject("Data writing error");
                    }
                });

            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }

    // Test whether a message can be successfully received via usb over an
    // ftdi connection
    function test3_FtdiUsbRecieving() {
        return Promise(function(resolve, reject) {

            // Check there is a valid device driver
            if (_driver != null) {

                local testString = "I'm a Blob";

                // Configure with timing
                _uart.configure(115200, 8, PARITY_NONE, 1, 0);

                // Write the test string from UART to USB
                _uart.write(testString);

                // Set up a listener for data events
                _driver.read(function(error, data, length) {
                    // Check the data received matches the sent string
                    if ( (error == USB_ERROR_IDLE || error == USB_ERROR_FREE) &&
                         data.tostring() == testString) {
                        resolve("Recieved data on Usb from Uart");
                    } else {
                        reject("Invalid data was received on Usb from Uart")
                    }
                }.bindenv(this))
            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }
}
