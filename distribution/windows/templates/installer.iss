[Setup]
AppId={{D9C6A2A6-83EA-4E37-B5DB-24BBA474D24E}
AppName=DeepSeek Desktop
AppVersion=__DESKTOP_VERSION__
AppVerName=DeepSeek Desktop __DESKTOP_VERSION__
AppPublisher=DeepSeek Desktop Community
AppPublisherURL=https://github.com/121103qwq/deepseek-desktop
AppSupportURL=https://github.com/121103qwq/deepseek-desktop/issues
AppUpdatesURL=https://github.com/121103qwq/deepseek-desktop/releases
DefaultDirName={localappdata}\Programs\DeepSeek Desktop
DefaultGroupName=DeepSeek Desktop
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir=__OUTPUT_DIR__
OutputBaseFilename=__OUTPUT_BASE__
SetupIconFile=__SETUP_ICON__
UninstallDisplayIcon={app}\DeepSeek Desktop.exe
WizardSmallImageFile=__WIZARD_LOGO__
WizardStyle=modern light polar includetitlebar
WizardSizePercent=130
DefaultDialogFontName=Microsoft YaHei UI
DisableWelcomePage=yes
DisableReadyPage=yes
DisableProgramGroupPage=yes
DisableFinishedPage=no
DisableStartupPrompt=yes
CloseApplications=yes
CloseApplicationsFilter=DeepSeek Desktop.exe
RestartApplications=no
AllowCancelDuringInstall=yes
Compression=lzma2/max
SolidCompression=no
CompressionThreads=auto
ArchiveExtraction=enhanced/nopassword
SetupLogging=yes
ChangesEnvironment=no
ChangesAssociations=no
UsePreviousAppDir=yes
UsePreviousTasks=yes
VersionInfoVersion=__FILE_VERSION__
VersionInfoProductName=DeepSeek Desktop
VersionInfoDescription=DeepSeek Desktop Windows Installer
VersionInfoCompany=DeepSeek Desktop Community

[Languages]
Name: "chinesesimplified"; MessagesFile: "__LANGUAGE_FILE__"

[InstallDelete]
Type: files; Name: "{app}\Uninstall DeepSeek Harness.cmd"
Type: files; Name: "{app}\Uninstall DeepSeek Harness.ps1"
Type: files; Name: "{app}\Uninstall DeepSeek Harness Cleanup.ps1"
Type: files; Name: "{app}\Launch DeepSeek Desktop.cmd"
Type: files; Name: "{app}\Update DeepSeek Desktop.ps1"
Type: files; Name: "{app}\DeepSeek Mirror Installer.exe"

[UninstallDelete]
Type: files; Name: "{app}\desktop-settings.json"
Type: files; Name: "{app}\updater-state.json"
Type: dirifempty; Name: "{app}"

[Files]
Source: "__PAYLOAD_ARCHIVE__"; DestDir: "{tmp}"; DestName: "deepseek-desktop-payload.7z"; Flags: ignoreversion nocompression deleteafterinstall
Source: "{tmp}\deepseek-desktop-payload.7z"; DestDir: "{app}"; ExternalSize: __PAYLOAD_BYTES__; Flags: external extractarchive ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\DeepSeek Desktop"; Filename: "{app}\DeepSeek Desktop.exe"; WorkingDir: "{app}"; IconFilename: "{app}\DeepSeek-Black-Logo.ico"
Name: "{autodesktop}\DeepSeek Desktop"; Filename: "{app}\DeepSeek Desktop.exe"; WorkingDir: "{app}"; IconFilename: "{app}\DeepSeek-Black-Logo.ico"; Check: ShouldCreateDesktopIcon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\DeepSeek Desktop"; Flags: deletekey

[Run]
__MIRROR_RUN__
Filename: "{app}\DeepSeek Installer Config.exe"; Parameters: "--model {code:GetModelMode} --update-channel {code:GetUpdateChannel} --auto-update {code:GetAutoUpdate} --vision {code:GetVisionEnabled} --install-mode __INSTALL_MODE__ --desktop-version __DESKTOP_VERSION__ --dsh-version __DSH_VERSION__"; StatusMsg: "正在写入中文、模型、更新和视觉配置…"; Flags: runhidden waituntilterminated
Filename: "{app}\DeepSeek Desktop.exe"; Description: "启动 DeepSeek Desktop"; Flags: nowait postinstall skipifsilent

[Code]
var
  OptionsPage: TWizardPage;
  ModelGroup: TPanel;
  UpdateGroup: TPanel;
  FreeModelRadio: TNewRadioButton;
  DeepSeekRadio: TNewRadioButton;
  AutoUpdateCheck: TNewCheckBox;
  OfficialUpdateRadio: TNewRadioButton;
  CommunityUpdateRadio: TNewRadioButton;
  VisionCheck: TNewCheckBox;
  DesktopIconCheck: TNewCheckBox;

procedure AddSectionTitle(const Caption: String; Top: Integer);
var
  LabelControl: TNewStaticText;
begin
  LabelControl := TNewStaticText.Create(OptionsPage);
  LabelControl.Parent := OptionsPage.Surface;
  LabelControl.Left := ScaleX(4);
  LabelControl.Top := ScaleY(Top);
  LabelControl.Caption := Caption;
  LabelControl.Font.Name := 'Microsoft YaHei UI';
  LabelControl.Font.Size := 10;
  LabelControl.Font.Style := [fsBold];
  LabelControl.Font.Color := $00301905;
end;

procedure AddHint(const Caption: String; Top: Integer; Height: Integer);
var
  Hint: TNewStaticText;
begin
  Hint := TNewStaticText.Create(OptionsPage);
  Hint.Parent := OptionsPage.Surface;
  Hint.Left := ScaleX(24);
  Hint.Top := ScaleY(Top);
  Hint.Width := OptionsPage.SurfaceWidth - ScaleX(30);
  Hint.Height := ScaleY(Height);
  Hint.AutoSize := False;
  Hint.WordWrap := True;
  Hint.Caption := Caption;
  Hint.Font.Color := $007A6250;
end;

procedure UpdateChannelControls(Sender: TObject);
begin
  OfficialUpdateRadio.Enabled := AutoUpdateCheck.Checked;
  CommunityUpdateRadio.Enabled := AutoUpdateCheck.Checked;
end;

procedure InitializeWizard;
begin
  WizardForm.Caption := '安装 DeepSeek Desktop';
  WizardForm.DirEdit.Text := ExpandConstant('{localappdata}\Programs\DeepSeek Desktop');
  OptionsPage := CreateCustomPage(wpSelectDir, '选择 DeepSeek Desktop 安装选项', '模型、更新和辅助识图会写入本机配置；需要更改时可重新运行安装包。');

  AddSectionTitle('首次模型路线', 2);
  ModelGroup := TPanel.Create(OptionsPage);
  ModelGroup.Parent := OptionsPage.Surface;
  ModelGroup.Left := 0;
  ModelGroup.Top := ScaleY(26);
  ModelGroup.Width := OptionsPage.SurfaceWidth;
  ModelGroup.Height := ScaleY(28);
  ModelGroup.Caption := '';
  ModelGroup.BevelOuter := bvNone;
  FreeModelRadio := TNewRadioButton.Create(OptionsPage);
  FreeModelRadio.Parent := ModelGroup;
  FreeModelRadio.Left := ScaleX(22);
  FreeModelRadio.Top := 0;
  FreeModelRadio.Width := ScaleX(280);
  FreeModelRadio.Height := ScaleY(24);
  FreeModelRadio.Caption := 'Kilo Auto Free（默认免登录，无需 Key）';
  FreeModelRadio.Checked := True;
  DeepSeekRadio := TNewRadioButton.Create(OptionsPage);
  DeepSeekRadio.Parent := ModelGroup;
  DeepSeekRadio.Left := ScaleX(320);
  DeepSeekRadio.Top := 0;
  DeepSeekRadio.Width := ScaleX(280);
  DeepSeekRadio.Height := ScaleY(24);
  DeepSeekRadio.Caption := 'DeepSeek API（稍后填写 Key）';
  AddHint('Kilo 是远程免费模型，不是本地模型；模型路线之后仍可在应用内修改。', 55, 26);

  AddSectionTitle('自动更新', 88);
  UpdateGroup := TPanel.Create(OptionsPage);
  UpdateGroup.Parent := OptionsPage.Surface;
  UpdateGroup.Left := 0;
  UpdateGroup.Top := ScaleY(140);
  UpdateGroup.Width := OptionsPage.SurfaceWidth;
  UpdateGroup.Height := ScaleY(28);
  UpdateGroup.Caption := '';
  UpdateGroup.BevelOuter := bvNone;
  AutoUpdateCheck := TNewCheckBox.Create(OptionsPage);
  AutoUpdateCheck.Parent := OptionsPage.Surface;
  AutoUpdateCheck.Left := ScaleX(22);
  AutoUpdateCheck.Top := ScaleY(116);
  AutoUpdateCheck.Width := ScaleX(330);
  AutoUpdateCheck.Height := ScaleY(24);
  AutoUpdateCheck.Caption := '自动检查更新（发现新版本后先询问）';
  AutoUpdateCheck.Checked := True;
  AutoUpdateCheck.OnClick := @UpdateChannelControls;
  OfficialUpdateRadio := TNewRadioButton.Create(OptionsPage);
  OfficialUpdateRadio.Parent := UpdateGroup;
  OfficialUpdateRadio.Left := ScaleX(44);
  OfficialUpdateRadio.Top := 0;
  OfficialUpdateRadio.Width := ScaleX(270);
  OfficialUpdateRadio.Height := ScaleY(24);
  OfficialUpdateRadio.Caption := '跟随上游 Harness 更新（推荐）';
  OfficialUpdateRadio.Checked := True;
  CommunityUpdateRadio := TNewRadioButton.Create(OptionsPage);
  CommunityUpdateRadio.Parent := UpdateGroup;
  CommunityUpdateRadio.Left := ScaleX(320);
  CommunityUpdateRadio.Top := 0;
  CommunityUpdateRadio.Width := ScaleX(290);
  CommunityUpdateRadio.Height := ScaleY(24);
  CommunityUpdateRadio.Caption := '社区桌面版（GitHub Release）';
  AddHint('上游通道更新 @deepseek-ai/dsh；社区通道更新 GitHub Release 中的完整桌面安装包。两者都不会静默安装。', 168, 36);

  AddSectionTitle('可选功能', 210);
  DesktopIconCheck := TNewCheckBox.Create(OptionsPage);
  DesktopIconCheck.Parent := OptionsPage.Surface;
  DesktopIconCheck.Left := ScaleX(22);
  DesktopIconCheck.Top := ScaleY(238);
  DesktopIconCheck.Width := ScaleX(260);
  DesktopIconCheck.Height := ScaleY(24);
  DesktopIconCheck.Caption := '创建桌面快捷方式';
  DesktopIconCheck.Checked := True;
  VisionCheck := TNewCheckBox.Create(OptionsPage);
  VisionCheck.Parent := OptionsPage.Surface;
  VisionCheck.Left := ScaleX(320);
  VisionCheck.Top := ScaleY(238);
  VisionCheck.Width := ScaleX(300);
  VisionCheck.Height := ScaleY(24);
  VisionCheck.Caption := '启用辅助识图（实验性）';
  AddHint('内置 dsh-vision-sidecar，默认调用 LLM7.io 匿名 default 视觉路由（免登录、免 Key）。不下载本地模型；图片会发送给远程视觉服务。', 266, 42);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = OptionsPage.ID) and (not WizardSilent) then
  begin
    Result := MsgBox(
      '【非官方社区版说明】' + #13#10 + #13#10 +
      'DeepSeek Desktop 是社区制作的非官方桌面封装，不是 DeepSeek 官方产品，也不代表、不隶属于 DeepSeek。' + #13#10 + #13#10 +
      '安装包会调用开源的 DeepSeek Harness；“跟随上游 Harness 更新”仅表示从 @deepseek-ai/dsh 获取组件更新，不代表本桌面程序获得官方背书。' + #13#10 + #13#10 +
      '是否继续安装？',
      mbInformation, MB_YESNO) = IDYES;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = OptionsPage.ID then
    WizardForm.NextButton.Caption := '立即安装'
  else if CurPageID = wpFinished then
    WizardForm.NextButton.Caption := SetupMessage(msgButtonFinish)
  else
    WizardForm.NextButton.Caption := SetupMessage(msgButtonNext);
end;

function GetModelMode(Param: String): String;
begin
  if DeepSeekRadio.Checked then Result := 'deepseek' else Result := 'free';
end;

function GetUpdateChannel(Param: String): String;
begin
  if CommunityUpdateRadio.Checked then Result := 'community' else Result := 'official';
end;

function GetAutoUpdate(Param: String): String;
begin
  if AutoUpdateCheck.Checked then Result := 'true' else Result := 'false';
end;

function GetVisionEnabled(Param: String): String;
begin
  if VisionCheck.Checked then Result := 'true' else Result := 'false';
end;

function ShouldCreateDesktopIcon: Boolean;
begin
  Result := DesktopIconCheck.Checked;
end;
