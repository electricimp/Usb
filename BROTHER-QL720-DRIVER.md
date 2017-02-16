# BrotherQL720Driver

This class provides device-side USB support for the [Brother BrotherQL720Driver label printer](http://www.brother.co.uk/en/Labelling/QL-Printers/BrotherQL720Driver).

### Setup

**To add this library to your project, add** `#require "brotherql720driver.class.nut:1.0.0"` **to the top of your device code**

This class requires the UsbHost class. The usb host will handle the connection and instantiation of this class. The class and its identifiers must be registered with the UsbHost and the device driver will be passed to the connection callback on the UsbHost. 

#### Example

```squirrel
#require "usbhost.class.nut:1.0.0"
#require "brotherql720driver.class.nut:1.0.0"

// Callback to handle device connection
function onDeviceConnected(device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case ("BrotherQL720Driver"):
            // device is a BrotherQL720Driver printer. Handle it here.
            local printer = device;
            break;
    }
}

// Callback to handle device disconnection
function onDeviceDisconnected(deviceName) {
    server.log(deviceName + " disconnected");
}
usbHost <- UsbHost(hardware.usb);

// Register the BrotherQL720Driver driver with usb host
usbHost.registerDriver(BrotherQL720Driver, BrotherQL720Driver.getIdentifiers());
usbHost.on("connected",onConnected);
usbHost.on("disconnected",onDisconnected);


```
## Class Usage

All public methods in the BrotherQL720Driver class return *this* (ie. the printer object itself), allowing you to easily chain multiple commands together:

```squirrel
printer
    .setOrientation(BrotherQL720Driver.LANDSCAPE)
    .setFont(BrotherQL720Driver.FONT_SAN_DIEGO)
    .setFontSize(BrotherQL720Driver.FONT_SIZE_48)
    .write("San Diego 48 ")
    .print();
```
### Constructor: FtdiDriver(*usb*)

Class instantiation is handled by the UsbHost class.

## Class Methods

### initialize()

The *initialize()* method runs the setup commands to put the printer in ESC/P standard mode and initialize the printer defaults.

```squirrel
printer.initialize();
```

### setOrientation(*orientation*)

The *setOrientation()* method sets the orientation of the printed text. This method takes one required parameter *orientation*, which takes either of the class constants *LANDSCAPE* or *PORTRAIT*.

```squirrel
// Set to landscape mode
printer.setOrientation(BrotherQL720Driver.LANDSCAPE);

// Set to portrait mode
printer.setOrientation(BrotherQL720Driver.PORTRAIT);
```

### setRightMargin(*column*)

The *setRightMargin()* method sets the right margin. This method takes one required parameter: *column*, an integer. The position of the right margin is the character width times *column* from the left edge. See [Margin Notes](#margin-notes) for more details.

### setLeftMargin(*column*)

The *setLeftMargin()* method sets the left margin. This method takes one required parameter: *column*, an integer. The position of the left margin is the character width times *column* from the left edge.

#### Margin Notes

![Margin Column Settings](./MarginFigure.png)

Cases when margin settings are ignored include:

- The left margin is set to the right of the right margin
- The difference between the right and left margins is less than one character
- The print medium is set to continuous length tape with no page length specified and orientation set to landscape

```squirrel
// Print hello and world on different lines using margin settings
printer
  .setOrientation(BrotherQL720Driver.PORTRAIT);
  .setFont(BrotherQL720Driver.FONT_BROUGHAM)
  .setFontSize(BrotherQL720Driver.FONT_SIZE_32)
  .write("Hello, World")
  .setLeftMargin(5)
  .setRightMargin(11)
  .print();
```

### setFont(*font*)

The *setFont()* method sets the font using the *font* parameter, which should be one of the constants listed below:

| Font Constant |
| ------------- |
| *FONT_BROUGHAM* |
| *FONT_LETTER_GOTHIC_BOLD* |
| *FONT_BRUSSELS* |
| *FONT_HELSINKI* |
| *FONT_SAN_DIEGO* |

```squirrel
// Set font to Helsinki
printer.setFont(BrotherQL720Driver.FONT_HELSINKI);
```

### setFontSize(*size*)

The *setFontSize()* method sets the font size using the *size* parameter, which should be one of the constants listed below:

| Size Constant |
| ------------- |
| *FONT_SIZE_24* |
| *FONT_SIZE_32* |
| *FONT_SIZE_48* |

```squirrel
// Set font size to 32
printer.setFont(BrotherQL720Driver.FONT_SIZE_32);
```

### write(*text[, options]*)

The *write()* method sets the text to be printed. This method takes one required parameter, *text*, a string containing the text to be printed. You may also pass one optional parameter, *options*. Options are selected by OR-ing together the class constants ITALIC, BOLD or UNDERLINE. By default no options are set.

**Note** This method only sets the text to be printed. To output the text, you must call the *print()* method.

```squirrel
// Print an underlined and italicized line of text
printer.setFont(BrotherQL720Driver.FONT_SAN_DIEGO)
       .setFontSize(BrotherQL720Driver.FONT_SIZE_48)
       .write("Hello, World", BrotherQL720Driver.UNDERLINE | BrotherQL720Driver.ITALIC )
       .print();
```

### writen(*text[, options]*)

The *writen()* method sets the text to be printed and automatically triggers a line feed at the end. This method takes one required parameter, *text*, a string containing the text to be printed. You may also pass one optional parameter, *options*. Options are selected by OR-ing together the class constants ITALIC, BOLD or UNDERLINE. By default no options are set. 

**Note** This method only sets the text to be printed. To output the text, you must call the *print()* method.

```squirrel
// Print an italicized line of text then an underlined line of text
printer.setFont(BrotherQL720Driver.FONT_SAN_DIEGO)
       .setFontSize(BrotherQL720Driver.FONT_SIZE_48)
       .writen("Hello, World", BrotherQL720Driver.BOLD | BrotherQL720Driver.ITALIC )
       .write("I'm Alive!", BrotherQL720Driver.UNDERLINE )
       .print();
```

### newline()

The *newline()* method appends a new line to the stored data to be printed.

**Note** This method only sets the text to be printed. To output the text, you must call the *print()* method.

```squirrel
// print two lines of text
printer.setFont(BrotherQL720Driver.FONT_SAN_DIEGO)
       .setFontSize(BrotherQL720Driver.FONT_SIZE_48)
       .write("Hello, World")
       .newline()
       .write("I'm Alive!")
       .print();
```

### writeBarcode(*data[, config]*)

The *writeBarcode()* method sets a barcode to be printed. This method takes one required parameter, *data*, and one optional parameter: a table of configuation parameters, as described below.

#### Configuation Table

| Config Table Key | Value Data type | Default Value | Description |
| ---------------- | --------------- | ------------- | ----------- |
| *type* | Barcode Type Constant | *BARCODE_CODE39* | Type of barcode to print (see table below) |
| *charsBelowBarcode* | Boolean | true | Whether to print data below the barcode |
| *width* | Barcode Width Constant | *BARCODE_WIDTH_XS* | Width of barcode (see table below) |
| *height* | Float | 0.5 | Height of barcode in inches |
| *ratio* | Barcode Ratio Constants | *BARCODE_RATIO_2_1* | Ratio between thick and thin bars. Setting available only for type *BARCODE_CODE39*, *BARCODE_ITF*, or *BARCODE_CODABAR* (see table below) |

#### Barcode Type

| Barcode Type Constant | Data Length |
| --------------------- | ----------- |
| *BARCODE_CODE39* | 1-50 characters ("*" is not included) |
| *BARCODE_ITF* | 1-64 characters |
| *BARCODE_EAN_8_13* | 7 characters (EAN-8), 12 characters (EAN-13) |
| *BARCODE_UPC_A* | 11 characters |
| *BARCODE_UPC_E* | 6 characters |
| *BARCODE_CODABAR* | 3-64 characters (Must begin and end with A, B, C, D) |
| *BARCODE_CODE128* | 1-64 characters |
| *BARCODE_GS1_128* | 1-64 characters |
| *BARCODE_RSS* | 3-15 characters (begins with "01") |
| *BARCODE_CODE93* | 1-64 characters |
| *BARCODE_POSTNET* | 5 characters, 9 characters, 11 characters |
| *BARCODE_UPC_EXTENTION* | 2 characters, 5 characters |

#### Barcode Width

| Barcode Width Constant |
| --------------------- |
| *BARCODE_WIDTH_XXS* |
| *BARCODE_WIDTH_XS* |
| *BARCODE_WIDTH_S* |
| *BARCODE_WIDTH_M* |
| *BARCODE_WIDTH_L* |

#### Barcode Ratio

| Barcode Ratio Constant |
| --------------------- |
| *BARCODE_RATIO_2_1* |
| *BARCODE_RATIO_25_1* |
| *BARCODE_RATIO_3_1* |

**Note** This method only sets the barcode to be printed. To print it, you must call the *print()* method.

```squirrel
// Print the device's MAC address as a barcode
barcodeConfig <- {"type" : BrotherQL720Driver.BARCODE_CODE39,
                  "charsBelowBarcode" : true,
                  "width" : BrotherQL720Driver.BARCODE_WIDTH_M,
                  "height" : 1,
                  "ratio" : BrotherQL720Driver.BARCODE_RATIO_3_1 }

printer.writeBarcode(imp.getmacaddress(), barcodeConfig).print();
```

### write2dBarcode(*data[, config]*)

The *write2dBarcode()* method creates a 2D QR barcode. This method takes one required parameter, *data*, and one optional parameter: a table of configuation parameters, as described below.

#### Configuation Table

| Config Table Key | Value Data type | Default Value | Description |
| ---------------- | --------------- | ------------- | ----------- |
| *cell_size* | Cell Size Constant | *BARCODE_2D_CELL_SIZE_3* | Specifies the dot size per cell side (see table below) |
| *symbol_type* | Symbol Type Constant | *BARCODE_2D_SYMBOL_MODEL_2* | Symbol type to be used (see table below) |
| *structured_append_partitioned* | Boolean | `false` | Whether the structured append is partitioned |
| *code_number* | Integer | 0 | Indicates the number of the symbol in a partitioned QR Code. Must set a number between 1-16 if *structured_append_partitioned* is set to `true` |
| *num_partitions* | Integer | 0 | Indicates the total number of symbols in a partitioned QR Code. Must set a number between 2-16 if *structured_append_partitioned* is set to `true` |
| *parity_data* | hexadecimal | 0 | Value in bytes of exclusively OR-ing all the print data (print data before partition) |
| *error_correction* | Error Correction Constant | *BARCODE_2D_ERROR_CORRECTION_STANDARD* | See table below |
| *data_input_method* | Data Input Method Constant | *BARCODE_2D_DATA_INPUT_AUTO* | Auto: *BARCODE_2D_DATA_INPUT_AUTO*, Manual: *BARCODE_2D_DATA_INPUT_MANUAL* |

#### Cell Size

| Cell Size Constant |
| ----------------- |
| *BARCODE_2D_CELL_SIZE_3* |
| *BARCODE_2D_CELL_SIZE_4* |
| *BARCODE_2D_CELL_SIZE_5* |
| *BARCODE_2D_CELL_SIZE_6* |
| *BARCODE_2D_CELL_SIZE_8* |
| *BARCODE_2D_CELL_SIZE_10* |

#### Symbol Type

| Symbol Type Constant |
| ------------------- |
| *BARCODE_2D_SYMBOL_MODEL_1* |
| *BARCODE_2D_SYMBOL_MODEL_2* |
| *BARCODE_2D_SYMBOL_MICRO_QR* |

####Error Correction

| Error Correction Constant | Level |
| ------------------------- | ----- |
| *BARCODE_2D_ERROR_CORRECTION_HIGH_DENSITY* | High-density level: L 7% |
| *BARCODE_2D_ERROR_CORRECTION_STANDARD* | Standard level: M 15% |
| *BARCODE_2D_ERROR_CORRECTION_HIGH_RELIABILITY* | High-reliability level: Q 25% |
| *BARCODE_2D_ERROR_CORRECTION_ULTRA_HIGH_RELIABILITY* | Ultra-high-reliability level: H 30% |

```squirrel
// Print QR code
printer.write2dBarcode(imp.getmacaddress(), {
    "cell_size": BrotherQL720Driver.BARCODE_2D_CELL_SIZE_5,
}).print();
```

**Note** This method only sets the QR code to be printed. To print it, you must call the *print()* method.

### print()

The *print()* method prints the stored data set by the *write()*, *writen()*, *writeBarcode()* and/or *write2dBarcode()* methods.

```squirrel
// Print a line of text
printer.write("Hello, World").print();
```

## To do

- More extensive testing (printer occasionally silently fails)
- Improve 2D barcode implementation to include more than QR codes and support partitioned data input

## License

The BrotherQL720Driver class is licensed under the [MIT License](./LICENSE).