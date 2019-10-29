// MIT License
//
// Copyright 2019 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// This is an example of keyboard control application
// NOTE: The code below should be built with Builder preprocessor, https://github.com/electricimp/builder

// Hardware connected via a USB: 
//      imp005 breakout board
//      Anker A7516 - 4 Port Ultra Slim USB 3.0 Data Hub


// ********** Imports **********
#require "USB.device.lib.nut:1.1.0"

@include "github:electricimp/usb/drivers/USB_Hub_Driver/USB.hub.device.nut@develop"

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

// Set up USB on an imp005 using the auto configure pins option
local driverClassArray = [HubUsbDriver];
host <- USB.Host(hardware.usb, driverClassArray, true);

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