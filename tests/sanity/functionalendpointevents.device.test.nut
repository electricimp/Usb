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
//

@include __PATH__+"/../../USB.device.lib.nut"
@include __PATH__+"/../UsbMock.nut"
@include __PATH__+"/../CorrectDriver.nut"
@include __PATH__+"/../DescriptorMock.nut"

// Sanity test for USB.FunctionalEndpoint
class UsbFunctionalEndpointEventsSanity extends ImpTestCase {
    _host = null;
    _usb = null;
    _drivers = [CorrectDriver];
    // working device
    _device = null;

    function setUp() {
        _usb = UsbMock();

        // instantiate usb host with mock _usb
        USB.Host.init(_drivers);
        USB.Host._usb = _usb;
        USB.Host.reset();


        _host = USB.Host;

        _usb.triggerEvent(USB_DEVICE_CONNECTED, correctDevice);

        return Promise(function(resolve, reject) {
            imp.wakeup(0, function() {
                local devices = _host.getAttachedDevices();
                assertTrue(devices.len() == 1, "Expected one device item");
                assertEqual("USB._Device", typeof(devices[0]), "Unexpected driver: " + typeof(devices[0]));
                // cache current device
                _device = devices[0];
                resolve();
            }.bindenv(this));
        }.bindenv(this));
    }

    function getInterfaces() {
        return _device.interfaces[0];
    }

    function test01GetEndpoint() {
        // create a new endpoint proxy.
        local ep = bulkIn.get();
        assertTrue(ep != null, "Failed to get correct endpoint");
        local ep_copy = bulkIn.get();
        assertEqual(ep, ep_copy, "Incorrect endpoint return. Expected the same instance of endpoint.");
        local ep_out = bulkOut.get();
        assertTrue(ep_out != null, "Failed to get bulk out endpoint");
    }

    function test02ReadPositive() {
      local ep = bulkIn.get();
      return Promise(function(resolve, reject) {
          ep.read(blob(5), function(epr, error, data, len) {
              assertEqual(ep, epr, "Unexpected endpoint value");
              assertTrue(null == error, "Unexpected error");
              assertEqual(3, len, "Unexpected length of data");
              resolve();
          }.bindenv(this));
          _usb.triggerEvent(USB_TRANSFER_COMPLETED, {
               "device": _device._address,
               "state": 0,
               "endpoint": ep._address,
               "length": 3});
      }.bindenv(this));
    }

    function test02ReadTimeout() {
      local ep = bulkIn.get();
      return Promise(function(resolve, reject) {
          ep.read(blob(5), function(epr, error, data, len) {
              assertEqual(ep, epr, "Unexpected endpoint value");
              assertTrue(error > 0, "Unexpected error");
              assertEqual(0, len, "Unexpected length of data");
              resolve();
          }.bindenv(this));
      }.bindenv(this));
    }

    function test02ReadError() {
      local ep = bulkIn.get();
      return Promise(function(resolve, reject) {
          ep.read(blob(5), function(epr, error, data, len) {
              assertEqual(ep, epr, "Unexpected endpoint value");
              assertTrue(error > 0, "Unexpected error");
              assertEqual(0, len, "Unexpected length of data");
              resolve();
          }.bindenv(this));
          _usb.triggerEvent(USB_TRANSFER_COMPLETED, {
               "device": _device._address,
               "state": 4,
               "endpoint": ep._address,
               "length": 0});
      }.bindenv(this));
    }
}
