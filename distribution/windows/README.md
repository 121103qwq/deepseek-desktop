# Windows installer

English | [中文](README.zh.md)

`scripts/build-windows-installer.ps1` produces one user-scope Windows x64 offline setup executable for DeepSeek Desktop, an unofficial community package built from the published `@deepseek-ai/dsh` package.

The setup bundles Node.js 22.19.0, opens the local Harness UI inside a `DeepSeek Desktop` WebView window, and adds one Start menu shortcut. It does not request administrator permissions or change the system `PATH`. The installer lets the user choose the destination folder and registers an uninstall entry in Windows Installed apps.

The offline setup includes the complete published Harness dependency closure, a fixed WebView2 runtime, and the optional vision sidecar. Application data stays in `%LOCALAPPDATA%\DeepSeek Harness Data`; the included uninstaller removes the program files and shortcut while preserving that data directory.

The installer offers one initial choice: **Free model (Kilo, no sign-in)** or **DeepSeek API**. The default route is Kilo Auto Free, which uses Kilo's anonymous free allocation and does not use a local model. It also offers upstream/community update channels and an optional anonymous OVHcloud vision sidecar. Before file extraction, a mandatory dialog states that this is not an official DeepSeek product.

## Build

Run this from a PowerShell session in the repository root:

```powershell
.\scripts\build-windows-installer.ps1
```

The offline setup is written to `distribution/windows/dist/`. The builder creates a fresh directory under `distribution/windows/build/` and refuses to overwrite an existing release asset.

## Verification

Before publishing, run the setup executable in a Windows user session. After installation, start **DeepSeek Desktop** from the Start menu and confirm that its embedded window loads the local UI.

The installer is an independent community distribution. It includes no API key and does not claim to be an official DeepSeek release.
