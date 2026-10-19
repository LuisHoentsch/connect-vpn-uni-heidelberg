# --- CONFIGURATION ---
$vpnExe = "C:\Program Files (x86)\Cisco\Cisco Secure Client\vpncli.exe"

# --- CHECK CISCO CLI INSTALLATION ---
if (-not (Test-Path $vpnExe)) {
    Write-Host "ERROR: Cisco Secure Client CLI was not found at:`n  $vpnExe`n" -ForegroundColor Red
    Write-Host "Please ensure Cisco Secure Client is installed." -ForegroundColor Yellow
    Write-Host "If installed in a different location, update the `$vpnExe path at the top of this script.`n" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# --- CHECK CISCO GUI NOT RUNNING ---
$guiProcesses = Get-Process -Name csc_ui, vpnui -ErrorAction SilentlyContinue
if ($guiProcesses) {
    Write-Host "ERROR: Cisco Secure Client GUI is currently running." -ForegroundColor Red
    Write-Host "The graphical interface blocks the CLI from managing the connection.`n" -ForegroundColor Yellow
    Write-Host "Please do the following:" -ForegroundColor Yellow
    Write-Host "  1. Shut down Cisco Secure Client (right-click the tray icon -> Quit)." -ForegroundColor Yellow
    Write-Host "  2. Disable its autostart (Task Manager -> 'Startup apps' tab -> Disable Cisco Secure Client).`n" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# --- CHECK STATUS (TOGGLE) ---
$stateOutput = & $vpnExe state 2>&1
if ($stateOutput -match "state:\s*(Connected|Verbunden)") {
    # DISCONNECT
    & $vpnExe disconnect
    exit
}

# --- CONNECT ---
# Verify CredentialManager module is available
if (-not (Get-Command Get-StoredCredential -ErrorAction SilentlyContinue)) {
    Import-Module CredentialManager -ErrorAction SilentlyContinue
}

if (-not (Get-Command Get-StoredCredential -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: PowerShell module 'CredentialManager' is not installed." -ForegroundColor Red
    Write-Host "Please install it by running the following command in PowerShell:`n" -ForegroundColor Yellow
    Write-Host "  Install-Module CredentialManager -Scope CurrentUser`n" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

# Retrieve credentials and seed
$vpnCred  = Get-StoredCredential -Target "Uni-Heidelberg-VPN" -ErrorAction SilentlyContinue
$user     = if ($vpnCred) { $vpnCred.UserName } else { $null }
$pass     = if ($vpnCred) { $vpnCred.GetNetworkCredential().Password } else { $null }

$seedCred = Get-StoredCredential -Target "Uni-Heidelberg-VPN-Seed" -ErrorAction SilentlyContinue
$seed     = if ($seedCred) { $seedCred.GetNetworkCredential().Password } else { $null }

$hasCreds = ($vpnCred -and -not [string]::IsNullOrWhiteSpace($user) -and -not [string]::IsNullOrWhiteSpace($pass))
$hasSeed  = ($seedCred -and -not [string]::IsNullOrWhiteSpace($seed))

if (-not $hasCreds -or -not $hasSeed) {
    Write-Host "ERROR: Missing VPN credentials in Windows Credential Manager.`n" -ForegroundColor Red
    
    if (-not $hasCreds) {
        Write-Host "Missing 'Uni-Heidelberg-VPN' (username & password)." -ForegroundColor Yellow
        Write-Host "Store it by running this in PowerShell:" -ForegroundColor Yellow
        Write-Host '  New-StoredCredential -Target "Uni-Heidelberg-VPN" -UserName "<your_uni_id>" -Password "<your_password>" -Persist LocalMachine' -ForegroundColor Cyan
        Write-Host ""
    }
    
    if (-not $hasSeed) {
        Write-Host "Missing 'Uni-Heidelberg-VPN-Seed' (Base32 OTP seed)." -ForegroundColor Yellow
        Write-Host "Store it by running this in PowerShell:" -ForegroundColor Yellow
        Write-Host '  New-StoredCredential -Target "Uni-Heidelberg-VPN-Seed" -UserName "seed" -Password "<YOUR_BASE32_SEED>" -Persist LocalMachine' -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "Alternatively, add them via GUI:" -ForegroundColor Yellow
    Write-Host "  Start -> Credential Manager -> Windows Credentials -> Add a generic credential`n" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

$vpnHost = "vpn-ac.urz.uni-heidelberg.de"   

# --- OTP GENERATION ---
$otp = & python -m oathtool $seed

# --- CONNECTION ---
$inputStrings = @($user, $pass, $otp, "y")
$inputStrings | & $vpnExe -s connect $vpnHost

