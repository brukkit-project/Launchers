unit ProcessAPI;

interface

uses
  Windows, TlHelp32;

//------------------------------------------------------------------------------

function WideStringToString(const WideStringToConversion: WideString; CodePage: Word): AnsiString;
function StringToWideString(const AnsiStringToConversion: AnsiString; CodePage: Word): WideString;

// Преобразование ProcessID в Handle:
function ProcessIDToHandle(ProcessID: LongWord): THandle;

// Преобразование Handle в ProcessID:
function HandleToProcessID(ProcessHandle: THandle): LongWord;

// Результат функции GetProcessList - массив процессов:
type

  tagPROCESSENTRY32A = record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ProcessID: DWORD;       // this process
    th32DefaultHeapID: ULONG_PTR;
    th32ModuleID: DWORD;        // associated exe
    cntThreads: DWORD;
    th32ParentProcessID: DWORD; // this process's parent process
    pcPriClassBase: Longint;    // Base priority of process's threads
    dwFlags: DWORD;
    szExeFile: array[0..MAX_PATH - 1] of AnsiChar;// Path
  end;
  TProcessEntry32A = tagPROCESSENTRY32A;

  TProcessInfo = TProcessEntry32A;
  TProcessList = array of TProcessInfo;

// Информация о загруженноых модулях:
  TModuleInfo = record
    FullPath: AnsiString;      // Полный путь к модулю
    ModuleName: AnsiString;    // Имя модуля
    BaseAddress: UInt64;   // Базовый адрес загрузки (начало распакованного файла в ОЗУ)
    EntryAddress: UInt64;  // Точка входа
    SizeOfImage: Cardinal; // Размер образа в байтах
  end;

  TModulesList = record
    Length: Cardinal;               // Всего загруженных модулей
    Modules: array of TModuleInfo;  // Массив из информации о каждом модуле
  end;

// Структура результата функции GetProcessInfo:
  PROCESS_INFO = record
  // Идентификаторы:
    Handle: LongWord;         // Хэндл процесса при получении информации
    ID: UInt64;               // Идентификатор процесса
    InheritedFromID: UInt64;  // Идентификатор процесса-родителя
    SessionID: LongWord;      // Идентификатор сессии

  // Свойства процесса:
    Priority: UInt64;         // Приоритет процесса
    AffinityMask: UInt64;     // Маска соответствия процесса ядрам (число надо перевести в двоичный вид)

  // Разное:
    IsDebugged: Boolean;      // Отлаживается ли процесс
    ExitStatus: LongWord;     // Код выхода
    ThreadsCount: LongWord;   // Количество потоков
    HandlesCount: LongWord;   // Количество открытых хэндлов
    ReservedMemory: LongWord; // Зарезервированная память в байтах

  // Адреса:
    ImageBaseAddress: UInt64; // Адрес загрузки образа в оперативной памяти
    LdrAddress: UInt64;       // Адрес загрузочной информации
    PEBAddress: UInt64;       // Адрес блока окружения процесса (структура PEB)

  // Хэндлы ввода-вывода:
    ConsoleHandle: UInt64;    // Хэндл консоли
    StdInputHandle: UInt64;   // Стандартный хэндл ввода
    StdOutputHandle: UInt64;  // Стандартный хэндл вывода
    StdErrorHandle: UInt64;   // Стандартный хэндл вывода ошибок

  // Строковые параметры:
    ProcessName: AnsiString;           // Имя процесса
    CurrentDirectoryPath: AnsiString;  // Текущая папка
    ImagePathName: AnsiString;         // Имя образа процесса
    CommandLine: AnsiString;           // Командная строка

  // Список загруженных модулей:
    ModulesList: TModulesList;

  // Глобальные системные свойства:
    Is64BitProcess: BOOL; // 64х-битный ли процесс
  end;

// Получение подробной информации о процессе по его ID:
procedure GetProcessInfo(ProcessID: LongWord; out ProcessInfo: PROCESS_INFO; Process32_64CompatibleMode: Boolean = false);

// Запущен ли процесс ProcessName:
function IsProcessLaunched(ProcessName: AnsiString): boolean;

// Получить список запущенных процессов с краткой информацией:
procedure GetProcessList(out ProcessList: TProcessList);

// Получить информацию из TlHelp32 по ID процесса:
function GetTlHelp32ProcessInfo(ProcessID: LongWord): TProcessInfo; overload;

// Получить информацию из TlHelp32 по имени процесса:
function GetTlHelp32ProcessInfo(ProcessName: AnsiString): TProcessInfo; overload;

// Получить загрузку ЦП данным процессом (Delay ставить в пределах от 25 до 500, меньше - неточно, больше - ни к чему):
function GetProcessCPULoading(ProcessID: LongWord; Delay: Cardinal): Single;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

type
  Pointer64 = UInt64;
  Pointer32 = UInt;

// Структура для получения данных о процессе под Win32
  PROCESS_BASIC_INFORMATION = record
    ExitStatus: LongWord;
    PebBaseAddress: Pointer;
    AffinityMask: Cardinal;
    BasePriority: Integer;
    uUniqueProcessId: LongWord;
    uInheritedFromUniqueProcessId: LongWord;
  end;

  PROCESS_BASIC_INFORMATION64 = record
    ExitStatus: LongWord;
    Reserved0: LongWord;
    PebBaseAddress: UInt64;
    AffinityMask: UInt64;
    BasePriority: LongWord;
    Reserved1: LongWord;
    uUniqueProcessId: UInt64;
    uInheritedFromUniqueProcessId: UInt64;
  end;

  PROCESS_BASIC_INFORMATION_WOW64 = record
    Wow64PebAddress: UInt64;
  end;


  UCHAR = AnsiChar;

// Юникодная строка в Win32
  UNICODE_STRING = record
    Length: Word;
    MaximumLength: Word;
    Buffer: Pointer;
  end;

  UNICODE_STRING_WOW64 = record
    Length: Word;
    MaximumLength: Word;
    Buffer: Pointer32;
  end;

  UNICODE_STRING64 = record
    Length: Word;
    MaximumLength: Word;
    Fill: LongWord;
    Buffer: UInt64;
  end;

  PLDR_MODULE = Pointer;
  TModuleListEntry = record
    ForwardLDRModule: PLDR_MODULE;
    BackwardLDRModule: PLDR_MODULE;
  end;

  LDR_MODULE = record
    InLoadModuleOrderList: TModuleListEntry;
    InMemoryModuleOrderList: TModuleListEntry;
    InInitializationModuleOrderList: TModuleListEntry;
    BaseAddress: Pointer;
    EntryPoint: Pointer;
    SizeOfImage: UInt;
    FullDLLName: UNICODE_STRING;
    BaseDLLName: UNICODE_STRING;
    Flags: ULONG;
    LoadCount: Short;
    TlsIndex: Short;
    TimeDateStamp: ULONG;
  end;

  PEB_LDR_DATA = record
    Size: ULong;
    Initialized: Boolean;
    SsHandle: Pointer;
    InLoadModuleOrderList: TModuleListEntry;
    InMemoryModuleOrderList: TModuleListEntry;
    InInitializationModuleOrderList: TModuleListEntry;
  end;
  PPEB_LDR_DATA = ^PEB_LDR_DATA;

// LDR WOW64:

  PLDR_MODULE_WOW64 = Pointer32;
  TModuleListEntryWow64 = record
    ForwardLDRModule: PLDR_MODULE_WOW64;
    BackwardLDRModule: PLDR_MODULE_WOW64;
  end;

  LDR_MODULE_WOW64 = record
    InLoadModuleOrderList: TModuleListEntryWow64;
    InMemoryModuleOrderList: TModuleListEntryWow64;
    InInitializationModuleOrderList: TModuleListEntryWow64;
    BaseAddress: Pointer32;
    EntryPoint: Pointer32;
    SizeOfImage: UInt;
    FullDLLName: UNICODE_STRING_WOW64;
    BaseDLLName: UNICODE_STRING_WOW64;
    Flags: ULONG;
    LoadCount: Short;
    TlsIndex: Short;
    TimeDateStamp: ULONG;
  end;

  PEB_LDR_DATA_WOW64 = record
    Size: ULong;
    Initialized: Boolean;
    SsHandle: Pointer32;
    InLoadModuleOrderList: TModuleListEntryWow64;
    InMemoryModuleOrderList: TModuleListEntryWow64;
    InInitializationModuleOrderList: TModuleListEntryWow64;
  end;
  PPEB_LDR_DATA_WOW64 = Pointer32;


// LDR x64:

  PLDR_MODULE64 = UInt64;
  TModuleListEntry64 = record
    ForwardLDRModule: PLDR_MODULE64;
    BackwardLDRModule: PLDR_MODULE64;
  end;

  LDR_MODULE64 = record
    InLoadModuleOrderList: TModuleListEntry64;
    InMemoryModuleOrderList: TModuleListEntry64;
    InInitializationModuleOrderList: TModuleListEntry64;
    BaseAddress: Pointer64;
    EntryPoint: Pointer64;
    SizeOfImage: ULong;
    FullDLLName: UNICODE_STRING64;
    BaseDLLName: UNICODE_STRING64;
    Flags: ULONG;
    LoadCount: Short;
    TlsIndex: Short;
    TimeDateStamp: ULONG;
  end;

  PEB_LDR_DATA64 = record
    Size: UInt;
    Initialized: Boolean;
    SsHandle: UInt64;
    InLoadModuleOrderList: TModuleListEntry64;
    InMemoryModuleOrderList: TModuleListEntry64;
    InInitializationModuleOrderList: TModuleListEntry64;
  end;


  PEB = record
    InheritedAddressSpace: UCHAR;
    ReadImageFileExecOptions: UCHAR;
    BeingDebugged: Boolean;
    BitField: UChar;
    Mutant: Pointer;
    ImageBaseAddress: Pointer;
    Ldr: PPEB_LDR_DATA;
    ProcessParameters: Pointer;
    Reserved0: array [0..103] of Byte;
    Reserved1: array [0..51] of Pointer;
    PostProcessInitRoutine: Pointer;
    Reserved2: array [0..127] of Byte;
    Reserved3: Pointer;
    SessionID: LongWord;
  end;

  PEB_WOW64 = record
    InheritedAddressSpace: UCHAR;
    ReadImageFileExecOptions: UCHAR;
    BeingDebugged: Boolean;
    BitField: UChar;
    Mutant: Pointer32;
    ImageBaseAddress: Pointer32;
    Ldr: PPEB_LDR_DATA_WOW64;
    ProcessParameters: Pointer32;
    Reserved0: array [0..103] of Byte;
    Reserved1: array [0..51] of Pointer32;
    PostProcessInitRoutine: Pointer32;
    Reserved2: array [0..127] of Byte;
    Reserved3: Pointer32;
    SessionID: LongWord;
  end;

  PEB64 = record
    InheritedAddressSpace: Byte;
    ReadImageFileExecOptions: Byte;
    BeingDebugged: Boolean;
    BitField: Byte;
    Reserved0: LongWord;
    Mutant: UInt64;
    ImageBaseAddress: UInt64;
    Ldr: UInt64;
    ProcessParameters: UInt64;
    Reserved1: array [0..519] of Byte;
    PostProcessInitRoutine: UInt64;
    Reserved2: array [0..135] of Byte;
    SessionID: LongWord;
  end;

// Структура RTL_USER_PROCESS_PARAMETERS под Win32
  RTL_USER_PROCESS_PARAMETERS = record
    MaximumLength: LongWord;
    Length: LongWord;
    Flags: LongWord;
    DebugFlags: LongWord;
    ConsoleHandle: THandle;
    ConsoleFlags: LongWord;
    StdInputHandle: THandle;
    StdOutputHandle: THandle;
    StdErrorHandle: THandle;
    CurrentDirectoryPath: UNICODE_STRING;
    CurrentDirectoryHandle: THandle;
    DllPath: UNICODE_STRING;
    ImagePathName: UNICODE_STRING;
    CommandLine: UNICODE_STRING;
  end;

  RTL_USER_PROCESS_PARAMETERS_WOW64 = record
    MaximumLength: LongWord;
    Length: LongWord;
    Flags: LongWord;
    DebugFlags: LongWord;
    ConsoleHandle: LongWord;
    ConsoleFlags: LongWord;
    StdInputHandle: LongWord;
    StdOutputHandle: LongWord;
    StdErrorHandle: LongWord;
    CurrentDirectoryPath: UNICODE_STRING_WOW64;
    CurrentDirectoryHandle: LongWord;
    DllPath: UNICODE_STRING_WOW64;
    ImagePathName: UNICODE_STRING_WOW64;
    CommandLine: UNICODE_STRING_WOW64;
  end;

  RTL_USER_PROCESS_PARAMETERS64 = record
    MaximumLength: LongWord;
    Length: LongWord;
    Flags: LongWord;
    DebugFlags: LongWord;
    ConsoleHandle: UInt64;
    ConsoleFlags: LongWord;
    Reserved: LongWord;
    StdInputHandle: UInt64;
    StdOutputHandle: UInt64;
    StdErrorHandle: UInt64;
    CurrentDirectoryPath: UNICODE_STRING64;
    CurrentDirectoryHandle: UInt64;
    DllPath: UNICODE_STRING64;
    ImagePathName: UNICODE_STRING64;
    CommandLine: UNICODE_STRING64;
  end;


  VM_COUNTERS = record
    PeakVirtualSize: LongWord;
    VirtualSize: LongWord;
    PageFaultCount: LongWord;
    PeakWorkingSetSize: LongWord;
    WorkingSetSize: LongWord;
    QuotaPeakPagedPoolUsage: LongWord;
    QuotaPagedPoolUsage: LongWord;
    QuotaPeakNonPagedPoolUsage: LongWord;
    QuotaNonPagedPoolUsage: LongWord;
    PagefileUsage: LongWord;
    PeakPagefileUsage: LongWord;
  end;

  PROCESSINFOCLASS = (
    ProcessBasicInformation,
    ProcessQuotaLimits,
    ProcessIoCounters,
    ProcessVmCounters,
    ProcessTimes,
    ProcessBasePriority,
    ProcessRaisePriority,
    ProcessDebugPort,
    ProcessExceptionPort,
    ProcessAccessToken,
    ProcessLdtInformation,
    ProcessLdtSize,
    ProcessDefaultHardErrorMode,
    ProcessIoPortHandlers,          // Note: this is kernel mode only
    ProcessPooledUsageAndLimits,
    ProcessWorkingSetWatch,
    ProcessUserModeIOPL,
    ProcessEnableAlignmentFaultFixup,
    ProcessPriorityClass,
    ProcessWx86Information,
    ProcessHandleCount,
    ProcessAffinityMask,
    ProcessPriorityBoost,
    ProcessDeviceMap,
    ProcessSessionInformation,
    ProcessForegroundInformation,
    ProcessWow64Information,
    ProcessImageFileName,
    ProcessLUIDDeviceMapsEnabled,
    ProcessBreakOnTermination,
    ProcessDebugObjectHandle,
    ProcessDebugFlags,
    ProcessHandleTracing,
    ProcessIoPriority,
    ProcessExecuteFlags,
    ProcessTlsInformation,
    ProcessCookie,
    ProcessImageInformation,
    ProcessCycleTime,
    ProcessPagePriority,
    ProcessInstrumentationCallback,
    ProcessThreadStackAllocation,
    ProcessWorkingSetWatchEx,
    ProcessImageFileNameWin32,
    ProcessImageFileMapping,
    ProcessAffinityUpdateMode,
    ProcessMemoryAllocationMode,
    ProcessGroupInformation,
    ProcessTokenVirtualizationEnabled,
    ProcessOwnerInformation,
    ProcessWindowInformation,
    ProcessHandleInformation,
    ProcessMitigationPolicy,
    ProcessDynamicFunctionTableInformation,
    ProcessHandleCheckingMode,
    ProcessKeepAliveCount,
    ProcessRevokeFileHandles,
    ProcessWorkingSetControl,
    ProcessHandleTable,
    ProcessCheckStackExtentsMode,
    ProcessCommandLineInformation,
    ProcessProtectionInformation,
    MaxProcessInfoClass
  );

  SYSTEMINFOCLASS = (
    SystemBasicInformation,
    Unknown,
    SystemPerformanceInformation,
    SystemInformationClassMax
  );

  NTStatus = LongWord;

  SIZE_T = Cardinal;

  _PROCESS_MEMORY_COUNTERS_EX = record
    cb: LongWord;
    PageFaultCount: LongWord;
    PeakWorkingSetSize: SIZE_T;
    WorkingSetSize: SIZE_T;
    QuotaPeakPagedPoolUsage: SIZE_T;
    QuotaPagedPoolUsage: SIZE_T;
    QuotaPeakNonPagedPoolUsage: SIZE_T;
    QuotaNonPagedPoolUsage: SIZE_T;
    PagefileUsage: SIZE_T;
    PeakPagefileUsage: SIZE_T;
    PrivateUsage: SIZE_T;
  end;

function NtQueryInformationProcess(
                                    ProcessHandle: THandle;
                                    ProcessInformationClass: PROCESSINFOCLASS;
                                    ProcessInformation: Pointer;
                                    ProcessInformationLength: LongWord;
                                    out ReturnLength: LongWord
                                   ): NTStatus; stdcall; external 'ntdll.dll';

function NtReadVirtualMemory(
                              ProcessHandle: THandle;
                              BaseAddress: Pointer;
                              Buffer: Pointer;
                              BufferLength: LongWord;
                              out ReturnLength: LongWord
                             ): BOOL; stdcall; external 'ntdll.dll';


function NtQuerySystemInformation(
                                   SystemInformationClass: SYSTEMINFOCLASS;
                                   SystemInformation: Pointer;
                                   SystemInformationLength: ULONG;
                                   ReturnLength: PDWORD
                                  ): NTStatus; stdcall; external 'ntdll.dll';


// 64х-битные аналоги:
var
  NtWow64QueryInformationProcess64: function(
                                           ProcessHandle: THandle;
                                           ProcessInformationClass: PROCESSINFOCLASS;
                                           ProcessInformation: Pointer;
                                           ProcessInformationLength: LongWord;
                                           out ReturnLength: UInt64
                                          ): NTStatus; stdcall;

  NtWow64ReadVirtualMemory64: function(
                                     ProcessHandle: THandle;
                                     BaseAddress: UInt64;
                                     Buffer: Pointer;
                                     BufferLength: UInt64;
                                     out ReturnLength: UInt64
                                    ): BOOL; stdcall;

  IsWow64Process: function(ProcessHandle: THandle; out Wow64Process: BOOL): BOOL; stdcall;

procedure GetProcessMemoryInfo(ProcessHandle: THandle; out ProcessMemoryCounters: _PROCESS_MEMORY_COUNTERS_EX; ProcessMemoryCountersSize: LongWord); stdcall; external 'psapi.dll';

function GetProcessId(Handle: THandle): LongWord; stdcall; external 'kernel32.dll';

function Process32FirstA(hSnapshot: THandle; var lppe: TProcessEntry32A): BOOL; stdcall; external 'kernel32.dll' name 'Process32First';
function Process32NextA(hSnapshot: THandle; var lppe: TProcessEntry32A): BOOL; stdcall; external 'kernel32.dll' name 'Process32Next';

function GetProcessHandleCount(ProcessHandle: THandle; CounterPtr: Pointer): LongBool; stdcall; external 'kernel32.dll';

implementation

var
  IsFunctionsAreInited: BOOL = FALSE;
  Is64BitWindows: BOOL = FALSE;

//------------------------------------------------------------------------------

function ProcessIDToHandle(ProcessID: LongWord): THandle;
begin
  Result := OpenProcess(
                         PROCESS_ALL_ACCESS,
                         FALSE,
                         ProcessID
                        );
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function HandleToProcessID(ProcessHandle: THandle): LongWord;
begin
  Result := GetProcessID(ProcessHandle);
end;

//------------------------------------------------------------------------------

function WideStringToString(const WideStringToConversion: WideString; CodePage: Word): AnsiString;
var
  L: Integer;
begin
  if WideStringToConversion = '' then
    Result := ''
  else
  begin
    L := WideCharToMultiByte(
                              CodePage,
                              WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR,
                              @WideStringToConversion[1],
                              -1,
                              nil,
                              0,
                              nil,
                              nil
                            );

    SetLength(Result, L - 1);

    if L > 1 then
      WideCharToMultiByte(
                           CodePage,
                           WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR,
                           @WideStringToConversion[1],
                           -1,
                           @Result[1],
                           L - 1,
                           nil,
                           nil
                         );
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function StringToWideString(const AnsiStringToConversion: AnsiString; CodePage: Word): WideString;
var
  L: Integer;
begin
  if AnsiStringToConversion = '' then
    Result := ''
  else
  begin
    L := MultiByteToWideChar(
                              CodePage,
                              MB_PRECOMPOSED,
                              PAnsiChar(@AnsiStringToConversion[1]),
                              -1,
                              nil,
                              0
                            );

    SetLength(Result, L - 1);

    if L > 1 then
      MultiByteToWideChar(
                           CodePage,
                           MB_PRECOMPOSED,
                           PAnsiChar(@AnsiStringToConversion[1]),
                           -1,
                           PWideChar(@Result[1]),
                           L - 1
                         );
  end;
end;

//------------------------------------------------------------------------------

const
  SE_DEBUG_NAME = 'SeDebugPrivilege';

// Установка привилегий
function NTSetPrivilege(sPrivilege: AnsiString; bEnabled: Boolean): Boolean;
var
  hToken: THandle;
  TokenPriv: TOKEN_PRIVILEGES;
  PrevTokenPriv: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
begin
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
  begin
    if LookupPrivilegeValueA(nil, PAnsiChar(sPrivilege), TokenPriv.Privileges[0].Luid) then
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

//------------------------------------------------------------------------------

function _Is64BitWindows: BOOL;
{$IFNDEF CPUX64}
var
  Wow64Process: Bool;
{$ENDIF}
begin
  IsWow64Process := GetProcAddress(GetModuleHandle(kernel32), 'IsWow64Process');
{$IFDEF CPUX64}
  Result := True;
{$ELSE}
  Wow64Process := false;
  if Assigned(IsWow64Process) then Wow64Process := IsWow64Process(GetCurrentProcess, Wow64Process) and Wow64Process;

  Result := Wow64Process;
{$ENDIF}
end;

//------------------------------------------------------------------------------

procedure _InitFunctions;
var
  NtdllHandle: THandle;
begin
  Is64BitWindows := _Is64BitWindows;
  if Is64BitWindows then
  begin
    // Ищем адреса 64х-битных функций:
    NtdllHandle := GetModuleHandleA('ntdll.dll');
    {$IFDEF CPUX64}
    NtWow64QueryInformationProcess64 := GetProcAddress(NtdllHandle, 'NtQueryInformationProcess');
    NtWow64ReadVirtualMemory64 := GetProcAddress(NtdllHandle, 'NtReadVirtualMemory');
    {$ELSE}
    NtWow64QueryInformationProcess64 := GetProcAddress(NtdllHandle, 'NtWow64QueryInformationProcess64');
    NtWow64ReadVirtualMemory64 := GetProcAddress(NtdllHandle, 'NtWow64ReadVirtualMemory64');
    {$ENDIF}
  end
  else
  begin
    Is64BitWindows := false;
  end;

  IsFunctionsAreInited := TRUE;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure _GetModulesList32(ProcessHandle: THandle; LDRAddress: Pointer; out Modules: TModulesList);
var
  LdrInfo: PEB_LDR_DATA;
  ModuleInfo: LDR_MODULE;

  StringBuffer: Pointer;
  StringPointer: Pointer;
  StringLength: Word;

  BytesRead: LongWord;
begin
// Читаем PEB_LDR_DATA:
  NtReadVirtualMemory(ProcessHandle, LDRAddress, @LdrInfo, SizeOf(LdrInfo), BytesRead);

// Читаем LDR_MODULE_INFO:
  NtReadVirtualMemory(ProcessHandle, LdrInfo.InLoadModuleOrderList.ForwardLDRModule, @ModuleInfo, SizeOf(ModuleInfo), BytesRead);

  FillChar(Modules, SizeOf(Modules), #0);

  while (LdrInfo.InLoadModuleOrderList.ForwardLDRModule <> nil) and (BytesRead <> 0) and (ModuleInfo.BaseAddress <> nil) do
  begin
    Inc(Modules.Length);
    SetLength(Modules.Modules, Modules.Length);

  // Получаем численную информацию:
    with Modules do
    begin
      Modules[Length - 1].BaseAddress := UInt64(ModuleInfo.BaseAddress);
      Modules[Length - 1].EntryAddress := UInt64(ModuleInfo.EntryPoint);
      Modules[Length - 1].SizeOfImage := UInt64(ModuleInfo.SizeOfImage);
    end;

  // Читаем полный путь:
    StringPointer := ModuleInfo.FullDLLName.Buffer;
    StringLength := ModuleInfo.FullDLLName.Length;
    GetMem(StringBuffer, StringLength + 2);
    FillChar(StringBuffer^, StringLength + 2, #0);
    NtReadVirtualMemory(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
    Modules.Modules[Modules.Length - 1].FullPath := WideStringToString(PWideChar(StringBuffer), 0);
    FreeMem(StringBuffer);

  // Читаем имя библиотеки:
    StringPointer := ModuleInfo.BaseDLLName.Buffer;
    StringLength := ModuleInfo.BaseDLLName.Length;
    GetMem(StringBuffer, StringLength + 2);
    FillChar(StringBuffer^, StringLength + 2, #0);
    NtReadVirtualMemory(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
    Modules.Modules[Modules.Length - 1].ModuleName := WideStringToString(PWideChar(StringBuffer), 0);
    FreeMem(StringBuffer);

  // Читаем следующий в списке LDR_MODULE_INFO:
    NtReadVirtualMemory(ProcessHandle, ModuleInfo.InLoadModuleOrderList.ForwardLDRModule, @ModuleInfo, SizeOf(ModuleInfo), BytesRead);
  end;
end;


procedure _GetProcessInfo32(ProcessID: LongWord; out ProcessInfo: PROCESS_INFO);
var
  ProcessHandle: THandle;
  ProcessBasicInfo: PROCESS_BASIC_INFORMATION;
  PEBInfo: PEB;
  UserParameters: RTL_USER_PROCESS_PARAMETERS;

  BytesRead: UInt;
  ReturnLength: UInt;

  //ReturnStatus: LongWord;

  _Is64BitProcess: BOOL;

  CurrentDirectory: AnsiString;
  ImageName: AnsiString;
  CmdLine: AnsiString;

  StringBuffer: Pointer;
  StringPointer: Pointer;
  StringLength: Word;

  TlHelp32Info: TProcessInfo;
  LocalHandlesCount: LongWord;

  MemoryCounters: _PROCESS_MEMORY_COUNTERS_EX;
begin
  FillChar(ProcessBasicInfo, SizeOf(ProcessBasicInfo), #0);
  FillChar(PEBInfo, SizeOf(PEBInfo), #0);
  FillChar(UserParameters, SizeOf(UserParameters), #0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), #0);

  NTSetPrivilege(SE_DEBUG_NAME, true);
  ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION + PROCESS_VM_READ, FALSE, ProcessID);

// Получаем разрядность процесса:
  _Is64BitProcess := FALSE; // Процессы заведомо 32х-битные

// Заполняем PROCESS_BASIC_INFORMATION:
  NtQueryInformationProcess(ProcessHandle, ProcessBasicInformation, @ProcessBasicInfo, SizeOf(ProcessBasicInfo), ReturnLength);
// Читаем PEB:
  NtReadVirtualMemory(ProcessHandle, ProcessBasicInfo.PebBaseAddress, @PEBInfo, SizeOf(PEBInfo), BytesRead);
// Читаем RTL_USER_PROCESS_PARAMETERS:
  NtReadVirtualMemory(ProcessHandle, PEBInfo.ProcessParameters, @UserParameters, SizeOf(UserParameters), BytesRead);

// Получаем список загруженных модулей:
  _GetModulesList32(ProcessHandle, PEBInfo.Ldr, ProcessInfo.ModulesList);

// Читаем строки:
  // CommandLine:
  StringPointer := UserParameters.CommandLine.Buffer;
  StringLength := UserParameters.CommandLine.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtReadVirtualMemory(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  CmdLine := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

  // ImageFilePath:
  StringPointer := UserParameters.ImagePathName.Buffer;
  StringLength := UserParameters.ImagePathName.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtReadVirtualMemory(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  ImageName := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

  //CurrentDirectoryPath:
  StringPointer := UserParameters.CurrentDirectoryPath.Buffer;
  StringLength := UserParameters.CurrentDirectoryPath.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtReadVirtualMemory(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  CurrentDirectory := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

// Получаем информацию о памяти процесса:
  FillChar(MemoryCounters, SizeOf(MemoryCounters), #0);
  GetProcessMemoryInfo(ProcessHandle, MemoryCounters, SizeOf(MemoryCounters));

// Получаем информацию из TlHelp32:
  FillChar(TlHelp32Info, SizeOf(TlHelp32Info), #0);
  TlHelp32Info := GetTlHelp32ProcessInfo(ProcessID);

// Получаем количество открытых хэндлов:
  GetProcessHandleCount(ProcessHandle, @LocalHandlesCount);

  // Возвращаем результат:
  with ProcessInfo do
  begin
    Handle := ProcessHandle;
    ID := ProcessBasicInfo.uUniqueProcessId;
    InheritedFromID := ProcessBasicInfo.uInheritedFromUniqueProcessId;
    SessionID := PEBInfo.SessionID;

    Priority := ProcessBasicInfo.BasePriority;
    AffinityMask := ProcessBasicInfo.AffinityMask;

    IsDebugged := PEBInfo.BeingDebugged;
    ExitStatus := ProcessBasicInfo.ExitStatus;
    ThreadsCount := TlHelp32Info.cntThreads;
    HandlesCount := LocalHandlesCount;
    ReservedMemory := MemoryCounters.PrivateUsage;

    ImageBaseAddress := UInt64(PEBInfo.ImageBaseAddress);
    LdrAddress := UInt64(PEBInfo.Ldr);
    PEBAddress := UInt64(ProcessBasicInfo.PebBaseAddress);

    ConsoleHandle := UserParameters.ConsoleHandle;
    StdInputHandle := UserParameters.StdInputHandle;
    StdOutputHandle := UserParameters.StdOutputHandle;
    StdErrorHandle := UserParameters.StdErrorHandle;

    ProcessName := TlHelp32Info.szExeFile;
    CurrentDirectoryPath := CurrentDirectory;
    ImagePathName := ImageName;
    CommandLine := CmdLine;

    Is64BitProcess := _Is64BitProcess;
  end;

  CloseHandle(ProcessHandle);
end;

//------------------------------------------------------------------------------

procedure _GetModulesList64(ProcessHandle: THandle; LDRAddress: UInt64; out Modules: TModulesList);
var
  LdrInfo: PEB_LDR_DATA64;
  ModuleInfo: LDR_MODULE64;

  StringBuffer: Pointer;
  StringPointer: UInt64;
  StringLength: Word;

  BytesRead: UInt64;
begin
// Читаем PEB_LDR_DATA:
  NtWow64ReadVirtualMemory64(ProcessHandle, LDRAddress, @LdrInfo, SizeOf(LdrInfo), BytesRead);
// Читаем LDR_MODULE_INFO:
  NtWow64ReadVirtualMemory64(ProcessHandle, UInt64(LdrInfo.InLoadModuleOrderList.ForwardLDRModule), @ModuleInfo, SizeOf(ModuleInfo), BytesRead);

  FillChar(Modules, SizeOf(Modules), #0);

  while (LdrInfo.InLoadModuleOrderList.ForwardLDRModule <> 0) and (BytesRead <> 0) and (ModuleInfo.BaseAddress <> 0) do
  begin
    Inc(Modules.Length);
    SetLength(Modules.Modules, Modules.Length);

  // Получаем численную информацию:
    with Modules do
    begin
      Modules[Length - 1].BaseAddress := ModuleInfo.BaseAddress;
      Modules[Length - 1].EntryAddress := ModuleInfo.EntryPoint;
      Modules[Length - 1].SizeOfImage := ModuleInfo.SizeOfImage;
    end;

  // Читаем полный путь:
    StringPointer := ModuleInfo.FullDLLName.Buffer;
    StringLength := ModuleInfo.FullDLLName.Length;
    GetMem(StringBuffer, StringLength + 2);
    FillChar(StringBuffer^, StringLength + 2, #0);
    NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
    Modules.Modules[Modules.Length - 1].FullPath := WideStringToString(PWideChar(StringBuffer), 0);
    FreeMem(StringBuffer);

  // Читаем имя библиотеки:
    StringPointer := ModuleInfo.BaseDLLName.Buffer;
    StringLength := ModuleInfo.BaseDLLName.Length;
    GetMem(StringBuffer, StringLength + 2);
    FillChar(StringBuffer^, StringLength + 2, #0);
    NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
    Modules.Modules[Modules.Length - 1].ModuleName := WideStringToString(PWideChar(StringBuffer), 0);
    FreeMem(StringBuffer);

  // Читаем следующий в списке LDR_MODULE_INFO:
    NtWow64ReadVirtualMemory64(ProcessHandle, ModuleInfo.InLoadModuleOrderList.ForwardLDRModule, @ModuleInfo, SizeOf(ModuleInfo), BytesRead);
  end;
end;

procedure _GetProcessInfo64(ProcessID: LongWord; out ProcessInfo: PROCESS_INFO);
var
  ProcessHandle: THandle;
  ProcessBasicInfo: PROCESS_BASIC_INFORMATION64;
  PEBInfo: PEB64;
  UserParameters: RTL_USER_PROCESS_PARAMETERS64;
  BytesRead: UInt64;
  ReturnLength: UInt64;

  //ReturnStatus: LongWord;

  _Is64BitProcess: BOOL;

  CurrentDirectory: AnsiString;
  ImageName: AnsiString;
  CmdLine: AnsiString;

  StringBuffer: Pointer;
  StringPointer: UInt64;
  StringLength: Word;

  TlHelp32Info: TProcessInfo;
  LocalHandlesCount: LongWord;

  MemoryCounters: _PROCESS_MEMORY_COUNTERS_EX;
begin
  FillChar(ProcessBasicInfo, SizeOf(ProcessBasicInfo), #0);
  FillChar(PEBInfo, SizeOf(PEBInfo), #0);
  FillChar(UserParameters, SizeOf(UserParameters), #0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), #0);

  NTSetPrivilege(SE_DEBUG_NAME, true);
  ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION + PROCESS_VM_READ, FALSE, ProcessID);

// Получаем разрядность процесса:
  IsWow64Process(ProcessHandle, _Is64BitProcess);
  _Is64BitProcess := not _Is64BitProcess;

// Заполняем PROCESS_BASIC_INFORMATION:
  NtWow64QueryInformationProcess64(ProcessHandle, ProcessBasicInformation, @ProcessBasicInfo, SizeOf(ProcessBasicInfo), ReturnLength);
// Читаем PEB:
  NtWow64ReadVirtualMemory64(ProcessHandle, ProcessBasicInfo.PebBaseAddress, @PEBInfo, SizeOf(PEBInfo), BytesRead);
// Читаем RTL_USER_PROCESS_PARAMETERS:
  NtWow64ReadVirtualMemory64(ProcessHandle, PEBInfo.ProcessParameters, @UserParameters, SizeOf(UserParameters), BytesRead);

// Получаем список загруженных модулей:
  _GetModulesList64(ProcessHandle, PEBInfo.Ldr, ProcessInfo.ModulesList);

// Читаем строки:
  // CommandLine:
  StringPointer := UserParameters.CommandLine.Buffer;
  StringLength := UserParameters.CommandLine.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  CmdLine := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

  // ImageFilePath:
  StringPointer := UserParameters.ImagePathName.Buffer;
  StringLength := UserParameters.ImagePathName.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  ImageName := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

  //CurrentDirectoryPath:
  StringPointer := UserParameters.CurrentDirectoryPath.Buffer;
  StringLength := UserParameters.CurrentDirectoryPath.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  CurrentDirectory := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

// Получаем информацию о памяти процесса:
  FillChar(MemoryCounters, SizeOf(MemoryCounters), #0);
  GetProcessMemoryInfo(ProcessHandle, MemoryCounters, SizeOf(MemoryCounters));

// Получаем информацию из TlHelp32:
  FillChar(TlHelp32Info, SizeOf(TlHelp32Info), #0);
  TlHelp32Info := GetTlHelp32ProcessInfo(ProcessID);

// Получаем количество открытых хэндлов:
  GetProcessHandleCount(ProcessHandle, @LocalHandlesCount);

  // Возвращаем результат:
  with ProcessInfo do
  begin
    Handle := ProcessHandle;
    ID := ProcessBasicInfo.uUniqueProcessId;
    InheritedFromID := ProcessBasicInfo.uInheritedFromUniqueProcessId;
    SessionID := PEBInfo.SessionID;

    Priority := ProcessBasicInfo.BasePriority;
    AffinityMask := ProcessBasicInfo.AffinityMask;

    IsDebugged := PEBInfo.BeingDebugged;
    ExitStatus := ProcessBasicInfo.ExitStatus;
    ThreadsCount := TlHelp32Info.cntThreads;
    handlesCount := LocalHandlesCount;
    ReservedMemory := MemoryCounters.PrivateUsage;

    ImageBaseAddress := PEBInfo.ImageBaseAddress;
    LdrAddress := PEBInfo.Ldr;
    PEBAddress := ProcessBasicInfo.PebBaseAddress;

    ConsoleHandle := UserParameters.ConsoleHandle;
    StdInputHandle := UserParameters.StdInputHandle;
    StdOutputHandle := UserParameters.StdOutputHandle;
    StdErrorHandle := UserParameters.StdErrorHandle;

    ProcessName := TlHelp32Info.szExeFile;
    CurrentDirectoryPath := CurrentDirectory;
    ImagePathName := ImageName;
    CommandLine := CmdLine;

    Is64BitProcess := _Is64BitProcess;
  end;

  CloseHandle(ProcessHandle);
end;


//------------------------------------------------------------------------------

procedure _GetModulesListWow64(ProcessHandle: THandle; LDRAddress: Pointer32; out Modules: TModulesList);
var
  LdrInfo: PEB_LDR_DATA_WOW64;
  ModuleInfo: LDR_MODULE_WOW64;

  StringBuffer: Pointer;
  StringPointer: UInt64;
  StringLength: Word;

  BytesRead: UInt64;
begin
// Читаем PEB_LDR_DATA:
  NtWow64ReadVirtualMemory64(ProcessHandle, UInt64(LDRAddress), @LdrInfo, SizeOf(LdrInfo), BytesRead);
// Читаем LDR_MODULE_INFO:
  NtWow64ReadVirtualMemory64(ProcessHandle, UInt64(LdrInfo.InLoadModuleOrderList.ForwardLDRModule), @ModuleInfo, SizeOf(ModuleInfo), BytesRead);

  FillChar(Modules, SizeOf(Modules), #0);

  while (LdrInfo.InLoadModuleOrderList.ForwardLDRModule <> 0) and (BytesRead <> 0) and (ModuleInfo.BaseAddress <> 0) do
  begin
    Inc(Modules.Length);
    SetLength(Modules.Modules, Modules.Length);

  // Получаем численную информацию:
    with Modules do
    begin
      Modules[Length - 1].BaseAddress := ModuleInfo.BaseAddress;
      Modules[Length - 1].EntryAddress := ModuleInfo.EntryPoint;
      Modules[Length - 1].SizeOfImage := ModuleInfo.SizeOfImage;
    end;

  // Читаем полный путь:
    StringPointer := ModuleInfo.FullDLLName.Buffer;
    StringLength := ModuleInfo.FullDLLName.Length;
    GetMem(StringBuffer, StringLength + 2);
    FillChar(StringBuffer^, StringLength + 2, #0);
    NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
    Modules.Modules[Modules.Length - 1].FullPath := WideStringToString(PWideChar(StringBuffer), 0);
    FreeMem(StringBuffer);

  // Читаем имя библиотеки:
    StringPointer := ModuleInfo.BaseDLLName.Buffer;
    StringLength := ModuleInfo.BaseDLLName.Length;
    GetMem(StringBuffer, StringLength + 2);
    FillChar(StringBuffer^, StringLength + 2, #0);
    NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
    Modules.Modules[Modules.Length - 1].ModuleName := WideStringToString(PWideChar(StringBuffer), 0);
    FreeMem(StringBuffer);

  // Читаем следующий в списке LDR_MODULE_INFO:
    NtWow64ReadVirtualMemory64(ProcessHandle, ModuleInfo.InLoadModuleOrderList.ForwardLDRModule, @ModuleInfo, SizeOf(ModuleInfo), BytesRead);
  end;
end;

procedure _GetProcessInfoWow64(ProcessID: LongWord; out ProcessInfo: PROCESS_INFO);
var
  ProcessHandle: THandle;
  ProcessBasicInfo: PROCESS_BASIC_INFORMATION64;
  ProcessBasicInfoWow64: PROCESS_BASIC_INFORMATION_WOW64;
  PEBInfo: PEB_WOW64;
  UserParameters: RTL_USER_PROCESS_PARAMETERS_WOW64;
  BytesRead: UInt64;
  ReturnLength: UInt64;

  //ReturnStatus: LongWord;

  _Is64BitProcess: BOOL;

  CurrentDirectory: AnsiString;
  ImageName: AnsiString;
  CmdLine: AnsiString;

  StringBuffer: Pointer;
  StringPointer: UInt64;
  StringLength: Word;

  TlHelp32Info: TProcessInfo;
  LocalHandlesCount: LongWord;

  MemoryCounters: _PROCESS_MEMORY_COUNTERS_EX;
begin
  FillChar(ProcessBasicInfo, SizeOf(ProcessBasicInfo), #0);
  FillChar(PEBInfo, SizeOf(PEBInfo), #0);
  FillChar(UserParameters, SizeOf(UserParameters), #0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), #0);

  NTSetPrivilege(SE_DEBUG_NAME, true);
  ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION + PROCESS_VM_READ, FALSE, ProcessID);

// Получаем разрядность процесса:
  IsWow64Process(ProcessHandle, _Is64BitProcess);
  _Is64BitProcess := not _Is64BitProcess;

// Заполняем PROCESS_BASIC_INFORMATION:
  NtWow64QueryInformationProcess64(ProcessHandle, ProcessBasicInformation, @ProcessBasicInfo, SizeOf(ProcessBasicInfo), ReturnLength);
// Получаем адрес 32х-битного PEB:
  NtWow64QueryInformationProcess64(Processhandle, ProcessWow64Information, @ProcessBasicInfoWow64, SizeOf(ProcessBasicInfoWow64), ReturnLength);
// Читаем PEB:
  //NtWow64ReadVirtualMemory64(ProcessHandle, ProcessBasicInfo.PebBaseAddress, @PEBInfo, SizeOf(PEBInfo), BytesRead);
  NtWow64ReadVirtualMemory64(ProcessHandle, ProcessBasicInfoWow64.Wow64PebAddress, @PEBInfo, SizeOf(PEBInfo), BytesRead);
// Читаем RTL_USER_PROCESS_PARAMETERS:
  NtWow64ReadVirtualMemory64(ProcessHandle, UInt64(PEBInfo.ProcessParameters), @UserParameters, SizeOf(UserParameters), BytesRead);

// Получаем список загруженных модулей:
  _GetModulesListWow64(ProcessHandle, UInt64(PEBInfo.Ldr), ProcessInfo.ModulesList);

// Читаем строки:
  // CommandLine:
  StringPointer := UserParameters.CommandLine.Buffer;
  StringLength := UserParameters.CommandLine.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  CmdLine := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

  // ImageFilePath:
  StringPointer := UserParameters.ImagePathName.Buffer;
  StringLength := UserParameters.ImagePathName.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  ImageName := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

  //CurrentDirectoryPath:
  StringPointer := UserParameters.CurrentDirectoryPath.Buffer;
  StringLength := UserParameters.CurrentDirectoryPath.Length;
  GetMem(StringBuffer, StringLength + 2);
  FillChar(StringBuffer^, StringLength + 2, #0);
  NtWow64ReadVirtualMemory64(ProcessHandle, StringPointer, StringBuffer, StringLength, BytesRead);
  CurrentDirectory := WideStringToString(PWideChar(StringBuffer), 0);
  FreeMem(StringBuffer);

// Получаем информацию о памяти процесса:
  FillChar(MemoryCounters, SizeOf(MemoryCounters), #0);
  GetProcessMemoryInfo(ProcessHandle, MemoryCounters, SizeOf(MemoryCounters));

// Получаем информацию из TlHelp32:
  FillChar(TlHelp32Info, SizeOf(TlHelp32Info), #0);
  TlHelp32Info := GetTlHelp32ProcessInfo(ProcessID);

// Получаем количество открытых хэндлов:
  GetProcessHandleCount(ProcessHandle, @LocalHandlesCount);

  // Возвращаем результат:
  with ProcessInfo do
  begin
    Handle := ProcessHandle;
    ID := ProcessBasicInfo.uUniqueProcessId;
    InheritedFromID := ProcessBasicInfo.uInheritedFromUniqueProcessId;
    SessionID := PEBInfo.SessionID;

    Priority := ProcessBasicInfo.BasePriority;
    AffinityMask := ProcessBasicInfo.AffinityMask;

    IsDebugged := PEBInfo.BeingDebugged;
    ExitStatus := ProcessBasicInfo.ExitStatus;
    ThreadsCount := TlHelp32Info.cntThreads;
    HandlesCount := LocalHandlesCount;
    ReservedMemory := MemoryCounters.PrivateUsage;

    ImageBaseAddress := UInt64(PEBInfo.ImageBaseAddress);
    LdrAddress := UInt64(PEBInfo.Ldr);
    PEBAddress := ProcessBasicInfo.PebBaseAddress;

    ConsoleHandle := UserParameters.ConsoleHandle;
    StdInputHandle := UserParameters.StdInputHandle;
    StdOutputHandle := UserParameters.StdOutputHandle;
    StdErrorHandle := UserParameters.StdErrorHandle;

    ProcessName := TlHelp32Info.szExeFile;
    CurrentDirectoryPath := CurrentDirectory;
    ImagePathName := ImageName;
    CommandLine := CmdLine;

    Is64BitProcess := _Is64BitProcess;
  end;

  CloseHandle(ProcessHandle);
end;


//------------------------------------------------------------------------------

procedure GetProcessInfo(ProcessID: LongWord; out ProcessInfo: PROCESS_INFO; Process32_64CompatibleMode: Boolean = false);
var
  IsTarget64Bit: LongBool;
  TargetHandle: THandle;
begin
  if not IsFunctionsAreInited then _InitFunctions;

  FillChar(ProcessInfo, SizeOf(ProcessInfo), #0);

  TargetHandle := ProcessIDToHandle(ProcessID);
  if TargetHandle = 0 then Exit;

  IsWow64Process(TargetHandle, IsTarget64Bit);
  IsTarget64Bit := not IsTarget64Bit;
  CloseHandle(TargetHandle);

  {$IFDEF CPUX64}
  if IsTarget64Bit then
    _GetProcessInfo64(ProcessID, ProcessInfo)
  else
    if Process32_64CompatibleMode then
      _GetProcessInfo64(ProcessID, ProcessInfo)
    else
      _GetProcessInfoWow64(ProcessID, ProcessInfo);
  {$ELSE}
  if Is64BitWindows then
    if IsTarget64Bit then
      _GetProcessInfo64(ProcessID, ProcessInfo)
    else
      if Process32_64CompatibleMode then
        _GetProcessInfo64(ProcessID, ProcessInfo)
      else
        _GetProcessInfo32(ProcessID, ProcessInfo)
  else
    _GetProcessInfo32(ProcessID, ProcessInfo);
  {$ENDIF}
end;

//------------------------------------------------------------------------------

function IsProcessLaunched(ProcessName: AnsiString): boolean;
var
  hSnap: THandle;
  PE: TProcessInfo;
begin
  Result := false;
  PE.dwSize := SizeOf(PE);
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Process32FirstA(hSnap, PE) then
  begin
    if PE.szExeFile = ProcessName then
    begin
      Result := true;
    end
    else
    begin
      while Process32NextA(hSnap, PE) do
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure GetProcessList(out ProcessList: TProcessList);
var
  hSnap: THandle;
  PE: TProcessInfo;
  Size: LongWord;
begin
  Size := 0;
  SetLength(ProcessList, Size);

  PE.dwSize := SizeOf(PE);
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Process32FirstA(hSnap, PE) then
  begin
    Inc(Size);
    SetLength(ProcessList, Size);
    ProcessList[Size - 1] := PE;

    while Process32NextA(hSnap, PE) do
    begin
      Inc(Size);
      SetLength(ProcessList, Size);
      ProcessList[Size - 1] := PE;
    end;
  end;
  CloseHandle(hSnap);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetTlHelp32ProcessInfo(ProcessID: LongWord): TProcessInfo; overload;
var
  hSnap: THandle;
  PE: TProcessInfo;
begin
  FillChar(Result, SizeOf(Result), #0);

  PE.dwSize := SizeOf(PE);
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Process32FirstA(hSnap, PE) then
  begin
    if PE.th32ProcessID = ProcessID then
    begin
      Result := PE;
    end
    else
    begin
      while Process32NextA(hSnap, PE) do
      begin
        if PE.th32ProcessID = ProcessID then
        begin
          Result := PE;
          Break;
        end;
      end;
    end;
  end;
  CloseHandle(hSnap);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetTlHelp32ProcessInfo(ProcessName: AnsiString): TProcessInfo; overload;
var
  hSnap: THandle;
  PE: TProcessInfo;
begin
  FillChar(Result, SizeOf(Result), #0);

  PE.dwSize := SizeOf(PE);
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Process32FirstA(hSnap, PE) then
  begin
    if PE.szExeFile = ProcessName then
    begin
      Result := PE;
    end
    else
    begin
      while Process32NextA(hSnap, PE) do
      begin
        if PE.szExeFile = ProcessName then
        begin
          Result := PE;
          Break;
        end;
      end;
    end;
  end;
  CloseHandle(hSnap);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetProcessCPULoading(ProcessID: LongWord; Delay: Cardinal): Single;
var
  SystemInfo: SYSTEM_INFO;
  ProcessorsCount: Byte;

  lpCreationTime, lpExitTime,
  lpKernelTime, lpUserTime: TFileTime;

  WorkingTime: Int64;
  WorkingInterval, LifeInterval: Single;

  FirstUpdateTime, SecondUpdateTime: Cardinal;
  FirstWorkingTime: Int64;

  ProcessHandle: THandle;
begin
  ProcessHandle := ProcessIDtoHandle(ProcessID);

  // Получаем количество ядер:
  GetSystemInfo(SystemInfo);
  ProcessorsCount := SystemInfo.dwNumberOfProcessors;

  // Получаем времена процесса:
  GetProcessTimes(ProcessHandle, lpCreationTime, lpExitTime, lpKernelTime, lpUserTime);
  FirstUpdateTime := GetTickCount;
  // Рабочее время в начале интервала:
  FirstWorkingTime := Int64(lpKernelTime) + Int64(lpUserTime);

  Sleep(Delay);

  // Получаем времена процесса через интервал:
  GetProcessTimes(ProcessHandle, lpCreationTime, lpExitTime, lpKernelTime, lpUserTime);
  SecondUpdateTime := GetTickCount;

  // Интервал, во время которого будем измерять нагрузку:
  LifeInterval := SecondUpdateTime - FirstUpdateTime;
  if LifeInterval <= 0 then LifeInterval := 0.01;

  // Рабочее время в конце интервала:
  WorkingTime := Int64(lpKernelTime) + Int64(lpUserTime);

  // Разность между рабочими временами в конце и начале интервала:
  WorkingInterval := WorkingTime - FirstWorkingTime;

  // Выводим результат:
  Result := WorkingInterval / (LifeInterval * 100 * ProcessorsCount);

  CloseHandle(ProcessHandle);
end;


end.
