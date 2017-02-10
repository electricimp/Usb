#include "UsbHost.nut"
#include "FtdiDriver.nut"
#include "UartLogger.nut"

function sendTestData(device) {
    server.log("sending test data.")
    local testData = blob();

    testData.writestring("I'm a Blob\n");
    //todo accept strings in the write method
    device.write(testData);

    imp.wakeup(10, function() {
        sendTestData(device)
    });
}

function onConnected(device) {
    device.on("data",dataEvent);
    server.log("our onconnected func")
    sendTestData(device);
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
        logs.log("Received message: " + dataString);
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

usbHost <- UsbHost(hardware.usb);
//todo check that this a class
usbHost.registerDriver(FtdiDriver, FtdiDriver.getIdentifiers());

usbHost.on("connected", onConnected);

// Configure with timing
uart.configure(115200, 8, PARITY_NONE, 1, 0, readback);
logs <- UartLogger(uart);
