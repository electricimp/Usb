#include "UsbHost.nut"
#include "FtdiDriver.nut"
#include "BrotherQL720Driver.nut"
#include "UartLogger.nut"

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
        case "BrotherQL720Driver":
            local getInfoReq = blob(3);
            // Get printer info
            getInfoReq.writen(0x1B, 'b');
            getInfoReq.writen(0x69, 'b');
            getInfoReq.writen(0x53, 'b');

            device
                .setOrientation(BrotherQL720Driver.LANDSCAPE)
                .setFont(BrotherQL720Driver.FONT_SAN_DIEGO)
                .setFontSize(BrotherQL720Driver.FONT_SIZE_48)
                .writeToBuffer("")
                .newline(3)
                .writeToBuffer("+61 (03) 8352-4490", BrotherQL720Driver.BOLD | BrotherQL720Driver.ITALIC)
                .setLeftMargin(8)
                // .print();
            break;
        case "FtdiDriver":
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


// UART 'data arrived' function
function readback() {

    dataString += uart.readstring();
    if (dataString.find("\n")) {
        server.log("Recieved data on UART [" + dataString + "] Sending data back to USB");
        logs.write("Hi from UART");
        dataString = "";
    }

}

// UART on imp005
uart <- hardware.uart1;
dataString <- "";

// power.
loadPin <- hardware.pinS;
loadPin.configure(DIGITAL_OUT);
loadPin.write(1);

hardware.pinW.configure(DIGITAL_OUT, 1);
hardware.pinR.configure(DIGITAL_OUT, 1);

usbHost <- UsbHost(hardware.usb);
usbHost.registerDriver(FtdiDriver, FtdiDriver.getIdentifiers());
usbHost.registerDriver(BrotherQL720Driver, BrotherQL720Driver.getIdentifiers());

usbHost.on("connected", onConnected);

// Configure with timing
uart.configure(115200, 8, PARITY_NONE, 1, 0, readback);
logs <- UartLogger(uart);
