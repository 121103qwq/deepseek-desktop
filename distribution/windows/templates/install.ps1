$ErrorActionPreference = 'Stop'
$InstallMode = '__INSTALL_MODE__'

$defaultInstallRoot = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Desktop'
$menuRoot = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Desktop'
$payload = Join-Path $PSScriptRoot ("payload-$InstallMode.zip")

if (!(Test-Path -LiteralPath $payload -PathType Leaf)) {
  throw "Installer payload is missing: $payload"
}

$installRoot = $defaultInstallRoot
$createDesktopShortcut = $false
$selectedModelMode = 'free'
if ([Environment]::UserInteractive) {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  $dialog = New-Object System.Windows.Forms.Form
  $dialog.Text = '安装 DeepSeek Desktop'
  $dialog.StartPosition = 'CenterScreen'
  $dialog.FormBorderStyle = 'FixedDialog'
  $dialog.MaximizeBox = $false
  $dialog.MinimizeBox = $false
  $dialog.ClientSize = New-Object System.Drawing.Size(590, 315)

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

  $modelDetail = New-Object System.Windows.Forms.Label
  $modelDetail.Text = '首次模型路线（仅在安装时选择；以后可在应用内修改）：'
  $modelDetail.AutoSize = $true
  $modelDetail.Location = New-Object System.Drawing.Point(26, 128)

  $freeModel = New-Object System.Windows.Forms.RadioButton
  $freeModel.Text = '免费模型（Kilo，免登录）'
  $freeModel.Checked = $true
  $freeModel.AutoSize = $true
  $freeModel.Location = New-Object System.Drawing.Point(26, 154)

  $deepSeekApi = New-Object System.Windows.Forms.RadioButton
  $deepSeekApi.Text = 'DeepSeek API（稍后在应用内填写 Key）'
  $deepSeekApi.AutoSize = $true
  $deepSeekApi.Location = New-Object System.Drawing.Point(26, 180)

  $desktopShortcut = New-Object System.Windows.Forms.CheckBox
  $desktopShortcut.Text = '创建桌面快捷方式'
  $desktopShortcut.Checked = $true
  $desktopShortcut.AutoSize = $true
  $desktopShortcut.Location = New-Object System.Drawing.Point(26, 212)

  $install = New-Object System.Windows.Forms.Button
  $install.Text = '安装'
  $install.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $install.Location = New-Object System.Drawing.Point(376, 254)
  $install.Size = New-Object System.Drawing.Size(90, 30)

  $cancel = New-Object System.Windows.Forms.Button
  $cancel.Text = '取消'
  $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $cancel.Location = New-Object System.Drawing.Point(472, 254)
  $cancel.Size = New-Object System.Drawing.Size(90, 30)

  $dialog.Controls.AddRange([System.Windows.Forms.Control[]]@($title, $detail, $pathBox, $browse, $modelDetail, $freeModel, $deepSeekApi, $desktopShortcut, $install, $cancel))
  $dialog.AcceptButton = $install
  $dialog.CancelButton = $cancel
  if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $installRoot = $pathBox.Text.Trim()
  $createDesktopShortcut = $desktopShortcut.Checked
  if ($deepSeekApi.Checked) { $selectedModelMode = 'deepseek' }
  if ([string]::IsNullOrWhiteSpace($installRoot)) { throw 'Please choose an installation folder.' }
}

New-Item -ItemType Directory -Force -Path $installRoot, $menuRoot | Out-Null
Expand-Archive -LiteralPath $payload -DestinationPath $installRoot -Force

$homeRoot = Join-Path $env:LOCALAPPDATA 'DeepSeek Harness Data'
$profileRoot = Join-Path $homeRoot 'profiles\web'
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
if (!(Test-Path -LiteralPath (Join-Path $profileRoot 'cordis.patch.yml'))) {
  Copy-Item -LiteralPath (Join-Path $installRoot 'defaults\cordis.patch.yml') -Destination (Join-Path $profileRoot 'cordis.patch.yml')
}
$patchPath = Join-Path $profileRoot 'cordis.patch.yml'
$patchText = Get-Content -LiteralPath $patchPath -Raw
$freeDefault = "provider: kilo`r`n    model: kilo-auto/free"
$deepSeekDefault = "provider: deepseek-official`r`n    model: deepseek-v4-flash"
$disabledDeepSeek = "- id: llm-deepseek`r`n  disabled: true"
$enabledDeepSeek = '- id: llm-deepseek'
if ($selectedModelMode -eq 'deepseek') {
  $patchText = $patchText.Replace($freeDefault, $deepSeekDefault).Replace($freeDefault.Replace("`r`n", "`n"), $deepSeekDefault.Replace("`r`n", "`n"))
  $patchText = $patchText.Replace($disabledDeepSeek, $enabledDeepSeek).Replace($disabledDeepSeek.Replace("`r`n", "`n"), $enabledDeepSeek)
} else {
  $patchText = $patchText.Replace($deepSeekDefault, $freeDefault).Replace($deepSeekDefault.Replace("`r`n", "`n"), $freeDefault.Replace("`r`n", "`n"))
  $patchText = $patchText.Replace($enabledDeepSeek + "`r`n  disabled: true", $disabledDeepSeek).Replace($enabledDeepSeek + "`n  disabled: true", $disabledDeepSeek)
  if (!$patchText.Contains($disabledDeepSeek) -and !$patchText.Contains($disabledDeepSeek.Replace("`r`n", "`n"))) { $patchText = $patchText.Replace($enabledDeepSeek, $disabledDeepSeek) }
}
Set-Content -LiteralPath $patchPath -Value $patchText -Encoding utf8
if (!(Test-Path -LiteralPath (Join-Path $homeRoot 'settings.yaml'))) {
@"
ui-onboarding:
  welcomeNoticeVersion: 2026-08-13.1
locale:
  preference: zh
llm-pi-ai:
  providers:
    kilo:
      displayName: Kilo AI Gateway（匿名免费）
      api: openai-completions
      baseURL: https://api.kilo.ai/api/gateway
      headers:
        Authorization: Bearer unused
      models:
        - id: kilo-auto/free
          name: Kilo Auto Free（免登录）
          contextWindow: 131072
          maxTokens: 8192
        - id: stepfun/step-3.7-flash:free
          name: StepFun 3.7 Flash（Kilo 免费）
          contextWindow: 131072
          maxTokens: 8192
"@ | Set-Content -LiteralPath (Join-Path $homeRoot 'settings.yaml') -Encoding utf8
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $menuRoot 'DeepSeek Desktop.lnk'))
$shortcut.TargetPath = Join-Path $installRoot 'Launch DeepSeek Desktop.cmd'
$shortcut.WorkingDirectory = $installRoot
$shortcut.IconLocation = (Join-Path $installRoot 'DeepSeek-Black-Logo.ico')
$shortcut.IconIndex = 0
$shortcut.Description = 'Open DeepSeek Desktop'
$shortcut.Save()

if ($createDesktopShortcut) {
  $desktopShortcutPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)) 'DeepSeek Desktop.lnk'
  $desktopLink = $shell.CreateShortcut($desktopShortcutPath)
  $desktopLink.TargetPath = Join-Path $installRoot 'Launch DeepSeek Desktop.cmd'
  $desktopLink.WorkingDirectory = $installRoot
  $desktopLink.IconLocation = (Join-Path $installRoot 'DeepSeek-Black-Logo.ico')
  $desktopLink.IconIndex = 0
  $desktopLink.Description = 'Open DeepSeek Desktop'
  $desktopLink.Save()
}

$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DeepSeek Desktop'
New-Item -Path $uninstallKey -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayName' -Value 'DeepSeek Desktop' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayVersion' -Value '__PRODUCT_VERSION__' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'Publisher' -Value 'DeepSeek Desktop Community' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'InstallLocation' -Value $installRoot -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayIcon' -Value (Join-Path $installRoot 'DeepSeek Desktop.exe') -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'UninstallString' -Value ('cmd.exe /d /s /c ""' + (Join-Path $installRoot 'Uninstall DeepSeek Harness.cmd') + '""') -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'InstallDate' -Value (Get-Date -Format 'yyyyMMdd') -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'URLInfoAbout' -Value 'https://github.com/121103qwq/deepseek-desktop' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'NoModify' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'NoRepair' -Value 1 -PropertyType DWord -Force | Out-Null
$estimatedBytes = (Get-ChildItem -LiteralPath $installRoot -File -Recurse | Measure-Object -Property Length -Sum).Sum
$estimatedSizeKb = [int]([Math]::Ceiling($estimatedBytes / 1KB))
New-ItemProperty -Path $uninstallKey -Name 'EstimatedSize' -Value $estimatedSizeKb -PropertyType DWord -Force | Out-Null

& (Join-Path $installRoot 'Launch DeepSeek Desktop.cmd')
