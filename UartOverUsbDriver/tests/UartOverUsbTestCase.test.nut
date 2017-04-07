// The MIT License (MIT)

// Copyright (c) 2017 Mysticpants

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

class UARTOverUsbTestCase extends ImpTestCase {
    // UART on imp005
    uart = null;
    dataString = "";
    usbHost = null;
    loadPin = null;
    _device = null;

    function setUp() {
        return Promise(function(resolve, reject) {

            hardware.pinW.configure(DIGITAL_OUT, 1);
            hardware.pinR.configure(DIGITAL_OUT, 1);

            uart = hardware.uart1;
            usbHost = UsbHost(hardware.usb);
            usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());
            usbHost.registerDriver(UartOverUsbDriver, UartOverUsbDriver.getIdentifiers());
            this.info("Hi from #{__FILE__}!")
            this.info("Connect any Uart over Usb device to imp");

            usbHost.on("connected", function(device) {
                this.info("usb connected")
                if (typeof device == "UartOverUsbDriver") {
                    _device = device;
                    return resolve("Device was a Uart over Usb device");
                }
                reject("Device connected is not a Uart over Usb device");
            }.bindenv(this));
        }.bindenv(this))
    }

    function test2QL720NWDriver() {
        return Promise(function(resolve, reject) {
            if (_device != null) {

                local testString = "I'm a Blob\n";
                local dataString = "";

                local printer = QL720NW(_device);
                server.log("Created printer using uartoverusb")

                printer
                    .setOrientation(QL720NW.LANDSCAPE)
                    .setFont(QL720NW.FONT_SAN_DIEGO)
                    .setFontSize(QL720NW.FONT_SIZE_48)
                    .write("San Diego 48 ")
                    .print();

                resolve("Printed data")


            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }

    function tearDown() {
        return "#{__FILE__} Test finished";
    }
}
