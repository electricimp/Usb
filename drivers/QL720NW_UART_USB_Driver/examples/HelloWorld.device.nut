// MIT License
//
// Copyright 2018 Electric Imp
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
//

// This is an example of QL720NW driver usage that prints "Hello,World!" with Bold/Italic fonts.

@include __PATH__ + "./../../../../USB.device.lib.nut"
@include __PATH__ + "./../QL720NWUartUsbDriver.device.lib.nut"

log <- server.log.bindenv(server);

ql720 <- null;

function usbDriverListener(event, data) {
    log("[App]: USB event: " + event);

    if (event == "started") {
        ql720 = data;

        log("Printing \"Hello,World!\"");

        local options = QL720NWUartUsbDriver.ITALIC |
                        QL720NWUartUsbDriver.BOLD   |
                        QL720NWUartUsbDriver.UNDERLINE;

        ql720.setFontSize(48).write("Hello,World!", options).print();
    }
}


usbHost <- USB.Host;
usbHost.init([QL720NWUartUsbDriver]);
log("[App]: USB.Host setup initialized");

usbHost.setDriverListener(usbDriverListener);
log("[App]: USB.Host setEventListener complete");

log("[App]: Waiting for a \"device connected\" event");
