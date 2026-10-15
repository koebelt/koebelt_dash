; Windows installer for koebelt dash (Inno Setup 6).
;   iscc /DVersion=1.0.0 /DSource=<build\windows\x64\runner\Release> /DOutput=<dir> koebelt-dash.iss
#ifndef Version
  #define Version "0.0.0"
#endif

[Setup]
AppId={{5D0B7A3E-6C2E-4F7B-9A43-0E5B1C7A9D21}
AppName=koebelt dash
AppVersion={#Version}
AppVerName=koebelt dash {#Version}
AppPublisher=Thomas Koebel
AppPublisherURL=https://github.com/koebelt/koebelt_dash
AppSupportURL=https://github.com/koebelt/koebelt_dash/issues
DefaultDirName={autopf}\koebelt dash
DefaultGroupName=koebelt dash
DisableProgramGroupPage=yes
; Per-user by default, no admin prompt; the dialog offers all users.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#Output}
OutputBaseFilename=koebelt-dash-{#Version}-windows-x64-setup
SetupIconFile={#SourcePath}\..\..\..\apps\dash\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\koebelt_dash.exe
LicenseFile={#SourcePath}\..\..\..\LICENSE
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; In-app updates run this silently while the app is quitting.
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#Source}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\koebelt dash"; Filename: "{app}\koebelt_dash.exe"
Name: "{autodesktop}\koebelt dash"; Filename: "{app}\koebelt_dash.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\koebelt_dash.exe"; Description: "{cm:LaunchProgram,koebelt dash}"; Flags: nowait postinstall skipifsilent
