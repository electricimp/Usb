# USB Drivers Framework #

The USB Drivers Framework is designed to simplify and standardize USB driver development and integration with Electric Imp device code. Its primary audience comprises:

- Application developers who want to leverage existing drivers.
- USB peripheral driver developers.

The USB Drivers Framework is a wrapper over the imp API’s [**hardware.usb**](https://developer.electricimp.com/api/hardware/usb) object and is intended to:

1. Unify driver initialization and the release process.
2. Support the use of multiple drivers by a single application.
3. Provide plug and unplug events handlers on the application level.
4. Address the driver compatibility issues with regards to device vendor, model, etc.

**Note** When using the framework or any driver built on top of it, please do not use the **hardware.usb** object directly.

## Documentation Structure ##

- [Application Development Guide](./docs/ApplicationDevelopmentGuide.md) &mdash' the documentation for application developers
- [Driver Development Guide](./docs/DriverDevelopmentGuide.md) &mdash; the guide for new USB driver developers

## Driver Examples ##

Application and driver developers may be interested in examining examples of specific device driver implementations. The following drivers are available as examples:

- [Generic HID Device Driver](./drivers/GenericHID_Driver/)
- [QL720NW Printer](./drivers/QL720NW_UART_USB_Driver/)
- [FTDI USB-to-UART Converter](./drivers/FT232RL_FTDI_USB_Driver/)
- [Keyboard with HID Protocol](./drivers/HIDKeyboard/)
- [Keyboard with Support for Boot Protocol](./drivers/BootKeyboard/)

**Note** Please use the driver examples for reference only. They were tested with a limited number of devices and may not support all devices of that type.

## License ##

This framework is licensed under the [MIT License](/LICENSE).
