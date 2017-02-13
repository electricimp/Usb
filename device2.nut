#include "UsbHost.nut"
#include "FtdiDriver.nut"
#include "BrotherQL720Driver.nut"
#include "UartLogger.nut"

function sendTestData(device) {
    server.log("sending test data.")
    local initialize = blob(2);
    local getInfoReq = blob(3);
    local setRaster = blob(4);

    initialize.writen(0x1B, 'b');
    initialize.writen(0x40, 'b');

    //Get printer info
    getInfoReq.writen(0x1B, 'b');
    getInfoReq.writen(0x69, 'b');
    getInfoReq.writen(0x53, 'b');

    //Set to Raster mode
    setRaster.writen(0x1B, 'b');
    setRaster.writen(0x69, 'b');
    setRaster.writen(0x61, 'b');
    setRaster.writen(0x11, 'b');

    //device.write(initialize);
  
    //server.log("Set raster");
    //device.write(setRaster);
    //server.log("Get info again");
    device.write(getInfoReq);


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

// Setup USB
hardware.pinW.configure(DIGITAL_OUT, 1);
hardware.pinR.configure(DIGITAL_OUT, 1);
usbHost <- UsbHost(hardware.usb);
usbHost.registerDriver(FtdiDriver, FtdiDriver.getIdentifiers());
usbHost.registerDriver(BrotherQL720Driver, BrotherQL720Driver.getIdentifiers());

usbHost.on("connected", onConnected);






