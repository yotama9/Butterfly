; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Butterfly"
#ifndef MyAppVersion
#define MyAppVersion "1.0"
#endif
#define MyAppPublisher "Linwood"
#define MyAppURL "https://www.linwood.dev"
#define MyAppExeName "butterfly.exe" 
#define BaseDirRelease "build\windows\runner\Release"
#define RunnerSourceDir "windows\runner"


[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{966CE504-4AA5-49C7-A63B-74BD6C073E5B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf64}\{#MyAppPublisher}\{#MyAppName}  
DefaultGroupName={#MyAppPublisher}\{#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
; Uncomment the following line to run in non administrative install mode (install for current user only.)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=build\windows
OutputBaseFilename=linwood-butterfly-windows-setup
SetupIconFile={#RunnerSourceDir}\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
Uninstallable=not WizardIsTaskSelected('portablemode')
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]     
Name: "desktopicon"; Description: "Create a Desktop shortcut"
Name: "startmenu"; Description: "Create a Start Menu entry"         
Name: "bfly"; Description: "Add Butterfly file association"
Name: "pdf"; Description: "Add PDF file association"
Name: "img"; Description: "Add Image file association"


[Files]
Source: "{#BaseDirRelease}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BaseDirRelease}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files



[Registry]
Root: HKA; Subkey: "Software\Classes\.bfly"; ValueType: string; ValueName: ""; ValueData: "{#MyAppName}-File"; Tasks: bfly; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-File"; ValueType: string; ValueName: ""; ValueData: "{#MyAppName}-File"; Tasks: bfly; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-File\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\data\flutter_assets\images\file.ico,0"
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-File\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".bfly"; ValueData: ""

Root: HKA; Subkey: "Software\Classes\.pdf\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}-PDF"; ValueData: ""; Tasks: pdf; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-PDF"; ValueType: string; ValueName: ""; ValueData: "{#MyAppName}-PDF"; Tasks: pdf; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-PDF\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\data\flutter_assets\images\file.ico,0"
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-PDF\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".pdf"; ValueData: ""

Root: HKA; Subkey: "Software\Classes\.jpg\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}-IMG"; ValueData: ""; Tasks: img; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".jpg"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\.jpeg\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}-IMG"; ValueData: ""; Tasks: img; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".jpeg"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\.png\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}-IMG"; ValueData: ""; Tasks: img; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".png"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\.gif\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}-IMG"; ValueData: ""; Tasks: img; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".gif"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\.bmp\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}-IMG"; ValueData: ""; Tasks: img; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".bmp"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\.ico\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}-IMG"; ValueData: ""; Tasks: img; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".ico"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-IMG"; ValueType: string; ValueName: ""; ValueData: "Open in {#MyAppName}"; Tasks: img; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-IMG\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\data\flutter_assets\images\file.ico,0"
Root: HKA; Subkey: "Software\Classes\{#MyAppName}-IMG\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Icons]
Name: "{group}\Visit Website"; Filename: "https://www.linwood.dev/"
Name: "{group}\Butterfly Documentation"; Filename: "https://docs.butterfly.linwood.dev/"
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
