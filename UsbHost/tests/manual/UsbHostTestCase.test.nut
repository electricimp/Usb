
class UsbHostTestCase extends ImpTestCase {
    // UART on imp005
    dataString = "";
    usbHost = null;
    loadPin = null;

    function setUp() {

        hardware.pinW.configure(DIGITAL_OUT, 1);
        hardware.pinR.configure(DIGITAL_OUT, 1);

        usbHost = UsbHost(hardware.usb);
        usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());
        usbHost.registerDriver(UartOverUsbDriver, UartOverUsbDriver.getIdentifiers());

        return "Hi from #{__FILE__}!";
    }

    function testUsbConnection() {
        this.info("Connect any registered usb device to imp");
        return Promise(function(resolve, reject) {
            usbHost.on("connected", function(device) {
                if (device != null) {
                    resolve("Device Connected");
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    function testUsbDisconnection() {
        this.info("Disconnect the usb device from imp");
        return Promise(function(resolve, reject) {
            usbHost.on("disconnected", function(device) {
                if (device != null) {
                    resolve("Device Disconnected");
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    function tearDown() {
        return "Test finished";
    }
}
