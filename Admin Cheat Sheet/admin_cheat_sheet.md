# macOS Admin Cheat Sheet

> Author: Benjamin Buchheim

A curated collection of handy macOS administration commands for daily sysadmin
and MDM work — covering user management, FileVault, certificates, Jamf, Active
Directory, and more.

> [!WARNING]
> These are **reference examples to copy and adapt**.
> Review every command before running it. All environment-specific values
> (usernames, passwords, domains, hostnames, tenant IDs, service accounts) have
> been replaced with placeholders such as `<admin-user>`, `<password>`,
> `example.com`, or `<service-account>`. Replace them with your own values.

## Contents

- [User Context & Information](#user-context--information)
- [Active Directory](#active-directory)
- [FileVault & SecureToken](#filevault--securetoken)
- [Configuration Profiles & Conversion](#configuration-profiles--conversion)
- [System Utilities & Software Update](#system-utilities--software-update)
- [LDAP & Directory Queries](#ldap--directory-queries)
- [Jamf AAD & Platform SSO](#jamf-aad--platform-sso)
- [Security, Trust Settings & Certificates](#security-trust-settings--certificates)
- [cURL & API Requests](#curl--api-requests)
- [awk & sed Quick Reference](#awk--sed-quick-reference)
- [Shell Aliases](#shell-aliases)
- [Homebrew Formulae (CLI Tools)](#homebrew-formulae-cli-tools)
- [Homebrew Casks (GUI Applications)](#homebrew-casks-gui-applications)

## User Context & Information

Commands for identifying the current console user, reading user attributes from
the local directory, and running actions in user context.

```bash
# /usr/bin/stat on /dev/console reliably returns the GUI-logged-in user
currentUser=$(/usr/bin/stat -f "%Su" /dev/console)

# List all "real" local users, filtering out system/service accounts
allLocalUser=$(dscl . list /Users | grep -Ev "_|root|nobody|daemon|jamf|<service-account>")

# get current computers jamf server url
jamfProURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
# Remove the trailing slash from the Jamf Pro URL if needed.
jamfProURL=${jamfProURL%%/}

# Run a command (e.g. open a URL) as the current user, not as root
sudo -H -iu "${currentUser}" open "$WebSite"
sudo -H -iu "${currentUser}" open "https://jamf.com"

# Submit an inventory update (recon) with the console username
jamf recon -endUsername "$(ls -la /dev/console | cut -d ' ' -f 4)"

# Read user attributes from the local directory (Open Directory)
dscl . -read /Users/$currentUser EMailAddress | cut -c 15-
dscl . -read /Users/$currentUser RealName
dscl . -read /Users/$currentUser RealName | sed -n '2 p' | cut -c 2-
dscl . -read "/Users/$currentUser" RealName | tail -n +2 | cut -c 2-

# Full recon oneliner: inventory update with real name and email
jamf recon -endUsername "$currentUser" \
  -realname "$(dscl . -read /Users/$currentUser RealName | sed -n '2 p' | cut -c 2-)" \
  -email "$(dscl . -read /Users/$currentUser EMailAddress | cut -c 15-)"

# Creates a mobile account on the Mac from an AD user record
sudo /System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n <username>
```

## Active Directory

Commands for checking AD bind status, polling, and binding configuration.

```bash
# Display the current Active Directory binding configuration
dsconfigad -show

# Polling loop: re-check AD status every 3 seconds (Ctrl+C to stop)
while true; do dsconfigad -show ; echo $(((i++))) ; sleep 3 ; done

# Polling loop: wait until the jamf binary is available on PATH
while true; do which jamf ; echo $(((i++))) ; sleep 3 ; done

# Unbind a Mac from Active Directory
sudo dsconfigad -force -remove -u <admin-user> -p <password>

# Example AD bind command — adjust OU, domain, and groups as needed
# dsconfigad -a "$hostName" -u <bind-service-account> \
#   -ou "OU=macOS,OU=Clients,OU=Company,DC=example,DC=com" \
#   -domain example.com -mobile enable -mobileconfirm enable \
#   -localhome enable -useuncpath enable -groups "<local-admins-group>" -alldomains enable
```

## FileVault & SecureToken

FileVault provides full-disk encryption on macOS. SecureToken is a per-user
attribute required to unlock FileVault and manage the volume. A SecureToken-enabled
admin account is needed to grant tokens to others.

### SecureToken Management

```bash
# Check whether a user has a SecureToken
sysadminctl -secureTokenStatus <user-account>
sysadminctl -secureTokenStatus <admin-user>

# Get the currently logged-in user
currentUser=$(/usr/bin/stat -f "%Su" /dev/console)

# Enable the SecureToken for a target account.
# The "-password -" flag prompts interactively; -adminUser must already hold a token
sysadminctl -secureTokenOn <user-account> -password - -adminUser <admin-user> -adminPassword -

# Grant SecureToken to the current GUI user in one command
sysadminctl -secureTokenOn "$(/usr/bin/stat -f "%Su" /dev/console)" -password - -adminUser <admin-user> -adminPassword -

# Loop: grant SecureToken to every "real" local user via an admin account
for i in $(dscl . list /Users | grep -Ev "_|root|nobody|daemon|jamf"); do
    sysadminctl -secureTokenOn "$i" -password - -adminUser <admin-user> -adminPassword -
done

# Verify status
sysadminctl -secureTokenStatus <user-account>

# Revoke a SecureToken (rarely needed; may require recovery key afterwards)
sudo sysadminctl -secureTokenOff <user-account> -password -
```

### User & Group Management

```bash
# Delete a user from the local directory service
sudo dscl . -delete /Users/<user-account>

# Add a user to the local admin group
sudo dseditgroup -o edit -a <username> -t user admin
```

### FileVault Enable / Disable

```bash
# Initiate FileVault encryption (prompts for credentials)
fdesetup enable

# Decrypt the volume — may take a long time on large disks
# (account must be in the appropriate static group)
fdesetup disable

# Add an additional user to the FileVault unlock list
fdesetup add -usertoadd <other-user>

# Change the APFS volume passphrase for a specific user UUID
diskutil apfs changePassphrase disk1s2 -user <user-uuid> -oldPassphrase - -newPassphrase -
```

### Preboot Volume

Always update the preboot volume after granting/revoking SecureTokens so it
stays in sync.

```bash
diskutil apfs updatepreboot /
sudo diskutil apfs updatepreboot / | grep "Exiting Update Preboot operation with overall error"
```

## Configuration Profiles & Conversion

```bash
# Decrypt a signed .mobileconfig and pretty-print as readable XML
security cms -D -i /path/to/downloaded_profile.mobileconfig | xmllint --format - > /path/to/readable_profile.xml
security cms -D -i ~/Downloads/JamfConnect_v2.mobileconfig | xmllint --format - > ~/Downloads/JamfConnect_v2.xml 
```

## System Utilities & Software Update

```bash
# Convert an .icns icon file to .png format
sips -s format png "/Applications/Install macOS Ventura.app/Contents/Resources/ProductPageIcon.icns" --out /some/path/ventura.png

# Download a full macOS installer to /Applications (specify version)
softwareupdate --fetch-full-installer --full-installer-version 13.0

# Force-install background-critical updates silently
sudo softwareupdate --background-critical --force

# Show Microsoft Defender health status (license, definitions, real-time protection)
mdatp health

# Redirect stdout and stderr to /dev/null for silent execution
echo "hello world" > /dev/null 2>&1
./script.sh > /dev/null 2>&1
./example.pl > /dev/null 2>&1
```

## LDAP & Directory Queries

```bash
# Query AD via LDAP to look up user objects by sAMAccountName
ldapsearch -H ldaps://ldap.example.com \
  -D 'CN=<service-account>,OU=ServiceAccounts,DC=example,DC=com' \
  -w "<password>" -x -b 'dc=example,dc=com' \
  "(&(objectClass=user)(sAMAccountName=<sam-account-name>))"
```

## Jamf AAD & Platform SSO

```bash
# Gather Azure AD information via the Jamf AAD helper binary
/usr/local/jamf/bin/jamfaad gatherAADInfo

# Check Platform SSO registration status (0 = default check)
/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/Jamf\ Conditional\ Access.app/Contents/MacOS/Jamf\ Conditional\ Access getPSSOStatus 0

# Extract the Azure device ID from the PSSO status output
/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/Jamf\ Conditional\ Access.app/Contents/MacOS/Jamf\ Conditional\ Access getPSSOStatus 0 \
  | grep -o 'primary_registration_metadata_device_id"): [^,]*' | cut -d' ' -f2

# Native macOS command to show Platform SSO status (macOS 13+)
app-sso platform -s
```

## Security, Trust Settings & Certificates

Techniques for programmatically trusting certificates on macOS. The
`authorizationdb` trick temporarily allows non-interactive cert trust, then
immediately revokes the permission for security.

### Standard Certificate Trust Commands

```bash
# Generic syntax: add a trusted cert with a specific trust policy
sudo security add-trusted-cert -d -r trustRoot -p [option] -k /Library/Keychains/System.keychain <certificate>

# trustAsRoot: trust the cert as if it were a root CA
sudo security add-trusted-cert -d -r trustAsRoot -k /Library/Keychains/System.keychain <certificate>
```

### Microsoft Intune / Company Portal Certificate

```bash
# Find the MS-ORGANIZATION-ACCESS certificate used for Intune device registration
security find-certificate -a /Users/$currentUser/Library/Keychains/login.keychain-db \
  | awk -F= '/issu/ && /MS-ORGANIZATION-ACCESS/ { getline; print $2}'
```

### Quarantine Flag Removal

macOS quarantines downloaded files; remove the xattr to allow execution.

```bash
sudo xattr -r -d com.apple.quarantine /path/to/MyApp.app
sudo xattr -r -d com.apple.quarantine /path/to/MyFile.mobileconfig
sudo xattr -r -d com.apple.quarantine /path/to/DownloadedScript.sh
```

## cURL & API Requests

Template for authenticated API calls to Jamf Pro (or similar REST APIs).
Swap the `--request` verb as needed: PUT, POST, GET, DELETE.

```bash
curl -s \
    --header "Authorization: Bearer ${apiToken}" \
    --header "Content-Type: text/xml" \
    --url "${jamfProURL}/${apiURL}" \
    --data "${apiData}" \
    --request PUT > /dev/null
```

## awk & sed Quick Reference

### awk

```bash
awk '{print $NF}'           # Print last field
awk '{print $1}'            # Print first field
awk -F: '{print $1}'        # -F defines separator, prints first field
```

### sed

```bash
sed 's/Bash/Perl/'          # Replace first match on each line
sed -i 's/[[:blank:]]*$//'  # Delete trailing whitespace
sed '/^$/d'                 # Delete empty / whitespace-only lines
sed '/Windows/ s/$/ 10/'    # Append "10" on lines containing "Windows"
sed "s/,/\n/g"              # Replace commas with newlines
sed 's/Bash/PHP/i'          # Case-insensitive replace
sed 's.\\./.g'              # Replace backslash with slash
sed -n '2 p'                # Print the second line
```

## Shell Aliases

Place these in `~/.zshrc` or `~/.aliases` and source them on shell startup.

```bash
alias ll='ls -alS'
alias tail_ls='_tail_ls() { ls -l "$1" | tail ;}; _tail_ls'
# brew commands 
alias burb='brew update && brew upgrade'
alias bic='brew install --cask '
alias bs='brew search '
alias bi='brew install '
# other admin commands
alias please='sudo $(history -p !!)'
alias tjam='tail -50f /var/log/jamf.log'
alias tins='tail -50f /var/log/install.log'
alias tsys='tail -50f /var/log/system.log'
# jamf related
alias comp='cd /Library/Application\ Support/JAMF/Composer/Sources/'
alias jca='/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/Jamf\ Conditional\ Access.app/Contents/MacOS/Jamf\ Conditional\ Access'
# print the man page of a command as PDF and open it via Preview
alias pman=' _pman() {mandoc -T pdf "$(/usr/bin/man -w $@)" | open -fa Preview}; _pman'
# show aliases
alias sal='cat ~/.aliases'
# use nano to edit aliases
alias nal='nano ~/.aliases'
# alias htop='sudo htop'
# I recommend the usage of btop instead of htop
# brew install btop
#
# when Installomator is cloned you may review if the label is implemented
alias icheck=' _icheck() { /path/to/git-collection/Installomator/installomator.sh | grep $1 }; _icheck'
alias ilabel=' _ilabel() { cat /path/to/git-collection/Installomator/fragments/labels/$1.sh }; _ilabel'
# alias jamf='sudo jamf'
alias pcp="rsync -r --progress"
alias cmail=' _cmail() {/usr/libexec/PlistBuddy -c "print :dsAttrTypeStandard\:EMailAddress:0" /dev/stdin <<< "$(dscl -plist /Active\ Directory/<DOMAIN>/All\ Domains read /Users/$@ EMailAddress)"}; _cmail'
alias cname=' _cname() {/usr/libexec/PlistBuddy -c "print :dsAttrTypeStandard\:RealName:0" /dev/stdin <<< "$(dscl -plist /Active\ Directory/<DOMAIN>/All\ Domains read /Users/$@ RealName)"}; _cname'
alias topng=' _topng() { sips -s format png "$1" --out /path/to/workdir/Jamf_Icons/$2.png }; _topng'
alias gpa='find . -type d -depth 1 -exec git --git-dir={}/.git --work-tree=$PWD/{} pull --force \;'
alias gpall='_gpall() {whereIWas=$(pwd); omz update ; cd /path/to/git-collection ; gpa; cd "$whereIWas" }; _gpall'
```

## Homebrew Formulae (CLI Tools)

Install with `brew install <formula>`.

| Formula | Description |
| --- | --- |
| `bat` | Clone of `cat(1)` with syntax highlighting and Git integration |
| `btop` | Resource monitor; continuation of bashtop / bpytop |
| `ffmpeg` | Codecs for video, audio and more |
| `git` | Version control |
| `grc` | Use with `tail` to highlight log files |
| `htop` | Process monitor |
| `midnight-commander` | Norton-Commander-style file explorer |
| `nano` | File editor with `.nanorc` highlighting |
| `neofetch` | Host information |
| `nmap` | Port scanning utility |
| `ollama` | Local AI host utility |
| `pyenv` | Python environment manager |
| `python-psutil` | Process and system utilities for Python |
| `python` | Python runtime |
| `pytorch` | Required for local LLMs |
| `pyyaml` | YAML parser for Python |
| `rust` | Rust toolchain |
| `shellcheck` | Shell script linter |
| `speedtest-cli` | Internet speed test |
| `tldr` | Simplified man pages |
| `tree` | Show files as a tree |
| `wget` | File downloader |
| `yt-dlp` | Video / audio download tool |
| `zsh` | Modern zsh |
| `zsh-autocomplete` | Command suggestions |
| `zsh-syntax-highlighting` | Syntax highlighting for zsh |

## Homebrew Casks (GUI Applications)

Install with `brew install --cask <cask>`.

| Cask | Description |
| --- | --- |
| `alt-tab` | Windows-style window switching |
| `apparency` | Review macOS apps |
| `autodesk-fusion` | CAD/CAM/CAE/PCB software |
| `balenaetcher` | Imaging tool |
| `bartender` | Declutter the menu bar |
| `bruno` | git-native API client |
| `coderunner` | Lightweight editor for shell scripts etc. |
| `crossover` | Run Windows applications |
| `crystalfetch` | Download Windows images |
| `db-browser-for-sqlite` | SQLite browser |
| `deeper` | Toggle hidden Finder/app functions |
| `diffusionbee` | Create images with LLMs |
| `font-hack-nerd-font` | Font for Powerlevel10k |
| `glance-chamburr` | QuickLook plugin to view code |
| `imazing-profile-editor` | Create configuration profiles |
| `jamf-migrator` | Clone between two Jamf instances |
| `loop` | Window manager with mouse interaction |
| `macfuse` | File system integration (NTFS etc.) |
| `menumeters` | System status in the menu bar |
| `mist` | Download macOS/iOS firmwares and installers |
| `obs` | Live streaming and screen recording |
| `ollama` | Manage local LLMs |
| `ollama-app` | Ollama desktop app |
| `omnidisksweeper` | Find and delete large files |
| `packages` | Build custom PKG installers |
| `pearcleaner` | Application cleanup utility |
| `powershell` | PowerShell on macOS |
| `pppc-utility` | Create/inspect `.mobileconfig` files |
| `prefs-editor` | Editor for plist files |
| `rancher` | Docker Desktop + Kubernetes alternative |
| `replicator` | Sync data with a Jamf server |
| `shottr` | Screenshot utility |
| `slack` | Messenger (e.g. for macadmins) |
| `stats` | Modern alternative to MenuMeters |
| `suspicious-package` | Inspect PKG files in QuickLook |
| `tabby` | Alternative terminal |
| `ukelele` | Unicode keyboard layout editor |
| `utm` | Virtual machines |
| `virtualbuddy` | Virtual macOS VMs |
| `whisky` | Run Windows applications (wine-based) |
