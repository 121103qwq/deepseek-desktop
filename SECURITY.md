# Security Policy

## Supported versions

| Version | Security support |
| --- | --- |
| 0.2.x | Supported |
| 0.1.x and earlier | Not supported; please reproduce on the latest release before reporting |

## Scope

Reports are welcome for security issues caused by this repository's:

- Windows installer, updater, uninstaller, and embedded WebView2 wrapper;
- build and packaging scripts;
- local configuration defaults and provider-selection flow;
- handling of user-supplied API keys or local application data; and
- integration of bundled dependencies when the vulnerability is introduced by this project's packaging or configuration.

DeepSeek Harness, Node.js, WebView2, Kilo, LLM7.io, and other third-party components or services have their own maintainers. Report vulnerabilities that exist independently of this packaging project to the relevant upstream project. If the issue is caused or worsened by the way DeepSeek Desktop integrates a dependency, report it here as well.

## Reporting a vulnerability

Do **not** disclose vulnerability details in a public issue, discussion, pull request, or social post.

Use the repository's **Security** tab and select **Report a vulnerability** to submit a private report:

https://github.com/121103qwq/deepseek-desktop/security/advisories/new

If private vulnerability reporting is unavailable, open a public issue titled `Request a private security contact` without technical details. The maintainer will arrange a private channel before you share the report.

Include, when possible:

- affected DeepSeek Desktop version and installer asset name;
- Windows version and relevant configuration;
- affected component and expected security boundary;
- reproduction steps and a minimal proof of concept;
- realistic impact and any known mitigation; and
- whether the issue has already been disclosed elsewhere.

Remove API keys, access tokens, private prompts, personal data, and unrelated logs before submitting. Use placeholders or revoked test credentials in proofs of concept.

## Response and disclosure

This is a solo-maintained community project. The maintainer aims to acknowledge a complete report within 7 days and provide an initial status update within 14 days. Complex or upstream-dependent issues may take longer.

Please allow time for validation, patch development, installer testing, and coordinated disclosure. A fixed release and advisory will credit reporters who want attribution, unless disclosure would create additional risk.

## Current hardening priorities

The public [Roadmap](README.md#roadmap) tracks planned work on update verification, code signing, upstream compatibility testing, and software supply-chain checks.

