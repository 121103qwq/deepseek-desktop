# DeepSeek Desktop

[English](README.md)

DeepSeek Harness 的 Windows x64 桌面安装包社区发行项目。

> **非官方社区版：** 本项目不是 DeepSeek 官方产品，不代表、不隶属于 DeepSeek，也未获得官方背书。安装器会在开始安装前再次明确提示。

![DeepSeek Desktop 中文界面](docs/images/deepseek-desktop-main.png)

DeepSeek Desktop 会在本机启动 DeepSeek Harness，并在名为 `DeepSeek Desktop` 的内置 WebView2 窗口中加载界面，不会打开外部浏览器。安装向导只在安装时询问一次使用 Kilo 匿名免费模型还是 DeepSeek API，之后仍可在 Harness 内修改。

## 主要功能

- 当前用户级 Windows 原生安装器，不要求管理员权限，并注册正常卸载入口。
- 内置 WebView2 桌面窗口、通知区域行为、开始菜单入口和可选桌面快捷方式。
- 离线安装包内置已发布的 Harness 完整依赖、Node.js、固定版 WebView2 runtime 和可选辅助识图插件；模型请求仍需联网。
- 可选 Kilo 匿名免费路由或用户自己的 DeepSeek API Key；安装包不包含任何共享 API Key。
- 默认中文界面、明确的第三方数据提示，以及安装新版本前先询问的更新流程。
- 卸载时保留 `%LOCALAPPDATA%\DeepSeek Harness Data` 中的会话和设置。

## 下载

当前 [GitHub Release](https://github.com/121103qwq/deepseek-desktop/releases/tag/deepseek-desktop-v0.2.2) 提供一个 Windows x64 安装包：

| 安装包 | 说明 |
| --- | --- |
| `Deepseek-desktop-offline.exe` | 内置 Harness、Node.js、固定版 WebView2 runtime 和可选辅助识图插件，安装时无需另行下载这些组件。 |

请只从本仓库的 Releases 页面下载安装包。当前社区构建尚未进行代码签名，Windows 可能显示“未知发布者”或信誉提示；请不要关闭 Microsoft Defender。

## 早期使用数据

截至 **2026-08-25** 的 GitHub 公开数据：

| Stars | 公开 Release | 安装包累计下载 |
| ---: | ---: | ---: |
| 15 | 4 | 399 |

下载量是四个已发布版本的 GitHub Release 资产下载计数之和，不代表独立用户数。可查看[完整发布记录](https://github.com/121103qwq/deepseek-desktop/releases)。

## 安全与隐私

本项目不附带共享 API Key。Kilo、DeepSeek API、LLM7.io 以及其他配置的模型提供商都是联网服务，具有各自的可用性和数据处理政策。除非已经理解并接受相应条款，否则不要向模型提供商提交个人、机密或敏感内容。

发现漏洞时，请按照 [SECURITY.md](SECURITY.md) 私下报告。不要在公开 Issue 中提交凭据、私人提示词或个人数据。

## Roadmap

- 在交给更新程序前验证 Release 元数据和安装包摘要，加强自动更新链路。
- 在具备合适证书和发布流程后，为安装器和桌面程序添加代码签名。
- 添加针对受支持 DeepSeek Harness 上游版本的自动兼容性检查。
- 通过依赖审查、保留许可证声明和生成软件物料清单，加强供应链检查。

以上是计划中的改进，不代表当前版本已经实现。相关工作会通过可审查的提交和 Release 逐步交付。

## 构建与文档

- [Windows 安装包构建说明（English）](distribution/windows/README.md)
- [中文图文介绍](distribution/windows/INTRODUCTION.zh.md)
- [Windows 安装包构建说明（中文）](distribution/windows/README.zh.md)

主要构建入口：

```powershell
.\scripts\build-windows-installer.ps1
```

## 许可证与署名

本仓库原创的 DeepSeek Desktop 桌面封装和打包代码采用 [MIT License](LICENSE)。

DeepSeek Harness 由 DeepSeek 开发，并按照其自身的 [MIT License](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE) 发布。安装包中的第三方 runtime、依赖、服务、名称和标志继续受各自许可证与条款约束。DeepSeek 名称和标志仅用于说明兼容关系，不代表官方隶属或背书。

