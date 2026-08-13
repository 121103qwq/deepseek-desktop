<##
.SYNOPSIS
Build DeepSeek Desktop setup executables for Windows x64.

.DESCRIPTION
Creates an offline setup with the complete published Harness dependency closure
and a mirror setup that downloads that closure from the China npm mirror during
installation. Both use a bundled Node runtime and an embedded WebView window.
##>
[CmdletBinding()]
param(
  [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$dshVersion = '0.1.0-rc.6'
$nodeVersion = '22.19.0'
$nodeArchiveName = "node-v$nodeVersion-win-x64.zip"
$nodeUrl = "https://npmmirror.com/mirrors/node/v$nodeVersion/$nodeArchiveName"
$nodeSha256 = 'ea3fad0e67a991d8477d8c01344b56e69c676ccb733f065b22436994b1253f86'
$mirrorRegistry = 'https://registry.npmmirror.com'
$webViewPackageVersion = '1.0.3856.49'
$webViewPackageUrl = "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/$webViewPackageVersion"
$fixedWebViewRuntimeVersion = '150.0.4078.99'
$fixedWebViewRuntimeUrl = "https://api.nuget.org/v3-flatcontainer/webview2.runtime.x64/$fixedWebViewRuntimeVersion/webview2.runtime.x64.$fixedWebViewRuntimeVersion.nupkg"
$fixedWebViewRuntimeSha256 = 'c0907ddb8f2fff6f91ccb7fe972284dc47f07e34684d0aedefda3d0f6edf75d8'
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
  @{ name = 'deepseek-desktop-runtime'; version = $dshVersion; private = $true; dependencies = @{ '@deepseek-ai/dsh' = $dshVersion } } |
    ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $AppRoot 'package.json') -Encoding utf8
}

function Copy-CommonPayload([string]$PayloadRoot, [bool]$IncludeFixedWebViewRuntime) {
  $runtimeRoot = Join-Path $PayloadRoot 'runtime'
  $appRoot = Join-Path $PayloadRoot 'app'
  $desktopRoot = $PayloadRoot
  New-Item -ItemType Directory -Force -Path $runtimeRoot, $appRoot, (Join-Path $PayloadRoot 'defaults') | Out-Null
  Copy-Item -Path (Join-Path $expandedNode '*') -Destination $runtimeRoot -Recurse
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\Launch DeepSeek Desktop.cmd') -Destination $PayloadRoot
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\Uninstall DeepSeek Harness.cmd') -Destination $PayloadRoot
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\default-web.patch.yml') -Destination (Join-Path $PayloadRoot 'defaults\cordis.patch.yml')
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\DeepSeek-Black-Logo.svg') -Destination (Join-Path $PayloadRoot 'DeepSeek-Black-Logo.svg')
  Copy-Item -LiteralPath (Join-Path $distributionRoot 'templates\DeepSeek-Black-Logo.png') -Destination $PayloadRoot
  Copy-Item -LiteralPath (Join-Path $webViewExtract 'lib\net462\Microsoft.Web.WebView2.Core.dll') -Destination $desktopRoot
  Copy-Item -LiteralPath (Join-Path $webViewExtract 'lib\net462\Microsoft.Web.WebView2.WinForms.dll') -Destination $desktopRoot
  Copy-Item -LiteralPath (Join-Path $webViewExtract 'build\native\x64\WebView2Loader.dll') -Destination $desktopRoot
  if ($IncludeFixedWebViewRuntime) {
    $fixedRuntimeSource = Join-Path $fixedWebViewRuntimeExtract 'contentFiles\any\any\WebView2'
    if (!(Test-Path -LiteralPath (Join-Path $fixedRuntimeSource 'msedgewebview2.exe') -PathType Leaf)) { throw 'The fixed WebView2 runtime is incomplete.' }
    Copy-Item -LiteralPath $fixedRuntimeSource -Destination (Join-Path $PayloadRoot 'WebView2') -Recurse
  }
  $compiler = 'D:\Program Files (x86)\visualstudio\MSBuild\Current\Bin\Roslyn\csc.exe'
  if (!(Test-Path -LiteralPath $compiler -PathType Leaf)) { throw "C# compiler is missing: $compiler" }
  $source = Join-Path $distributionRoot 'templates\DeepSeekDesktop.cs'
  $responseFile = Join-Path $workRoot "desktop-$([IO.Path]::GetFileName($PayloadRoot)).rsp"
  @"
/nologo
/target:winexe
/out:"$(Join-Path $PayloadRoot 'DeepSeek Desktop.exe')"
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
  Write-AppManifest $appRoot
}

function New-Setup([string]$Kind, [bool]$IncludeDependencies) {
  $payloadRoot = Join-Path $workRoot "payload-$Kind"
  $appRoot = Join-Path $payloadRoot 'app'
  $runtimeRoot = Join-Path $payloadRoot 'runtime'
  $payloadArchive = Join-Path $workRoot "payload-$Kind.zip"
  $installerName = if ($Kind -eq 'offline') { "DeepSeek-Desktop-$dshVersion-Windows-x64-Offline-Setup.exe" } else { "DeepSeek-Desktop-$dshVersion-Windows-x64-Setup-默认.exe" }
  $installerPath = Join-Path $outputPath $installerName
  if (Test-Path -LiteralPath $installerPath) { throw "Refusing to overwrite an existing installer: $installerPath" }
  Copy-CommonPayload $payloadRoot $IncludeDependencies
  if ($IncludeDependencies) {
    Write-Host "Installing complete @deepseek-ai/dsh@$dshVersion dependency closure..."
    $originalPath = $env:PATH
    try {
      $env:PATH = "$runtimeRoot;$originalPath"
      Push-Location $appRoot
      & (Join-Path $runtimeRoot 'npm.cmd') install '--omit=dev' '--no-audit' '--no-fund' '--package-lock=false' '--fetch-retries=2' '--fetch-timeout=120000'
      Assert-ExternalSuccess 'npm install'
    } finally {
      Pop-Location
      $env:PATH = $originalPath
    }
    $dshBin = Join-Path $appRoot 'node_modules\@deepseek-ai\dsh\lib\bin.js'
    if (!(Test-Path -LiteralPath $dshBin -PathType Leaf)) { throw "Published DeepSeek Harness binary is missing: $dshBin" }
    & (Join-Path $runtimeRoot 'node.exe') $dshBin --help
    Assert-ExternalSuccess 'DeepSeek Harness smoke test'
  }
  Set-Content -LiteralPath (Join-Path $payloadRoot 'VERSION.txt') -Value "DeepSeek Desktop $dshVersion`r`nBundled Node.js $nodeVersion" -Encoding ascii
  Compress-Archive -Path (Join-Path $payloadRoot '*') -DestinationPath $payloadArchive -CompressionLevel Optimal
  $installScript = Join-Path $workRoot "install-$Kind.ps1"
  $mode = if ($IncludeDependencies) { 'offline' } else { 'mirror' }
  (Get-Content -Raw (Join-Path $distributionRoot 'templates\install.ps1')).Replace("'__INSTALL_MODE__'", "'$mode'") | Set-Content -LiteralPath $installScript -Encoding utf8
  $sedPath = Join-Path $workRoot "installer-$Kind.sed"
  @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=DeepSeek Desktop was installed for this Windows user.
TargetName=$installerPath
FriendlyName=DeepSeek Desktop $dshVersion
AppLaunched=cmd.exe /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File install-$Kind.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[Strings]
FILE0="payload-$Kind.zip"
FILE1="install-$Kind.ps1"
[SourceFiles]
SourceFiles0=$workRoot\
[SourceFiles0]
%FILE0%=
%FILE1%=
"@ | Set-Content -LiteralPath $sedPath -Encoding ascii
  Write-Host "Creating $Kind setup executable..."
  $iexpress = Start-Process -FilePath (Join-Path $env:WINDIR 'System32\iexpress.exe') -ArgumentList @('/N', '/Q', $sedPath) -PassThru -Wait -WindowStyle Hidden
  if ($iexpress.ExitCode -ne 0) { throw "IExpress failed with exit code $($iexpress.ExitCode)" }
  if (!(Test-Path -LiteralPath $installerPath -PathType Leaf)) { throw 'IExpress did not create the setup executable.' }
  $hashPath = "$installerPath.sha256"
  $installerHash = Get-Sha256 $installerPath
  Set-Content -LiteralPath $hashPath -Value "$installerHash  $installerName" -Encoding ascii
  Get-Item -LiteralPath $installerPath, $hashPath | Select-Object FullName, Length
}

if ([Environment]::Is64BitOperatingSystem -eq $false) { throw 'This installer build targets Windows x64 only.' }
if (!(Test-Path -LiteralPath (Join-Path $env:WINDIR 'System32\iexpress.exe') -PathType Leaf)) { throw 'IExpress is not available on this Windows installation.' }
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

New-Setup 'offline' $true
New-Setup 'mirror' $false
