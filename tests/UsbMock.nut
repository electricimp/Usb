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

class UsbMock {

    static validSizes = [8, 16, 32, 64];

    _cb = null;

    function configure(callback) {
        if (typeof callback != "function") throw "Must be function";
        _cb = callback;
    }

    function controltransfer(speed, deviceAddress, endpointAddress,
                             requestType, request, value, index,
                             maxpacketsize, data = null) {
        _checkStatus();
        _checkSpeed(speed);
        _checkEpAddress(endpointAddress);
        _checkPktSize(maxpacketsize);

        if(typeof data == "blob" && data.len() > 0) data.writen(0xEE, 'c');
    }

    function disable() {
        _cb = null;
    }

    function generaltransfer(deviceAddress, endpointAddress, type, data) {
        _checkStatus();
    }

    function openendpoint(speed, deviceAddress, interface, type, maxpacketsize, endpointAddress, interval = 255) {
        _checkStatus();
    }

    // ------------- test API ----------------

    function triggerEvent(event, payload) {
      if (_cb != null)
          _cb(event, payload);
    }

    // ------------- private API --------------

    function _checkStatus() {
        if (null == _cb) throw "Not configured";
    }

    function _checkSpeed(speed) {
        if (speed != 1.5 && speed != 2) throw "Invalid speed value: " + speed;
    }

    function _checkEpAddress(endpointAddress) {
        if ((endpointAddress & (~0xF ^ USB_DIRECTION_MASK)) > 0) throw "Invalid EP address: " + endpointAddress;
    }

    function  _checkPktSize(size) {
        foreach (validSize in validSizes) if (validSize == size) return;

        throw "Invalid max packet size:" + size;
    }

}
