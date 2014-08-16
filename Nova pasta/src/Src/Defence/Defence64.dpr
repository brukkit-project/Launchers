program Defence64;


{$SETPEFLAGS $0001 or $0002 or $0004 or $0008 or $0010 or $0020 or $0200 or $0400 or $0800 or $1000}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$DEFINE SHOW_CONSOLE} // Показывать консоль с отладочными сообщениями

{$IFDEF SHOW_CONSOLE}
  //{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Windows,
  SysUtils,
  TlHelp32,
  CodepageAPI in 'CodepageAPI.pas',
  HookAPI in 'HookAPI.pas',
  OOPSocketsTCP in 'OOPSocketsTCP.pas',
  ProcessAPI in 'ProcessAPI.pas';

function GetCurrentProcessId: LongWord; stdcall; external 'kernel32.dll';

var
  UseWatchDog, UseInjectors: Boolean;

const
  {$IFDEF CPUX64}
  Lib: AnsiString = 'HookLib64.dll';
  {$ELSE}
  Lib: AnsiString = 'HookLib32.dll';
  {$ENDIF}


var
  CurrentDir: AnsiString;
  LauncherID, MinecraftID: LongWord;
  Login: AnsiString;
  PrimaryIP, SecondaryIP: AnsiString;
  Port: Word;
  CommandLine: AnsiString;
  Socket: TClientSocketTCP;
  Data: AnsiString;

  LauncherIDString, MinecraftIDString: AnsiString;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function GetXMLParameter(Data: AnsiString; Param: AnsiString): AnsiString;
var
  PosStart, Size: Word;
  StartParam, EndParam: AnsiString;
begin
  Result := '';
  StartParam := '<'+Param+'>';
  EndParam := '</'+Param+'>';
  PosStart := Pos(StartParam, Data);

  if PosStart = 0 then Exit;

  PosStart := PosStart + Length(StartParam);
  Size := Pos(EndParam, Data) - PosStart;
  Result := Copy(Data, PosStart, Size);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure KillTask(ProcessID: LongWord);
var
  ProcessHandle: THandle;
begin
  ProcessHandle := OpenProcess(PROCESS_TERMINATE, FALSE, ProcessID);
  TerminateProcess(ProcessHandle, 0);
  CloseHandle(ProcessHandle);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function IsProcLaunched(ProcessID: LongWord): Boolean;
var
  hSnap: THandle;
  PE: TProcessEntry32;
begin
  Result := false;
  PE.dwSize := SizeOf(PE);
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if not Process32First(hSnap, PE) then Exit;

  if PE.th32ProcessID = ProcessID then
  begin
    Result := true;
    Exit;
  end;

  while Process32Next(hSnap, PE) do
  begin
    if PE.th32ProcessID = ProcessID then
    begin
      Result := true;
      Exit;
    end;
  end;
  CloseHandle(hSnap);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function IsLibraryInList(const ModulesList: TModulesList; const DesiredModule: AnsiString): Boolean;
var
  I: LongWord;
begin
  Result := false;

  // Модули не успели подгрузиться?
  if ModulesList.Length = 0 then
  begin
    // Ну ничего, в следующей итерации мы его возьмём!
    Result := True; // Хрен с тобой, живи пока.
    Exit;
  end;

  for I := 0 to ModulesList.Length - 1 do
  begin
    if DesiredModule = ModulesList.Modules[I].ModuleName then
    begin
      Result := True;
      Break;
    end;
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure InjectAll;
var
  ProcessList: TProcessList;
  I: Cardinal;
  ProcessLen: Cardinal;
  ProcessInfo: PROCESS_INFO;
  CurrentID: LongWord;
begin
  CurrentID := GetCurrentProcessID;
  GetProcessList(ProcessList);
  ProcessLen := Length(ProcessList);

  EmptyWorkingSet(GetCurrentProcess);


  for I := 0 to ProcessLen - 1 do
  begin
    if ProcessList[I].th32ProcessID = MinecraftID then Continue;

    GetProcessInfo(ProcessList[I].th32ProcessID, ProcessInfo);

    // Если процесс не системный, не наш и ещё не инфицирован, то проводим инъекцию:
    if (ProcessInfo.ID <> CurrentID) and (ProcessInfo.SessionID > 0) then
    begin
      if ProcessInfo.Is64BitProcess then
      begin
        {$IFDEF CPUX64}
        if not IsLibraryInList(ProcessInfo.ModulesList, Lib) then
          if InjectDLL64(ProcessInfo.ID, PAnsiChar(CurrentDir + Lib)) then
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Успешно  -  x64  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    )
          {$ENDIF}
          else
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Ошибка  -  x64  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    );
          {$ENDIF}
        {$ELSE}
        Continue;
        {$ENDIF}
      end
      else
      begin
        {$IFDEF CPUX64}
        Continue;
        {$ELSE}
        if not IsLibraryInList(ProcessInfo.ModulesList, Lib) then
          if InjectDLL32(ProcessInfo.ID, PAnsiChar(CurrentDir + Lib)) then
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Успешно  -  x32  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    )
          {$ENDIF}
          else
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Ошибка  -  x32  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    );
          {$ENDIF}
        {$ENDIF}
      end;
    end;
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure UnloadAll;
var
  ProcessList: TProcessList;
  I: Cardinal;
  ProcessLen: Cardinal;
  ProcessInfo: PROCESS_INFO;
begin
  GetProcessList(ProcessList);
  ProcessLen := Length(ProcessList);

  for I := 0 to ProcessLen - 1 do
  begin
    GetProcessInfo(ProcessList[I].th32ProcessID, ProcessInfo);

    if ProcessInfo.SessionID > 0 then
    begin
      if ProcessInfo.Is64BitProcess then
      begin
        {$IFDEF CPUX64}
        if IsLibraryInList(ProcessInfo.ModulesList, Lib) then
          if UnloadDLL64(ProcessInfo.ID, PAnsiChar(Lib)) then
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Успешно выгружено -  x64  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    )
          {$ENDIF}
          else
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Ошибка  -  x64  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    );
          {$ENDIF}
        {$ELSE}
        Continue;
        {$ENDIF}
      end
      else
      begin
        {$IFDEF CPUX64}
        Continue;
        {$ELSE}
        if IsLibraryInList(ProcessInfo.ModulesList, Lib) then
          if UnloadDLL32(ProcessInfo.ID, PAnsiChar(Lib)) then
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Успешно выгружено -  x32  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    )
          {$ENDIF}
          else
          {$IFDEF SHOW_CONSOLE}
            WriteLn(
                     'Ошибка  -  x32  -  ',
                     ProcessInfo.ID,
                     '  -  ',
                     ProcessInfo.ProcessName
                    );
          {$ENDIF}
        {$ENDIF}
      end;
    end;
  end;
end;


var
  WideStrCommandLine: string;
  Buffer: Pointer;

  T1, T2, iCounterPerSec: Int64;
  Counter: Byte = 0;
begin
  SetConsoleTitle('Inject ''Em All');

  UnloadAll;

  CommandLine := GetCommandLineA;
{
  CommandLine := '<launcher_id>196</launcher_id>' +
                 '<minecraft_id>460</minecraft_id>' +
                 '<login>HoShiMin</login>' +
                 '<primary_ip>127.0.0.1</primary_ip>' +
                 '<secondary_ip>127.0.0.1</secondary_ip>' +
                 '<port>65533</port>' +
                 '<wd>' +
                 '<injectors>'
                 ;
}
  LauncherIDString := GetXMLParameter(CommandLine, 'launcher_id');
  MinecraftIDString := GetXMLParameter(CommandLine, 'minecraft_id');

  if Length(LauncherIDString) = 0 then Exit;
  if Length(MinecraftIDString) = 0 then Exit;

  LauncherID := StrToInt(StringToWideString(LauncherIDString, 0));
  MinecraftID := StrToInt(StringToWideString(MinecraftIDString, 0));
  Login := GetXMLParameter(CommandLine, 'login');
  PrimaryIP := GetXMLParameter(CommandLine, 'primary_ip');
  SecondaryIP := GetXMLParameter(CommandLine, 'secondary_ip');
  Port := StrToInt(StringToWideString(GetXMLParameter(CommandLine, 'port'), 0));

  WideStrCommandLine := StringToWideString(CommandLine, 0);

  UseWatchDog := Pos('<wd>', WideStrCommandLine) <> 0;
  UseInjectors := Pos('<injectors>', WideStrCommandLine) <> 0;

  if not (UseWatchDog or UseInjectors) then Exit;

  GetMem(Buffer, 512);
  GetCurrentDirectoryA(512, Buffer);
  CurrentDir := PAnsiChar(Buffer) + '\';

  while IsProcLaunched(LauncherID) and IsProcLaunched(MinecraftID) do
  begin
    QueryPerformanceFrequency(iCounterPerSec);
    QueryPerformanceCounter(T1);

    if UseInjectors then InjectAll;

    QueryPerformanceCounter(T2);
    {$IFDEF CPUX64}
    SetConsoleTitle(PWideChar('Inject ''Em All x64:  [' + IntToHex(Counter, 2) + '] - Цикл завершён за: ' + FormatFloat('0.0000', (T2 - T1) / iCounterPerSec) + ' сек.'));
    {$ELSE}
    SetConsoleTitle(PWideChar('Inject ''Em All x32:  [' + IntToHex(Counter, 2) + '] - Цикл завершён за: ' + FormatFloat('0.0000', (T2 - T1) / iCounterPerSec) + ' сек.'));
    {$ENDIF}
    Sleep(500);
    if Counter = $FF then Counter := 0;
    Inc(Counter);
  end;


  if UseWatchDog then
  begin
    KillTask(MinecraftID);

    Socket := TClientSocketTCP.Create;
    Socket.ConnectToServer(PAnsiChar(PrimaryIP), Port);

    if Socket.ConnectionStatus then
    begin
      Data := {$IFDEF SEND_SALT}GlobalSalt +{$ENDIF}'<wd><type>deauth</type><login>' + Login + '</login>';
      Socket.Send(PAnsiChar(Data), Length(Data));
    end
    else
    begin
      Socket.Disconnect;
      Socket.ConnectToServer(PAnsiChar(PrimaryIP), Port);
      if Socket.ConnectionStatus then
      begin
        Data := {$IFDEF SEND_SALT}GlobalSalt +{$ENDIF}'<wd><type>deauth</type><login>' + Login + '</login>';
        Socket.Send(PAnsiChar(Data), Length(Data));
      end;
    end;
    Socket.Destroy;
  end;

  UnloadAll;
end.
