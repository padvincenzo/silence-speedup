; Inno Setup script for Silence SpeedUp.
;
; Build it with installer\build-installer.ps1, which reads the version out of
; pubspec.yaml and passes it in — do not hardcode a version here.
;
;   iscc /DAppVersion=0.9.0 installer\silence-speedup.iss
;
; The whole Release folder is packaged, not just the executable: the bundled
; FFmpeg libraries sit beside it and the app will not start without them.

#ifndef AppVersion
  #error Pass the version with /DAppVersion=x.y.z (see build-installer.ps1)
#endif

#define AppName "Silence SpeedUp"
#define AppPublisher "Vincenzo Padula"
#define AppUrl "https://github.com/padvincenzo/silence-speedup"
#define AppExeName "silence_speedup.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
; Never change this GUID: Windows identifies the installation by it, and a new
; one would make an upgrade install alongside the old copy instead of over it.
AppId={{D011682E-5406-4416-9EFF-C1117D4E3A78}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} setup

DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=SilenceSpeedUp-{#AppVersion}-windows-x64-setup
SetupIconFile=..\assets\icons\icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}

; The bundled FFmpeg is a large part of the payload, so it is worth the slower
; compression to keep the download down.
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

; The FFmpeg build shipped with the app is x86_64 and needs Windows 10 or newer.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

; Offer a per-user install too, so the app can be installed without admin.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
; Matching the two languages the app itself speaks.
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Everything the build produced: the executable, the Flutter runtime, the
; plugin DLLs, the FFmpeg libraries and the asset bundle under data\.
Source: "{#BuildDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\*"; DestDir: "{app}"; Excludes: "{#AppExeName}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; The default scratch directory. Intermediate fragments are normally removed
; as each file finishes, but a run interrupted at the wrong moment can leave
; gigabytes behind, and nothing else ever writes here.
; Settings and any scratch directory the user moved elsewhere are left alone.
Type: filesandordirs; Name: "{localappdata}\Temp\silence-speedup"
