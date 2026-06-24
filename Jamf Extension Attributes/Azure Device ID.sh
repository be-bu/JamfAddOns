#!/bin/zsh

# ---
# This script determines the Microsoft Entra ID (Azure AD) Device ID.
# Strategy 1: Login keychain certificate (traditional WPJ / non-PSSO devices).
# Strategy 2: Jamf Conditional Access tool (Platform SSO devices).
# ---

currentUser=$(/usr/bin/stat -f "%Su" /dev/console)
tenantID="123abc-456d-789e-012f-3456789abcde"  # Replace with your actual tenant ID
deviceAzureID=""

log() {
    echo "$1" >&2
}

# --- Strategy 1: Login keychain certificate ---
keychainPath="/Users/$currentUser/Library/Keychains/login.keychain-db"

if [ -f "$keychainPath" ]; then
    deviceAzureID=$(security find-certificate -a "$keychainPath" | \
        awk -F= '/issu/ && /MS-ORGANIZATION-ACCESS/ { getline; print $2}' | tr -d '"')
fi

if [ -n "$deviceAzureID" ]; then
    log "Device ID retrieved from login keychain."
else
    log "No MS-ORGANIZATION-ACCESS cert in login keychain. Trying PSSO method."

    # --- Strategy 2: Jamf Conditional Access (PSSO) ---
    # Extract all UUIDs from the output and exclude the known tenant ID.
    jamfCaPath="/Library/Application Support/JAMF/Jamf.app/Contents/MacOS/Jamf Conditional Access.app/Contents/MacOS/Jamf Conditional Access"

    if [ -f "$jamfCaPath" ]; then
        pssoOutput=$("$jamfCaPath" getPSSOStatus 2>/dev/null)

        if [ -n "$pssoOutput" ]; then
            deviceAzureID=$(echo "$pssoOutput" | \
                grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | \
                grep -iv "$tenantID" | head -1)
        fi

        if [ -n "$deviceAzureID" ]; then
            log "Device ID retrieved via Jamf Conditional Access (PSSO)."
        else
            log "Warning: Jamf CA tool returned no parseable Device ID."
        fi
    else
        log "Error: Jamf Conditional Access tool not found."
    fi
fi

# Output result in Jamf EA format.
if [ -z "$deviceAzureID" ]; then
    echo "<result></result>"
else
    echo "<result>${deviceAzureID}</result>"
fi