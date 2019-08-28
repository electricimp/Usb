// ********** Imports **********
#require "USB.device.lib.nut:1.1.0"
#require "USB.hub.device.lib.nut:1.0.0"

// ********** Globals **********
hubDriver <- null;

// ********** Functions **********

// This is the callback that is triggered when the USB host detects connected
// devices and loads their drivers. We use it to store a reference to the
// hub's driver for later use
function driverStatusListener(eventType, driver) {
    switch (eventType) {
        case USB_DRIVER_STATE_STARTED:
            if (typeof driver == "HubUsbDriver") {
                hubDriver = driver;
            } else {
                // Checks for other driver types can be included here
            }
            break;
        case USB_DRIVER_STATE_STOPPED:
            if (typeof driver == "HubUsbDriver") {
                hubDriver = null;
            }
    }
}

// ********** Runtime Start **********

// Set up USB
local driverClassArray = [HubUsbDriver];
host <- USB.Host(hardware.usb, driverClassArray);

// Register the driver listener callback
host.setDriverListener(driverStatusListener);

// Register handler(s) for agent-issued messages
agent.on("list.hub.devices", function(ignoredValue) {
    if (hubDriver != null) {
        // We have a  hub present to get a port-status update...
        local ports = hubDriver.checkPorts();
        local sendPorts = [];
        foreach (port, portState in ports) {
            server.log(format("Port %02i is %s", port, portState));
            sendPorts.append(portState);
        }

        // ...and send the result to the agent for browser display
        agent.send("list.hub.devices", sendPorts);
    } else {
        agent.send("error.message", "No USB hub connected to this imp");
    }
});