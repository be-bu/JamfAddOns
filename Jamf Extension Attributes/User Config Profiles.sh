#!/bin/bash

mainUser=$( last -100 | grep console | awk '{print $1}' | grep -v "^admin$" | grep -v "^serviceAdmin$" | grep -v "^root$" | grep -v "^_mbsetupuser$" | head -n 10 | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}' )

RESULT=$(sudo -u "$mainUser" printf "%s\n" "$(sudo -u "$mainUser" profiles list | cut -d' ' -f4 |  tr '\n' ' ')")

if [ "${RESULT}" == "configuration " ]; then
        RESULT="NONE"
fi

echo "<result>${RESULT}</result>"