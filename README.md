# USB Drivers Framework

USB Drivers Framework is designed to simplify and standardize USB driver development,
integration with Electric Imp device code. It's primary target audience is:

- Application developers who want to leverage existing drivers
- New USB peripheral drivers developers

The USB driver framework is a wrapper over the `hardware.usb` Squirrel API and is intended to:

1. Unify driver initialization and release process
2. Support multiple drivers used by a single application
3. Provide plug/unplug events handlers on the application level application
4. Address the driver compatibility issues with regards to device vendor, model, etc.

**Note**: when using the framework or any drivers built on top of it, please never use the
`hardware.usb` API directly!

## Documentation Structure

- [Application Development Guide](./docs/ApplicationDevelopmentGuide.md) - the documentation for application developers
- [Driver Development Guide](./docs/DriverDevelopmentGuide.md) - the guide for new USB driver developers


## Driver Examples

Application and driver developers may be interested in examples of
specific device driver implementations. The framework includes the followin driver examples:

- [Generic HID Device Driver](./drivers/GenericHID_Driver/)
- [QL720NW Printer](./drivers/QL720NW_UART_USB_Driver/)
- [FTDI USB-to-UART Converter](./drivers/FT232RL_FTDI_USB_Driver/)
- [Keyboard with HID Protocol](./drivers/HIDKeyboard/)
- [Keyboard with Support for Boot Protocol](./drivers/BootKeyboard/)

**NOTE**: Please use the driver examples for reference only. They were tested with a limited number
of devices and may not support all devices of that type.

# License

This library is licensed under the [MIT License](/LICENSE).
