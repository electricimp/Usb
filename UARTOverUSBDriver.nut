class UARTOverUSBDriver extends DriverBase {

    static VERSION = "1.0.0";

    // Brother QL720 
    static VID = 0x04f9;
    static PID = 0x2044;

    _deviceAddress = null;
    _bulkIn = null;
    _bulkOut = null;
    _buffer = null; // buffer for building text


    constructor(usb) {
        _buffer = blob();
        base.constructor(usb);
    }

    // Metafunction to return class name when typeof <instance> is run
    function _typeof() {
        return "UARTOverUSBDriver";
    }

    // Returns an array of VID PID combinations
    function getIdentifiers() {
        local identifiers = {};
        identifiers[VID] <-[PID];
        return [identifiers];
    }

    // Called by Usb host to initialize driver
    function connect(deviceAddress, speed, descriptors) {
        _setupEndpoints(deviceAddress, speed, descriptors);
        _start();
    }

    // Called when a Usb request is succesfully completed
    function transferComplete(eventdetails) {
        local direction = (eventdetails["endpoint"] & 0x80) >> 7;
        if (direction == USB_DIRECTION_IN) {
            local readData = _bulkIn.done(eventdetails);

            if (readData.len() >= 3) {
                readData.seek(2);
                onEvent("data", readData.readblob(readData.len()));
            }
        } else if (direction == USB_DIRECTION_OUT) {
            _bulkOut.done(eventdetails);
        }
    }

    // Initialize the read buffer
    function _start() {
        _bulkIn.read(blob(1));
    }

    // Write bulk transfer on Usb host
    function write(data) {
        local _data = null;

        if (typeof data == "string") {
            _data = blob();
            _data.writestring(data);
        } else if (typeof data == "blob") {
            _data = data;
        } else {
            server.error("Write data must of type string or blob");
            return;
        }
        _bulkOut.write(_data);
    }
}
