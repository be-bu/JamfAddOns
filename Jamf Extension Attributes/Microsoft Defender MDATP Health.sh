#!/bin/zsh

fileToCheck="/usr/local/bin/mdatp"

if [[ -f $fileToCheck ]]; then 
    #result=$(mdatp health | grep "healthy" | awk '{print $NF}'  )
    result=$(mdatp health --field healthy)
else 
    result="missing"
fi

echo "<result>$result</result>"