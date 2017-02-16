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

    // Set printer defaults
    function initialize() {
        write(CMD_ESCP_ENABLE); // Select ESC/P mode
        write(CMD_ESCP_INIT); // Initialize ESC/P mode
        return this;
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


    /* Formating commands */
    
    // Set print orientation
    function setOrientation(orientation) {
        // Create a new buffer that we prepend all of this information to
        local orientationBuffer = blob();
        // Set the orientation
        orientationBuffer.writestring(CMD_SET_ORIENTATION);
        orientationBuffer.writestring(orientation);
        _write(orientationBuffer);
        return this;
    }

    function setRightMargin(column) {
        return _setMargin(CMD_SET_RIGHT_MARGIN, column);
    }

    function setLeftMargin(column) {
        return _setMargin(CMD_SET_LEFT_MARGIN, column);;
    }

    function setFont(font) {
        if (font < 0 || font > 4) throw "Unknown font";

        _buffer.writestring(CMD_SET_FONT);
        _buffer.writen(font, 'b');

        return this;
    }

    function setFontSize(size) {
        if (size != 24 && size != 32 && size != 48) throw "Invalid font size";

        _buffer.writestring(CMD_SET_FONT_SIZE)
        _buffer.writen(size, 'b');
        _buffer.writen(0, 'b');

        return this;
    }

    /* Text commands */

    // Writes text to a buffer
    function write(text, options = 0) {
        local beforeText = "";
        local afterText = "";

        if (options & ITALIC) {
            beforeText += CMD_ITALIC_START;
            afterText += CMD_ITALIC_STOP;
        }

        if (options & BOLD) {
            beforeText += CMD_BOLD_START;
            afterText += CMD_BOLD_STOP;
        }

        if (options & UNDERLINE) {
            beforeText += CMD_UNDERLINE_START;
            afterText += CMD_UNDERLINE_STOP;
        }

        _buffer.writestring(beforeText + text + afterText);

        return this;
    }

    // Writes text + a new line to buffer
    function writen(text, options = 0) {
        return write(text + TEXT_NEWLINE, options);
    }

    // Writes a new line char to buffer
    function newline(lines = 1) {
        for (local i = 0; i < lines; i++) {
            write(TEXT_NEWLINE);
        }
        return this;
    }

    // Barcode commands
    function writeBarcode(data, config = {}) {
        // Set defaults
        if (!("type" in config)) { config.type <- BARCODE_CODE39; }
        if (!("charsBelowBarcode" in config)) { config.charsBelowBarcode <- true; }
        if (!("width" in config)) { config.width <- BARCODE_WIDTH_XS; }
        if (!("height" in config)) { config.height <- 0.5; }
        if (!("ratio" in config)) { config.ratio <- BARCODE_RATIO_2_1; }

        // Start the barcode
        _buffer.writestring(CMD_BARCODE);

        // Set the type
        _buffer.writestring(config.type);

        // Set the text option
        if (config.charsBelowBarcode) {
            _buffer.writestring(BARCODE_CHARS);
        } else {
            _buffer.writestring(BARCODE_NO_CHARS);
        }

        // Set the width
        _buffer.writestring(config.width);

        // Convert height to dots
        local h = (config.height * 300).tointeger();
        // Set the height
        _buffer.writestring("h"); // Height marker
        _buffer.writen(h & 0xFF, 'b'); // Lower bit of height
        _buffer.writen((h / 256) & 0xFF, 'b'); // Upper bit of height

        // Set the ratio of thick to thin bars
        _buffer.writestring(config.ratio);

        // Set data
        _buffer.writestring("\x62");
        _buffer.writestring(data);

        // End the barcode
        if (config.type == BARCODE_CODE128 || config.type == BARCODE_GS1_128 || config.type == BARCODE_CODE93) {
            _buffer.writestring("\x5C\x5C\x5C");
        } else {
            _buffer.writestring("\x5C");
        }

        return this;
    }

    function write2dBarcode(data, config = {}) {
        // Set defaults
        if (!("cell_size" in config)) { config.cell_size <- BARCODE_2D_CELL_SIZE_3; }
        if (!("symbol_type" in config)) { config.symbol_type <- BARCODE_2D_SYMBOL_MODEL_2; }
        if (!("structured_append_partitioned" in config)) { config.structured_append_partitioned <- false; }
        if (!("code_number" in config)) { config.code_number <- 0; }
        if (!("num_partitions" in config)) { config.num_partitions <- 0; }

        if (!("parity_data" in config)) { config["parity_data"] <- 0; }
        if (!("error_correction" in config)) { config["error_correction"] <- BARCODE_2D_ERROR_CORRECTION_STANDARD; }
        if (!("data_input_method" in config)) { config["data_input_method"] <- BARCODE_2D_DATA_INPUT_AUTO; }

        // Check ranges
        if (config.structured_append_partitioned) {
            config.structured_append <- BARCODE_2D_STRUCTURE_PARTITIONED;
            if (config.code_number < 1 || config.code_number > 16) throw "Unknown code number";
            if (config.num_partitions < 2 || config.num_partitions > 16) throw "Unknown number of partitions";
        } else {
            config.structured_append <- BARCODE_2D_STRUCTURE_NOT_PARTITIONED;
            config.code_number = "\x00";
            config.num_partitions = "\x00";
            config.parity_data = "\x00";
        }

        // Start the barcode
        _buffer.writestring(CMD_2D_BARCODE);

        // Set the parameters
        _buffer.writestring(config.cell_size);
        _buffer.writestring(config.symbol_type);
        _buffer.writestring(config.structured_append);
        _buffer.writestring(config.code_number);
        _buffer.writestring(config.num_partitions);
        _buffer.writestring(config.parity_data);
        _buffer.writestring(config.error_correction);
        _buffer.writestring(config.data_input_method);

        // Write data
        _buffer.writestring(data);

        // End the barcode
        _buffer.writestring("\x5C\x5C\x5C");

        return this;
    }

    // Prints the label
    function print() {
        _buffer.writestring(PAGE_FEED);
        _write(_buffer);

        _buffer = blob();
    }

    // Metafunction to return class name when typeof <instance> is run
    function _typeof() {
        return "BrotherQL720Driver";
    }

    // Initialize the read buffer
    function _start() {
        _bulkIn.read(blob(1));
    }

    // Write bulk transfer on Usb host
    function _write(data) {
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

    function _print(text, options = 0) {
        local beforeText = "";
        local afterText = "";

        if (options & ITALIC) {
            beforeText += CMD_ITALIC_START;
            afterText += CMD_ITALIC_STOP;
        }

        if (options & BOLD) {
            beforeText += CMD_BOLD_START;
            afterText += CMD_BOLD_STOP;
        }

        if (options & UNDERLINE) {
            beforeText += CMD_UNDERLINE_START;
            afterText += CMD_UNDERLINE_STOP;
        }

        _buffer.writestring(beforeText + text + afterText);

        return this;
    }

    function _setMargin(command, margin) {
        local marginBuffer = blob();
        marginBuffer.writestring(command);
        marginBuffer.writen(margin & 0xFF, 'b');

        _write(marginBuffer);

        return this;
    }

}
