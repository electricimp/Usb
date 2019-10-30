// MIT License
//
// Copyright 2019 Electric Imp
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
//  - imp005 Breakout Board
//  - USB hub
//      - Upstream port connected to imp
//      - Downstream port connected to FTDI cable
//  - FT232RL FTDI USB to TTL Serial Adapter cable
//      - USB wired to USB hub downstream port
//      - TX and RX wired to uart1 


// Tests
// ---------------------------------------------------------------------

// Includes
@include __PATH__+"/../../drivers/FT232RL_FTDI_USB_Driver/FT232RLFtdiUsbDriver.device.nut"
@include __PATH__+"/../../drivers/USB_Hub_Driver/USB.hub.device.nut"

const TX_MESSAGE = "Bell-bottoms! Bell-bottoms!"

hubDriver <- null;
ftdiDriver <- null;
usbHost <- null;
uart <- null;
usb <- null;

class USBHubDriverTestCase2 extends ImpTestCase {

    // Set up the peripherals
    function setUp() {
        local driverClassArray = [HubUsbDriver, FT232RLFtdiUsbDriver];
        ::usb = hardware.usb;
        ::uart = hardware.uart1;
        ::usbHost = USB.Host(::usb, driverClassArray, true);
        
        return "USB setup complete";
    }

    // Testing whether the connection event is emitted on device connection
    // and device drivers instantiated are the correct ones.
    // NOTE: Requires manual action from a user to connect correct device before
    //       or during running the tests.
    function testFTDIConnection() {
        local infoFunc = this.info.bindenv(this);

        return _setUpHost().then(function(d) {
            return Promise(function(resolve, reject) {
                // Prepare the UART to receive data
                local rx_text = "";
                ::uart.configure(115200, 8, PARITY_NONE, 1, NO_CTSRTS, function() {
                    local byte = ::uart.read();
                    local done = false;
                    while (byte != -1) {
                        // As long as UART read value is not -1, we're getting data
                        if (byte.tochar() == "\n") {
                            // Got the message end marker
                            done = true;
                            break;
                        }
                        rx_text += byte.tochar();
                        byte = ::uart.read();
                    }

                    if (done) {
                        infoFunc("READ: " + rx_text);
                        this.assertEqual(TX_MESSAGE, rx_text);
                        resolve();
                    }
                }.bindenv(this));

                // Send data via FDTI
                ::ftdiDriver.write(TX_MESSAGE + "\n", function(e, d, l) {
                    if (e != null) {
                        infoFunc("ERROR: " + e);
                    } else {
                        infoFunc("DATA SENT: " + l + " bytes");
                    }
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Setup USB.Host and wait for to driver start
    function _setUpHost() {
        local infoFunc = this.info.bindenv(this);
        local loadedFTDIDriver = false;
        local loadedHubDriver = false;

        // Reset USB
        ::usbHost.reset();

        return Promise(function(resolve, reject) {
            // report error if no device is attached
            local timer = imp.wakeup(5, function() {
                if (loadedFTDIDriver && loadedHubDriver) {
                    resolve();
                } else {
                    reject("Drivers failed to load");
                }
            });

            ::usbHost.setDriverListener(function(event, data) {
                if (event == USB_DRIVER_STATE_STARTED) {
                    local driverType = typeof data;
                    infoFunc("Driver of type '" + driverType + "' loaded " + data);
                    if (driverType == "HubUsbDriver") {
                        ::hubDriver = data;
                        loadedHubDriver = true
                    }

                    if (driverType == "FT232RLFtdiUsbDriver") {
                        ::ftdiDriver = data;
                        loadedFTDIDriver = true
                    }
                }
            });
        }.bindenv(this));
    }

}