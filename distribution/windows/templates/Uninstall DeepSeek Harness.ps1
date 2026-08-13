$ErrorActionPreference = 'Stop'

$installRoot = $PSScriptRoot
$menuRoot = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Desktop'
$desktopShortcut = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)) 'DeepSeek Desktop.lnk'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DeepSeek Desktop'
$cleanupScript = Join-Path $env:TEMP ('DeepSeek-Desktop-Cleanup-' + [Guid]::NewGuid().ToString('N') + '.ps1')

Remove-Item -LiteralPath $menuRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $desktopShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $uninstallKey -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath (Join-Path $installRoot 'Uninstall DeepSeek Harness Cleanup.ps1') -Destination $cleanupScript
$quotedCleanupScript = '"' + $cleanupScript + '"'
$quotedInstallRoot = '"' + $installRoot + '"'
Start-Process -FilePath powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', $quotedCleanupScript, '-InstallRoot', $quotedInstallRoot) -WindowStyle Hidden
