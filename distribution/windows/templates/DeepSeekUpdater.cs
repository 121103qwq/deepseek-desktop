using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

internal static class DeepSeekUpdater
{
    private static readonly string InstallRoot = AppDomain.CurrentDomain.BaseDirectory;
    private static readonly string SettingsPath = Path.Combine(InstallRoot, "desktop-settings.json");
    private static readonly string StatePath = Path.Combine(InstallRoot, "updater-state.json");
    private static readonly string LogPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DeepSeek Harness Data", "updater.log");

    [STAThread]
    private static int Main(string[] args)
    {
        bool manual = Array.IndexOf(args, "--manual") >= 0;
        bool force = Array.IndexOf(args, "--force") >= 0;
        try
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            if (!File.Exists(SettingsPath) || !ReadBoolean(SettingsPath, "autoUpdate", false)) return 0;
            if (!force && CheckedRecently()) return 0;
            File.WriteAllText(StatePath, "{\r\n  \"lastCheckUtc\": \"" + DateTime.UtcNow.ToString("o") + "\"\r\n}\r\n", new UTF8Encoding(false));
            string channel = ReadString(SettingsPath, "updateChannel", "official");
            return string.Equals(channel, "community", StringComparison.OrdinalIgnoreCase)
                ? CheckCommunityUpdate()
                : CheckOfficialUpdate();
        }
        catch (Exception error)
        {
            File.AppendAllText(LogPath, DateTime.UtcNow.ToString("o") + " " + error + Environment.NewLine, Encoding.UTF8);
            if (manual) MessageBox.Show("更新检查失败：\r\n" + error.Message, "DeepSeek Desktop", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return 1;
        }
    }

    private static bool CheckedRecently()
    {
        if (!File.Exists(StatePath)) return false;
        string value = ReadString(StatePath, "lastCheckUtc", string.Empty);
        DateTime last;
        return DateTime.TryParse(value, out last) && DateTime.UtcNow - last.ToUniversalTime() < TimeSpan.FromHours(24);
    }

    private static int CheckOfficialUpdate()
    {
        string appRoot = Path.Combine(InstallRoot, "app");
        string manifestPath = Path.Combine(appRoot, "package.json");
        if (!File.Exists(manifestPath)) return 0;
        string metadata;
        metadata = DownloadText("https://registry.npmjs.org/@deepseek-ai%2Fdsh/latest");
        string latest = ReadStringValue(metadata, "version", string.Empty);
        string current = ReadDependencyVersion(File.ReadAllText(manifestPath, Encoding.UTF8));
        if (latest.Length == 0 || string.Equals(latest, current, StringComparison.OrdinalIgnoreCase)) return 0;
        if (MessageBox.Show("上游 DeepSeek Harness 已发布 " + latest + "。\r\n当前版本：" + current + "\r\n\r\n现在更新运行组件吗？", "上游 Harness 更新", MessageBoxButtons.YesNo, MessageBoxIcon.Information) != DialogResult.Yes) return 0;

        string runtime = Path.Combine(InstallRoot, "runtime");
        string npm = Path.Combine(runtime, "npm.cmd");
        string node = Path.Combine(runtime, "node.exe");
        string stage = Path.Combine(InstallRoot, "app-update-" + Guid.NewGuid().ToString("N"));
        string backup = Path.Combine(InstallRoot, "app-backup-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(stage);
        File.WriteAllText(Path.Combine(stage, "package.json"), "{\r\n  \"name\": \"deepseek-desktop-runtime\",\r\n  \"version\": \"" + JsonEscape(latest) + "\",\r\n  \"private\": true,\r\n  \"dependencies\": {\r\n    \"@deepseek-ai/dsh\": \"" + JsonEscape(latest) + "\",\r\n    \"dsh-vision-sidecar\": \"file:../vision/dsh-vision-sidecar-v0.1.3.tgz\"\r\n  }\r\n}\r\n", new UTF8Encoding(false));
        try
        {
            RunBusy("正在更新 DeepSeek Harness", "正在从 npm 官方源下载上游运行组件，请勿关闭。", delegate
            {
                RunProcess("cmd.exe", "/d /s /c \"\"" + npm + "\" install --omit=dev --no-audit --no-fund --package-lock=false --registry=https://registry.npmjs.org --fetch-retries=3 --fetch-timeout=120000\"", stage, runtime);
            });
            string bin = Path.Combine(stage, "node_modules", "@deepseek-ai", "dsh", "lib", "bin.js");
            if (!File.Exists(bin)) throw new InvalidOperationException("更新后的 Harness 组件不完整。");
            RunProcess(node, "\"" + bin + "\" --help", stage, runtime);
            Directory.Move(appRoot, backup);
            try { Directory.Move(stage, appRoot); }
            catch { Directory.Move(backup, appRoot); throw; }
            Directory.Delete(backup, true);
            ReplaceSetting(SettingsPath, "installedDshVersion", latest);
            MessageBox.Show("上游 DeepSeek Harness 已更新到 " + latest + "。", "更新完成", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return 0;
        }
        finally
        {
            if (Directory.Exists(stage)) Directory.Delete(stage, true);
        }
    }

    private static int CheckCommunityUpdate()
    {
        string json = DownloadText("https://api.github.com/repos/121103qwq/deepseek-desktop/releases/latest");
        var serializer = new JavaScriptSerializer();
        var release = serializer.DeserializeObject(json) as Dictionary<string, object>;
        if (release == null) throw new InvalidOperationException("GitHub Release 响应无效。");
        string latest = Convert.ToString(release["tag_name"]).Replace("deepseek-desktop-v", string.Empty);
        string current = ReadString(SettingsPath, "desktopVersion", "0.0.0");
        if (!IsNewer(latest, current)) return 0;
        bool offline = string.Equals(ReadString(SettingsPath, "installMode", "mirror"), "offline", StringComparison.OrdinalIgnoreCase);
        Dictionary<string, object> selected = null;
        var assets = release["assets"] as object[];
        if (assets != null)
        {
            foreach (object item in assets)
            {
                var asset = item as Dictionary<string, object>;
                if (asset == null) continue;
                string name = Convert.ToString(asset["name"]);
                bool matches = name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) && (offline ? name.IndexOf("Offline", StringComparison.OrdinalIgnoreCase) >= 0 || name.Contains("离线版") : name.IndexOf("Offline", StringComparison.OrdinalIgnoreCase) < 0 && !name.Contains("离线版"));
                if (matches) { selected = asset; break; }
            }
        }
        if (selected == null) throw new InvalidOperationException("社区 Release 中没有匹配的 Windows 安装包。");
        if (MessageBox.Show("社区桌面版已发布 " + latest + "。\r\n当前版本：" + current + "\r\n\r\n现在下载安装吗？", "DeepSeek Desktop 社区更新", MessageBoxButtons.YesNo, MessageBoxIcon.Information) != DialogResult.Yes) return 0;
        string nameValue = Convert.ToString(selected["name"]);
        string download = Path.Combine(Path.GetTempPath(), nameValue);
        string url = Convert.ToString(selected["browser_download_url"]);
        RunBusy("正在下载 DeepSeek Desktop", "正在从 GitHub Release 获取社区安装包。", delegate { DownloadFile(url, download); });
        object digestValue;
        if (selected.TryGetValue("digest", out digestValue)) VerifyDigest(download, Convert.ToString(digestValue));
        Process.Start(new ProcessStartInfo(download) { UseShellExecute = true });
        return 10;
    }

    private static string DownloadText(string url)
    {
        using (var client = NewWebClient()) return client.DownloadString(url);
    }

    private static void DownloadFile(string url, string path)
    {
        using (var client = NewWebClient()) client.DownloadFile(url, path);
    }

    private static WebClient NewWebClient()
    {
        var client = new WebClient();
        client.Headers[HttpRequestHeader.UserAgent] = "DeepSeek-Desktop-Updater/0.2.2";
        client.Headers[HttpRequestHeader.Accept] = "application/vnd.github+json";
        return client;
    }

    private static void VerifyDigest(string path, string digest)
    {
        if (string.IsNullOrEmpty(digest) || !digest.StartsWith("sha256:", StringComparison.OrdinalIgnoreCase)) return;
        using (SHA256 sha = SHA256.Create())
        using (FileStream stream = File.OpenRead(path))
        {
            string actual = BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", string.Empty).ToLowerInvariant();
            if (!string.Equals(actual, digest.Substring(7), StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("下载的社区安装包完整性校验失败。");
        }
    }

    private static void RunBusy(string title, string detail, Action action)
    {
        using (var form = new BusyForm(title, detail))
        {
            Task task = Task.Run(action);
            form.Show();
            while (!task.IsCompleted)
            {
                Application.DoEvents();
                System.Threading.Thread.Sleep(50);
            }
            form.Close();
            task.GetAwaiter().GetResult();
        }
    }

    private static void RunProcess(string file, string arguments, string workingDirectory, string runtime)
    {
        var start = new ProcessStartInfo(file, arguments) { UseShellExecute = false, CreateNoWindow = true, WorkingDirectory = workingDirectory };
        start.EnvironmentVariables["PATH"] = runtime + ";" + Environment.GetEnvironmentVariable("PATH");
        using (Process process = Process.Start(start))
        {
            if (process == null) throw new InvalidOperationException("无法启动更新进程。");
            process.WaitForExit();
            if (process.ExitCode != 0) throw new InvalidOperationException("更新进程失败，退出代码 " + process.ExitCode + "。");
        }
    }

    private static bool IsNewer(string candidate, string current)
    {
        Match a = Regex.Match(candidate, @"^v?(\d+)\.(\d+)\.(\d+)(?:-([^+]+))?");
        Match b = Regex.Match(current, @"^v?(\d+)\.(\d+)\.(\d+)(?:-([^+]+))?");
        if (!a.Success || !b.Success) return false;
        for (int index = 1; index <= 3; index++)
        {
            int av = int.Parse(a.Groups[index].Value);
            int bv = int.Parse(b.Groups[index].Value);
            if (av != bv) return av > bv;
        }
        return a.Groups[4].Value.Length == 0 && b.Groups[4].Value.Length > 0;
    }

    private static string ReadDependencyVersion(string json)
    {
        Match match = Regex.Match(json, @"""@deepseek-ai/dsh""\s*:\s*""([^""]+)""");
        return match.Success ? match.Groups[1].Value : string.Empty;
    }

    private static string ReadString(string path, string name, string fallback)
    {
        return File.Exists(path) ? ReadStringValue(File.ReadAllText(path, Encoding.UTF8), name, fallback) : fallback;
    }

    private static string ReadStringValue(string json, string name, string fallback)
    {
        Match match = Regex.Match(json, "\\\"" + Regex.Escape(name) + "\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"");
        return match.Success ? match.Groups[1].Value : fallback;
    }

    private static bool ReadBoolean(string path, string name, bool fallback)
    {
        Match match = Regex.Match(File.ReadAllText(path, Encoding.UTF8), "\\\"" + Regex.Escape(name) + "\\\"\\s*:\\s*(true|false)", RegexOptions.IgnoreCase);
        return match.Success ? string.Equals(match.Groups[1].Value, "true", StringComparison.OrdinalIgnoreCase) : fallback;
    }

    private static void ReplaceSetting(string path, string name, string value)
    {
        string json = File.ReadAllText(path, Encoding.UTF8);
        json = Regex.Replace(json, "(\\\"" + Regex.Escape(name) + "\\\"\\s*:\\s*)\\\"[^\\\"]*\\\"", "$1\"" + JsonEscape(value) + "\"");
        File.WriteAllText(path, json, new UTF8Encoding(false));
    }

    private static string JsonEscape(string value)
    {
        return value.Replace("\\", "\\\\").Replace("\"", "\\\"");
    }
}

internal sealed class BusyForm : Form
{
    internal BusyForm(string heading, string detail)
    {
        Text = "DeepSeek Desktop";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new System.Drawing.Size(500, 160);
        ControlBox = false;
        ShowInTaskbar = false;
        BackColor = System.Drawing.Color.White;
        Controls.Add(new Label { Text = heading, AutoSize = true, Font = new System.Drawing.Font("Microsoft YaHei UI", 13, System.Drawing.FontStyle.Bold), Location = new System.Drawing.Point(26, 24) });
        Controls.Add(new Label { Text = detail, AutoSize = true, Location = new System.Drawing.Point(28, 62) });
        Controls.Add(new ProgressBar { Style = ProgressBarStyle.Marquee, MarqueeAnimationSpeed = 28, Location = new System.Drawing.Point(28, 100), Size = new System.Drawing.Size(444, 22) });
    }
}
