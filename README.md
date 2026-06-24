# JamfAddOns

A collection of [Jamf Pro](https://www.jamf.com/) **Scripts** and **Extension Attributes** for managing macOS devices.

> [!WARNING]
> These items are shared as-is. **Always review and test every script and Extension Attribute in a non-production environment before deploying it to managed devices.** They may need to be adapted to fit your own Jamf Pro instance, organization names, or macOS versions.

## Contents

| Folder | Description |
| --- | --- |
| [`Jamf Extension Attributes/`](./Jamf%20Extension%20Attributes) | Extension Attributes that collect inventory data from devices. |
| [`Jamf Scripts/`](./Jamf%20Scripts) | Scripts that run on managed devices through Jamf policies. |
| [`Admin Cheat Sheet/`](./Admin%20Cheat%20Sheet) | Curated macOS administration command snippets for reference. |

### Extension Attributes

| Name | Purpose |
| --- | --- |
| [Azure Device ID](./Jamf%20Extension%20Attributes/Azure%20Device%20ID.sh) | Returns the Microsoft Entra ID (Azure AD) Device ID. Reads it from the login keychain certificate (WPJ devices) and falls back to the Jamf Conditional Access tool for Platform SSO devices. |
| [Current WiFi SSID](./Jamf%20Extension%20Attributes/Current%20WiFi%20SSD_Clean.sh) | Returns the SSID of the currently connected Wi-Fi network. Known corporate networks are reported by name; everything else is reported as `personal WiFi`. Supports macOS 26 and earlier versions. |
| [iCloud Account](./Jamf%20Extension%20Attributes/iCloud%20Account.sh) | Lists the iCloud account(s) configured per local user, or `None` if no account is present. |
| [Microsoft Defender MDATP Health](./Jamf%20Extension%20Attributes/Microsoft%20Defender%20MDATP%20Health.sh) | Reports the Microsoft Defender (`mdatp`) health status, or `missing` if Defender is not installed. |
| [PlatformSSO Enabled](./Jamf%20Extension%20Attributes/PlatformSSO%20Enabled.sh) | Returns the detailed Platform SSO registration state via the Jamf Conditional Access tool (e.g. enabled and registered, enabled but not registered, or not enabled). |
| [User Config Profiles](./Jamf%20Extension%20Attributes/User%20Config%20Profiles.sh) | Lists the user-level configuration profiles installed for the primary console user, or `NONE` if there are none. |

### Scripts

| Name | Purpose |
| --- | --- |
| [Update Current User Info](./Jamf%20Scripts/update_current_user_info.sh) | Submits the currently logged-in user's full name, short name and email to Jamf inventory via `jamf recon`. |

### Admin Cheat Sheet

The [`Admin Cheat Sheet/`](./Admin%20Cheat%20Sheet) folder holds reference
snippets for common macOS administration tasks (user context, FileVault,
certificates, Active Directory, Jamf, and more). These are **examples to copy and
adapt**, not turnkey scripts — review each command before running it.

## Usage

### Extension Attributes

1. In Jamf Pro, go to **Settings → Computer Management → Extension Attributes**.
2. Create a **New** Extension Attribute with the data type **String** and input type **Script**.
3. Paste the contents of the desired `.sh` file.
4. Save and allow your devices to submit inventory.

### Scripts

1. In Jamf Pro, go to **Settings → Computer Management → Scripts**.
2. Create a **New** script and paste the contents of the desired `.sh` file.
3. Add the script to a **Policy** and scope it to the relevant devices.

## Customization

Several items contain values that are specific to an organization and **must be
adjusted before use**, for example:

- **Current WiFi SSID** — the list of known Wi-Fi network names:

  ```bash
  "Office"|"Remote"|"OfficeBerlin"|"OfficeMunic"|"OfficeHamburg")
  ```

- **Azure Device ID** — the `tenantID` variable must be set to your own Microsoft
  Entra ID tenant ID.
- **iCloud Account** / **User Config Profiles** — the lists of excluded admin/service
  account names may need to match your environment.

Replace these with the values that match your own environment before deploying.

## Contributing

Suggestions and improvements are welcome. Please open an issue or a pull request.
Note that pull requests are reviewed before being merged.

## License

This project is licensed under the [MIT License](./LICENSE) — you are free to use,
modify, and distribute these scripts, including for commercial purposes.
