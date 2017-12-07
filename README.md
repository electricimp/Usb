# USB Drivers Framework

USB Drivers Framework is intended to simplify and standardize USB driver creation, integration and usage in your IMP device code. It consists of several abstractions and can be used by two types of developers:
- if you want to utilize the existing USB drivers in your application, see an [Application Development Guide](./ApplicationDevelopentGuide.md);
- if you want to create and add a new USB driver, see [Driver Development Guide](./DriverDevelopmentGuide.md) below.

## Common introduction

ElectricImp platform provides base abstraction for a usb API over the native code see [hardware.usb](https://electricimp.com/docs/api/hardware/usb/). By default imp005 has USB port only but probably your are working on some custom board which also has USB port (or several USB ports).
The `hardware.usb` api gives the direct access to the usb configurations, interfaces and endpoints and allow to perform usb operations like control or bulk transfer. Based on that api developer could create device library which could interact with concrete device and such library will be called as *DRIVER* in all documentation.
The `hardware.usb` API does not provide any restrictions for a driver developers which could lead to vendor incompatible drivers and inability to use several drivers simultaneously in a single application, therefore it is not recommended to use `hardware.usb` directly for a driver creation.

For this purpose USB Drivers Framework is a pure squirrel library which wrap the native `hardware.usb` api, it was intended for standardization of the driver process creation and unify the application development. And of course the main features of the framework are multiple drivers support and runtime plug an unplug feasibility. USB Framework wraps all methods of the `hardware.usb`, which allow driver developer handle USB reset in common way for all drivers and do not care about `hardware.usb` methods call for an un-pluged device.
The framework impose a constraints on driver development but they are minimal: first of all it is prohibited to access to the `hardware.usb` api directly and the second limitation is that each driver should implement `match()` and `release()` methods [see driver development guide](./DriverDevelopmentGuide.md).
There is no more limitations for the driver API therefore each driver could provide it's own custom API.
It is important for an application developer to read driver API first (for each included driver) and for a driver developers it is important to provide detailed documentation on driver API.

USB Driver Framework make it possible to cooperate multiple drivers in a single application it means that application developer could simply include custom driver library without investigation of it's internals therefore. And driver developer should implement `match()` method very carefully to avoid matching to a wrong device see [multiple device support](./ApplicationDevelopentGuide.md#multiple-device-support) Application Development Guide and [match() method](./DriverDevelopmentGuide.md#match) of the Driver Development Guide.

# License

This library is licensed under the [MIT License](/LICENSE).
