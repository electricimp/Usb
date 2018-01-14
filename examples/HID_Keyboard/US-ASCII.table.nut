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

local HID_INPUT     = [  40,   43,  44,  45,  46,  47,  48,   49,  51,   52,  54,  55,  56];
local ASCII_OUTPUT  = ['\n', '\t', ' ', '-', '=', '[', ']', '\\', ';', '\'', ',', '.', '/'];

// A function that plays a role of table for converting of HID keyboard usage ID to US-ASCII codes
// Used with HIDKeyboard class if this file is included into application code
// NOTE: this is just example function that doesn't process key modifier like CRTL or SHIFT
local US_ASCII_LAYOUT = function (keys) {
        local result = [];
        local index = -1;

        foreach (key in keys) {
            if (key > 3 && key < 30) {
                key =  'a' + (key - 4);
            } else if ((key > 29 && key < 40) ) {
                key = '1' + (key - 30);
            } else if (-1 != (index = HID_INPUT.find(key))) {
                key = ASCII_OUTPUT[index];
            } else { //
                // Zero means error
                key = 0;
            }

            if (key != 0) result.append(key);
        }

        return result;
}
