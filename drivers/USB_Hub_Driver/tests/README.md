# USB Hub Driver 1.0.0 Tests #

The tests in this directory are ready to run. Both require imp005- or impC001-based development hardware.

## Setup ##

In both cases, you will need to to connect your USB hub and attached peripherals(s) before running the tests.

The tests require Electric Imp’s [impt](https://github.com/electricimp/imp-central-impt) tool and load in USB Host, FTDI and USB Hub drivers locally from the host machine. You should clone the [USB Host](https://github.com/electricimp/Usb) as well as the USB Hub repos and update the tests lines 44 through 46 to point to the named files on your system.

## Running ##

At the command line, run

```bash
impt tests run
```

to run all the tests.

You can also run the tests individually:

```bash
impt test run --tests HubDriverTestCase1
impt test run --tests HubDriverTestCase2
```

### Test 1 ###

The first test, `HubDriverTestCase1`, checks that the hub driver has loaded and reports back on the number of devices, if any, attached to the hub and provides a readout of the state of the hub’s ports.

Set the constant *NUMBER_OF_DEVICES* in line 49 to the number of devices attached.

### Test 2 ###

The second test, `HubDriverTestCase2`, requires the attachment of a FTDI USB-to-UART adapter. It checks that the hub driver and the [FTDI driver](https://github.com/electricimp/Usb/tree/master/drivers/FT232RL_FTDI_USB_Driver) have loaded. It then attempts to send a text message out via the FTDI. The messagae is read back on one of the imp’s UARTs &mdash; of transmitted and received messages match, the test is considered to have passed.

Set the constant *TX_MESSAGE* in line 44 to the message you wish to send.

## License ##

This library is licensed under the terms of the [MIT License](LICENSE). It is copyright &copy; 2019, Electric Imp, Inc.
