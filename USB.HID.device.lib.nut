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

// HID Input, Output and Feature Report Item Flags
// May be useful for an application
const HID_IOF_CONSTANT              =   0x01;
const HID_IOF_DATA                  =   0x00;
const HID_IOF_VARIABLE              =   0x02;
const HID_IOF_ARRAY                 =   0x00;
const HID_IOF_RELATIVE              =   0x04;
const HID_IOF_ABSOLUTE              =   0x00;
const HID_IOF_WRAP                  =   0x08;
const HID_IOF_NO_WRAP               =   0x00;
const HID_IOF_NON_LINEAR            =   0x10;
const HID_IOF_LINEAR                =   0x00;
const HID_IOF_NO_PREFERRED_STATE    =   0x20;
const HID_IOF_PREFERRED_STATE       =   0x00;
const HID_IOF_NULLSTATE             =   0x40;
const HID_IOF_NO_NULL_POSITION      =   0x00;
const HID_IOF_VOLATILE              =   0x80;
const HID_IOF_NON_VOLATILE          =   0x00;
const HID_IOF_BUFFERED_BYTES        =   0x100;
const HID_IOF_BITFIELD              =   0x00;

// HID Report Descriptor Item Types and Tags
// No so useful for an application
const HID_RI_DATA_SIZE_MASK         =  0x03;
const HID_RI_TYPE_MASK              =  0x0C;
const HID_RI_TAG_MASK               =  0xF0;

const HID_RI_TYPE_MAIN              =  0x00;
const HID_RI_TYPE_GLOBAL            =  0x04;
const HID_RI_TYPE_LOCAL             =  0x08;

const HID_RI_DATA_BITS_0            =  0x00;
const HID_RI_DATA_BITS_8            =  0x01;
const HID_RI_DATA_BITS_16           =  0x02;
const HID_RI_DATA_BITS_32           =  0x03;

const HID_RI_INPUT                  = 0x80;
const HID_RI_OUTPUT                 = 0x90;
const HID_RI_COLLECTION             = 0xA0;
const HID_RI_FEATURE                = 0xB0;
const HID_RI_END_COLLECTION         = 0xC0;
const HID_RI_USAGE_PAGE             = 0x04;
const HID_RI_LOGICAL_MINIMUM        = 0x14;
const HID_RI_LOGICAL_MAXIMUM        = 0x24;
const HID_RI_PHYSICAL_MINIMUM       = 0x34;
const HID_RI_PHYSICAL_MAXIMUM       = 0x44;
const HID_RI_UNIT_EXPONENT          = 0x54;
const HID_RI_UNIT                   = 0x64;
const HID_RI_REPORT_SIZE            = 0x74;
const HID_RI_REPORT_ID              = 0x84;
const HID_RI_REPORT_COUNT           = 0x94;
const HID_RI_PUSH                   = 0xA4;
const HID_RI_POP                    = 0xB4;
const HID_RI_USAGE                  = 0x08;
const HID_RI_USAGE_MINIMUM          = 0x18;
const HID_RI_USAGE_MAXIMUM          = 0x28;

const HID_REPORT_ITEM_IN            = 0;
const HID_REPORT_ITEM_OUT           = 1;
const HID_REPORT_ITEM_FEATURE       = 2;

// USB protocol HID related constants
const USB_DESCRIPTOR_HID_REPORT     = 34;
const USB_DESCRIPTOR_HID            = 33;
const USB_CLASS_HID                 = 3;

const USB_HID_GET_REPORT_REQUEST    = 0x01;
const USB_HID_SET_REPORT_REQUEST    = 0x09;
const USB_HID_SET_IDLE_REQUEST      = 0x0A;

// The class that represents HID report that may be sent or received from particular devices
// It contains a set of HID report items grouped by their types: INPUT, OUTPUT and FEATURE
// See more at "Device Class Definition for Human Interface Devices (HID)" 6.2.2
class HIDReport {

    // USB interface descriptor - owner of this report
    _interface      = null;

    // An array of input items (if any). Doesn't include padding (constant) items
    _inputItems     = null;

    // An array of out items (if any). Doesn't include padding (constant) items
    _outputItems    = null;

    // An array of feature items (if any). Doesn't include padding (constant) items
    _featureItems   = null;

    // This report ID (if any)
    _reportID       = 0;

    // Total size of input  report packet
    _totalInSize    = 0;

    // Total size of output report packet
    _totalOutSize   = 0;

    // Total size of feature report packet
    _totalFeatSize  = 0;

    // ----------- Public API ---------------------

    // Synchronous read of input items.
    // Returns: nothing.
    // Throws: if error happens during transfer or control endpoint is closed
    function request() {
        local buffer = blob(_totalInSize);
        local ep0 = _interface.getDevice().getEndpointZero();

        ep0.transfer(USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_CLASS | USB_SETUP_RECIPIENT_INTERFACE,
                    USB_HID_GET_REPORT_REQUEST,
                    (HID_REPORT_ITEM_IN + 1) << 8 | _reportID,
                    _interface.interfacenumber,
                    buffer);

        _parseInputData(buffer);
    }

    // Synchronous send of output items.
    // The items value need to be updated prior to call.
    //
    // Throws: endpoint is closed or something happens during call to native USB API
    function send() {
        local buffer = blob(_totalOutSize);
        foreach (item in _outputItems) {
            item._writeTo(buffer);
        }

        local ep0 = _interface.getDevice().getEndpointZero();
        ep0.transfer(USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_CLASS | USB_SETUP_RECIPIENT_INTERFACE,
                    USB_HID_SET_REPORT_REQUEST,
                    (HID_REPORT_ITEM_OUT + 1) << 8 | _reportID,
                    _interface.interfacenumber,
                    buffer);
     }

     // Issue "Set Idle" command for the interface this report is bound to.
     //
     // Parameters:
     //     millis - IDLE time for this report between 4 - 1020 ms
     //
     // Trows is EP0 is closed, or something happens during call to native USB API
     function setIdleTimeMs(millis) {

        local timeUnit = (millis.tointeger() / 4) & 0xFF;

        local ep0 = _interface.getDevice().getEndpointZero();

        ep0.transfer(USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_CLASS | USB_SETUP_RECIPIENT_INTERFACE,
                    USB_HID_SET_IDLE_REQUEST,
                    (timeUnit) << 8 | _reportID,
                    _interface.interfacenumber);

     }

     // Returns an array of input items or null
     function getInputItems() {
        return _inputItems;
     }

     // Returns an array of output items or null
     function getOutputItems() {
        return _outputItems;
     }

     // Returns an array of feature items or null
     function getFeatureItems() {
        return _featureItems;
     }

     // ---------------- Private Functions -------------------------

    // Constructor. Receives owner of this report
    constructor(interface) {
        _interface      = interface;
        _inputItems     = [];
        _outputItems    = [];
        _featureItems   = [];
    }

    // Update input items with data stored at provided buffer
    function _parseInputData(buffer) {
        foreach (item in _inputItems) {
            item._parse(buffer);
        }
    }
}


// Individual report item class
class HIDReport.Item {

    // Instance of HIDReport.Item.Attributes
    attributes          = null;

    // A set of item HID_IOF_*  flags
    itemFlags           = 0;

    // Item collection path
    collectionPath      = null;

    // An offset of this item in the report packet
    _bitOffset          = 0;

    // Last item value
    _value              = 0;


    // Returns last item value
    function get() {
        return _value;
    }

    // Updates item value
    //
    // Throws if provided value in not a number
    function set(value) {
        _value = value.tointeger();
    }

    // Debug function. Prints items to  given stream.
    //
    // Parameters:
    //          stream - function that prints this item to some output stream.
    function print(stream) {
        stream("HIDReport.Item: ");
        stream("     itemFlags: " + itemFlags);
        stream("     bitOffset: " + _bitOffset);
        attributes.print(stream);
        collectionPath.print(stream);
        stream("====== END OF HIDReport.Item =========");
    }

    // ---------------------- private API -----------------------------------

    // Constructor.
    // Parameters:
    //   attr       - item attributes. Must be instance of HIDReport.Item.Attributes
    //   flags      - a set of item HID_IOF_*  flags
    //   path       - item collection path, instance of HIDReport.Collection
    constructor(attr, flags, path) {
        attributes      = attr;
        itemFlags       = flags;
        collectionPath  = path;
    }

    // Extract item data from given data buffer.
    // Parameters:
    //          buffer - blob instance
    // Throws if buffer size is less than item offset + item size
    function _parse(buffer) {
        local size     = attributes.bitSize;
        local offset   = _bitOffset;
        local bitMask  = (1 << 0);

        _value = 0;
        buffer.seek(offset / 8, 'b');
        local data = buffer.readn('b');

        while (size-- > 0)
        {
            if (data & (1 << (offset % 8))) _value = _value | bitMask;

            offset++;
            bitMask = bitMask << 1;

            if ( 0 == (offset % 8) && size > 0) {
                data = buffer.readn('b');
            }
        }
    }

    // Write the item to given data buffer.
    // Parameters:
    //      buffer - blob instance
    // Throws if buffer size is less than item offset + item size
    function _writeTo(buffer) {
        local size     = attributes.bitSize;
        local offset   = _bitOffset;
        local bitMask  = (1 << 0);

        buffer.seek(offset / 8, 'b');

        local data = buffer.readn('b');


        while (size-- > 0)
        {
            if (_value & bitMask) data = data | (1 << (offset % 8));

            offset++;
            bitMask = bitMask << 1;

            buffer.seek(-1, 'c');
            buffer.writen(data, 'b');

            if ( 0 == (offset % 8) && size > 0) {
                buffer.seek(-1, 'c');
                data = buffer.readn('b');
            }
        }
    }
}

// HID Report Item attributes storage
class HIDReport.Item.Attributes {
    // Maximum value that a variable or array item will report
    logicalMaximum     = null;

    // Minimum  value that a variable or array item will report
    logicalMinimum     = null;

    // This represents the Logical Minimum with units applied to it
    physicalMaximum    = null;

    // This represents the Logical Minimum with units applied to it
    physicalMinimum    = null;

    // Value of the unit exponent
    unitExponent       = null;

    // Item unit
    unitType           = null;

    // The item Usage Page
    usagePage          = null;

    // The item usage ID
    usageUsage         = null;

    // A number of bits this item occupies in the report
    bitSize            = 0;

    // Debug function. Prints attributes to given stream.
    //
    // Parameters:
    //          stream - function that prints this item to some output stream.
    function print(stream) {
        stream("HIDReport.Item.Attributes: ");
        stream("          logicalMaximum: " + logicalMaximum);
        stream("          logicalMinimum: " + logicalMinimum);
        stream("         physicalMaximum: " + physicalMaximum);
        stream("         physicalMinimum: " + physicalMinimum);
        stream("            unitExponent: " + unitExponent);
        stream("                unitType: " + unitType);
        stream("               usagePage: " + usagePage);
        stream("              usageUsage: " + usageUsage);
        stream("                 bitSize: " + bitSize);
        stream("=== END OF HIDReport.Item.Attributes ======");
    }
}

// HID Report Collection Path class
class HIDReport.Collection {

    // Parent unit in path chain,
    parent      = null;

    type        = null;
    usagePage   = null;
    usageUsage  = null;

    // Debug function. Prints collection path  to given stream.
    //
    // Parameters:
    //          stream - function that prints this item to some output stream.
    function print(stream) {
        stream("HIDReport.Collection: ");
        stream("                    type: " + type);
        stream("               usagePage: " + usagePage);
        stream("              usageUsage: " + usageUsage);
        stream("====== END OF HIDReport.Collection =========");

        if (null != parent) {
            parent.print(stream);
        }
    }

    // ------------- Private Functions ---------------

    // Constructor.
    // Parameters:
    //      parent - previous item in path chain.
    constructor(parent) {
        this.parent = parent;
    }
}

// Generic driver for HID devices.
class HIDDriver extends USB.Driver {

    // Implementation version
    static VERSION = "1.0.0";

    // A set of reports supported by this drivers
    _reports    = null;

    // Input endpoint to read data asynchronously
    _epIn       = null;

    // USB interface descriptor this driver assigned to.
    _interface  = null;

    // User callback for async read
    _epReadUserCb     = null;

    // Constructor.
    // Parameters:
    //      ep                  - instance of USB.ControlEndpoint for Endpoint 0
    //      reports             - an array of HIDReport instances
    //      interface           - USB device interface this driver assigned to.
    constructor(reports, interface) {
        _reports    = reports;

        _interface  = interface;
        try {
            _epIn       = interface.find(USB_ENDPOINT_INTERRUPT, USB_SETUP_DEVICE_TO_HOST);
        } catch (e) {
            // we may face a limitation of native API when only one Interrupt In endpoint may be opened.
            USB.err("Can't open Interrupt In endpoint:" + e);
        }
    }

    // Queried by USB.Host if this driver supports
    // given interface function of the device.
    // Should return new instance of the driver object if
    // driver matches
    function match(device, interfaces) {
        local log = USB.log.bindenv(USB);
        local found = [];

        foreach(interface in interfaces) {
            if (interface["class"] == USB_CLASS_HID) {
                found.append(interface);
            }
        }

        log("Driver matched " + found.len() + " interfaces");

        if (found.len() > 0) {
            local ep0 = device.getEndpointZero();

            local wTotalLen = 0;
            {
                // estimate Hid Report Descriptor max size:
                // read buffer size is no more than configuration descriptor size
                local data = blob(USB_CONFIGURATION_DESCRIPTOR_LENGTH);
                log("getting configuration descriptor");
                ep0.transfer(USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_STANDARD| USB_SETUP_RECIPIENT_DEVICE,
                             USB_REQUEST_GET_DESCRIPTOR,
                             USB_DESCRIPTOR_CONFIGURATION << 8, 0,
                            data);
                wTotalLen = data.readn('w');
                log("done");
            }

            log("start driver initialization");
            local drivers = [];

            foreach(interface in found) {
                local hidReportDescriptor = _getReportDescr(ep0, interface, wTotalLen);
                if (null != hidReportDescriptor) {
                    local hidReports = _parse(hidReportDescriptor, interface);
                    if (null != hidReports) {
                        local newDriver = _createInstance(hidReports, interface);
                        drivers.append(newDriver);
                    } else {
                        log("Empty Report is returned from parser");
                    }
                }
            }

            log("initialization done");
            return drivers;
        }
        return null;
    }

    // Get list of supported HID reports.
    // Returns an array of HIDReport instances.
    function getReports() {
        return _reports;
    }

    // Asynchronous read of input items. The result of the read is one of registered HID reports.
    //
    // Parameters:
    //      cb  - a callback to receive notification. Its signature is following:
    //              function callback(_error, report), where
    //                  error  - error message or null
    //                  report - HIDReport instance
    //
    // Throws: if there is ongoing read from related endpoint, or endpoint is closed,
    //          or something happens during call to native USB API,
    //          or interface descriptor doesn't describe input endpoint
    function getAsync(cb) {
        if (_epReadUserCb != null) throw "Ongoing HID report read";

        if (_epIn == null) throw "No Interrupt Input Endpoint found at HID interface";

        local buffer = blob(_epIn.getMaxPacketSize());
        _epIn.read(buffer, _epReadCb.bindenv(this));

        _epReadUserCb = cb;
    }

    // --------------------------- private functions ---------------

    // Try to get HID Report Descriptor of the given interface with "Get Report" command.
    //
    // Parameters:
    //  ep0         - USB.ControlEndpoint instance for endpoint zero
    //  interface   - interface descriptor
    //  maxLen      - maximum possible length for Report Descriptor.
    //
    // Return null if hardware doesn't support the command or there was a transfer error.
    function _getReportDescr(ep0, interface, maxLen) {
        local log = USB.log.bindenv(USB);
        log("getting hid descriptor for " + interface.interfacenumber + " interface");
        // hid descriptor can't be more than config descriptor
        local data = blob(maxLen);
        try {
            ep0.transfer(USB_SETUP_DEVICE_TO_HOST | USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_DEVICE,
                         USB_REQUEST_GET_DESCRIPTOR,
                         USB_DESCRIPTOR_HID_REPORT << 8, interface.interfacenumber,
                         data);
        } catch (e) {
            // is it boot interface?
            USB.err(       "device doesn't support Get_Descriptor Request: " + e);
            return null;
        }
        log("done");
        return data;
    }

    // Used by HID Report Descriptor parser to check if provided hidItem should be included to the HIDReport.
    //
    // Parameters:
	//		type	- item type [HID_RI_INPUT, HID_RI_OUTPUT, HID_RI_FEATURE]
    //      hidItem - instance of HIDReport.Item
    //
    // Returns true if the item should be included to the report, or false to drop it.
    //
    // Note: custom HIDDriver may rewrite this function to reduce memory consumption.
    function _filter(type, hidItem) {
        return true;
    }

    // Used by match() function to create correct class instance in case of this class is overridden.
    //
    // Parameters:
    //      reports     - an array of HIDReport instances
    //      interface   - USB device interface this driver assigned to.
    function _createInstance(reports, interface) {
        return HIDDriver(reports, interface);
    }

	// A callback function that receives notification from HIDReport
	//
	// Parameters:
	//			error  -  possibly error or null
    //			ep     -  source endpoint
    //          data   -  blob with data
    //          len    - read data len
	function _epReadCb(ep, error, data, len) {
		if (null == _epReadUserCb) return;
        local cb = _epReadUserCb;
        _epReadUserCb = null; // prevent exception

		if (null == error || error == USB_TYPE_FREE || error == USB_TYPE_IDLE) {
            local reportID = 0;
            if (_reports.len() > 1) {
                data.seek(0, 'b');
                reportID = data.readn('b');
            }
            foreach (report in _reports) {
                if (report._reportID == reportID) {
                    try {
                        report._parseInputData(data);
                    } catch (e) {
                        cb("Report data parsing error: " + e, null);
                        return;
                    }
                    cb(null, report);
                    return;
                }
            }
            // not found. possible, the driver is not interesting in this report
            // try to read next one
            USB.log("Report " + reportID + " was read, but not found in watch list. Trying to read next one.");
            getAsync(cb);
		} else {
            cb("USB error: " + error, null);
		}
	}


    // Internal class that represents Report Descriptor parser state
    ParserState = class {
        attributes      = null;
        reportID        = null;
        reportCount     = null;
        parent          = null;

        constructor(previousState = null) {
            if (previousState != null) {
                attributes  = clone(previousState.attributes);
                reportID    = previousState.reportID;
                reportCount = previousState.reportCount;
            } else {
                attributes      = HIDReport.Item.Attributes();
                reportID        = 0;
                reportCount     = 0;
            }

            parent = previousState;
        }

    }

    // Function to parse given report descriptor.
    //
    // Parameters:
    //  hidReportDescriptor  -  blob instance with report descriptor data
    //  interface            -  owner of all returned reports
    //
    // Returns:
    //       an array of HIDReport instances or null if no reports was found.
    //
    // Throws if provided buffer contains invalid data or too short
    function _parse(hidReportDescriptor, interface) {

        local currStateTable     = ParserState();
        local currCollectionPath = null;
        local currReport        = HIDReport(interface);
        local usageList         = [];
        local usageMinMax       = {"Minimum" : 0, "Maximum" : 0};

        local usingReportID = false;
        local reports = [currReport];

        while (!hidReportDescriptor.eos()) {
            local  reportItem  = hidReportDescriptor.readn('b');
            local  reportItemData;

            switch (reportItem & HID_RI_DATA_SIZE_MASK) {
                case HID_RI_DATA_BITS_32:
                    reportItemData  = hidReportDescriptor.readn('i');
                    break;

                case HID_RI_DATA_BITS_16:
                    reportItemData  = hidReportDescriptor.readn('w');
                    break;

                case HID_RI_DATA_BITS_8:
                    reportItemData  = hidReportDescriptor.readn('b');
                    break;

                default:
                    reportItemData  = 0;
                    break;
            }

            switch (reportItem & (HID_RI_TYPE_MASK | HID_RI_TAG_MASK)) {
                case HID_RI_PUSH:
                    currStateTable = ParserState(currStateTable);
                    break;

                case HID_RI_POP:
                    currStateTable = currStateTable.parent;
                    break;

                case HID_RI_USAGE_PAGE:
                    if ((reportItem & HID_RI_DATA_SIZE_MASK) == HID_RI_DATA_BITS_32)
                        currStateTable.attributes.usagePage = (reportItemData >> 16);
                    else  currStateTable.attributes.usagePage =  reportItemData;
                    break;

                case HID_RI_LOGICAL_MINIMUM:
                    currStateTable.attributes.logicalMinimum = reportItemData;
                    break;

                case HID_RI_LOGICAL_MAXIMUM:
                    currStateTable.attributes.logicalMaximum = reportItemData;
                    break;

                case HID_RI_PHYSICAL_MINIMUM:
                    currStateTable.attributes.physicalMinimum = reportItemData;
                    break;

                case HID_RI_PHYSICAL_MAXIMUM:
                    currStateTable.attributes.physicalMaximum = reportItemData;
                    break;

                case HID_RI_UNIT_EXPONENT:
                    currStateTable.attributes.unitExponent = reportItemData;
                    break;

                case HID_RI_UNIT:
                    currStateTable.attributes.unitType = reportItemData;
                    break;

                case HID_RI_REPORT_SIZE:
                    currStateTable.attributes.bitSize = reportItemData;
                    break;

                case HID_RI_REPORT_COUNT:
                    currStateTable.reportCount = reportItemData;
                    break;

                case HID_RI_REPORT_ID:
                    currStateTable.reportID = reportItemData;

                    if (usingReportID) {
                        currReport = null;

                        foreach (report in reports) {
                            if (report._reportID == currStateTable.reportID) {
                                currReport = report;
                                break;
                            }
                        }

                        if (currReport == null) {
                            currReport = HIDReport(interface);
                            reports.append(currReport);
                        }
                    }

                    usingReportID = true;
                    currReport._reportID = currStateTable.reportID;
                    break;

                case HID_RI_USAGE:
                    usageList.append(reportItemData);
                    break;

                case HID_RI_USAGE_MINIMUM:
                    usageMinMax.Minimum = reportItemData;
                    break;

                case HID_RI_USAGE_MAXIMUM:
                    usageMinMax.Maximum = reportItemData;
                    break;

                case HID_RI_COLLECTION:
                    currCollectionPath = HIDReport.Collection(currCollectionPath);

                    currCollectionPath.type      = reportItemData;
                    currCollectionPath.usagePage = currStateTable.attributes.usagePage;

                    if (usageList.len()) {
                        currCollectionPath.usageUsage = usageList.remove(0);
                    } else if (usageMinMax.Minimum <= usageMinMax.Maximum) {
                        currCollectionPath.usageUsage = usageMinMax.Minimum++;
                    }
                    break;

                case HID_RI_END_COLLECTION:
                    currCollectionPath = currCollectionPath.parent;
                    break;

                case HID_RI_INPUT:
                case HID_RI_OUTPUT:
                case HID_RI_FEATURE:
                    local reportCount = currStateTable.reportCount;

                    while (reportCount--) {
                        local newItem = HIDReport.Item(clone(currStateTable.attributes), reportItemData, currCollectionPath);

                        if (usageList.len() > 0) {
                            newItem.attributes.usageUsage = usageList.remove(0);
                        } else if (usageMinMax.Minimum <= usageMinMax.Maximum) {
                            newItem.attributes.usageUsage = usageMinMax.Minimum++;
                        }

                        local ItemTypeTag = (reportItem & (HID_RI_TYPE_MASK | HID_RI_TAG_MASK));

                        local destArr = currReport._featureItems;

                        if (ItemTypeTag == HID_RI_INPUT) {
                            newItem._bitOffset = currReport._totalInSize;
                            currReport._totalInSize += newItem.attributes.bitSize;

                            destArr = currReport._inputItems;

                        } else if (ItemTypeTag == HID_RI_OUTPUT) {
                            newItem._bitOffset = currReport._totalOutSize;
                            currReport._totalOutSize += newItem.attributes.bitSize;

                            destArr = currReport._outputItems;
                        } else {
                            newItem._bitOffset = currReport._totalFeatSize;
                            currReport._totalFeatSize += newItem.attributes.bitSize;
                        }

                        if (!(reportItemData & HID_IOF_CONSTANT) && _filter(ItemTypeTag, newItem)) {
                            destArr.append(newItem);
                        }
                    }
                    break;
                default:
                    break;
            }

            if ((reportItem & HID_RI_TYPE_MASK) == HID_RI_TYPE_MAIN) {
                usageMinMax.Minimum = 0;
                usageMinMax.Maximum = 0;
                usageList = [];
            }
        }

        reports = reports.filter(
            function(index, report) {
                local len = report._featureItems.len() +
                            report._outputItems .len() +
                            report._inputItems  .len();
                return len != 0;
            }
        );

        // notify caller that the driver need no reports
        // or reports are empty
        if (reports.len() ==  0) reports = null;
        return reports;
    }

	// Metafunction to return class name when typeof <instance> is run
	function _typeof() {
		return "HIDDriver";
	}
}

