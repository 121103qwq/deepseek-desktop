$ErrorActionPreference = 'Stop'
$InstallMode = '__INSTALL_MODE__'

$installRoot = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Desktop'
$menuRoot = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Desktop'
$payload = Join-Path $PSScriptRoot ("payload-$InstallMode.zip")

if (!(Test-Path -LiteralPath $payload -PathType Leaf)) {
  throw "Installer payload is missing: $payload"
}

New-Item -ItemType Directory -Force -Path $installRoot, $menuRoot | Out-Null
Expand-Archive -LiteralPath $payload -DestinationPath $installRoot -Force

if ($InstallMode -eq 'mirror') {
  $runtimeRoot = Join-Path $installRoot 'runtime'
  $appRoot = Join-Path $installRoot 'app'
  $savedPath = $env:PATH
  try {
    $env:PATH = "$runtimeRoot;$savedPath"
    Push-Location $appRoot
    & (Join-Path $runtimeRoot 'npm.cmd') install '--omit=dev' '--no-audit' '--no-fund' '--package-lock=false' '--registry=https://registry.npmmirror.com' '--fetch-retries=3' '--fetch-timeout=120000'
    if ($LASTEXITCODE -ne 0) { throw "DeepSeek Desktop download failed with exit code $LASTEXITCODE" }
  } finally {
    Pop-Location
    $env:PATH = $savedPath
  }
}

$homeRoot = Join-Path $env:LOCALAPPDATA 'DeepSeek Harness Data'
$profileRoot = Join-Path $homeRoot 'profiles\web'
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
if (!(Test-Path -LiteralPath (Join-Path $profileRoot 'cordis.patch.yml'))) {
  Copy-Item -LiteralPath (Join-Path $installRoot 'defaults\cordis.patch.yml') -Destination (Join-Path $profileRoot 'cordis.patch.yml')
}
if (!(Test-Path -LiteralPath (Join-Path $homeRoot 'settings.yaml'))) {
@"
ui-onboarding:
  welcomeNoticeVersion: 2026-08-13.1
"@ | Set-Content -LiteralPath (Join-Path $homeRoot 'settings.yaml') -Encoding utf8
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $menuRoot 'DeepSeek Desktop.lnk'))
$shortcut.TargetPath = Join-Path $installRoot 'Launch DeepSeek Desktop.cmd'
$shortcut.WorkingDirectory = $installRoot
$shortcut.Description = 'Open DeepSeek Desktop'
$shortcut.Save()

& (Join-Path $installRoot 'Launch DeepSeek Desktop.cmd')
