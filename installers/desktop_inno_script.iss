; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Facilino OTA"
#define MyAppVersion "1.0"
#define MyAppPublisher "UPV"
#define MyAppURL "facilino.webs.upv.es"
#define MyAppExeName "facilino_ota_gui.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{B4790084-8A24-42C9-AFA3-A5EB7394762F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
;DefaultDirName={autopf}\{#MyAppName}
DefaultDirName=C:\FacilinoOTA
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=C:\Users\Leo\Documents\GitHub\facilino_ota_gui\installers
OutputBaseFilename=facilino_ota_{#MyAppVersion}
SetupIconFile=C:\Users\Leo\Documents\GitHub\facilino_ota_gui\assets\facilino.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "catalan"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\desktop_webview_window_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\flutter_libserialport_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\flutter_secure_storage_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\screen_retriever_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\serialport.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\Webview2Loader.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Leo\Documents\GitHub\facilino_ota_gui\build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\*"