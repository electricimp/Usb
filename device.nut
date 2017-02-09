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
    dataString += data;
    if (data.find("\n")) {
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
usbHost.registerDriver(FtdiDriver, FtdiDriver.getIdentifiers());

usbHost.on(USB_DEVICE_CONNECTED, onConnected);

// Configure with timing
uart.configure(115200, 8, PARITY_NONE, 1, 0, readback);
logs <- UartLogger(uart);
