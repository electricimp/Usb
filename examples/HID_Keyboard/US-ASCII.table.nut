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

// A function that plays a role of table for converting of HID keyboard usage ID to US-ASCII codes
// Used with HIDKeyboard class if this file is included into application code
// NOTE: this is just example function that doesn't process key modifier like CRTL or SHIFT
local US_ASCII_LAYOUT = function (keys) {
        local result = [];

        foreach (key in keys) {
            if (key > 3 && key < 30) {
                key =  'a' + (key - 3);
            } else if ((key > 29 && key < 40) ) {
                key = '1' + (key - 29);
            } else if (key == 44) {
                key = ' ';
            } else if (key == 43) { // tab
                key = '\t';
            } else if (key > 44 && key < 47) { // - =
                key = '-' + (key - 44);
            } else if (key == 47 || key == 48) { // [ ]
                key = '[' + (key - 47);
            } else if (key == 51 || key == 52) { // ; '
                key = ';' + (key - 51);
            } else if (key == 49) { // \
                key = '\\';
            } else if (key > 53 && key < 57) { // ,./
                key = ',' + key - 53;
            } else { //
                // Zero means error
                key = 0;
            }

            if (key != 0) result.append(key);
        }

        return result;
}
