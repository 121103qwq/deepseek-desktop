# DeepSeek Desktop：Windows 版 DeepSeek Harness

> DeepSeek Desktop 是由社区维护的 Windows x64 发行项目，基于已发布的 `@deepseek-ai/dsh` 构建。它不是 DeepSeek 官方桌面客户端，也不包含任何 API Key。

## 在桌面窗口中运行

DeepSeek Desktop 会在本机启动 Harness 服务，并在名为 `DeepSeek Desktop` 的内置 WebView2 窗口中加载界面，不会另行打开默认浏览器。界面默认使用中文，之后仍可在应用内切换语言。

![DeepSeek Desktop 中文界面](../../docs/images/deepseek-desktop-main.png)

## 安装时选择模型路线

安装向导只在安装时询问一次初始模型路线；安装完成后仍可在应用内修改，后续启动不会重复询问。

- **免费模型（Kilo，免登录）**：默认选中 Kilo Auto Free，不要求登录或 API Key，也不是本地模型。Kilo 官方说明免费模型支持匿名访问并按 IP 限速；免费额度、具体路由和可用性由 Kilo 决定。Auto Free 可能把请求转发给会记录输入和输出的第三方服务，不要提交个人、机密或敏感内容。
- **DeepSeek API**：启用 Harness 内置的 DeepSeek 路由，用户稍后在应用内填写自己的 API Key；安装包不会附带密钥。

## 选择安装包

| 安装包 | 适用情况 |
| --- | --- |
| `Deepseek-desktop-offline.exe` | 内置 Harness 完整依赖、Node.js、固定版 WebView2 runtime 和辅助识图插件，安装组件无需另行下载。安装会一次性写入全部运行文件；Kilo、DeepSeek API 和视觉模型请求仍需联网。 |

## 安装与首次启动

1. 从项目 [Release](https://github.com/121103qwq/deepseek-desktop/releases/tag/deepseek-desktop-v0.2.2) 下载离线版安装包。
2. 运行安装程序，选择安装位置、初始模型路线、更新通道、辅助识图及是否创建桌面快捷方式；辅助识图使用 dsh-vision-sidecar 0.1.3，默认调用 LLM7.io 匿名 `default` 视觉路由，不使用本地模型或共享 Key。
3. 点击“立即安装”，阅读非官方社区版说明；只有确认继续后才开始安装。
4. 原生安装进度条完成后启动 DeepSeek Desktop。第一次关闭窗口时，选择以后最小化到右下角通知区域或直接退出；通知区域图标可双击恢复窗口，并提供“退出”菜单。

安装器会创建开始菜单入口和 Windows“已安装的应用”记录，桌面快捷方式由用户在安装向导中决定。自动更新发现新版本后先询问，不会静默安装。

## 卸载与数据保留

在 Windows“设置 → 应用 → 已安装的应用”中找到 `DeepSeek Desktop` 并选择“卸载”。卸载程序会停止桌面窗口和随附的 Node 服务，并删除程序文件、注册项、开始菜单入口和桌面快捷方式。

会话与设置保存在 `%LOCALAPPDATA%\DeepSeek Harness Data`，卸载时会保留，方便以后重装继续使用。需要完全清除时，可在退出应用后自行删除该目录。

## 使用前须知

当前发行仅支持 Windows x64。安装程序是未签名的非官方社区构建，Windows Defender 或 SmartScreen 可能显示“未知发布者”或信誉提示；请只从项目 Release 下载，不要关闭 Defender。

Kilo 匿名访问说明和 Auto Free 数据处理提示见 [Kilo 官方文档](https://kilo.ai/docs/gateway/authentication) 与 [Using Kilo for Free](https://kilo.ai/docs/getting-started/using-kilo-for-free)。
