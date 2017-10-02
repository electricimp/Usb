bulkOut <- {
    "address" : 0x2,
    "attributes" : 0x2,
    "maxpacketsize" : 32,
    "interval" : 0
}


bulkIn <- {
    "address" : 0x81,
    "attributes" : 0x2,
    "maxpacketsize" : 32,
    "interval" : 0
}

correctInterface <- {
    "interfacenumber" : 0,
    "altsetting" : 0,
    "class" : 0xFF,
    "subclass" : 0xFF,
    "protocol" : 0xFF,
    "interface" : 0,
    "endpoints" : [bulkIn, bulkOut]
}

correctConfig <- {
    "value" : 1,
    "configuration" : 0,
    "attributes" : 0,
    "maxpower" : 100,
    "interfaces" : [correctInterface]
}

correctDescriptor <- {
    "usb" : 0x0110,
    "class" : 0xFF,
    "subclass" : 0xFF,
    "protocol" : 0xFF,
    "maxpacketsize0" : 8,
    "vendorid" : 0xEE,
    "productid" : 0xCC,
    "device" : 0x1234,
    "manufacturer" : 0,
    "product" : 0,
    "serial" : 0,
    "numofconfigurations" : 1,
    "configurations" : [correctConfig]
}

correctDevice <- {
    "speed" : 1.5,
    "descriptors" : correctDescriptor
}