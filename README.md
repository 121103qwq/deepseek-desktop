# DeepSeek Desktop

DeepSeek Harness 的 Windows x64 桌面安装包社区发行项目。

> **非官方社区版：** 本项目不是 DeepSeek 官方产品，不代表、不隶属于 DeepSeek，也未获得官方背书。安装器会在开始安装前再次明确提示。

![DeepSeek Desktop 中文界面](docs/images/deepseek-desktop-main.png)

安装后会在名为 `DeepSeek Desktop` 的内置 WebView 窗口中运行，不会打开外部浏览器。安装向导只在安装时选择一次 Kilo 匿名免费模型或 DeepSeek API，后续启动不会重复询问；默认的 Kilo Auto Free 不需要登录或 API Key，也不是本地模型。

## 下载

[GitHub Release](https://github.com/121103qwq/deepseek-desktop/releases/tag/deepseek-desktop-v0.2.0) 提供一个 Windows x64 离线安装包：

| 安装包 | 说明 |
| --- | --- |
| `DeepSeek-Desktop-0.2.0-Windows-x64-Offline.exe`（Release 标签：`离线版`） | 内置 Harness、Node.js、固定版 WebView2 runtime 和辅助识图插件；安装组件无需另行下载。GitHub 会自动移除资产文件名中的中文字符，因此下载名使用 `Offline`。 |

安装器支持自定义安装位置、可选桌面快捷方式、Kilo/DeepSeek API 路线、上游/社区更新通道和实验性辅助识图，并在 Windows“已安装的应用”中注册正常卸载入口。离线版只表示安装组件已内置，模型请求仍需联网。首次点击关闭窗口时，可选择以后最小化到任务栏或直接退出。

查看[中文图文介绍](distribution/windows/INTRODUCTION.zh.md)和[Windows 安装包构建说明](distribution/windows/README.zh.md)。

这是社区发行，不包含任何 API Key。安装开始前会再次显示非官方声明并要求确认。
