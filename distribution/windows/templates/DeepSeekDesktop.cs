using System;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Net;
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
    private System.Drawing.Icon applicationIcon;
    private int port;

    internal DesktopForm()
    {
        Text = "DeepSeek Desktop";
        Width = 1440;
        Height = 920;
        MinimumSize = new System.Drawing.Size(960, 640);
        WindowState = FormWindowState.Maximized;
        LoadApplicationIcon();
        Controls.Add(view);
        Shown += async (_, __) =>
        {
            try
            {
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
        FormClosed += (_, __) =>
        {
            if (server != null && !server.HasExited) server.Kill();
        };
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
        if (MessageBox.Show("首次启动需要从国内高速镜像下载运行组件。下载完成后会自动打开，后续启动不会重复下载。", "准备运行组件", MessageBoxButtons.OKCancel, MessageBoxIcon.Information) != DialogResult.OK)
        {
            throw new OperationCanceledException("已取消下载运行组件。");
        }
        using (var progress = new DownloadProgressForm())
        {
            progress.Show(this);
            var start = new ProcessStartInfo(npm, "install --omit=dev --no-audit --no-fund --package-lock=false --registry=https://registry.npmmirror.com --fetch-retries=3 --fetch-timeout=120000")
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
        };
        start.EnvironmentVariables["DSH_HOME"] = home;
        start.EnvironmentVariables["DSH_WEB_DESKTOP"] = "1";
        server = Process.Start(start);
        if (server == null) throw new InvalidOperationException("DeepSeek Desktop could not start the local Harness service.");
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

    private static void WaitForServer(int port)
    {
        var deadline = DateTime.UtcNow.AddSeconds(30);
        while (DateTime.UtcNow < deadline)
        {
            try
            {
                using (var client = new TcpClient())
                {
                    client.Connect("127.0.0.1", port);
                    return;
                }
            }
            catch (SocketException)
            {
                Thread.Sleep(250);
            }
        }
        throw new TimeoutException("DeepSeek Desktop did not start within 30 seconds.");
    }
}

internal sealed class DownloadProgressForm : Form
{
    internal DownloadProgressForm()
    {
        Text = "DeepSeek Desktop";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterParent;
        ClientSize = new System.Drawing.Size(480, 150);
        ControlBox = false;
        MaximizeBox = false;
        MinimizeBox = false;
        ShowInTaskbar = false;
        var title = new Label { Text = "正在下载运行组件", AutoSize = true, Font = new System.Drawing.Font(System.Drawing.SystemFonts.MessageBoxFont.FontFamily, 13, System.Drawing.FontStyle.Bold), Location = new System.Drawing.Point(24, 24) };
        var detail = new Label { Text = "正在通过国内高速镜像下载，请勿关闭此窗口。", AutoSize = true, Location = new System.Drawing.Point(26, 58) };
        var bar = new ProgressBar { Style = ProgressBarStyle.Marquee, MarqueeAnimationSpeed = 28, Location = new System.Drawing.Point(26, 92), Size = new System.Drawing.Size(428, 22) };
        Controls.AddRange(new Control[] { title, detail, bar });
    }
}
