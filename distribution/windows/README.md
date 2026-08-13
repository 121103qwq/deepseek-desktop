# Windows installer

English | [中文](README.zh.md)

`scripts/build-windows-installer.ps1` produces two user-scope Windows x64 setup executables for DeepSeek Desktop, a community package built from the published `@deepseek-ai/dsh` package.

Both setups bundle Node.js 22.19.0, open the local Harness UI inside a `DeepSeek Desktop` WebView window, and add one Start menu shortcut. They do not request administrator permissions or change the system `PATH`. The installer lets the user choose the destination folder and registers an uninstall entry in Windows Installed apps.

The offline setup includes the complete published Harness dependency closure and a fixed WebView2 runtime. The standard setup uses the Windows WebView2 runtime when it is already installed, then on its first start clearly asks to download the fixed Harness closure through `registry.npmmirror.com` and shows a download progress indicator; it skips that download when the dependency is already present. Application data stays in `%LOCALAPPDATA%\DeepSeek Harness Data`; the included uninstaller removes the program files and shortcut while preserving that data directory.

Each opening begins with a clear choice: **Free model (Kilo, no sign-in)** or **DeepSeek API**. The default route is Kilo Auto Free, which uses Kilo's anonymous free allocation and does not use a local model. The embedded model picker also includes another Kilo free model. Choosing DeepSeek API uses the existing embedded DeepSeek-key setup.

## Build

Run this from a PowerShell session in the repository root:

```powershell
.\scripts\build-windows-installer.ps1
```

The standard setup and `Offline` setup are written to `distribution/windows/dist/`. The builder creates a fresh directory under `distribution/windows/build/` and refuses to overwrite an existing release asset.

## Verification

Before publishing, verify every generated checksum and run both setup executables in a Windows user session. After installation, start **DeepSeek Desktop** from the Start menu and confirm that its embedded window loads the local UI.

The installer is an independent community distribution. It includes no API key and does not claim to be an official DeepSeek release.
