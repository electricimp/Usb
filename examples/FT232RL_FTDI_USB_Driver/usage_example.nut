#require "USB.device.lib.nut:0.2.0"

// Initialize USB Host
usbHost <- USB.Host(hardware.usb);

// Register the Ftdi driver with USB Host
usbHost.registerDriver(FT232RLFtdiUsbDriver);

// Log instructions for user
server.log("USB listeners opened.  Plug and unplug FTDI board in to see logs.");
