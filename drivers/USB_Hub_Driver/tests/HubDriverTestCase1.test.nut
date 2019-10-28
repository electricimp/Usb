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
//  - imp005 Breakout Board or impC001 Breakout Board
//  - USB hub
//      - Upstream port connected to imp
//      - Downstream port connected to FTDI cable
//  - Any n USB devices connected to the hub
//
//  NOTE Set the number of connected devices BEFORE running the test:
//       Use the NUMBER_OF_DEVICES constant


// Tests
// ---------------------------------------------------------------------

// Includes
@include "github:electricimp/Usb/USB.device.lib.nut"
@include "github:electricimp/Usb/drivers/FT232RL_FTDI_USB_Driver/FT232RLFtdiUsbDriver.device.nut"
@include "github:electricimp/Usb/drivers/USB_Hub_Driver/USB.hub.device.nut"

// Set the number of connected devices BEFORE running the test
const NUMBER_OF_DEVICES = 1;

hubDriver <- null;
usbHost <- null;
usb <- null;
uart <- null;

class USBHubDriverTestCase extends ImpTestCase {

    function setUp() {
        local driverClassArray = [HubUsbDriver, FT232RLFtdiUsbDriver];

        switch(imp.info().type) {
            case "imp005":
                ::usb = hardware.usb;
                ::uart = hardware.uart1;
                ::usbHost = USB.Host(::usb, driverClassArray, true);
                break;
            case "impC001": 
                ::usb = hardware.usbAB;
                ::uart = hardware.uartNU;    
                ::usbHost = USB.Host(::usb, driverClassArray);            
                break;
            default: 
                throw "Unsupported hardware. Setup failed.";
        }
        
        return "USB setup complete";
    }

    // Testing whether the connection event is emitted on device connection
    // and device drivers instantiated are the correct ones.
    // NOTE: Requires manual action from a user to connect correct device before
    //       or during running the tests.
    function testHubConnection() {
        local infoFunc = this.info.bindenv(this);

        return _setUpHost().then(function(hubDrv) {
            return Promise(function(resolve, reject) {
                local ports = hubDrv.checkPorts();
                local numberOfDevices = 0;
                foreach (port, state in ports) {
                    if (state == "connected") {
                        state = "populated";
                        numberOfDevices++;
                    }

                    infoFunc("Port " + port + " is " + state);
                }

                this.assertEqual(NUMBER_OF_DEVICES, numberOfDevices);
                resolve();
            }.bindenv(this));
        }.bindenv(this));
    }

    // Setup USB.Host and wait for to driver start
    function _setUpHost() {
        local infoFunc = this.info.bindenv(this);
        local canSeeHub = false;

        // Reset USB
        ::usbHost.reset();

        return Promise(function(resolve, reject) {
            // report error if no device is attached
            local timer = imp.wakeup(5, function() {
                if (canSeeHub) {
                    resolve(::hubDriver);
                } else {
                    reject("No USB Hub attached to this imp");
                }
            });

            ::usbHost.setDriverListener(function(event, data) {
                if (event == USB_DRIVER_STATE_STARTED) {
                    local driverType = typeof data;
                    infoFunc("Driver of type '" + driverType + "' loaded " + data);
                    if (driverType == "HubUsbDriver") {
                        ::hubDriver = data;
                        canSeeHub = true;
                    }
                }
            });
        }.bindenv(this));
    }
}