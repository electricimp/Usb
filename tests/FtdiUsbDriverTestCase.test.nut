class UsbHostTestCase extends ImpTestCase {
    // UART on imp005
    uart = null;
    dataString = "";
    usbHost = null;
    loadPin = null;
    _device = null;

    function setUp() {
        // power.
        loadPin = hardware.pinS;
        loadPin.configure(DIGITAL_OUT);
        loadPin.write(1);

        hardware.pinW.configure(DIGITAL_OUT, 1);
        hardware.pinR.configure(DIGITAL_OUT, 1);

        uart = hardware.uart1;
        usbHost = UsbHost(hardware.usb);
        usbHost.registerDriver(FtdiDriver, FtdiDriver.getIdentifiers());
        usbHost.registerDriver(UARTOverUSBDriver, UARTOverUSBDriver.getIdentifiers());


        return "Hi from #{__FILE__}!";
    }

    function testFtdiConnection() {
        this.info("Connect any Ftdi device to imp");
        return Promise(function(resolve, reject) {
            usbHost.on("connected", function(device) {
                if (typeof device == "FtdiDriver") {
                    _device = device;
                    return resolve("Device was a Ftdi device");
                }
                reject("Device connected is not a ftdi device");
            }.bindenv(this));
        }.bindenv(this))
    }


    function testFtdiUsbSending() {
        return Promise(function(resolve, reject) {
            if (_device != null) {

                local testString = "I'm a Blob\n";
                local dataString = "";

                // Configure with timing
                uart.configure(115200, 8, PARITY_NONE, 1, 0, function() {
                    dataString += uart.readstring();
                    if (dataString.find("\n")) {
                        if (testString == dataString) {
                            resolve("Recieved sent message on Uart");
                        } else {
                            reject("Data recieved did not match");
                        }
                        dataString = "";
                    }
                }.bindenv(this));

                _device.write(testString);

            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }

    function testFtdiUsbRecieving() {
        return Promise(function(resolve, reject) {
            if (_device != null) {

                local testString = "I'm a Blob";
                local dataString = "";

                _device.on("data", function(data) {
                    this.info(typeof data);
                    this.info(typeof testString);
                    this.info(data.tostring() == testString);
                        if (data.tostring() == testString) {
                            resolve("Recieved data on Usb from Uart");
                        } 
                    }.bindenv(this))
                // Configure with timing
                uart.configure(115200, 8, PARITY_NONE, 1, 0);
                    // Configure with timing
                uart.write(testString);


            } else {
                reject("No device connected");
            }
        }.bindenv(this))
    }

    function tearDown() {
        return "#{__FILE__} Test finished";
    }
}
