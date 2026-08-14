# Windows 安装包

[English](README.md) | 中文

`scripts/build-windows-installer.ps1` 为 DeepSeek Desktop 生成一个仅限当前用户的 Windows x64 离线安装程序；它是基于已发布 `@deepseek-ai/dsh` 包的非官方社区打包版。

安装程序内置 Node.js 22.19.0，在名为 `DeepSeek Desktop` 的 WebView 窗口中打开本地 Harness UI，并添加一个开始菜单快捷方式。它不请求管理员权限，也不修改系统 `PATH`。安装向导可选择安装位置和是否创建桌面快捷方式，并会在 Windows“已安装的应用”中注册卸载入口。

离线版内置已发布 Harness 的完整依赖闭包、固定版 WebView2 runtime 和辅助识图插件。安装器会一次性展开运行文件，首次启动不做安装工作。应用数据保存在 `%LOCALAPPDATA%\DeepSeek Harness Data`；附带的卸载程序会移除程序文件和快捷方式，同时保留该数据目录。

安装向导会一次性提供两种选择：**免费模型（Kilo，免登录）** 或 **DeepSeek API**；以后可在应用内修改，后续启动不会重复询问。默认路由是 Kilo Auto Free，使用 Kilo 的匿名免费额度，不使用本地模型。界面默认中文。还可选择跟随上游 Harness 或社区桌面 Release 检查更新，并启用 LLM7.io 匿名 `default` 视觉路由辅助识图。点击安装时必须确认非官方社区版声明。

## 国内网络测试版（不随默认构建发布）

需要验证国内网络下载时，显式传入 `-BuildMirror`：

```powershell
.\scripts\build-windows-installer.ps1 -BuildMirror -OutputDirectory .\distribution\windows\dist-mirror-test
```

该命令额外生成 `Deepseek-desktop-online.exe` 测试安装包。它只把 Node.js、桌面运行文件和依赖清单放入安装包；点击安装后先启动独立的“DeepSeek Desktop 安装”窗口，在桌面窗口启动前完成依赖下载。窗口顶部显示文件写入进度，中部显示整体依赖进度，并实时显示下载速度。安装器先探测 `registry.npmmirror.com`，连接超时或 npm 失败时自动切换 `registry.npmjs.org`；两条源都失败时不会把下载工作推迟到首次打开桌面窗口。

`-BuildMirror` 仅用于本地测试，当前发布流程只上传离线版。

## 构建

在仓库根目录的 PowerShell 会话中运行：

```powershell
.\scripts\build-windows-installer.ps1
```

`离线版`安装程序会写入 `distribution/windows/dist/`。构建器会在 `distribution/windows/build/` 下新建目录，并拒绝覆盖已有的发布产物。

## 验证

发布前，在 Windows 用户会话中运行安装程序。安装完成后，从开始菜单启动 **DeepSeek Desktop**，确认其内置窗口加载本地 UI。

该安装程序是独立的社区分发物，不含 API key，也不声称是 DeepSeek 官方发布。
