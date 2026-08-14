using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;

internal static class DeepSeekInstallerConfig
{
    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            var values = ParseArguments(args);
            string installRoot = AppDomain.CurrentDomain.BaseDirectory;
            string home = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DeepSeek Harness Data");
            string profile = Path.Combine(home, "profiles", "web");
            Directory.CreateDirectory(profile);

            string patchPath = Path.Combine(profile, "cordis.patch.yml");
            string defaults = Path.Combine(installRoot, "defaults", "cordis.patch.yml");
            if (!File.Exists(patchPath))
            {
                File.Copy(defaults, patchPath);
            }
            else
            {
                string existing = File.ReadAllText(patchPath, Encoding.UTF8);
                if (existing.Contains("provider: groq") && existing.Contains("baseURL: https://api.groq.com/openai/v1"))
                {
                    File.Copy(defaults, patchPath, true);
                }
            }
            ConfigureModelPatch(patchPath, values["model"]);
            ConfigureSettings(home);
            WriteDesktopSettings(installRoot, values);
            PrepareHarnessProfile(installRoot, home, values);
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "DeepSeek Desktop 安装失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    private static Dictionary<string, string> ParseArguments(string[] args)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (int index = 0; index + 1 < args.Length; index += 2)
        {
            if (!args[index].StartsWith("--", StringComparison.Ordinal)) throw new ArgumentException("安装配置参数无效。");
            result[args[index].Substring(2)] = args[index + 1];
        }
        foreach (string key in new[] { "model", "update-channel", "auto-update", "vision", "install-mode", "desktop-version", "dsh-version" })
        {
            if (!result.ContainsKey(key)) throw new ArgumentException("缺少安装配置参数：" + key);
        }
        return result;
    }

    private static void ConfigureModelPatch(string patchPath, string modelMode)
    {
        string patch = File.ReadAllText(patchPath, Encoding.UTF8).Replace("\r\n", "\n");
        const string freeDefault = "provider: kilo\n    model: kilo-auto/free";
        const string deepSeekDefault = "provider: deepseek-official\n    model: deepseek-v4-flash";
        const string disabledDeepSeek = "- id: llm-deepseek\n  disabled: true";
        const string enabledDeepSeek = "- id: llm-deepseek";
        if (string.Equals(modelMode, "deepseek", StringComparison.OrdinalIgnoreCase))
        {
            patch = patch.Replace(freeDefault, deepSeekDefault).Replace(disabledDeepSeek, enabledDeepSeek);
        }
        else
        {
            patch = patch.Replace(deepSeekDefault, freeDefault);
            patch = patch.Replace(enabledDeepSeek + "\n  disabled: true", disabledDeepSeek);
            if (!patch.Contains(disabledDeepSeek)) patch = patch.Replace(enabledDeepSeek, disabledDeepSeek);
        }
        File.WriteAllText(patchPath, patch.Replace("\n", "\r\n"), new UTF8Encoding(false));
    }

    private static void ConfigureSettings(string home)
    {
        string settingsPath = Path.Combine(home, "settings.yaml");
        const string providers = "llm-pi-ai:\r\n" +
            "  providers:\r\n" +
            "    kilo:\r\n" +
            "      displayName: Kilo AI Gateway（匿名免费）\r\n" +
            "      api: openai-completions\r\n" +
            "      baseURL: https://api.kilo.ai/api/gateway\r\n" +
            "      headers:\r\n" +
            "        Authorization: Bearer unused\r\n" +
            "      models:\r\n" +
            "        - id: kilo-auto/free\r\n" +
            "          name: Kilo Auto Free（免登录）\r\n" +
            "          contextWindow: 131072\r\n" +
            "          maxTokens: 8192\r\n" +
            "        - id: stepfun/step-3.7-flash:free\r\n" +
            "          name: StepFun 3.7 Flash（Kilo 免费）\r\n" +
            "          contextWindow: 131072\r\n" +
            "          maxTokens: 8192\r\n";
        string settings;
        if (File.Exists(settingsPath))
        {
            settings = File.ReadAllText(settingsPath, Encoding.UTF8).TrimEnd() + "\r\n";
            if (!settings.Contains("locale:\r\n") && !settings.Replace("\r\n", "\n").Contains("locale:\n"))
            {
                settings += "locale:\r\n  preference: zh\r\n";
            }
            if (!settings.Contains("llm-pi-ai:\r\n") && !settings.Replace("\r\n", "\n").Contains("llm-pi-ai:\n"))
            {
                settings += providers;
            }
        }
        else
        {
            settings = "ui-onboarding:\r\n  welcomeNoticeVersion: 2026-08-14.1\r\nlocale:\r\n  preference: zh\r\n" + providers;
        }
        File.WriteAllText(settingsPath, settings, new UTF8Encoding(true));
    }

    private static void PrepareHarnessProfile(string installRoot, string home, Dictionary<string, string> values)
    {
        string node = Path.Combine(installRoot, "runtime", "node.exe");
        string dsh = Path.Combine(installRoot, "app", "node_modules", "@deepseek-ai", "dsh", "lib", "bin.js");
        string configureVision = Path.Combine(installRoot, "Configure Vision.mjs");
        if (!File.Exists(node) || !File.Exists(dsh) || !File.Exists(configureVision)) throw new InvalidOperationException("DeepSeek Desktop 运行文件不完整。请重新运行安装包。");

        LinkApplicationModulesIntoProfile(installRoot, home);
        RunNode(node, "\"" + dsh + "\" --profile web --dump-config", installRoot, home, "DeepSeek Harness 配置初始化失败。");
        RunNode(node, "\"" + configureVision + "\" \"" + home + "\" " + BooleanLiteral(values["vision"]) + " " + values["model"], installRoot, home, "辅助识图配置失败。");
        RunNode(node, "\"" + dsh + "\" --profile web --dump-config", installRoot, home, "DeepSeek Harness 配置验证失败。");
    }

    private static void RunNode(string node, string arguments, string workingDirectory, string home, string errorMessage)
    {
        var start = new ProcessStartInfo(node, arguments)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            WorkingDirectory = workingDirectory,
        };
        start.EnvironmentVariables["DSH_HOME"] = home;
        using (var process = Process.Start(start))
        {
            if (process == null) throw new InvalidOperationException(errorMessage);
            process.WaitForExit();
            if (process.ExitCode != 0) throw new InvalidOperationException(errorMessage);
        }
    }

    private static void LinkApplicationModulesIntoProfile(string installRoot, string home)
    {
        string source = Path.Combine(installRoot, "app", "node_modules");
        string target = Path.Combine(home, "profiles", "web", "node_modules");
        string sourceManifest = Path.Combine(source, "@deepseek-ai", "dsh", "package.json");
        string targetManifest = Path.Combine(target, "@deepseek-ai", "dsh", "package.json");
        if (!File.Exists(sourceManifest)) throw new InvalidOperationException("DeepSeek Harness 依赖缺失。请重新运行安装包。");
        if (File.Exists(targetManifest) && (File.GetAttributes(target) & FileAttributes.ReparsePoint) != 0) return;
        if (Directory.Exists(target)) Directory.Delete(target, true);
        Directory.CreateDirectory(Path.GetDirectoryName(target));
        var createJunction = new ProcessStartInfo("cmd.exe", "/d /s /c mklink /J \"" + target + "\" \"" + source + "\"")
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            WorkingDirectory = installRoot,
        };
        using (var process = Process.Start(createJunction))
        {
            if (process == null) throw new InvalidOperationException("无法连接 DeepSeek Harness 依赖。请重新运行安装包。");
            process.WaitForExit();
            if (process.ExitCode != 0 || !File.Exists(targetManifest)) throw new InvalidOperationException("DeepSeek Harness 依赖连接失败。请重新运行安装包。");
        }
    }

    private static void WriteDesktopSettings(string installRoot, Dictionary<string, string> values)
    {
        string json = "{\r\n" +
            "  \"desktopVersion\": \"" + Escape(values["desktop-version"]) + "\",\r\n" +
            "  \"installedDshVersion\": \"" + Escape(values["dsh-version"]) + "\",\r\n" +
            "  \"installMode\": \"" + Escape(values["install-mode"]) + "\",\r\n" +
            "  \"modelMode\": \"" + Escape(values["model"]) + "\",\r\n" +
            "  \"autoUpdate\": " + BooleanLiteral(values["auto-update"]) + ",\r\n" +
            "  \"updateChannel\": \"" + Escape(values["update-channel"]) + "\",\r\n" +
            "  \"visionEnabled\": " + BooleanLiteral(values["vision"]) + "\r\n" +
            "}\r\n";
        File.WriteAllText(Path.Combine(installRoot, "desktop-settings.json"), json, new UTF8Encoding(false));
    }

    private static string BooleanLiteral(string value)
    {
        return string.Equals(value, "true", StringComparison.OrdinalIgnoreCase) ? "true" : "false";
    }

    private static string Escape(string value)
    {
        return value.Replace("\\", "\\\\").Replace("\"", "\\\"");
    }
}
