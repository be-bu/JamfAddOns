#!/bin/bash

# Jamf Extension attribute to return SSID
# Check if the system is running macOS 26
if [[ $(sw_vers -productVersion) == "26"* ]]; then
    # Enable verbose mode for ipconfig on macOS 26
    ipconfig setverbose 1
    # Get the current SSID and display it for interface en0
    SSID=$(ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}')
    # Disable verbose mode for other macOS versions
    ipconfig setverbose 0
else
    # Get the current Wi-Fi SSID using system_profiler and PlistBuddy
    SSID=$(/usr/libexec/PlistBuddy -c 'Print :0:_items:0:spairport_airport_interfaces:0:spairport_current_network_information:_name' /dev/stdin <<< "$(system_profiler SPAirPortDataType -xml)" 2> /dev/null)
fi

# Check if SSID is found
    if [ -n "$SSID" ]; then
        case $SSID in
            "Office"|"Remote"|"OfficeBerlin"|"OfficeMunic"|"OfficeHamburg")
                result="$SSID"
                ;;
            *)
                result="personal WiFi"
                ;;
        esac
    else
        result="No Wi-Fi network connected."
    fi
# Result for Jamf
echo "<result>$result</result>"