; Скрипт установщика для ARGUS
; Создан на основе документации Inno Setup

[Setup]
; Уникальный идентификатор приложения
AppId={{D3E5F2A1-4B8C-4D6E-9F0A-1B2C3D4E5F6A}
; Название и версия приложения
AppName=ARGUS
AppVersion=0.0.1
; Издатель
AppPublisher=VERTEX GROUP
; Папка установки по умолчанию (Program Files)
DefaultDirName={autopf}\ARGUS
; Название файла установщика
OutputBaseFilename=ARGUS_Setup
; Папка, куда будет сохранен установщик
OutputDir=installer_output
; Сжатие
Compression=lzma2
SolidCompression=yes
; Иконка для установщика (если есть .ico)
SetupIconFile=assets\icons\app_icon.ico

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
; Создание ярлыка на рабочем столе
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
; Создание ярлыка в меню Пуск
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Копируем все файлы из папки Release, включая все DLL плагинов
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Ярлыки в меню Пуск и на рабочем столе
Name: "{autoprograms}\ARGUS"; Filename: "{app}\argus_app.exe"
Name: "{autodesktop}\ARGUS"; Filename: "{app}\argus_app.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\ARGUS"; Filename: "{app}\argus_app.exe"; Tasks: quicklaunchicon

[Run]
; Запуск приложения после установки
Filename: "{app}\argus_app.exe"; Description: "{cm:LaunchProgram,ARGUS}"; Flags: nowait postinstall skipifsilent