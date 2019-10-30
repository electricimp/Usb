# Tests Instructions #

The tests in the current directory are intended to check the behavior of the USB library and example drivers. They are written for and should be used with [*impt*](https://github.com/electricimp/imp-central-impt). 

All the tests require USB hardware to be attached at the time when the tests are run. For convenience the tests have been split into two catagories: *sanity*, tests that have a common configuration, and *manual*, tests that require custom hardware configurations. Each *manual* test file contains the hardware setup required for that test. 

This repository's test configuration file, `.impt.test`, is set up to run only the *sanity* tests. If you wish to run *manual* tests the configuration file will need to be updated. Please see the [*impt* Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for details on how to configure and run the tests.

## Setup ##

All tests have been configured to run on an imp005 breakout board.

### Sanity ###

These tests require the following hardware:

- imp005 Breakout Board
- FT232RL FTDI USB to TTL Serial Adapter cable

### Manual ###

Details about the USB peripherals and set up can be found in each test file. Hardware needed for these tests include the following: 

- imp005 Breakout Board
- FT232RL FTDI USB to TTL Serial Adapter cable
- Any HID device (mouse, keyboard, joystick)
- Any USB keyboard (ie Logitech K120)
- Brother QL-720NW label printer
- Jumper wires

## Running ##

Once your hardware is configured, create or update the impt test configuration file to run selected tests on your device/device group. Please see the [*impt* Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for details. Log into your Electric Imp account using impt command line tool, then run with the following command:

```bash
impt test run
```
