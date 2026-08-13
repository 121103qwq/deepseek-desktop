# Windows 安装包

[English](README.md) | 中文

`scripts/build-windows-installer.ps1` 为 DeepSeek Desktop 生成两个仅限当前用户的 Windows x64 安装程序；它是基于已发布 `@deepseek-ai/dsh` 包的社区打包版。

两个安装程序都会在校验 SHA-256 后内置 Node.js 22.19.0，在名为 `DeepSeek Desktop` 的 WebView 窗口中打开本地 Harness UI，并添加一个开始菜单快捷方式。它们不请求管理员权限，也不修改系统 `PATH`。

完整离线版内置已发布 Harness 的完整依赖闭包和固定版 WebView2 runtime。标准版会在安装时通过 `registry.npmmirror.com` 下载相同的固定 Harness 依赖闭包，并使用 Windows 已安装的 WebView2 runtime。应用数据保存在 `%LOCALAPPDATA%\DeepSeek Harness Data`；附带的卸载程序会移除程序文件和快捷方式，同时保留该数据目录。

每次打开都会明确提供两种选择：**免费模型（Groq Free Plan）** 或 **DeepSeek API**。默认 Groq 路由会在内置 Harness 模型选择器中预先配置 GPT-OSS 20B、GPT-OSS 120B 和 Qwen3.6 27B，不使用本地模型。应用会直接打开所选路由，而不是先显示 API key 页面；只有在内置“模型”设置中配置 Groq 时才需要其 key，选择 DeepSeek API 则使用原有的内置 DeepSeek key 配置流程。

## 构建

在仓库根目录的 PowerShell 会话中运行：

```powershell
.\scripts\build-windows-installer.ps1
```

标准安装程序、`Offline` 安装程序及对应的 `.sha256` 文件会写入 `distribution/windows/dist/`。构建器会在 `distribution/windows/build/` 下新建目录，并拒绝覆盖已有的发布产物。

## 验证

发布前，校验所有生成的 SHA-256，并在 Windows 用户会话中运行两个安装程序。安装完成后，从开始菜单启动 **DeepSeek Desktop**，确认其内置窗口加载本地 UI。

该安装程序是独立的社区分发物，不含 API key，也不声称是 DeepSeek 官方发布。
