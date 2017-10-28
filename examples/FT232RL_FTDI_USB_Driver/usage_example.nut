#require "USB.device.lib.nut:0.2.0"
#require "FT232RLFtdiUsbDriver.device.lib.nut:1.0.0"

// Initialize USB Host
usbHost <- USB.Host(hardware.usb, [FT232RLFtdiUsbDriver]);

usbHost.setEventListener(function(eventName, eventDetails) {
    if (eventName == "started") {
        server.log("FT232RLFtdiUsbDriver started");
        local drvier = eventDetails;
        driver.write("Example message", function(error, data, length) {
          if (!error) {
            server.log("Test message send");
          }
          else {
            server.error("FT232RLFtdiUsbDriver write error: " + error);
          }
        });
    }
});

// Log instructions for user
server.log("USB listeners opened.  Plug and unplug FTDI board in to see logs.");
