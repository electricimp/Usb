# UsbHost

The UsbHost Class acts as a wrapper around the hardware.usb object and manages USB device connections, disconnections, transfers and driver selection.

Click [here](https://api.staging.conctr.com/docs) for the full documentation of the Conctr API.

### Setup

**To add this library to your project, add** `#require "usbhost.class.nut:1.0.0"` **to the top of your device code**

## Device Class Usage

### Constructor: UsbHost(*usb*)

Instantiates the UsbHost class. It takes `hardware.usb` as its only parameter.
#### Example

```squirrel
#require "usbhost.class.nut:1.0.0"

usbHost <- UsbHost(hardware.usb);
```
 
### registerDriver(*driverClass, identifiers*)

Registers a driver to a devices list of VID/PID combinations. When a device is connected via usb its VID/PID combination will be looked up and the matching driver will be instantiated to interface with device.

#### Example

```squirrel
#require "usbhost.class.nut:1.0.0"
#require "ftdidriver.class.nut:1.0.0"

usbHost <- UsbHost(hardware.usb);
// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiDriver, FtdiDriver.getIdentifiers());

```

### sendData(*payload[, callback]*)

The *sendData* method is used to send a data payload to Conctr. This function emits the payload to as a "conctr_data" event. The agents sendData() function is called by the corresponding event listener and the payload is sent to Conctr via the data ingeston endpoint. 

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *payload* | Table | Yes | A table containing the data to be sent to Conctr. This keys in the table should correspond to fields from the model and the keys should be of type specified in the model |
| *callback* | Function | No | Function to be called on response from Conctr. The function should take two arguements, *error* and *response*. When no error occurred, the first arguement will be null |

#### Example

```squirrel
local currentTempAndPressure = { "temperature" : 29, "pressure" : 1032};

conctr.sendData(currentTempAndPressure, function(error, response) {
    if (error) {
        server.error("Failed to deliver to Conctr: " + error);
    } else {
        server.log("Data was successfully recieved from the device by Conctr");
    }
}.bindenv(this));
```

### send(*unusedKey, payload[, callback]*)

Alias for *sendData* method above, allows for *conctr.send* to work using the same arguments as the Electic Imp internal `agent.send(key, payload)` 


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *unusedKey* | String | Yes | A string that will be ignored. |
| *payload* | Table | Yes | A table containing the data to be sent to Conctr. This keys in the table should correspond to fields from the model and the keys should be of type specified in the model |
| *callback* | Function | No | Function to be called on response from Conctr. The function should take two arguements, *error* and *response*. When no error occurred, the first arguement will be null |

#### Example

```squirrel
local currentTempAndPressure = { "temperature" : 29, "pressure" : 1032};

conctr.send("any string", currentTempAndPressure, function(error, response) {
    if (error) {
        server.error("Failed to deliver to Conctr: " + error);
    } else {
        server.log("Data was successfully recieved from the device by Conctr");
    }
}.bindenv(this));
```


## License

The Conctr library is licensed under [MIT License](./LICENSE).