unit Defence;

interface

uses
  Windows, SysUtils, Classes, LauncherSettings, ProcessAPI;

{$I Definitions.inc}

// Поток ожидания завершения любого из процессов:
type
  TControlThread = class(TThread)
    protected
    Login: string;
    MainFormHandle: THandle;
    Handles: array of THandle;
    ProcessIDs: array of LongWord;
    SendProc: procedure;
    procedure Execute; override;
    procedure SendDeauthMessage;
  end;

  TBeaconThread = class(TThread)
    Interval: LongWord;
    MCHandle: THandle;
    protected
    SendProc: procedure;
    procedure Execute; override;
    procedure SendBeaconMessage;
  end;

  TEuristicDefence = class(TThread)
    MinecraftID: LongWord;
    MCHandle: THandle;
    Interval: LongWord;
    protected
    procedure Execute; override;
  end;

procedure StartDefence(MinecraftHandle, MainFormHandle: THandle; MinecraftID: LongWord; SendProcPtr: Pointer);
procedure StartEuristicDefence(MinecraftHandle: THandle; MinecraftID: LongWord; Interval: LongWord);
procedure StartBeacon(MinecraftHandle: THandle; Delay: LongWord; SendProcPtr: Pointer);
procedure StartProcess(CommandLine: string; out ProcessHandle: THandle; out ProcessID: LongWord);

{$IFDEF CONTROL_PROCESSES}
{$R Defence.res}
{$ENDIF}

implementation

function GetProcessId(Handle: THandle): LongWord; stdcall; external 'kernel32.dll';


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


procedure StartProcess(CommandLine: string; out ProcessHandle: THandle; out ProcessID: LongWord);
var
  ProcessInfo: _PROCESS_INFORMATION;
  StartupInfo: _STARTUPINFOA;
begin
  FillChar(StartupInfo, SizeOf(StartupInfo), #0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), #0);

  StartupInfo.wShowWindow := SW_SHOWNORMAL;

  CreateProcess(
                 nil,
                 PAnsiChar(CommandLine),
                 nil,
                 nil,
                 FALSE,
                 0,
                 nil,
                 nil,
                 StartupInfo,
                 ProcessInfo
                );

  CloseHandle(ProcessInfo.hThread);

  ProcessHandle := ProcessInfo.hProcess;
  ProcessID := ProcessInfo.dwProcessId;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure ExtractRes(ResName, FileName: string);
var
  Res: TResourceStream;
begin
  Res := TResourceStream.Create(hInstance, ResName, RT_RCDATA);
  Res.SaveToFile(FileName);
  Res.Free;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function Is64BitWindows: Boolean;
{$IFNDEF CPUX64}
var
  Wow64Process: Bool;
  IsWow64Process: function(ProcessHandle: THandle; out Wow64Process: BOOL): BOOL; stdcall;
{$ENDIF}
begin
{$IFDEF CPUX64}
  Result := True;
{$ELSE}
  IsWow64Process := GetProcAddress(GetModuleHandle(kernel32), 'IsWow64Process');
  Wow64Process := false;
  if Assigned(IsWow64Process) then Wow64Process := IsWow64Process(GetCurrentProcess, Wow64Process) and Wow64Process;

  Result := Wow64Process;
{$ENDIF}
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function FindOverlappings(const MainStr, SubStr: string): Word;
var
  TempStr: string;
  StartPos, SubStrLength: Word;
begin
  TempStr := MainStr;
  Result := 0;
  SubStrLength := Length(SubStr);

  StartPos := Pos(SubStr, TempStr);
  while StartPos <> 0 do
  begin
    Delete(TempStr, 1, StartPos + SubStrLength - 1);
    Inc(Result);
    StartPos := Pos(SubStr, TempStr);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure KillOverlappingProcesses(MinecraftID: LongWord);
var
  ProcessList: TProcessList;
  ProcessInfo: PROCESS_INFO;
  I, ProcessLength: Word;
begin

    GetProcessList(ProcessList);
    ProcessLength := Length(ProcessList);

    for I := 0 to ProcessLength - 1 do
    begin
      // Получаем всю информацию о каждом процессе:
      GetProcessInfo(ProcessList[I].th32ProcessID, ProcessInfo);

      // Приводим всё в нижний регистр:
      ProcessInfo.CommandLine := LowerCase(ProcessInfo.CommandLine);

      if ProcessInfo.ID = MinecraftID then Continue; // А не наш ли это процесс?

      if
        (ProcessInfo.ReservedMemory shr 20 > 64) // Процесс не наш, но ест память?
        and
        (
          (FindOverlappings(ProcessInfo.CommandLine, '.jar') > 2) // И джаров там больше двух?
          or
          (Pos('net.minecraft.client.main.main', ProcessInfo.CommandLine) <> 0) // И даже классы совпадают?!
          or
          (Pos('net.minecraft.launchwrapper.launch', ProcessInfo.CommandLine) <> 0) // Да там ещё и фордж!!
        )
      then
        KillTask(ProcessList[I].th32ProcessID); // Да провались оно всё, валим его, братан!
    end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure StartEuristicDefence(MinecraftHandle: THandle; MinecraftID: LongWord; Interval: LongWord);
var
  EuristicDefence: TEuristicDefence;
begin
  EuristicDefence := TEuristicDefence.Create(True);
  EuristicDefence.MCHandle := MinecraftHandle;
  EuristicDefence.MinecraftID := MinecraftID;
  EuristicDefence.Interval := Interval;
  EuristicDefence.FreeOnTerminate := True;
  EuristicDefence.Priority := tpLower;
  EuristicDefence.Resume;
end;



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


{ TEuristicDefence }

procedure TEuristicDefence.Execute;
begin
  inherited;
  while WaitForSingleObject(MCHandle, Interval) = WAIT_TIMEOUT do
    KillOverlappingProcesses(MinecraftID);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure StartDefence(MinecraftHandle, MainFormHandle: THandle; MinecraftID: LongWord; SendProcPtr: Pointer);
var
  ControlThread: TControlThread;
  Use64: Boolean;
  ProcessHandle: THandle;
  ProcessID: LongWord;
  ArrayCount: LongWord;
  MinecraftIDStr, LauncherIDStr: string;
begin
  ControlThread := TControlThread.Create(True);

  ControlThread.MainFormHandle := MainFormHandle;
  ShowWindow(ControlThread.MainFormHandle, SW_HIDE);

  MinecraftIDStr := IntToStr(MinecraftID);
  LauncherIDStr := IntToStr(GetCurrentProcessID);

  // Используем ли 64х-битные защитники:
  Use64 := Is64BitWindows;

  // Удаляем временные файлы:
  DeleteFile('Defence32.exe');
  DeleteFile('Defence64.exe');
  DeleteFile('HookLib32.dll');
  DeleteFile('HookLib64.dll');

  // Чистим данные потока:
  ArrayCount := 1;

  SetLength(ControlThread.Handles, ArrayCount);
  SetLength(ControlThread.ProcessIDs, ArrayCount);

  ControlThread.Handles[ArrayCount - 1] := MinecraftHandle;
  ControlThread.ProcessIDs[ArrayCount - 1] := MinecraftID;

  // Распаковываем и запускаем защитников:
  if not FileExists('Defence32.exe') then
    ExtractRes('DEFENCE32', 'Defence32.exe');

  if not FileExists('HookLib32.dll') then
    ExtractRes('HOOKLIB32', 'HookLib32.dll');

  StartProcess(
                'Defence32.exe ' +
                '<minecraft_id>' + MinecraftIDStr + '</minecraft_id>' +
                '<launcher_id>' + LauncherIDStr + '</launcher_id>' +
                '<primary_ip>' + PrimaryIP + '</primary_ip>' +
                '<secondary_ip>' + SecondaryIP + '</secondary_ip>' +
                '<port>' + IntToStr(ServerPort) + '</port>'
                {$IFDEF USE_INJECTORS}+ '<injectors>'{$ENDIF}
                {$IFDEF USE_WATCHDOG}+ '<wd>'{$ENDIF},
                ProcessHandle,
                ProcessID
               );

  Inc(ArrayCount);

  SetLength(ControlThread.Handles, ArrayCount);
  SetLength(ControlThread.ProcessIDs, ArrayCount);

  ControlThread.Handles[ArrayCount - 1] := ProcessHandle;
  ControlThread.ProcessIDs[ArrayCount - 1] := ProcessID;


  if Use64 then
  begin
    if not FileExists('Defence64.exe') then
      ExtractRes('DEFENCE64', 'Defence64.exe');

    if not FileExists('HookLib64.dll') then
      ExtractRes('HOOKLIB64', 'HookLib64.dll');

    StartProcess(
                  'Defence64.exe ' +
                  '<minecraft_id>' + MinecraftIDStr + '</minecraft_id>' +
                  '<launcher_id>' + LauncherIDStr + '</launcher_id>' +
                  '<primary_ip>' + PrimaryIP + '</primary_ip>' +
                  '<secondary_ip>' + SecondaryIP + '</secondary_ip>' +
                  '<port>' + IntToStr(ServerPort) + '</port>'
                  {$IFDEF USE_INJECTORS} + '<injectors>' {$ENDIF}
                  {$IFDEF USE_WATCHDOG} + '<wd>' {$ENDIF},
                  ProcessHandle,
                  ProcessID
                 );

    Inc(ArrayCount);

    SetLength(ControlThread.Handles, ArrayCount);
    SetLength(ControlThread.ProcessIDs, ArrayCount);

    ControlThread.Handles[ArrayCount - 1] := ProcessHandle;
    ControlThread.ProcessIDs[ArrayCount - 1] := ProcessID;
  end;


  // Запускаем поток:
  ControlThread.FreeOnTerminate := True;
  ControlThread.Priority := tpLower;
  ControlThread.SendProc := SendProcPtr;
  ControlThread.Resume;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


{ TControlProcessesThread }

procedure TControlThread.Execute;
var
  I: LongWord;
  ProcessesCount: Byte;
begin
  inherited;
  ProcessesCount := Length(Handles);

  // Ждём, пока кто-либо закроется:
  WaitForMultipleObjects(ProcessesCount, @Handles[0], FALSE, INFINITE);

  // Убиваем процесс майна:
  KillTask(ProcessIDs[0]);

  // Ждём, пока закроются инъекторы:
  if ProcessesCount > 1 then
    WaitForMultipleObjects(ProcessesCount - 1, @Handles[1], TRUE, INFINITE);

  // Закрываем процессы и хэндлы:
  for I := 0 to ProcessesCount - 1 do
  begin
    //KillTask(ProcessIDs[I]);
    CloseHandle(Handles[I]);
  end;

  DeleteFile('Defence32.exe');
  DeleteFile('Defence64.exe');
  DeleteFile('HookLib32.dll');
  DeleteFile('HookLib64.dll');

  Synchronize(SendDeauthMessage);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TControlThread.SendDeauthMessage;
begin
  SendProc;
  ShowWindow(Self.MainFormHandle, SW_SHOWNORMAL);
  SetForegroundWindow(Self.MainFormHandle);
end;



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// Запуск маячка:
procedure StartBeacon(MinecraftHandle: THandle; Delay: LongWord; SendProcPtr: Pointer);
var
  BeaconThread: TBeaconThread;
begin
  BeaconThread := TBeaconThread.Create(True);
  BeaconThread.MCHandle := MinecraftHandle;
  BeaconThread.Interval := Delay;
  BeaconThread.SendProc := SendProcPtr;
  BeaconThread.FreeOnTerminate := True;
  BeaconThread.Priority := tpLower;
  BeaconThread.Resume;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


{ TBeaconThread }

procedure TBeaconThread.Execute;
begin
  inherited;
  while WaitForSingleObject(MCHandle, Interval) = WAIT_TIMEOUT do
  begin
    Synchronize(SendBeaconMessage);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TBeaconThread.SendBeaconMessage;
begin
  SendProc;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


end.
