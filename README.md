# DeepSeek Desktop

DeepSeek Harness 的 Windows x64 桌面安装包社区发行项目。

![DeepSeek Desktop 中文界面](docs/images/deepseek-desktop-main.png)

安装后会在名为 `DeepSeek Desktop` 的内置 WebView 窗口中运行，不会打开外部浏览器。安装向导只在安装时选择一次 Kilo 匿名免费模型或 DeepSeek API，后续启动不会重复询问；默认的 Kilo Auto Free 不需要登录或 API Key，也不是本地模型。

## 下载

[GitHub Release](https://github.com/121103qwq/deepseek-desktop/releases/tag/deepseek-desktop-v0.1.0) 提供两个 Windows x64 安装包：

| 安装包 | 说明 |
| --- | --- |
| `Windows-x64-Setup-默认.exe` | 体积较小；首次启动时通过国内高速镜像下载固定的 Harness 依赖，并显示下载进度。 |
| `Windows-x64-Offline-Setup.exe` | 内置 Harness 完整依赖和固定版 WebView2 runtime，安装组件无需另行下载。 |

两个版本都支持自定义安装位置、可选桌面快捷方式、开始菜单入口和 Windows“已安装的应用”卸载入口。离线版只表示安装组件已内置，模型请求仍需联网。

查看[中文图文介绍](distribution/windows/INTRODUCTION.zh.md)和[Windows 安装包构建说明](distribution/windows/README.zh.md)。

[观看 62 秒中文演讲视频](presentation/video/out/deepseek-desktop-v0.1.0-zh.mp4)，或查看[可编辑的 Remotion 视频源文件](presentation/video/README.md)。

这是社区发行，不包含任何 API Key，也不是 DeepSeek 官方发布。
