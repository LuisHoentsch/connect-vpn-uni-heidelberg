# Creates "Toggle VPN" shortcut on the desktop,
# pointing at toggle_vpn.ps1 located next to this file.
$ps         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$desktop    = [Environment]::GetFolderPath("Desktop")
$shell      = New-Object -ComObject WScript.Shell

$scriptPath = Join-Path $PSScriptRoot "toggle_vpn.ps1"
$lnk        = $shell.CreateShortcut((Join-Path $desktop "Toggle VPN.lnk"))
$lnk.TargetPath       = $ps
$lnk.Arguments        = "-ExecutionPolicy Bypass -File `"$scriptPath`""
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.Save()
