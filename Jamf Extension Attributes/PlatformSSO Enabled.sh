#!/bin/zsh

# ------------------------------------------------------------------------------
# Script to get the detailed Platform SSO status via Jamf Conditional Access.
# Method: Uses the Jamf Conditional Access helper tool for a detailed result.
# ------------------------------------------------------------------------------

jamfTool="/Library/Application Support/JAMF/Jamf.app/Contents/MacOS/Jamf Conditional Access.app/Contents/MacOS/Jamf Conditional Access"
result="unknown" # Default result

if [[ ! -x "$jamfTool" ]]; then
    result="JamfToolNotFound"
else
    # Get the numeric status code from the tool
    pSSOState=$("$jamfTool" getPSSOStatus | sed -n '1p')

    # Compare the numeric status code
    if [[ "$pSSOState" -eq 0 ]]; then
        result="MSALPlatformSSONotEnabled"
    elif [[ "$pSSOState" -eq 1 ]]; then
        result="MSALPlatformSSOEnabledNotRegistered"
    elif [[ "$pSSOState" -eq 2 ]]; then
        result="MSALPlatformSSOEnabledAndRegistered"
    fi
fi

echo "<result>${result}</result>"