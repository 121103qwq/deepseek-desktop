# Windows installer

English | [中文](README.zh.md)

`scripts/build-windows-installer.ps1` produces two user-scope Windows x64 setup executables for DeepSeek Desktop, a community package built from the published `@deepseek-ai/dsh` package.

Both setups bundle Node.js 22.19.0 after checking its SHA-256, open the local Harness UI inside a `DeepSeek Desktop` WebView window, and add one Start menu shortcut. They do not request administrator permissions or change the system `PATH`.

The offline setup includes the complete published Harness dependency closure and a fixed WebView2 runtime. The standard setup downloads the same fixed Harness closure through `registry.npmmirror.com` while installing and uses the Windows WebView2 runtime when it is already installed. Application data stays in `%LOCALAPPDATA%\DeepSeek Harness Data`; the included uninstaller removes the program files and shortcut while preserving that data directory.

Each opening begins with a clear choice: **Free model (Groq Free Plan)** or **DeepSeek API**. The default Groq route preconfigures GPT-OSS 20B, GPT-OSS 120B, and Qwen3.6 27B in the embedded Harness model picker; it does not use a local model. The app opens directly to the selected route rather than an API-key screen. A Groq key is required only when the user configures that provider in the embedded Models settings; choosing DeepSeek API uses the existing embedded DeepSeek-key setup.

## Build

Run this from a PowerShell session in the repository root:

```powershell
.\scripts\build-windows-installer.ps1
```

The standard setup, `Offline` setup, and their `.sha256` files are written to `distribution/windows/dist/`. The builder creates a fresh directory under `distribution/windows/build/` and refuses to overwrite an existing release asset.

## Verification

Before publishing, verify every generated checksum and run both setup executables in a Windows user session. After installation, start **DeepSeek Desktop** from the Start menu and confirm that its embedded window loads the local UI.

The installer is an independent community distribution. It includes no API key and does not claim to be an official DeepSeek release.
