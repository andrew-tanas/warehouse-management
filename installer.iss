[Setup]
; App Information
AppName=Warehouse Management (مصنع المهندس)
AppVersion=1.0.0
AppPublisher=El Mohandes Factory
AppCopyright=Copyright (C) 2026 El Mohandes Factory

; Default Installation Folder
DefaultDirName={autopf}\El Mohandes Factory\Warehouse Management
DefaultGroupName=El Mohandes Factory

; Output Installer Settings
OutputDir=.\Installer
OutputBaseFilename=WarehouseManagement_Setup
Compression=lzma2
SolidCompression=yes

; Provide a cleaner, more modern look
WizardStyle=modern
UninstallDisplayIcon={app}\warehouse_management.exe

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Copy the main executable
Source: "build\windows\x64\runner\Release\warehouse_management.exe"; DestDir: "{app}"; Flags: ignoreversion

; Copy all DLLs and data folders
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Start Menu Shortcut
Name: "{group}\Warehouse Management"; Filename: "{app}\warehouse_management.exe"
Name: "{group}\Uninstall Warehouse Management"; Filename: "{uninstallexe}"

; Desktop Shortcut
Name: "{autodesktop}\Warehouse Management"; Filename: "{app}\warehouse_management.exe"; Tasks: desktopicon

[Run]
; Launch the app after installation
Filename: "{app}\warehouse_management.exe"; Description: "{cm:LaunchProgram,Warehouse Management}"; Flags: nowait postinstall skipifsilent
