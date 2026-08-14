using System;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

internal static class DeepSeekDesktop
{
    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new DesktopForm());
    }
}

internal sealed class DesktopForm : Form
{
    private readonly WebView2 view = new WebView2 { Dock = DockStyle.Fill };
    private Process server;
    private readonly StringBuilder serverOutput = new StringBuilder();
    private System.Drawing.Icon applicationIcon;
    private NotifyIcon notificationIcon;
    private int port;
    private string closeBehavior;
    private bool exiting;

    internal DesktopForm()
    {
        Text = "DeepSeek Desktop";
        Width = 1440;
        Height = 920;
        MinimumSize = new System.Drawing.Size(960, 640);
        WindowState = FormWindowState.Maximized;
        LoadApplicationIcon();
        InitializeNotificationIcon();
        closeBehavior = ReadStringSetting(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "desktop-settings.json"), "closeBehavior", "ask");
        Controls.Add(view);
        Shown += async (_, __) =>
        {
            try
            {
                CheckForUpdates();
                EnsureHarnessDependencies();
                StartServer();
                WaitForServer(port);
                CoreWebView2Environment webViewEnvironment = null;
                string fixedRuntime = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "WebView2");
                if (File.Exists(Path.Combine(fixedRuntime, "msedgewebview2.exe")))
                {
                    string home = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DeepSeek Harness Data");
                    webViewEnvironment = await CoreWebView2Environment.CreateAsync(fixedRuntime, Path.Combine(home, "webview2"));
                }
                await view.EnsureCoreWebView2Async(webViewEnvironment);
                view.CoreWebView2.Settings.AreDevToolsEnabled = false;
                view.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
                view.CoreWebView2.Navigate("http://127.0.0.1:" + port);
            }
            catch (Exception error)
            {
                MessageBox.Show(error.Message, "DeepSeek Desktop", MessageBoxButtons.OK, MessageBoxIcon.Error);
                Close();
            }
        };
        FormClosing += HandleFormClosing;
        FormClosed += (_, __) =>
        {
            if (server != null && !server.HasExited) server.Kill();
            if (notificationIcon != null) notificationIcon.Dispose();
        };
    }

    private void HandleFormClosing(object sender, FormClosingEventArgs eventArgs)
    {
        if (exiting) return;
        if (eventArgs.CloseReason != CloseReason.UserClosing) return;
        if (string.Equals(closeBehavior, "ask", StringComparison.OrdinalIgnoreCase))
        {
            DialogResult choice = MessageBox.Show(
                "这是第一次关闭 DeepSeek Desktop。\r\n\r\n选择“是”：以后点关闭时最小化到右下角通知区域。\r\n选择“否”：以后点关闭时直接退出。\r\n选择“取消”：返回应用，下次关闭时再询问。",
                "选择关闭窗口行为",
                MessageBoxButtons.YesNoCancel,
                MessageBoxIcon.Question,
                MessageBoxDefaultButton.Button1);
            if (choice == DialogResult.Cancel)
            {
                eventArgs.Cancel = true;
                return;
            }
            closeBehavior = choice == DialogResult.Yes ? "minimize" : "close";
            WriteStringSetting(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "desktop-settings.json"), "closeBehavior", closeBehavior);
        }
        if (string.Equals(closeBehavior, "minimize", StringComparison.OrdinalIgnoreCase))
        {
            eventArgs.Cancel = true;
            HideToNotificationArea();
        }
    }

    private void InitializeNotificationIcon()
    {
        notificationIcon = new NotifyIcon
        {
            Text = "DeepSeek Desktop",
            Icon = applicationIcon,
            Visible = false,
        };
        var menu = new ContextMenuStrip();
        menu.Items.Add("打开 DeepSeek Desktop", null, (_, __) => RestoreFromNotificationArea());
        menu.Items.Add("退出", null, (_, __) => ExitApplication());
        notificationIcon.ContextMenuStrip = menu;
        notificationIcon.DoubleClick += (_, __) => RestoreFromNotificationArea();
    }

    private void HideToNotificationArea()
    {
        notificationIcon.Visible = true;
        Hide();
    }

    private void RestoreFromNotificationArea()
    {
        Show();
        WindowState = FormWindowState.Normal;
        Activate();
        notificationIcon.Visible = false;
    }

    private void ExitApplication()
    {
        exiting = true;
        notificationIcon.Visible = false;
        Close();
    }

    private bool CheckForUpdates()
    {
        string updater = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "DeepSeek Updater.exe");
        if (!File.Exists(updater)) return true;
        var start = new ProcessStartInfo(updater)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            WorkingDirectory = AppDomain.CurrentDomain.BaseDirectory,
        };
        Process.Start(start);
        return true;
    }

    private void LoadApplicationIcon()
    {
        string logo = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "DeepSeek-Black-Logo.ico");
        if (!File.Exists(logo)) return;
        applicationIcon = new System.Drawing.Icon(logo);
        Icon = applicationIcon;
    }

    private void EnsureHarnessDependencies()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string node = Path.Combine(root, "runtime", "node.exe");
        string npm = Path.Combine(root, "runtime", "npm.cmd");
        string bin = Path.Combine(root, "app", "node_modules", "@deepseek-ai", "dsh", "lib", "bin.js");
        if (File.Exists(bin)) return;
        if (!File.Exists(node) || !File.Exists(npm)) throw new InvalidOperationException("DeepSeek Desktop is incomplete. Reinstall the application.");
        string installMode = ReadStringSetting(Path.Combine(root, "desktop-settings.json"), "installMode", "offline");
        if (string.Equals(installMode, "mirror", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("国内网络版安装器未完成运行组件下载。请重新运行安装包，安装器会先完成依赖下载，再打开 DeepSeek Desktop。");
        }
        if (MessageBox.Show("安装内容不完整，需要从 npm 官方源修复运行组件。下载完成后会自动打开。", "修复运行组件", MessageBoxButtons.OKCancel, MessageBoxIcon.Information) != DialogResult.OK)
        {
            throw new OperationCanceledException("已取消下载运行组件。");
        }
        using (var progress = new DownloadProgressForm("正在修复运行组件", "正在通过 npm 官方源下载，请勿关闭此窗口。"))
        {
            progress.Show(this);
            var start = new ProcessStartInfo("cmd.exe", "/d /s /c \"\"" + npm + "\" install --omit=dev --no-audit --no-fund --package-lock=false --registry=https://registry.npmjs.org --fetch-retries=3 --fetch-timeout=120000\"")
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                WorkingDirectory = Path.Combine(root, "app"),
            };
            start.EnvironmentVariables["PATH"] = Path.Combine(root, "runtime") + ";" + Environment.GetEnvironmentVariable("PATH");
            using (var install = Process.Start(start))
            {
                if (install == null) throw new InvalidOperationException("无法启动运行组件下载。");
                while (!install.WaitForExit(100)) Application.DoEvents();
                if (install.ExitCode != 0) throw new InvalidOperationException("运行组件下载失败。请检查网络后重新打开 DeepSeek Desktop。");
            }
        }
        if (!File.Exists(bin)) throw new InvalidOperationException("运行组件下载不完整。请重新打开 DeepSeek Desktop。");
    }

    private static string ReadStringSetting(string path, string name, string fallback)
    {
        if (!File.Exists(path)) return fallback;
        Match match = Regex.Match(File.ReadAllText(path), "\\\"" + Regex.Escape(name) + "\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"");
        return match.Success ? match.Groups[1].Value : fallback;
    }

    private static void WriteStringSetting(string path, string name, string value)
    {
        string json = File.Exists(path) ? File.ReadAllText(path) : "{\r\n}\r\n";
        string pattern = "\\\"" + Regex.Escape(name) + "\\\"\\s*:\\s*\\\"[^\\\"]*\\\"";
        string property = "\"" + name + "\": \"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
        if (Regex.IsMatch(json, pattern))
        {
            json = new Regex(pattern).Replace(json, property, 1);
        }
        else
        {
            int closingBrace = json.LastIndexOf('}');
            if (closingBrace < 0) throw new InvalidDataException("desktop-settings.json 格式无效。");
            string before = json.Substring(0, closingBrace).TrimEnd();
            if (!before.EndsWith("{", StringComparison.Ordinal)) before += ",";
            json = before + "\r\n  " + property + "\r\n}" + json.Substring(closingBrace + 1);
        }
        File.WriteAllText(path, json, new UTF8Encoding(false));
    }

    private void StartServer()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string home = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DeepSeek Harness Data");
        Directory.CreateDirectory(home);
        string node = Path.Combine(root, "runtime", "node.exe");
        string bin = Path.Combine(root, "app", "node_modules", "@deepseek-ai", "dsh", "lib", "bin.js");
        if (!File.Exists(node) || !File.Exists(bin)) throw new InvalidOperationException("DeepSeek Desktop is incomplete. Reinstall the application.");
        port = FindAvailablePort();
        var start = new ProcessStartInfo(node, "\"" + bin + "\" web --port " + port)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            WorkingDirectory = root,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        start.EnvironmentVariables["DSH_HOME"] = home;
        start.EnvironmentVariables["DSH_WEB_DESKTOP"] = "1";
        server = new Process { StartInfo = start };
        server.OutputDataReceived += (_, eventArgs) => AppendServerOutput(eventArgs.Data);
        server.ErrorDataReceived += (_, eventArgs) => AppendServerOutput(eventArgs.Data);
        if (!server.Start()) throw new InvalidOperationException("DeepSeek Desktop could not start the local Harness service.");
        server.BeginOutputReadLine();
        server.BeginErrorReadLine();
    }

    private void AppendServerOutput(string line)
    {
        if (string.IsNullOrEmpty(line)) return;
        lock (serverOutput)
        {
            serverOutput.AppendLine(line);
            if (serverOutput.Length > 8000) serverOutput.Remove(0, serverOutput.Length - 8000);
        }
    }

    private static int FindAvailablePort()
    {
        var listener = new TcpListener(IPAddress.Loopback, 0);
        try
        {
            listener.Start();
            return ((IPEndPoint)listener.LocalEndpoint).Port;
        }
        finally
        {
            listener.Stop();
        }
    }

    private void WaitForServer(int port)
    {
        var deadline = DateTime.UtcNow.AddSeconds(30);
        while (DateTime.UtcNow < deadline)
        {
            if (server == null || server.HasExited)
            {
                string detail;
                lock (serverOutput) detail = serverOutput.ToString().Trim();
                throw new InvalidOperationException("DeepSeek Harness 本地服务启动失败。" + (detail.Length == 0 ? "" : "\r\n\r\n" + detail));
            }
            try
            {
                var request = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:" + port + "/");
                request.Timeout = 1000;
                request.ReadWriteTimeout = 1000;
                request.Proxy = null;
                using (var response = (HttpWebResponse)request.GetResponse())
                {
                    if (response.StatusCode == HttpStatusCode.OK) return;
                }
            }
            catch (WebException)
            {
                Thread.Sleep(250);
            }
        }
        throw new TimeoutException("DeepSeek Desktop did not start within 30 seconds.");
    }
}

internal sealed class DownloadProgressForm : Form
{
    internal DownloadProgressForm(string heading, string description)
    {
        Text = "DeepSeek Desktop";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterParent;
        ClientSize = new System.Drawing.Size(480, 150);
        ControlBox = false;
        MaximizeBox = false;
        MinimizeBox = false;
        ShowInTaskbar = false;
        var title = new Label { Text = heading, AutoSize = true, Font = new System.Drawing.Font(System.Drawing.SystemFonts.MessageBoxFont.FontFamily, 13, System.Drawing.FontStyle.Bold), Location = new System.Drawing.Point(24, 24) };
        var detail = new Label { Text = description, AutoSize = true, Location = new System.Drawing.Point(26, 58) };
        var bar = new ProgressBar { Style = ProgressBarStyle.Marquee, MarqueeAnimationSpeed = 28, Location = new System.Drawing.Point(26, 92), Size = new System.Drawing.Size(428, 22) };
        Controls.AddRange(new Control[] { title, detail, bar });
    }
}
