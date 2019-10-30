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

// ********** Globals **********
savedResponse <- null;

// Register a very basic HTTP request handler function:
// the user is provided instructions in the log: see below.
http.onrequest(function(request, response) {
    server.log("Device list received... querying device");
    try {
        if ("listdevices" in request.query) {
            device.send("list.hub.devices", true);
            savedResponse = response;
        }
    } catch (error) {
        response.send(500, error);
    }
});

// Register handler(s) for device-issued messages
device.on("error.message", function(msg) {
    // Report an error received from the device
    server.error("[USB-HUB-DRIVER] error: " + msg);
});

device.on("list.hub.devices", function(ports) {
    // Return the list of hub port states to the browser
    local respText = "Device USB hub port status:\n";
    foreach (index, portState in ports) {
        respText += format("Port %02i is %s\n", (index + 1), portState);
    }
    if (savedResponse != null) {
        savedResponse.send(200, respText);
        savedResponse = null;
    }
});

// Instruct the developer what to do
local url = http.agenturl();
server.log("Paste the following URL -- between the two | symbols -- into a web browser,");
server.log("in order to receive a report on the status of the ports integrated into the");
server.log("device's connected USB hub:");
server.log(" | " + url + "?listdevices |");
