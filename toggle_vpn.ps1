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

# CONNECT
$vpnCred = Get-StoredCredential -Target "Uni-Heidelberg-VPN"
$user = $vpnCred.UserName
$pass = $vpnCred.GetNetworkCredential().Password

$vpnHost = "vpn-ac.urz.uni-heidelberg.de"
$seedCred = Get-StoredCredential -Target "Uni-Heidelberg-VPN-Seed"
$seed     = $seedCred.GetNetworkCredential().Password   

# --- OTP GENERATION ---
$otp = & python -m oathtool $seed

# --- CONNECTION ---
$inputStrings = @($user, $pass, $otp, "y")
$inputStrings | & $vpnExe -s connect $vpnHost

