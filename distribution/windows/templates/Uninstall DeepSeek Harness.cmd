@echo off
setlocal
set "INSTALL_ROOT=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Desktop'; Remove-Item -LiteralPath $menu -Recurse -Force -ErrorAction SilentlyContinue; Start-Process powershell.exe -ArgumentList '-NoProfile','-WindowStyle','Hidden','-Command',('Start-Sleep -Seconds 1; Remove-Item -LiteralPath ''' + $env:INSTALL_ROOT + ''' -Recurse -Force') -WindowStyle Hidden"
