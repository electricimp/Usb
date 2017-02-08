#include "usb.nut"
#include "UartLogger.nut"

function sendTestData(device) {
    server.log("sending test data.")
    local testData = blob();

    testData.writestring("I'm a Blob\n");
    device.write(testData);

    imp.wakeup(10, function() {
        sendTestData(device)
    });
}

function onConnected(device) {
    server.log("our onconnected func")
    sendTestData(device);
}

function onDisconnected(devicetype) {
    server.log(devicetype + " disconnected");
}


// UART 'data arrived' function
function readback() {
    local data = uart.readstring();
    logs.log("recieved");
}

server.log("initilized")

// UART on imp005
uart <- hardware.uart1;

// Configure with timing
uart.configure(115200, 8, PARITY_NONE, 1, 0, readback);
logs <- UartLogger(uart);

// power.
loadPin <- hardware.pinS;
loadPin.configure(DIGITAL_OUT);
loadPin.write(1);

usbHost <- UsbHost(hardware.usb, onConnected, onDisconnected);
