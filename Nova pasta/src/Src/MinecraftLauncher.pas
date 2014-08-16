unit MinecraftLauncher;

interface

uses
  Windows, Classes, cHash, SysUtils, Additions;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{$I Definitions.inc}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

type
  TMinecraftData = record
    Minepath: string;
    Java: string;
    JVMParams: string;
    Xms: string;
    Xmx: string;
    NativesPath: string;
    CP: string;
    MainClass: string;
    LogonInfo: string;
    GameVersion: string;
    GameDir: string;
    AssetsDir: string;
    AssetIndex: string;
    TweakClass: string;
  end;

type
  TMCProcessInfo = record
    Handle: THandle;
    ID: LongWord;
  end;

procedure ExecuteMinecraft(MinecraftData: TMinecraftData; out MCProcessInfo: TMCProcessInfo);
procedure LoadFileToMemory(FilePath: PAnsiChar; out Size: LongWord; out FilePtr: Pointer);
procedure GetFileList(Dir, Pattern: string; var FileList: string);
procedure GetFolderChecksum(Dir, Pattern: string; var Checksum: string);
function GetGameHash(const RootDirectory: string): string;
function GetGameFileList(const RootDirectory: string): string;
procedure FlushGameFolder(const Minepath: string);

implementation


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// Запуск Minecraft:
procedure ExecuteMinecraft(MinecraftData: TMinecraftData; out MCProcessInfo: TMCProcessInfo);
var
  lpDirectory, lpFile, lpParameters: PANSIChar;

  StartupInfo: _STARTUPINFOA;
  ProcessInfo: _PROCESS_INFORMATION;
begin
  with MinecraftData do
  begin
    lpDirectory := PAnsiChar(MinePath);
    lpParameters := PAnsiChar(
                               '-Dfml.ignoreInvalidMinecraftCertificates=true -Dfml.ignorePatchDiscrepancies=true ' +
                               '-Xms' + Xms + 'm ' +
                               '-Xmx' + Xmx + 'm ' +
                               JVMParams +
                               '-Djava.library.path="' + NativesPath + '" ' +
                               '-cp "' + CP + '" ' +
                               MainClass + ' ' +
                               LogonInfo + ' ' +
                               '--version ' + GameVersion + ' ' +
                               '--gameDir ' + GameDir + ' ' +
                               '--assetsDir ' + AssetsDir + ' ' +
                               '--assetIndex ' + AssetIndex + ' ' +
                               '--uuid 00000000-0000-0000-0000-000000000000 ' +
                               '--accessToken ${auth_access_token} ' +
                               '--userProperties {} ' +
                               '--userType ${user_type} ' +
                               TweakClass
                              );
    lpFile := PAnsiChar(Java);
  end;

  FillChar(StartupInfo, SizeOf(StartupInfo), #0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), #0);

  StartupInfo.wShowWindow := SW_SHOWNORMAL;
  StartupInfo.cb := SizeOf(StartupInfo);


  CreateProcess(nil, PAnsiChar(lpFile + ' ' + lpParameters), nil, nil, FALSE, 0, nil, lpDirectory, StartupInfo, ProcessInfo);
  MCProcessInfo.Handle := ProcessInfo.hProcess;
  MCProcessInfo.ID := ProcessInfo.dwProcessId;

  CloseHandle(ProcessInfo.hThread);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// Запуск Minecraft до 1.5.2 включительно:
procedure ExecuteMinecraftOLD(Minepath, Java, Xms, Xmx, Login, Pass: string; out MCProcessInfo: TMCProcessInfo);
var
  lpDirectory, lpFile, lpParameters: PANSIChar;

  StartupInfo: _STARTUPINFOA;
  ProcessInfo: _PROCESS_INFORMATION;
begin
  lpDirectory := PAnsiChar(MinePath + '\bin\');
  lpFile := PAnsiChar(Java + '\javaw.exe');
  lpParameters := PAnsiChar(' -Xms' + Xms + 'm ' +
                            '-Xmx' + Xmx + 'm ' +
                            '-Djava.library.path=natives ' +
                            '-cp "minecraft.jar;jinput.jar;lwjgl.jar;lwjgl_util.jar;" '+
                            'net.minecraft.client.Minecraft ' +
                            Login + ' ' + Pass);

  FillChar(StartupInfo, SizeOf(StartupInfo), #0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), #0);

  StartupInfo.wShowWindow := SW_SHOWNORMAL;
  StartupInfo.cb := SizeOf(StartupInfo);

  CreateProcess(nil, PAnsiChar(lpFile + ' ' + lpParameters), nil, nil, FALSE, 0, nil, lpDirectory, StartupInfo, ProcessInfo);
  MCProcessInfo.Handle := ProcessInfo.hProcess;
  MCProcessInfo.ID := ProcessInfo.dwProcessId;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure LoadFileToMemory(FilePath: PAnsiChar; out Size: LongWord; out FilePtr: Pointer);
var
  hFile: THandle;
  BytesRead: LongWord;
begin
  hFile := CreateFile(
                       FilePath,
                       GENERIC_READ,
                       FILE_SHARE_READ,
                       nil,
                       OPEN_EXISTING,
                       FILE_ATTRIBUTE_NORMAL,
                       0
                      );

  Size := GetFileSize(hFile, nil);
  GetMem(FilePtr, Size);
  ReadFile(hFile, FilePtr^, Size, BytesRead, nil);
  CloseHandle(hFile);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// Получение списка всех файлов и суммарного хэша:
procedure GetGameFileListAndHash(const RootDirectory: string; var FileList, SummaryHash: string);
begin
  FileList := GetGameFileList(RootDirectory);
  SummaryHash := GetGameHash(RootDirectory);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// Добавляйте сюда свои папки через GetFileList, если файлы из них нужно вставить в строку запуска:
function GetGameFileList(const RootDirectory: string): string;
var
  FileList: string;
begin
  GetFileList(RootDirectory + '\libraries\', '*.jar', FileList);
  GetFileList(RootDirectory + '\versions\', '*.jar', FileList);

  Result := FileList;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// Добавляйте сюда свои папки через GetFolderChecksum, если их нужно проверять:
function GetGameHash(const RootDirectory: string): string;
var
  SummaryHash: string;
  {$IFDEF SALTED_HASH}
  Salt: string;
  {$ENDIF}
begin
  GetFolderChecksum(RootDirectory + '\libraries\', '*.jar', SummaryHash);
  GetFolderChecksum(RootDirectory + '\versions\', '*.jar', SummaryHash);
  GetFolderChecksum(RootDirectory + '\mods\', '*.jar', SummaryHash);
  GetFolderChecksum(RootDirectory + '\mods\', '*.zip', SummaryHash);

  Result := MD5DigestToHex(CalcMD5(SummaryHash));

  {$IFDEF SALTED_HASH}
  Randomize;
  Salt := LowerCase(IntToHex(Random($FF), 2));
  Result := Salt + MD5DigestToHex(CalcMD5(Result + Salt));
  {$ENDIF}
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// Добавляйте сюда свои папки для удаления при перекачивании клиента:
procedure FlushGameFolder(const Minepath: string);
begin
  DeleteDirectory(Minepath + '\versions');
  DeleteDirectory(Minepath + '\libraries');
  DeleteDirectory(Minepath + '\mods');
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure GetFileList(Dir, Pattern: string; var FileList: string);
var
  SearchRec: TSearchRec;
begin
  if FindFirst(Dir + '*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        GetFileList(Dir + SearchRec.Name + '\', Pattern, FileList);
      end;
    until FindNext(SearchRec) <> 0;
  end;
  FindClose(SearchRec);

  if FindFirst(Dir + Pattern, faAnyFile xor faDirectory, SearchRec) = 0 then
  begin
    repeat
      FileList := FileList + Dir + SearchRec.Name + ';';
    until FindNext(SearchRec) <> 0;
  end;
  FindClose(SearchRec);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure GetFolderChecksum(Dir, Pattern: string; var Checksum: string);
var
  SearchRec: TSearchRec;

  Size: LongWord;
  FilePtr: pointer;
begin
  if FindFirst(Dir + '*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        GetFolderChecksum(Dir + SearchRec.Name + '\', Pattern, Checksum);
      end;
    until FindNext(SearchRec) <> 0;
  end;
  FindClose(SearchRec);

  if FindFirst(Dir + Pattern, faAnyFile xor faDirectory, SearchRec) = 0 then
  begin
    repeat
      LoadFileToMemory(PAnsiChar(Dir + SearchRec.Name), Size, FilePtr);
      Checksum := Checksum + MD5DigestToHex(CalcMD5(FilePtr^, Size));
      FreeMem(FilePtr);
    until FindNext(SearchRec) <> 0;
  end;
  FindClose(SearchRec);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


end.
