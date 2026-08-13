$ErrorActionPreference = 'Stop'
$InstallMode = '__INSTALL_MODE__'

$defaultInstallRoot = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Desktop'
$menuRoot = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Desktop'
$payload = Join-Path $PSScriptRoot ("payload-$InstallMode.zip")

if (!(Test-Path -LiteralPath $payload -PathType Leaf)) {
  throw "Installer payload is missing: $payload"
}

$installRoot = $defaultInstallRoot
if ([Environment]::UserInteractive) {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  $dialog = New-Object System.Windows.Forms.Form
  $dialog.Text = '安装 DeepSeek Desktop'
  $dialog.StartPosition = 'CenterScreen'
  $dialog.FormBorderStyle = 'FixedDialog'
  $dialog.MaximizeBox = $false
  $dialog.MinimizeBox = $false
  $dialog.ClientSize = New-Object System.Drawing.Size(590, 205)

  $title = New-Object System.Windows.Forms.Label
  $title.Text = '选择安装位置'
  $title.Font = New-Object System.Drawing.Font($dialog.Font.FontFamily, 14, [System.Drawing.FontStyle]::Bold)
  $title.AutoSize = $true
  $title.Location = New-Object System.Drawing.Point(24, 22)

  $detail = New-Object System.Windows.Forms.Label
  $detail.Text = 'DeepSeek Desktop 将为当前 Windows 用户安装，并在开始菜单和已安装应用中创建入口。'
  $detail.AutoSize = $true
  $detail.Location = New-Object System.Drawing.Point(26, 58)

  $pathBox = New-Object System.Windows.Forms.TextBox
  $pathBox.Text = $defaultInstallRoot
  $pathBox.Location = New-Object System.Drawing.Point(26, 88)
  $pathBox.Size = New-Object System.Drawing.Size(430, 24)

  $browse = New-Object System.Windows.Forms.Button
  $browse.Text = '浏览...'
  $browse.Location = New-Object System.Drawing.Point(466, 86)
  $browse.Size = New-Object System.Drawing.Size(96, 28)
  $browse.Add_Click({
    $picker = New-Object System.Windows.Forms.FolderBrowserDialog
    $picker.Description = '选择 DeepSeek Desktop 的安装文件夹'
    $picker.SelectedPath = $pathBox.Text
    if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $pathBox.Text = $picker.SelectedPath }
  })

  $install = New-Object System.Windows.Forms.Button
  $install.Text = '安装'
  $install.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $install.Location = New-Object System.Drawing.Point(376, 145)
  $install.Size = New-Object System.Drawing.Size(90, 30)

  $cancel = New-Object System.Windows.Forms.Button
  $cancel.Text = '取消'
  $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $cancel.Location = New-Object System.Drawing.Point(472, 145)
  $cancel.Size = New-Object System.Drawing.Size(90, 30)

  $dialog.Controls.AddRange([System.Windows.Forms.Control[]]@($title, $detail, $pathBox, $browse, $install, $cancel))
  $dialog.AcceptButton = $install
  $dialog.CancelButton = $cancel
  if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $installRoot = $pathBox.Text.Trim()
  if ([string]::IsNullOrWhiteSpace($installRoot)) { throw 'Please choose an installation folder.' }
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

$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DeepSeek Desktop'
New-Item -Path $uninstallKey -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayName' -Value 'DeepSeek Desktop' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayVersion' -Value '__PRODUCT_VERSION__' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'Publisher' -Value 'DeepSeek Desktop Community' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'InstallLocation' -Value $installRoot -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayIcon' -Value (Join-Path $installRoot 'DeepSeek Desktop.exe') -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'UninstallString' -Value ('cmd.exe /d /s /c ""' + (Join-Path $installRoot 'Uninstall DeepSeek Harness.cmd') + '""') -PropertyType String -Force | Out-Null

& (Join-Path $installRoot 'Launch DeepSeek Desktop.cmd')
