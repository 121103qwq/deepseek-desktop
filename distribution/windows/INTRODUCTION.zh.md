# DeepSeek Desktop：Windows 版 DeepSeek Harness

![黑色 DeepSeek 图案](templates/DeepSeek-Black-Logo.png)

DeepSeek Desktop 把已发布的 DeepSeek Harness 封装成 Windows x64 安装程序。安装后从开始菜单打开 `DeepSeek Desktop`，Harness 会在内置 WebView 窗口中运行，不会额外打开浏览器，也不修改系统 `PATH`。

首次打开明确选择两条路线：

- **免费模型（Groq Free Plan）**：默认提供 GPT-OSS 20B、GPT-OSS 120B 和 Qwen3.6 27B，不使用本地模型。Groq 免费计划的 key 只在内置“模型”设置中配置，不会在开屏时强制填写。
- **DeepSeek API**：使用 DeepSeek Harness 的原有模型路由与内置 key 配置流程。

Release 提供一个标准 `Setup.exe` 和一个带 `Offline` 名称的完整离线 `Setup.exe`，并为每个文件附上 SHA-256 校验文件。离线版同时内置固定版 WebView2 runtime。两者均为当前用户安装：程序文件位于 `%LOCALAPPDATA%\Programs\DeepSeek Desktop`，会话和设置位于 `%LOCALAPPDATA%\DeepSeek Harness Data`，卸载程序保留会话和设置。

这是社区分发，不包含任何 API key，也不代表 DeepSeek 官方发布。
