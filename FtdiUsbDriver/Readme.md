# FtdiUsbDriver

The FtdiUsbDriver class exposes methods to interact with an device connected to usb via an ftdi cable. 

### Setup

**The USB class must be required before this driver class at the top of the device code. As shown below:**

```
#require "USB.device.lib.nut:1.0.0"
#require "FtdiUsbDriver.device.lib.nut:1.0.0"
```

The [USB.Host](../USB/) will handle the connection/disconnection events and instantiation of this class. This class and its identifiers will be registered with the [USB.Host](../USB/) and when a device with matching identifiers is connected the device driver will be instantiated and passed to the `"connection"` event callback registered with the [USB.Host](../USB/). As this can be confusing an example of receiving an instantiated driver object is shown below:

#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FtdiUsbDriver.device.lib.nut:1.0.0"

// Callback function to handle device connection
function onDeviceConnected(device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case ("FtdiUsbDriver"):
            // device is a ftdi device. Handle it here.
            break;
    }
}

// Callback to handle device disconnection
function onDeviceDisconnected(deviceName) {
    server.log(deviceName + " disconnected");
}
// Instantiated usb host
usbHost <- USB.Host(hardware.usb);

// Register the Ftdi driver with usb host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

// Set up callbacks for connection/disconnection events
usbHost.on("connected",onDeviceConnected);
usbHost.on("disconnected",onDeviceDisconnected);

// Log instructions for user
server.log("USB listeners opened.  Plug FTDI board in to see logs.");
```

## Device Class Usage

### Constructor: FtdiUsbDriver(*usb*)

Class instantiation is handled by the [USB.Host](../USB/) class. This class should not be manually instantiated.


### getIdentifiers()

Returns an array of tables with VID-PID key value pairs respectively. Identifiers are used by the [USB.Host](../USB/) to instantiate the corresponding devices driver.


#### Example

```squirrel
#require "FtdiUsbDriver.device.lib.nut:1.0.0"

local identifiers = FtdiUsbDriver.getIdentifiers();

foreach (i, identifier in identifiers) {
    foreach (VID, PID in identifier){
        server.log("VID =" + VID + " PID = " + PID);
    }
}

```

### on(*eventName, callback*)

Subscribe a callback function to a specific event.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to subscribe to. |
| *callback* | Function | Yes | Function to be called on event |

Events emitted by this class:
| eventName | Data Type Returned |  Description |
| --- | ---------  | ----------- |
| *data* | [blob](https://electricimp.com/docs/squirrel/blob/) |Called when data is received over usb. A blob containing the data is called as the only arguement to the callback function.|
#### Example
Replace the `onDeviceConnected` function in the example shown in the setup section with the one below.
```squirrel

// Callback to handle device connection
function onDeviceConnected(device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case ("FtdiUsbDriver"):
            device.on("data", function (data){
                server.log("Recieved " + data + " via usb");
            });
            server.log("listening for data events");
            break;
    }
}

```

### off(*eventName*)

Clears a subscribed callback function from a specific event.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *eventName* | String | Yes | The string name of the event to unsubscribe from.|


#### Example
Replace the `onDeviceConnected` function in the example shown in the setup section with the one below.
```squirrel

// Callback to handle device connection
function onDeviceConnected(device) {
    server.log(typeof device + " was connected!");
    switch (typeof device) {
        case ("FtdiUsbDriver"):

            // Listen for data events
            device.on("data", function(data) {
                server.log("Recieved " + data + " via usb");
            });
            server.log("listening for data events");

            // Cancel data events listener after 5 seconds
            imp.wakeup(5, function() {
                device.off("data");
                server.log("stopped listening for data events");
            }.bindenv(this))

            break;
    }
}


```


### write(data)

Writes String or Blob data out to ftdi.


| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| *data* | String/Blob | Yes | The String or Blob to be written to ftdi.|


#### Example

```squirrel
#require "USB.device.lib.nut:1.0.0"
#require "FtdiUsbDriver.device.lib.nut:1.0.0"

usbHost <- USB.Host(hardware.usb);

// Register the Ftdi usb driver driver with usb host
usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());

usbHost.on("connected",function (device) {
    switch (typeof device) {
        case ("FtdiUsbDriver"):
            device.write("Testing ftdi over usb");
            break;
    }
});

// Log instructions for user
server.log("USB listeners opened.  Plug FTDI board in to see logs.");
```

## License

The FtdiUsbDriver is licensed under [MIT License](../LICENSE).
