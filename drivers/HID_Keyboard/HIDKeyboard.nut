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
const USAGE_PAGE_KEYBOARD 	= 7;
const USAGE_PAGE_LED 		= 8;

// ID of Num Lock Led to use with HIDKeyboard.SetLEDs
const HID_LED_NUMLOCK		= 1;
// ID of Caps Lock Led to use with HIDKeyboard.SetLEDs
const HID_LED_CAPSLOCK		= 2;
// ID of Scroll Lock Led to use with HIDKeyboard.SetLEDs
const HID_LED_SCROLLLOCK	= 3;


// Example class that reduce generic HID API to simple keyset notification.
class HIDKeyboard extends HIDDriver {

	static VERSION = "1.0.0"

	_timerTick = null;
	_getAsyncUserCb    = null;

	// keyboard layout
	_layout = null;

	// ------- Public API ---------------------------------------

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
		if (_getAsyncUserCb != null) throw "Poll is already started";

		foreach( report in _reports ) {
			try {
				report.setIdleTime(time_ms);
				USB.log("Idle time set to " + time_ms);
			} catch(e) {
				if (e == USB_ERROR_STALL) {
					USB.log("Set IDLE is not supported by device. Using poll timer");
					_timerTick = time_ms;
				} else {
					throw "USB error " + e;
				}
			}

		}

		getAsync(_getAsyncCb.bindenv(this));
		_getAsyncUserCb = cb;
	}

	// Stops keyboard polling.
	function stopPoll() {
		_timerTick  = null;
		_getAsyncUserCb		= null;
	}

	// Update Keyboard LED status
	//
	// Parameters:
	//		ledList - a list of integers with a LED identifier according to HID spec chap.8
	//
	//	Throws if argument is not array or due to USB issue
	//
	// Note: the function report nothing if the device doesn't have any LEDs
	function setLEDs(ledList) {
		if (typeof ledList == "array") {
			local toSend = [];
			foreach (report in _reports) {
				local found = false;
				foreach(item in report.getOutputItems()) {
					foreach (led in ledList) {
						if (item.attributes.usagePage == USAGE_PAGE_LED &&
							item.attributes.usageUsage == led) {
								item.set(1);
								found = true;
						}
					}
				}
				found && toSend.append(report);
			}

			foreach (report in toSend) {
				report.send();
			}
			if (toSend.len() == 0) {
				return "No LED found at the keyboard";
			}
		} else {
			throw "The argument must be Integer array";
		}
	}

    // Notify that driver is going to be released
    // No endpoint operation should be performed at this function.
    function release() {
		stopPoll();
	}

	// Change keyboard layout.
	// Setting NULL force the class to report native HID usage ID.
	//
	// Parameters:
	//	newLayout - function that is used to convert native scancodes to desired values.
	//				the function signature is
	//					functin newLayout(keyArrays), where
	//						keyArray - the array of scancodes (integers)
	function setLayout(newLayout) {
		_layout = newLayout;
	}

	// --------- private functions section -------------------

	// Constructor. Overrides default one by trying to set default keyboard layout
	constructor(reports, interface) {
		base.constructor(reports, interface);
		try {
			_layout = US_ASCII_LAYOUT;
		} catch (e) {
			// no default layout found or not included into the source
			USB.log("Default keyboard layout not found: " + e);
		}
	}

    // Used by HID Report Descriptor parser to check if provided hidItem should be included to the HIDReport.
    //
	// Parameters:
	//		type	- item type [HID_RI_INPUT, HID_RI_OUTPUT, HID_RI_FEATURE]
    //      hidItem - instance of HIDReport.Item
    //
    // Returns true if the item should be included to the report, or false to drop it.
    function _filter(type, hidItem) {
		return  (hidItem.attributes.usagePage == USAGE_PAGE_KEYBOARD ||
				 hidItem.attributes.usagePage == USAGE_PAGE_LED);
	}

    // Used by match() function to create correct class instance in case of this class is overridden.
    //
    // Parameters:
    //      reports     - an array of HIDReport instances
    //      interface   - USB device interface this driver assigned to.
    function _createInstance(reports, interface) {
        return HIDKeyboard(reports, interface);
    }

	// A callback function that receives notification from HIDReport
	//
	// Parameters:
	//			error  -  possibly error or null
	//			report -  HIDReport instance that calls this function if no error was observed.
	function _getAsyncCb(error, report) {

		if (null == _getAsyncUserCb) return;

		if (null == error) {
			local keys = [];
			foreach (item in report.getInputItems()) {
				local val = item.get();
				if (0 != val) {
					keys.append(val);
				}
			}

			if (null != _layout) {
				keys =  _layout(keys);
			}

			_getAsyncUserCb(keys);

			if (_timerTick) {
				imp.wakeup(_timerTick / 1000.0, _timerCb.bindenv(this));
			} else {
				getAsync(_getAsyncCb.bindenv(this));
			}
		} else {
			USB.err("Some HID driver issue: " + error);
			_getAsyncUserCb = null;
		}
	}

	// Timer callback function if a hardware doesn't support "Set Idle" command
	function _timerCb() {
		if (null != _timerTick) {
			getAsync(_getAsyncCb.bindenv(this));
		}
	}

	// Metafunction to return class name when typeof <instance> is run
	function _typeof() {
		return "HIDKeyboard";
	}
}
