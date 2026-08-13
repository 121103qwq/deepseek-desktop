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

    private enum ModelMode
    {
        Free,
        DeepSeekApi,
    }

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
                var mode = ChooseModelMode();
                if (!mode.HasValue)
                {
                    Close();
                    return;
                }
                ApplyModelMode(mode.Value);
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

    private ModelMode? ChooseModelMode()
    {
        using (var dialog = new Form())
        {
            dialog.Text = "DeepSeek Desktop";
            dialog.FormBorderStyle = FormBorderStyle.FixedDialog;
            dialog.StartPosition = FormStartPosition.CenterParent;
            dialog.ClientSize = new System.Drawing.Size(560, 275);
            dialog.MinimizeBox = false;
            dialog.MaximizeBox = false;
            dialog.ShowInTaskbar = false;

            var title = new Label
            {
                Text = "选择本次使用的模型",
                AutoSize = true,
                Font = new System.Drawing.Font(System.Drawing.SystemFonts.MessageBoxFont.FontFamily, 15, System.Drawing.FontStyle.Bold),
                Location = new System.Drawing.Point(28, 26),
            };
            var detail = new Label
            {
                Text = "Kilo Auto Free 可匿名使用，不需要登录或 API Key。DeepSeek API 模式则在内置界面中配置自己的密钥。",
                AutoSize = true,
                MaximumSize = new System.Drawing.Size(500, 0),
                Location = new System.Drawing.Point(30, 68),
            };
            var free = new Button
            {
                Text = "免费模型（Kilo，免登录）",
                DialogResult = DialogResult.Yes,
                Size = new System.Drawing.Size(225, 88),
                Location = new System.Drawing.Point(30, 132),
            };
            var api = new Button
            {
                Text = "DeepSeek API",
                DialogResult = DialogResult.No,
                Size = new System.Drawing.Size(225, 88),
                Location = new System.Drawing.Point(305, 132),
            };
            dialog.Controls.AddRange(new Control[] { title, detail, free, api });
            dialog.AcceptButton = free;
            var result = dialog.ShowDialog(this);
            if (result == DialogResult.Yes) return ModelMode.Free;
            if (result == DialogResult.No) return ModelMode.DeepSeekApi;
            return null;
        }
    }

    private static void ApplyModelMode(ModelMode mode)
    {
        string home = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DeepSeek Harness Data");
        string patch = Path.Combine(home, "profiles", "web", "cordis.patch.yml");
        if (!File.Exists(patch)) throw new InvalidOperationException("DeepSeek Desktop setup is incomplete. Reinstall the application.");
        string disabled = "- id: llm-deepseek\r\n  disabled: true";
        string enabled = "- id: llm-deepseek";
        string freeDefault = "provider: kilo\r\n    model: kilo-auto/free";
        string deepSeekDefault = "provider: deepseek-official\r\n    model: deepseek-v4-flash";
        string text = File.ReadAllText(patch);
        if (mode == ModelMode.Free)
        {
            text = text.Replace(deepSeekDefault, freeDefault);
            text = text.Replace(enabled + "\r\n  disabled: true", disabled).Replace(enabled + "\n  disabled: true", disabled);
            if (!text.Contains(disabled)) text = text.Replace(enabled, disabled);
        }
        else
        {
            text = text.Replace(freeDefault, deepSeekDefault);
            text = text.Replace(disabled, enabled).Replace("- id: llm-deepseek\n  disabled: true", enabled);
        }
        File.WriteAllText(patch, text);
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
