
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

// Keyboard usage page defined by USB specification
// http://www.usb.org/developers/hidpage/Hut1_12v2.pdf
const USAGE_PAGE_KEYBOARD = 7;

// Example class that reduce generic HID API to simple keyset notification.
class HIDKeyboard {

	_keyItems = null;
	_timerTick = false;
	_userCb   = null;

	// ------- Public API ---------------------------------------

	// Static function to check if given HID drivers reports include
	// keyboard related items.
	// Returns:
	//		an instance of HIDKeyboard class or null
	//
	// Notes:
	//		this function tries to find only first HIDReport that contain keyboard report items.
	function checkIfSupport(hidDriver) {
		local itemsToWatch = [];
		foreach (report in hidDriver.getReports()) {
			foreach (item in report.getInputItems()) {
				if (item.attributes.usagePage == USAGE_PAGE_KEYBOARD) {
					itemsToWatch.append(item);
				}
			}

			if (itemsToWatch.len() > 0) break;
		}

		if (itemsToWatch.len() > 0) {
			return HIDKeyboard(itemsToWatch);
		}

		return null;
	}

	// Start keyboard polling.
	// Parameters:
	//		time_ms - poll time in a range of [4 .. 1020] ms
	//      cb		- user callback function that receive keyboard state.
	//				  Its signature is
	//					function callback(keyset), where
	//						keyset is an array of pressed keys
	// Throws:
	// 		if active polling is ongoing
	//
	// Note: the function tries to issue "Set Idle" USB HID command that request keyboard hardware
	//       to setup key matrix poll time. If the command was issued successfully,
	//       this class implementation expects HIDReport.getAsync() will generate next keyboard state
	//		 event after desired amount of time. If the hardware doesn't support the command,
	//       the implementation expects to receive response from HIDReport.getAsync() immediately
	//		 and will use timer to implement IDLE time functionality.
	function startPoll(time_ms, cb) {

		if (null == cb) return;

		if (_userCb != null) throw "Poll is already started";
		local report = _keyItems[0].getReport();
		try {
			report.setIdleTime(time_ms);
		} catch(e) {
			if (e == USB_ERROR_STALL) {
				server.log("Set IDLE is not supported by device. Using poll timer");
				_timerTick = time_ms;
			} else {
				throw "USB error " + e;
			}
		}

		report.getAsync(_reportReadCb.bindenv(this));

		_userCb = cb;
	}

	// Stops keyboard polling.
	function stopPoll() {
		_timerTick = null;
	}

	// --------- private functions section -------------------

	// A callback function that receives notification from HIDReport
	//
	// Parameters:
	//			error  -  possibly error or null
	//			report -  HIDReport instance that calls this function if no error was observed.
	function _reportReadCb(error, report) {
		if (null == error) {
			local keys = [];
			foreach( item in _keyItems) {
				local val = item.get();
				if (null != val) keys.append(val);
			}

			try {
				_userCb(keys);
			} catch (e) {
				server.error("User code exception: " + e);
			}

			if (_timerTick) {
				imp.wakeup(_timerTick, _timerCb.bindenv(this));
			} else {
				report.getAsync(_reportReadCb.bindenv(this));
			}
		} else {
			server.error("Some HID driver issue: " + error);

			_userCb = null;
		}
	}

	// Timer callback function if a hardware doesn't support "Set Idle" command
	function _timerCb() {
		if (null != _timerTick) {
			report.getAsync(_reportReadCb.bindenv(this));
		}
	}

	// Constructor
	// Parameters:
	//			itemsToWatch - an array of HIDReport.Item
	constructor(itemsToWatch) {
		_keyItems = itemsToWatch;
	}
}
