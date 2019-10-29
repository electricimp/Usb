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
//  - Brother QL-720NW label printer

// Software Dependencies
//  - QL720NW Driver Class

// Tests
// ---------------------------------------------------------------------

@include "github:electricimp/electricimp/QL720NW/QL720NW.device.lib.nut"
@include __PATH__+ "/../../USB.device.lib.nut"
@include __PATH__+ "/../../drivers/QL720NW_UART_USB_Driver/QL720NWUsbToUartDriver.device.nut"

class QL720NWUartUsbDriverTestCase extends ImpTestCase {

    dataString  = "";
    usbHost     = null;
    _printer    = null;
    getInfo     = "/x1B/x69/x53";

    // Test connection of valid device instantiated driver
    function test1_UartOverUsbConnection() {


        // Request user to connect the correct device to imp
        this.info("Connect any Uart over Usb device to imp");

        return Promise(function(resolve, reject) {
            usbHost = USB.Host(hardware.usb, [QL720NWUartUsbDriver], true);

            // Register cb for connection event
            usbHost.setDriverListener(function(event, driver) {

                if (event == USB_DRIVER_STATE_STARTED) {
                    // Check the device is an instance of QL720NWUartUsbDriver
                    if (typeof driver == "QL720NWUartUsbDriver") {

                        // Store the driver for the next test
                        _printer = QL720NW(driver);

                        return resolve("Device was a Uart over Usb device");
                    }
                    // Wrong device was connected
                    reject("Device connected is not a Uart over Usb device");

                }

            }.bindenv(this));
        }.bindenv(this))
    }


    // Tests the driver is compatible with a uart device
    function test2_UartPrinterDriver() {
        return Promise(function(resolve, reject) {

            // Check there is a valid device driver
            if (_printer != null) {

                local testString = "I'm a Blob\n";
                local dataString = "";

                _printer
                    .setOrientation(QL720NW_LANDSCAPE)
                    .setFont(QL720NW_FONT_SAN_DIEGO)
                    .setFontSize(QL720NW_FONT_SIZE_48)
                    .write("San Diego 48 ")
                    .print();

                // Configure Barcode
                local barcodeConfig = {
                    "type": QL720NW_BARCODE_CODE39,
                    "charsBelowBarcode": true,
                    "width": QL720NW_BARCODE_WIDTH_M,
                    "height": 1,
                    "ratio": QL720NW_BARCODE_RATIO_3_1
                };

                // Print bacode of the imp's mac address
                _printer.writeBarcode(imp.getmacaddress(), barcodeConfig).print();

                // Requires manual validation
                resolve("Printed data");


            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }
}
