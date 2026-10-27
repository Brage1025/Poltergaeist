; Inno Setup script. Install Inno Setup (jrsoftware.org), run build.bat first,
; then open this file in Inno Setup and press Compile. The GitHub build
; replaces the AppVersion line below with the release version. The result is
; installer_output\Poltergaeist-Setup.exe

[Setup]
AppName=Poltergaeist
AppVersion=1.0
AppPublisher=Brage1025
DefaultDirName={autopf}\Poltergaeist
DefaultGroupName=Poltergaeist
OutputDir=installer_output
OutputBaseFilename=Poltergaeist-Setup
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\Poltergaeist.exe
InfoBeforeFile=NOTICE.txt
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
WizardStyle=modern
DisableProgramGroupPage=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked
Name: "startup"; Description: "Start Poltergaeist whenever I sign in to Windows (it cannot be paused; stop it in Task Manager or uninstall)"

[Files]
Source: "dist\Poltergaeist\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
Source: "LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Poltergaeist"; Filename: "{app}\Poltergaeist.exe"
Name: "{group}\Uninstall Poltergaeist"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Poltergaeist"; Filename: "{app}\Poltergaeist.exe"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Poltergaeist"; ValueData: """{app}\Poltergaeist.exe"""; Flags: uninsdeletevalue; Tasks: startup

[Run]
Filename: "{app}\Poltergaeist.exe"; Description: "Launch Poltergaeist now"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /im Poltergaeist.exe /f"; Flags: runhidden; RunOnceId: "StopPoltergaeist"

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\Poltergaeist"
