<##
.SYNOPSIS
Build DeepSeek Desktop setup executables for Windows x64.

.DESCRIPTION
Creates an offline setup with the complete published Harness dependency closure.
With -BuildMirror it also creates a smaller domestic-network setup whose dependency
download runs inside the installer before the desktop window is launched.
The payload is stored as a non-solid 7-Zip archive so Setup can appear quickly and
extract every required runtime file during installation with native progress reporting.
##>
[CmdletBinding()]
param(
  [string]$OutputDirectory,
  [switch]$BuildMirror
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$desktopVersion = '0.2.2'
$dshVersion = '0.1.0-rc.6'
$nodeVersion = '22.19.0'
$nodeArchiveName = "node-v$nodeVersion-win-x64.zip"
$nodeUrl = "https://nodejs.org/dist/v$nodeVersion/$nodeArchiveName"
$nodeSha256 = 'ea3fad0e67a991d8477d8c01344b56e69c676ccb733f065b22436994b1253f86'
$webViewPackageVersion = '1.0.3856.49'
$webViewPackageUrl = "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/$webViewPackageVersion"
$fixedWebViewRuntimeVersion = '150.0.4078.99'
$fixedWebViewRuntimeUrl = "https://api.nuget.org/v3-flatcontainer/webview2.runtime.x64/$fixedWebViewRuntimeVersion/webview2.runtime.x64.$fixedWebViewRuntimeVersion.nupkg"
$fixedWebViewRuntimeSha256 = 'c0907ddb8f2fff6f91ccb7fe972284dc47f07e34684d0aedefda3d0f6edf75d8'
$visionPluginVersion = '0.1.3'
$visionPluginUrl = "https://codeload.github.com/121103qwq/dsh-vision-sidecar/tar.gz/refs/tags/v$visionPluginVersion"
$visionPluginSha256 = 'bc2036a3369889352f99cb09b5036dcf1419f5e34951e70bb8b0415fa894a1b5'
$innoLanguageUrl = 'https://raw.githubusercontent.com/jrsoftware/issrc/is-6_7_3/Files/Languages/Unofficial/ChineseSimplified.isl'
$innoLanguageSha256 = '7d544b9bb1d142cfa11f2e5d3cc8abe2e55f8e066c5124e3772675aa236e1278'
$repoRoot = Split-Path -Parent $PSScriptRoot
$distributionRoot = Join-Path $repoRoot 'distribution\windows'
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = Join-Path $distributionRoot 'dist' }
$outputPath = [IO.Path]::GetFullPath($OutputDirectory)
$workRoot = Join-Path $distributionRoot ("build\windows-installer-" + [Guid]::NewGuid().ToString('N'))
$nodeArchive = Join-Path $workRoot $nodeArchiveName
$webViewPackage = Join-Path $workRoot 'webview2.nupkg'
$webViewExtract = Join-Path $workRoot 'webview2'
$fixedWebViewRuntimePackage = Join-Path $workRoot 'webview2-runtime.nupkg'
$fixedWebViewRuntimeExtract = Join-Path $workRoot 'webview2-runtime'
$visionPluginArchive = Join-Path $workRoot "dsh-vision-sidecar-v$visionPluginVersion.tgz"
$innoCompiler = 'D:\DevTools\Scoop\apps\innosetup7-np\7.1.0\ISCC.exe'
$sevenZip = 'D:\DevTools\Scoop\shims\7z.exe'
$innoLanguageFile = Join-Path $workRoot 'ChineseSimplified.isl'

function Assert-ExternalSuccess([string]$Subject) {
  if ($LASTEXITCODE -ne 0) { throw "$Subject failed with exit code $LASTEXITCODE" }
}

function Get-Sha256([string]$Path) {
  $lines = & certutil.exe -hashfile $Path SHA256
  Assert-ExternalSuccess "SHA-256 calculation for $Path"
  $hashLine = @($lines | Where-Object { $_ -match '^[0-9A-Fa-f ]+$' } | Select-Object -First 1)
  if ($hashLine.Count -ne 1) { throw "certutil did not return a SHA-256 hash for $Path" }
  return ($hashLine[0] -replace '\s', '').ToLowerInvariant()
}

function Write-AppManifest([string]$AppRoot) {
  @{ name = 'deepseek-desktop-runtime'; version = $dshVersion; private = $true; dependencies = @{ '@deepseek-ai/dsh' = $dshVersion; 'dsh-vision-sidecar' = "file:../vision/dsh-vision-sidecar-v$visionPluginVersion.tgz" } } |
    ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $AppRoot 'package.json') -Encoding utf8
}

function Remove-NonRuntimePackageFiles([string]$NodeModulesRoot) {
  $directoryNames = @('.github', '.yarn', '__tests__', 'benchmark', 'benchmarks', 'coverage', 'example', 'examples', 'test', 'tests')
  $directories = Get-ChildItem -LiteralPath $NodeModulesRoot -Directory -Recurse -Force |
    Where-Object { $directoryNames -contains $_.Name.ToLowerInvariant() } |
    Sort-Object { $_.FullName.Length } -Descending
  foreach ($directory in $directories) {
    Remove-Item -LiteralPath $directory.FullName -Recurse -Force
  }
  Get-ChildItem -LiteralPath $NodeModulesRoot -File -Recurse -Force |
    Where-Object { $_.Name -like '*.map' -or $_.Name -like '*.d.ts' -or $_.Name -like '*.d.mts' -or $_.Name -like '*.d.cts' -or $_.Name -like '*.ts' } |
    Remove-Item -Force
}

function Copy-CommonPayload([string]$PayloadRoot, [bool]$IncludeMirrorInstaller) {
  $runtimeRoot = Join-Path $PayloadRoot 'runtime'
  $appRoot = Join-Path $PayloadRoot 'app'
  $desktopRoot = $PayloadRoot
  New-Item -ItemType Directory -Force -Path $runtimeRoot, $appRoot, (Join-Path $PayloadRoot 'defaults') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $PayloadRoot 'vision') | Out-Null
  Copy-Item -Path (Join-Path $expandedNode '*') -Destination $runtimeRoot -Recurse
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\Configure Vision.mjs') -Destination $PayloadRoot
  Copy-Item -LiteralPath $visionPluginArchive -Destination (Join-Path $PayloadRoot "vision\dsh-vision-sidecar-v$visionPluginVersion.tgz")
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\default-web.patch.yml') -Destination (Join-Path $PayloadRoot 'defaults\cordis.patch.yml')
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\DeepSeek-Black-Logo.svg') -Destination (Join-Path $PayloadRoot 'DeepSeek-Black-Logo.svg')
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\DeepSeek-Black-Logo.png') -Destination $PayloadRoot
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\DeepSeek-Black-Logo.ico') -Destination $PayloadRoot
  Copy-Item -LiteralPath (Join-Path $webViewExtract 'lib\net462\Microsoft.Web.WebView2.Core.dll') -Destination $desktopRoot
  Copy-Item -LiteralPath (Join-Path $webViewExtract 'lib\net462\Microsoft.Web.WebView2.WinForms.dll') -Destination $desktopRoot
  Copy-Item -LiteralPath (Join-Path $webViewExtract 'build\native\x64\WebView2Loader.dll') -Destination $desktopRoot
  $fixedRuntimeSource = Join-Path $fixedWebViewRuntimeExtract 'contentFiles\any\any\WebView2'
  if (!(Test-Path -LiteralPath (Join-Path $fixedRuntimeSource 'msedgewebview2.exe') -PathType Leaf)) { throw 'The fixed WebView2 runtime is incomplete.' }
  Copy-Item -LiteralPath $fixedRuntimeSource -Destination (Join-Path $PayloadRoot 'WebView2') -Recurse
  $compiler = 'D:\Program Files (x86)\visualstudio\MSBuild\Current\Bin\Roslyn\csc.exe'
  if (!(Test-Path -LiteralPath $compiler -PathType Leaf)) { throw "C# compiler is missing: $compiler" }
  $source = Join-Path $distributionRoot 'templates\DeepSeekDesktop.cs'
  $responseFile = Join-Path $workRoot "desktop-$([IO.Path]::GetFileName($PayloadRoot)).rsp"
  @"
/nologo
/target:winexe
/out:"$(Join-Path $PayloadRoot 'DeepSeek Desktop.exe')"
/win32icon:"$(Join-Path $PayloadRoot 'DeepSeek-Black-Logo.ico')"
/win32manifest:"$(Join-Path $distributionRoot 'templates\DeepSeekDesktop.manifest')"
/reference:System.dll
/reference:System.Core.dll
/reference:System.Drawing.dll
/reference:System.Windows.Forms.dll
/reference:"$(Join-Path $desktopRoot 'Microsoft.Web.WebView2.Core.dll')"
/reference:"$(Join-Path $desktopRoot 'Microsoft.Web.WebView2.WinForms.dll')"
"$source"
"@ | Set-Content -LiteralPath $responseFile -Encoding utf8
  & $compiler "@$responseFile"
  Assert-ExternalSuccess 'DeepSeek Desktop compilation'
  $configSource = Join-Path $distributionRoot 'templates\DeepSeekInstallerConfig.cs'
  & $compiler /nologo /target:winexe "/out:$(Join-Path $PayloadRoot 'DeepSeek Installer Config.exe')" /reference:System.dll /reference:System.Core.dll /reference:System.Windows.Forms.dll $configSource
  Assert-ExternalSuccess 'DeepSeek installer configuration helper compilation'
  $updaterSource = Join-Path $distributionRoot 'templates\DeepSeekUpdater.cs'
  & $compiler /nologo /target:winexe "/out:$(Join-Path $PayloadRoot 'DeepSeek Updater.exe')" "/win32icon:$(Join-Path $PayloadRoot 'DeepSeek-Black-Logo.ico')" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.Extensions.dll $updaterSource
  Assert-ExternalSuccess 'DeepSeek updater compilation'
  if ($IncludeMirrorInstaller) {
    $mirrorSource = Join-Path $distributionRoot 'templates\DeepSeekMirrorInstaller.cs'
    & $compiler /nologo /target:winexe "/out:$(Join-Path $PayloadRoot 'DeepSeek Mirror Installer.exe')" "/win32icon:$(Join-Path $PayloadRoot 'DeepSeek-Black-Logo.ico')" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll $mirrorSource
    Assert-ExternalSuccess 'Domestic mirror installer compilation'
  }
  Write-AppManifest $appRoot
}

function New-Setup([string]$Kind, [bool]$IncludeDependencies) {
  $payloadRoot = Join-Path $workRoot "payload-$Kind"
  $appRoot = Join-Path $payloadRoot 'app'
  $runtimeRoot = Join-Path $payloadRoot 'runtime'
  $offlineSuffix = [string][char]0x79bb + [char]0x7ebf + [char]0x7248
  $mirrorSuffix = [string][char]0x56fd + [char]0x5185 + [char]0x7f51 + [char]0x7edc
  $installerSuffix = if ($IncludeDependencies) { $offlineSuffix } else { $mirrorSuffix }
  $installerName = "DeepSeek-Desktop-$desktopVersion-Windows-x64-$installerSuffix.exe"
  $installerPath = Join-Path $outputPath $installerName
  $innoBaseName = "DeepSeek-Desktop-$desktopVersion-Windows-x64-$Kind.tmp"
  $innoTarget = Join-Path $outputPath ($innoBaseName + '.exe')
  if (Test-Path -LiteralPath $installerPath) { throw "Refusing to overwrite an existing installer: $installerPath" }
  if (Test-Path -LiteralPath $innoTarget) { throw "Refusing to overwrite an existing Inno Setup target: $innoTarget" }
  Copy-CommonPayload $payloadRoot (-not $IncludeDependencies)
  if ($IncludeDependencies) {
    Write-Host "Installing complete @deepseek-ai/dsh@$dshVersion dependency closure..."
    $originalPath = $env:PATH
    try {
      $env:PATH = "$runtimeRoot;$originalPath"
      Push-Location $appRoot
      & (Join-Path $runtimeRoot 'npm.cmd') install '--omit=dev' '--no-audit' '--no-fund' '--package-lock=false' '--registry=https://registry.npmjs.org' '--fetch-retries=2' '--fetch-timeout=120000'
      Assert-ExternalSuccess 'npm install'
    } finally {
      Pop-Location
      $env:PATH = $originalPath
    }
    $dshBin = Join-Path $appRoot 'node_modules\@deepseek-ai\dsh\lib\bin.js'
    if (!(Test-Path -LiteralPath $dshBin -PathType Leaf)) { throw "Published DeepSeek Harness binary is missing: $dshBin" }
    & (Join-Path $runtimeRoot 'node.exe') $dshBin --help
    Assert-ExternalSuccess 'DeepSeek Harness smoke test'
    $visionManifest = Join-Path $appRoot 'node_modules\dsh-vision-sidecar\package.json'
    if (!(Test-Path -LiteralPath $visionManifest -PathType Leaf)) { throw 'The bundled vision plugin is missing.' }
    Push-Location $appRoot
    try {
      & (Join-Path $runtimeRoot 'npm.cmd') dedupe '--omit=dev' '--no-audit' '--no-fund' '--package-lock=false' '--registry=https://registry.npmjs.org'
      Assert-ExternalSuccess 'Production dependency deduplication'
    } finally {
      Pop-Location
    }
    & (Join-Path $runtimeRoot 'node.exe') $dshBin --help
    Assert-ExternalSuccess 'DeepSeek Harness post-plugin smoke test'
    Write-Host 'Removing development-only package files from the installer payload...'
    Remove-NonRuntimePackageFiles (Join-Path $appRoot 'node_modules')
    & (Join-Path $runtimeRoot 'node.exe') $dshBin --help
    Assert-ExternalSuccess 'DeepSeek Harness optimized payload smoke test'
    $buildDshHome = Join-Path $workRoot 'dsh-home-smoke'
    $originalDshHome = $env:DSH_HOME
    try {
      $buildProfile = Join-Path $buildDshHome 'profiles\web'
      New-Item -ItemType Directory -Force -Path $buildProfile | Out-Null
      Copy-Item -LiteralPath (Join-Path $payloadRoot 'defaults\cordis.patch.yml') -Destination (Join-Path $buildProfile 'cordis.patch.yml') -Force
      $profileModules = Join-Path $buildProfile 'node_modules'
      $moduleLinkCommand = 'mklink /J "' + $profileModules + '" "' + (Join-Path $appRoot 'node_modules') + '"'
      & cmd.exe /d /s /c $moduleLinkCommand | Out-Null
      Assert-ExternalSuccess 'Harness profile dependency link creation'
      $env:DSH_HOME = $buildDshHome
      $node = Join-Path $runtimeRoot 'node.exe'
      & $node $dshBin --profile web --dump-config | Out-Null
      Assert-ExternalSuccess 'DeepSeek Harness profile initialization smoke test'
      & $node (Join-Path $payloadRoot 'Configure Vision.mjs') $buildDshHome true free
      Assert-ExternalSuccess 'Vision profile configuration smoke test'
      & $node $dshBin --profile web --dump-config | Out-Null
      Assert-ExternalSuccess 'DeepSeek Harness optimized vision profile smoke test'
      $webPort = Get-Random -Minimum 40000 -Maximum 50000
      $webOutput = Join-Path $workRoot 'web-smoke.stdout.txt'
      $webError = Join-Path $workRoot 'web-smoke.stderr.txt'
      $webProcess = Start-Process -FilePath $node -ArgumentList ('"' + $dshBin + '" --profile web --port ' + $webPort) -WorkingDirectory $payloadRoot -RedirectStandardOutput $webOutput -RedirectStandardError $webError -PassThru
      $webReady = $false
      try {
        $deadline = [DateTime]::UtcNow.AddSeconds(30)
        while ([DateTime]::UtcNow -lt $deadline) {
          if ($webProcess.HasExited) {
            $detail = (Get-Content -LiteralPath $webOutput, $webError -Raw -ErrorAction SilentlyContinue) -join "`n"
            throw "Optimized Harness web server exited during smoke test.`n$detail"
          }
          try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri ("http://127.0.0.1:" + $webPort + '/') -TimeoutSec 1
            if ($response.StatusCode -eq 200 -and $response.Content -match 'DeepSeek Harness') { $webReady = $true; break }
          } catch {
          }
          Start-Sleep -Milliseconds 250
        }
      } finally {
        if (!$webProcess.HasExited) { $webProcess | Stop-Process -Force; $webProcess.WaitForExit() }
      }
      if (!$webReady) { throw 'Optimized Harness web server did not return the expected page within 30 seconds.' }
    } finally {
      $env:DSH_HOME = $originalDshHome
    }
  }
  Set-Content -LiteralPath (Join-Path $payloadRoot 'VERSION.txt') -Value "DeepSeek Desktop $desktopVersion`r`nDeepSeek Harness $dshVersion`r`nBundled Node.js $nodeVersion" -Encoding ascii
  $payloadFiles = Get-ChildItem -LiteralPath $payloadRoot -Recurse -File -Force
  $excludedPayloadFiles = $payloadFiles | Where-Object {
    $_.Name -like '*.map' -or $_.Name -like '*.d.ts' -or $_.Name -like '*.d.mts' -or $_.Name -like '*.d.cts' -or $_.Name -like '*.ts'
  }
  $payloadBytes = ($payloadFiles | Measure-Object -Property Length -Sum).Sum - ($excludedPayloadFiles | Measure-Object -Property Length -Sum).Sum
  if ($payloadBytes -le 0) { throw 'The offline payload is empty.' }
  $payloadArchive = Join-Path $workRoot "payload-$Kind.7z"
  Write-Host "Packing the offline payload as a non-solid archive..."
  Push-Location $payloadRoot
  try {
    & $sevenZip a -t7z $payloadArchive '.\*' '-mx=5' '-ms=off' '-mmt=on' '-xr!*.map' '-xr!*.d.ts' '-xr!*.d.mts' '-xr!*.d.cts' '-xr!*.ts' | Out-Null
    Assert-ExternalSuccess 'Offline payload archive creation'
  } finally {
    Pop-Location
  }
  & $sevenZip t $payloadArchive | Out-Null
  Assert-ExternalSuccess 'Offline payload archive verification'
  $mode = if ($IncludeDependencies) { 'offline' } else { 'mirror' }
  $mirrorRun = if ($IncludeDependencies) { '' } else { 'Filename: "{app}\DeepSeek Mirror Installer.exe"; StatusMsg: "正在下载运行组件（国内网络优先）…"; Flags: waituntilterminated' }
  $issPath = Join-Path $workRoot "installer-$Kind.iss"
  $fileVersion = $desktopVersion + '.0'
  $issText = [IO.File]::ReadAllText((Join-Path $distributionRoot 'templates\installer.iss'), [Text.Encoding]::UTF8)
  $issText = $issText.Replace('__DESKTOP_VERSION__', $desktopVersion).Replace('__DSH_VERSION__', $dshVersion).Replace('__FILE_VERSION__', $fileVersion).Replace('__INSTALL_MODE__', $mode).Replace('__MIRROR_RUN__', $mirrorRun).Replace('__PAYLOAD_ARCHIVE__', $payloadArchive).Replace('__PAYLOAD_BYTES__', ([string]$payloadBytes)).Replace('__OUTPUT_DIR__', $outputPath).Replace('__OUTPUT_BASE__', $innoBaseName).Replace('__SETUP_ICON__', (Join-Path $distributionRoot 'templates\DeepSeek-Black-Logo.ico')).Replace('__WIZARD_LOGO__', (Join-Path $workRoot 'installer-logo.bmp')).Replace('__LANGUAGE_FILE__', $innoLanguageFile)
  [IO.File]::WriteAllText($issPath, $issText, (New-Object Text.UTF8Encoding($false)))
  Write-Host "Creating $Kind setup executable with Inno Setup..."
  & $innoCompiler --quiet-progress $issPath
  Assert-ExternalSuccess "Inno Setup $Kind compilation"
  if (!(Test-Path -LiteralPath $innoTarget -PathType Leaf)) { throw 'Inno Setup did not create the setup executable.' }
  Move-Item -LiteralPath $innoTarget -Destination $installerPath
  Get-Item -LiteralPath $installerPath | Select-Object FullName, Length
}

if ([Environment]::Is64BitOperatingSystem -eq $false) { throw 'This installer build targets Windows x64 only.' }
if (!(Test-Path -LiteralPath $innoCompiler -PathType Leaf)) { throw "Inno Setup compiler is missing: $innoCompiler" }
if (!(Test-Path -LiteralPath $sevenZip -PathType Leaf)) { throw "7-Zip is missing: $sevenZip" }
New-Item -ItemType Directory -Force -Path $outputPath, $workRoot | Out-Null

Write-Host "Downloading Node.js $nodeVersion..."
& curl.exe --fail --location --silent --show-error --output $nodeArchive $nodeUrl
Assert-ExternalSuccess 'Node.js download'
$actualNodeHash = Get-Sha256 $nodeArchive
if ($actualNodeHash -ne $nodeSha256) { throw "Node.js checksum mismatch: expected $nodeSha256, got $actualNodeHash" }
Expand-Archive -LiteralPath $nodeArchive -DestinationPath $workRoot
$expandedNode = Join-Path $workRoot "node-v$nodeVersion-win-x64"
if (!(Test-Path -LiteralPath (Join-Path $expandedNode 'node.exe') -PathType Leaf)) { throw 'The extracted Node.js runtime is incomplete.' }

Write-Host 'Downloading the embedded WebView binding...'
& curl.exe --fail --location --silent --show-error --output $webViewPackage $webViewPackageUrl
Assert-ExternalSuccess 'WebView binding download'
& 'D:\DevTools\Scoop\shims\7z.exe' x $webViewPackage "-o$webViewExtract" -y | Out-Null
Assert-ExternalSuccess 'WebView binding extraction'

Write-Host "Downloading the fixed WebView2 runtime $fixedWebViewRuntimeVersion..."
& curl.exe --fail --location --silent --show-error --output $fixedWebViewRuntimePackage $fixedWebViewRuntimeUrl
Assert-ExternalSuccess 'Fixed WebView2 runtime download'
$actualFixedRuntimeHash = Get-Sha256 $fixedWebViewRuntimePackage
if ($actualFixedRuntimeHash -ne $fixedWebViewRuntimeSha256) { throw "Fixed WebView2 runtime checksum mismatch: expected $fixedWebViewRuntimeSha256, got $actualFixedRuntimeHash" }
& 'D:\DevTools\Scoop\shims\7z.exe' x $fixedWebViewRuntimePackage "-o$fixedWebViewRuntimeExtract" -y | Out-Null
Assert-ExternalSuccess 'Fixed WebView2 runtime extraction'

Write-Host "Downloading optional vision assistant $visionPluginVersion..."
& curl.exe --fail --location --silent --show-error --output $visionPluginArchive $visionPluginUrl
Assert-ExternalSuccess 'Vision assistant download'
$actualVisionHash = Get-Sha256 $visionPluginArchive
if ($actualVisionHash -ne $visionPluginSha256) { throw "Vision assistant checksum mismatch: expected $visionPluginSha256, got $actualVisionHash" }

Write-Host 'Downloading the pinned Inno Setup Simplified Chinese messages...'
& curl.exe --fail --location --silent --show-error --output $innoLanguageFile $innoLanguageUrl
Assert-ExternalSuccess 'Inno Setup Chinese messages download'
$actualLanguageHash = Get-Sha256 $innoLanguageFile
if ($actualLanguageHash -ne $innoLanguageSha256) { throw "Inno Setup Chinese messages checksum mismatch: expected $innoLanguageSha256, got $actualLanguageHash" }

Add-Type -AssemblyName System.Drawing
$sourceLogo = [Drawing.Image]::FromFile((Join-Path $distributionRoot 'templates\DeepSeek-Black-Logo.png'))
$wizardLogo = New-Object Drawing.Bitmap(64, 64)
$graphics = [Drawing.Graphics]::FromImage($wizardLogo)
$graphics.Clear([Drawing.Color]::White)
$graphics.DrawImage($sourceLogo, 6, 6, 52, 52)
$wizardLogo.Save((Join-Path $workRoot 'installer-logo.bmp'), [Drawing.Imaging.ImageFormat]::Bmp)
$graphics.Dispose()
$wizardLogo.Dispose()
$sourceLogo.Dispose()

New-Setup 'offline' $true
if ($BuildMirror) { New-Setup 'mirror' $false }
