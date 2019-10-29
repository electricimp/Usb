// MIT License
//
// Copyright 2017 Electric Imp
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

// Various descriptors for tests

bulkOut <- {
    "address"       : 0x2,
    "attributes"    : 0x2,
    "maxpacketsize" : 32,
    "interval"      : 0
}


bulkIn <- {
    "address"       : 0x81,
    "attributes"    : 0x2,
    "maxpacketsize" : 32,
    "interval"      : 0
}

correctInterface <- {
    "interfacenumber" : 0,
    "altsetting"      : 0,
    "class"           : 0xFF,
    "subclass"        : 0xFF,
    "protocol"        : 0xFF,
    "interface"       : 0,
    "endpoints"       : [bulkIn, bulkOut]
}

correctConfig <- {
    "value"         : 1,
    "configuration" : 0,
    "attributes"    : 0,
    "maxpower"      : 100,
    "interfaces"    : [correctInterface]
}

correctDescriptor <- {
    "usb"                 : 0x0110,
    "class"               : 0xFF,
    "subclass"            : 0xFF,
    "protocol"            : 0xFF,
    "maxpacketsize0"      : 8,
    "vendorid"            : 0xEE,
    "productid"           : 0xCC,
    "device"              : 0x1234,
    "manufacturer"        : 0,
    "product"             : 0,
    "serial"              : 0,
    "numofconfigurations" : 1,
    "configurations"      : [correctConfig]
}

correctDevice <- {
    "speed"       : 1.5,
    "descriptors" : correctDescriptor
}