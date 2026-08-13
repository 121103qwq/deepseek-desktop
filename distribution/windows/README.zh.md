# Windows 安装包

[English](README.md) | 中文

`scripts/build-windows-installer.ps1` 为 DeepSeek Desktop 生成两个仅限当前用户的 Windows x64 安装程序；它是基于已发布 `@deepseek-ai/dsh` 包的社区打包版。

两个安装程序都会内置 Node.js 22.19.0，在名为 `DeepSeek Desktop` 的 WebView 窗口中打开本地 Harness UI，并添加一个开始菜单快捷方式。它们不请求管理员权限，也不修改系统 `PATH`。安装向导可选择安装位置和是否创建桌面快捷方式，并会在 Windows“已安装的应用”中注册卸载入口。

完整离线版内置已发布 Harness 的完整依赖闭包和固定版 WebView2 runtime。标准版会在安装时通过 `registry.npmmirror.com` 下载相同的固定 Harness 依赖闭包，并使用 Windows 已安装的 WebView2 runtime。应用数据保存在 `%LOCALAPPDATA%\DeepSeek Harness Data`；附带的卸载程序会移除程序文件和快捷方式，同时保留该数据目录。

每次打开都会明确提供两种选择：**免费模型（Kilo，免登录）** 或 **DeepSeek API**。默认路由是 Kilo Auto Free，使用 Kilo 的匿名免费额度，不使用本地模型；内置 Harness 的模型选择器还提供另一个 Kilo 免费模型。选择 DeepSeek API 则使用原有的内置 DeepSeek key 配置流程。

## 构建

在仓库根目录的 PowerShell 会话中运行：

```powershell
.\scripts\build-windows-installer.ps1
```

标准安装程序和 `Offline` 安装程序会写入 `distribution/windows/dist/`。构建器会在 `distribution/windows/build/` 下新建目录，并拒绝覆盖已有的发布产物。

## 验证

发布前，在 Windows 用户会话中运行两个安装程序。安装完成后，从开始菜单启动 **DeepSeek Desktop**，确认其内置窗口加载本地 UI。

该安装程序是独立的社区分发物，不含 API key，也不声称是 DeepSeek 官方发布。
