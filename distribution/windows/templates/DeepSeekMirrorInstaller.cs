using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;
using System.Windows.Forms;

internal static class DeepSeekMirrorInstaller
{
    private const string MirrorRegistry = "https://registry.npmmirror.com";
    private const string OfficialRegistry = "https://registry.npmjs.org";

    [STAThread]
    private static int Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string runtimeRoot = Path.Combine(root, "runtime");
        string appRoot = Path.Combine(root, "app");
        string npm = Path.Combine(runtimeRoot, "npm.cmd");
        string harness = Path.Combine(appRoot, "node_modules", "@deepseek-ai", "dsh", "lib", "bin.js");
        if (!File.Exists(npm))
        {
            MessageBox.Show("安装器缺少内置 Node.js 运行组件。请重新运行安装包。", "DeepSeek Desktop", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 2;
        }

        using (var progress = new InstallProgressForm())
        {
            progress.Show();
            Application.DoEvents();
            Exception mirrorError;
            bool installed = TryInstall(root, appRoot, runtimeRoot, npm, MirrorRegistry, "国内镜像", progress, out mirrorError);
            if (!installed)
            {
                progress.UseFallback(mirrorError);
                Exception officialError;
                installed = TryInstall(root, appRoot, runtimeRoot, npm, OfficialRegistry, "国外源", progress, out officialError);
                if (!installed)
                {
                    string detail = officialError == null ? "未知错误" : officialError.Message;
                    MessageBox.Show(
                        "运行组件下载失败，国内镜像和国外源都无法完成安装。\r\n\r\n" + detail + "\r\n\r\n请检查网络后重新运行安装包。",
                        "DeepSeek Desktop 安装失败",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error);
                    return 1;
                }
            }
            if (!File.Exists(harness))
            {
                MessageBox.Show("运行组件下载完成，但 DeepSeek Harness 文件不完整。请重新运行安装包。", "DeepSeek Desktop", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
            progress.Complete();
            Thread.Sleep(450);
        }
        return 0;
    }

    private static bool TryInstall(
        string root,
        string appRoot,
        string runtimeRoot,
        string npm,
        string registry,
        string routeName,
        InstallProgressForm progress,
        out Exception failure)
    {
        failure = null;
        progress.SetRoute(routeName, registry);
        try
        {
            ProbeRegistry(registry);
        }
        catch (Exception error)
        {
            failure = new InvalidOperationException(routeName + "连接超时或不可用。", error);
            progress.SetFailure(routeName + "连接超时，准备切换下载源。");
            return false;
        }

        string nodeModules = Path.Combine(appRoot, "node_modules");
        string logPath = Path.Combine(Path.GetTempPath(), "deepseek-desktop-install-" + routeName + ".log");
        var start = new ProcessStartInfo(
            "cmd.exe",
            "/d /s /c \"\"" + npm + "\" install --omit=dev --no-audit --no-fund --package-lock=false --registry=" + registry + " --fetch-retries=1 --fetch-timeout=20000 --loglevel=notice\"")
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            WorkingDirectory = appRoot,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        start.EnvironmentVariables["PATH"] = runtimeRoot + ";" + Environment.GetEnvironmentVariable("PATH");
        start.EnvironmentVariables["NPM_CONFIG_REGISTRY"] = registry;
        var output = new StringBuilder();
        try
        {
            using (Process install = Process.Start(start))
            {
                if (install == null) throw new InvalidOperationException("无法启动 npm 安装进程。");
                install.OutputDataReceived += (_, eventArgs) => AppendOutput(output, eventArgs.Data, logPath);
                install.ErrorDataReceived += (_, eventArgs) => AppendOutput(output, eventArgs.Data, logPath);
                install.BeginOutputReadLine();
                install.BeginErrorReadLine();
                long previousBytes = DirectoryBytes(nodeModules);
                DateTime previousAt = DateTime.UtcNow;
                while (!install.WaitForExit(250))
                {
                    Application.DoEvents();
                    DateTime now = DateTime.UtcNow;
                    if ((now - previousAt).TotalMilliseconds >= 500)
                    {
                        long currentBytes = DirectoryBytes(nodeModules);
                        double seconds = Math.Max(0.001, (now - previousAt).TotalSeconds);
                        progress.UpdateStats(currentBytes, (currentBytes - previousBytes) / seconds, LastLine(output));
                        previousBytes = currentBytes;
                        previousAt = now;
                    }
                }
                install.WaitForExit();
                Application.DoEvents();
                long finalBytes = DirectoryBytes(nodeModules);
                progress.UpdateStats(finalBytes, 0, LastLine(output));
                if (install.ExitCode == 0) return true;
                failure = new InvalidOperationException(routeName + "安装失败，npm 退出代码 " + install.ExitCode + "。" + FormatOutput(output));
                progress.SetFailure(routeName + "安装失败，准备切换下载源。");
                return false;
            }
        }
        catch (Exception error)
        {
            failure = new InvalidOperationException(routeName + "安装失败。" + FormatOutput(output), error);
            progress.SetFailure(routeName + "安装失败，准备切换下载源。");
            return false;
        }
    }

    private static void ProbeRegistry(string registry)
    {
        var request = (HttpWebRequest)WebRequest.Create(registry + "/@deepseek-ai%2fdsh");
        request.Method = "HEAD";
        request.Timeout = 8000;
        request.ReadWriteTimeout = 8000;
        request.UserAgent = "DeepSeek-Desktop-Installer/0.2.2";
        using (var response = (HttpWebResponse)request.GetResponse())
        {
            if ((int)response.StatusCode < 200 || (int)response.StatusCode >= 400)
                throw new InvalidOperationException("HTTP " + (int)response.StatusCode);
        }
    }

    private static void AppendOutput(StringBuilder output, string line, string logPath)
    {
        if (string.IsNullOrEmpty(line)) return;
        lock (output)
        {
            output.AppendLine(line);
            if (output.Length > 12000) output.Remove(0, output.Length - 12000);
        }
        try { File.AppendAllText(logPath, line + Environment.NewLine, Encoding.UTF8); }
        catch { }
    }

    private static string LastLine(StringBuilder output)
    {
        lock (output)
        {
            string text = output.ToString().TrimEnd();
            int index = text.LastIndexOf('\n');
            return index < 0 ? text : text.Substring(index + 1).Trim();
        }
    }

    private static string FormatOutput(StringBuilder output)
    {
        string line = LastLine(output);
        return line.Length == 0 ? string.Empty : "\r\n\r\n" + line;
    }

    private static long DirectoryBytes(string path)
    {
        if (!Directory.Exists(path)) return 0;
        long total = 0;
        try
        {
            foreach (string file in Directory.GetFiles(path, "*", SearchOption.AllDirectories))
            {
                try { total += new FileInfo(file).Length; }
                catch { }
            }
        }
        catch { }
        return total;
    }
}

internal sealed class InstallProgressForm : Form
{
    private readonly Label route = new Label();
    private readonly Label file = new Label();
    private readonly Label speed = new Label();
    private readonly Label state = new Label();
    private readonly ProgressBar fileProgress = new ProgressBar();
    private readonly ProgressBar totalProgress = new ProgressBar();

    internal InstallProgressForm()
    {
        Text = "DeepSeek Desktop 安装";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(620, 270);
        ControlBox = false;
        MaximizeBox = false;
        MinimizeBox = false;
        ShowInTaskbar = true;
        TopMost = true;
        BackColor = Color.White;
        var title = new Label { Text = "正在安装 DeepSeek Desktop", AutoSize = true, Font = new Font("Microsoft YaHei UI", 14, FontStyle.Bold), Location = new Point(28, 22) };
        route.AutoSize = true;
        route.Location = new Point(30, 58);
        file.AutoSize = true;
        file.Location = new Point(30, 94);
        file.Text = "文件进度：准备中";
        fileProgress.Location = new Point(30, 118);
        fileProgress.Size = new Size(560, 22);
        fileProgress.Style = ProgressBarStyle.Marquee;
        fileProgress.MarqueeAnimationSpeed = 24;
        state.AutoSize = true;
        state.Location = new Point(30, 151);
        state.Text = "总体进度：正在解析依赖";
        totalProgress.Location = new Point(30, 175);
        totalProgress.Size = new Size(560, 22);
        totalProgress.Style = ProgressBarStyle.Marquee;
        totalProgress.MarqueeAnimationSpeed = 18;
        speed.AutoSize = true;
        speed.Location = new Point(30, 211);
        speed.Text = "下载速度：计算中";
        Controls.AddRange(new Control[] { title, route, file, fileProgress, state, totalProgress, speed });
    }

    internal void SetRoute(string name, string registry)
    {
        route.Text = "下载源：" + name + "（" + registry + "）";
        state.Text = "总体进度：正在解析依赖";
        file.Text = "文件进度：准备中";
        speed.Text = "下载速度：计算中";
    }

    internal void UseFallback(Exception error)
    {
        route.Text = "国内镜像不可用，正在切换国外源";
        state.Text = "总体进度：重新连接（" + (error == null ? "网络超时" : "连接失败") + "）";
        file.Text = "文件进度：等待备用源";
    }

    internal void SetFailure(string message)
    {
        state.Text = message;
        Application.DoEvents();
    }

    internal void UpdateStats(long bytes, double bytesPerSecond, string lastLine)
    {
        file.Text = "文件进度：已写入 " + FormatBytes(bytes) + (lastLine.Length == 0 ? string.Empty : "（" + TrimLine(lastLine) + "）");
        speed.Text = "下载速度：" + FormatBytes(bytesPerSecond) + "/秒";
        Application.DoEvents();
    }

    internal void Complete()
    {
        fileProgress.Style = ProgressBarStyle.Continuous;
        fileProgress.MarqueeAnimationSpeed = 0;
        fileProgress.Value = fileProgress.Maximum;
        totalProgress.Style = ProgressBarStyle.Continuous;
        totalProgress.MarqueeAnimationSpeed = 0;
        totalProgress.Value = totalProgress.Maximum;
        state.Text = "总体进度：安装完成";
        speed.Text = "下载速度：完成";
    }

    private static string TrimLine(string value)
    {
        value = value.Replace("\r", " ").Replace("\n", " ").Trim();
        return value.Length <= 68 ? value : value.Substring(0, 68) + "…";
    }

    private static string FormatBytes(double bytes)
    {
        if (bytes < 1024) return Math.Max(0, bytes).ToString("0") + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).ToString("0.0") + " KB";
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).ToString("0.0") + " MB";
        return (bytes / (1024 * 1024 * 1024)).ToString("0.00") + " GB";
    }
}
