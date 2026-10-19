# connect-vpn-uni-heidelberg
Make the vpn connection one click on windows.

PowerShell scripts that toggle the connection to the University of Heidelberg VPN (`vpn-ac.urz.uni-heidelberg.de`) via the Cisco Secure Client CLI: if disconnected, it generates the OTP and connects; if already connected, it disconnects. No phone or manual OTP entry needed.

> [!WARNING]
> Storing your TOTP seed on the same machine as your password weakens two-factor authentication. Only do this on a device you trust. 

## Requirements

### 1. Cisco Secure Client CLI
Ensure that Cisco Secure Client is installed at `C:\Program Files (x86)\Cisco\Cisco Secure Client\vpncli.exe`.
If you have your Cisco Secure Client installed in a different location, update `$vpnExe` in the script (`toggle_vpn.ps1`).

### 2. Shut down the Cisco GUI and disable its autostart
The GUI would conflict with the CLI session.
- Quit it: tray icon → right-click → *Quit*
- Disable autostart: Task Manager → *Startup apps* → "Cisco Secure Client - AnyConnect UI" (or "Cisco AnyConnect") → *Disable*.

### 3. Get your OTP seed
Add a new authenticator/2FA device in the university's token self-service portal (see the URZ VPN/MFA documentation). When a QR code is shown, "show secret key" to get the **Base32 secret**. That string is your seed. 

### 4. Store username, password and seed in the Credential Manager
Nothing secret lives in the scripts. They read everything from the Windows Credential Manager through the [CredentialManager](https://www.powershellgallery.com/packages/CredentialManager) PowerShell module.

Install the module once:

```powershell
Install-Module CredentialManager -Scope CurrentUser
```

Add the two entries (each is identified by its `-Target` name, which the scripts look up):

```powershell
# Username + password
New-StoredCredential -Target "Uni-Heidelberg-VPN" -UserName "your_uni_id" -Password "your_password" -Persist LocalMachine

# OTP seed (stored in the password field; the username is just a placeholder)
New-StoredCredential -Target "Uni-Heidelberg-VPN-Seed" -UserName "seed" -Password "YOUR_BASE32_SEED" -Persist LocalMachine
```

Check or change entries:

```powershell
Get-StoredCredential -Target "Uni-Heidelberg-VPN"      # shows the entry (password is hidden)
Remove-StoredCredential -Target "Uni-Heidelberg-VPN"   # delete, then re-add with New-StoredCredential to update
```

You can also manage them in the GUI: Start menu → *Credential Manager* → *Windows Credentials* → *Add a generic credential*. Use the target names above as the "Internet or network address".

| Target | User name | Password |
|---|---|---|
| `Uni-Heidelberg-VPN` | your uni ID | your uni password |
| `Uni-Heidelberg-VPN-Seed` | `seed` (anything) | your Base32 OTP seed |

### 5. Install oathtool
Python implementation of `oathtool` (requires Python 3):

```powershell
pip install oathtool
```

Test: `python -m oathtool YOUR_SEED` should print a 6-digit code.

## Setup

1. Clone or download this repo.
2. Store your username, password and seed in the Credential Manager (step 4).
3. Run `create_shortcut.ps1` (right-click → *Run with PowerShell*) to create the desktop shortcut **Toggle VPN**.


## Usage
Double-click **Toggle VPN** to connect if disconnected, or disconnect if currently connected.

## Files
- `toggle_vpn.ps1`: checks connection state and toggles (disconnects if connected, otherwise retrieves credentials, generates OTP, and connects)
- `create_shortcut.ps1`: creates the desktop shortcut
