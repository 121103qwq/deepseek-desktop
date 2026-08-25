# DeepSeek Desktop

[简体中文](README.md)

A community-maintained Windows x64 desktop distribution of [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).

> **Unofficial community build:** DeepSeek Desktop is not an official DeepSeek product, is not affiliated with DeepSeek, and is not endorsed by DeepSeek. The installer repeats this notice before installation begins.

![DeepSeek Desktop Chinese interface](docs/images/deepseek-desktop-main.png)

DeepSeek Desktop starts DeepSeek Harness locally and opens its interface in an embedded WebView2 window named `DeepSeek Desktop`, instead of launching an external browser. The installer asks once whether to start with anonymous Kilo models or the DeepSeek API; the choice can be changed later inside Harness.

## Highlights

- Native per-user Windows installer with a normal uninstall entry and no administrator requirement.
- Embedded WebView2 desktop window, tray behavior, Start menu entry, and optional desktop shortcut.
- Offline installation payload containing the published Harness dependency closure, Node.js, a pinned WebView2 runtime, and the optional vision sidecar. Model requests still require an internet connection.
- Kilo anonymous free routing or a user-supplied DeepSeek API key. No API key is bundled with the installer.
- Chinese defaults, explicit third-party data notices, and an update flow that asks before installing a new version.
- User sessions and settings are preserved under `%LOCALAPPDATA%\DeepSeek Harness Data` when the application is uninstalled.

## Download

The current [GitHub Release](https://github.com/121103qwq/deepseek-desktop/releases/tag/deepseek-desktop-v0.2.2) provides one Windows x64 installer:

| Installer | Description |
| --- | --- |
| `Deepseek-desktop-offline.exe` | Includes Harness, Node.js, a pinned WebView2 runtime, and the optional vision sidecar, so installation components do not need to be downloaded during setup. |

Only download installers from this repository's Releases page. The current community build is not code-signed, so Windows may show an unknown-publisher or reputation warning. Do not disable Microsoft Defender.

## Early usage snapshot

Public GitHub data as of **2026-08-25**:

| Stars | Public releases | Cumulative installer downloads |
| ---: | ---: | ---: |
| 15 | 4 | 399 |

The download figure is the sum of GitHub Release asset download counters across the four published versions; it is not a unique-user count. See the [release history](https://github.com/121103qwq/deepseek-desktop/releases).

## Security and privacy

The project does not ship shared API keys. Kilo, DeepSeek API, LLM7.io, and other configured model providers are network services with their own availability and data-handling policies. Do not submit personal, confidential, or sensitive information to a provider unless you understand and accept its terms.

Please report vulnerabilities privately according to [SECURITY.md](SECURITY.md). Do not include credentials, private prompts, or personal data in public issues.

## Roadmap

- Harden the update path by verifying release metadata and downloaded installer digests before handoff.
- Code-sign the installer and desktop executables when a suitable signing certificate and release process are available.
- Add automated compatibility checks against supported upstream DeepSeek Harness releases.
- Expand supply-chain checks with dependency review, retained license notices, and a generated software bill of materials.

These are planned improvements, not claims about the current release. Work will be delivered through reviewable commits and releases.

## Build and documentation

- [Windows installer build guide](distribution/windows/README.md)
- [Chinese illustrated introduction](distribution/windows/INTRODUCTION.zh.md)
- [Chinese Windows build guide](distribution/windows/README.zh.md)

The primary build entry point is:

```powershell
.\scripts\build-windows-installer.ps1
```

## License and attribution

The original DeepSeek Desktop wrapper and packaging code in this repository are available under the [MIT License](LICENSE).

DeepSeek Harness is developed by DeepSeek and distributed under its own [MIT License](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE). Bundled third-party runtimes, libraries, services, names, and logos remain governed by their respective licenses and terms. The DeepSeek name and logo are used only to describe compatibility and are not evidence of affiliation or endorsement.

