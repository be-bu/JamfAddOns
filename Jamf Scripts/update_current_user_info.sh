#!/bin/zsh

currentUser=$(/usr/bin/stat -f "%Su" /dev/console)

fullName=$(dscl . -read /Users/${currentUser} RealName | sed -n '2 p' )
shortName=$(dscl . -read /Users/${currentUser} RecordName | /usr/bin/awk '{ print $2 }')
mailAdress=$(dscl . -read /Users/${currentUser} | grep NetworkUser | awk '{print $2}' )

jamfCall(){
    jamf recon -endUsername "${shortName}" -realname "${fullName}" -email "${mailAdress}"
}

jamfCall
exit $?