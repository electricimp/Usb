class UARTOverUsbTestCase extends ImpTestCase {
    // UART on imp005
    uart = null;
    dataString = "";
    usbHost = null;
    loadPin = null;
    _device = null;

    function setUp() {
        return Promise(function(resolve, reject) {
            // power.
            loadPin = hardware.pinS;
            loadPin.configure(DIGITAL_OUT);
            loadPin.write(1);

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
        return "#{__FILE__} Test finished";
    }
}
