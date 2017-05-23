
# [UsbHost](./UsbHost/)

The UsbHost class acts as a wrapper around the hardware.usb object and manages USB device connections, disconnections, transfers and driver selection. This library is a prerequisite to other libraries.

Drivers compatible with the UsbHost class extend the UsbDriverBase class. [click here](./UsbHost/USB-DRIVER-BASE.md) for documentation.


# [UartOverUsbDriver](./UartOverUsbDriver/)

The UartOverUsbDriver class creates an interface object that exposes methods similar to the uart object to provide compatability for uart drivers over usb.


# [FtdiUsbDriver](./FtdiUsbDriver/)

The FtdiUsbDriver class exposes methods to interact with an device connected to usb via an ftdi cable.


# License

This library is licensed under the [MIT License](https://github.com/electricimp/thethingsapi/tree/master/LICENSE).