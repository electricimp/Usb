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
function sendTestData(device) {
    server.log("sending test data.")
    device.write("I'm a Blob\n");
    imp.wakeup(10, function() {
        sendTestData(device)
    });
}

function onConnected(device) {
    device.on("data", dataEvent);
    switch (typeof device) {
        case "UartOverUsbDriver":
            printer <- QL720NW(device);
            server.log("Created printer using uartoverusb")

            printer
                .setOrientation(QL720NW.LANDSCAPE)
                .setFont(QL720NW.FONT_SAN_DIEGO)
                .setFontSize(QL720NW.FONT_SIZE_48)
                .write("San Diego 48 ")
                .print();

            
            barcodeConfig <- {
                "type": QL720NW.BARCODE_CODE39,
                "charsBelowBarcode": true,
                "width": QL720NW.BARCODE_WIDTH_M,
                "height": 1,
                "ratio": QL720NW.BARCODE_RATIO_3_1
            }

            printer.writeBarcode(imp.getmacaddress(), barcodeConfig).print();
            break;
        case "FtdiUsbDriver":
            sendTestData(device);
            break;
    }
}

function dataEvent(eventDetails) {
    server.log("got data on usb: " + eventDetails);
}

function onDisconnected(devicetype) {
    server.log(devicetype + " disconnected");
}



function readback() {

    dataString += uart.readstring();
    if (dataString.find("\n")) {
        server.log("Recieved data on UART [" + dataString + "] Sending data back to USB");
        logs.write("Hi from UART");
        dataString = "";
    }

}


uart <- hardware.uart1;
dataString <- "";


loadPin <- hardware.pinS;
loadPin.configure(DIGITAL_OUT);
loadPin.write(1);

hardware.pinW.configure(DIGITAL_OUT, 1);
hardware.pinR.configure(DIGITAL_OUT, 1);

usbHost <- UsbHost(hardware.usb);

usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());



vid <- 0x04f9;
pid <- 0x2044;
identifier <- {};
identifier[vid] <- pid;
identifiers <- [identifier]
usbHost.registerDriver(UartOverUsbDriver, identifiers);


usbHost.on("connected", onConnected);


uart.configure(115200, 8, PARITY_NONE, 1, 0, readback);
logs <- UartLogger(uart);
*/