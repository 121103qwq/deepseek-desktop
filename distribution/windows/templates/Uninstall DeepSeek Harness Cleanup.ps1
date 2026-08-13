param(
  [Parameter(Mandatory = $true)]
  [string]$InstallRoot
)

$ErrorActionPreference = 'Stop'
Start-Sleep -Seconds 1
$normalizedRoot = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\\') + '\\'
Get-CimInstance Win32_Process | ForEach-Object {
  if ($_.ExecutablePath -and $_.ExecutablePath.StartsWith($normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
}
for ($attempt = 0; $attempt -lt 10; $attempt++) {
  try {
    Remove-Item -LiteralPath $InstallRoot -Recurse -Force -ErrorAction Stop
    Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
    exit 0
  } catch {
    Start-Sleep -Seconds 1
  }
}
