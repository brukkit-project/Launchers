library HookLib64;

{$SETPEFLAGS $0002 or $0004 or $0008 or $0010 or $0020 or $0200 or $0400 or $0800 or $1000}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  Windows, TlHelp32, ProcessAPI;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{$IFDEF CPUX64}

// Структура для х64:
type
  TFarJump = packed record
    MovRaxCommand: Word;
    MovRaxArgument: Pointer;
    PushRaxCommand: Byte;
    RetCommand: Byte;
  end;

  NativeUInt = UInt64;

{$ELSE}

// Структура для х32:
type
  TFarJump = packed record
    PushOp: Byte;
    PushArg: Pointer;
    RetOp: Byte;
  end;

  NativeUInt = UInt32;

{$ENDIF}

  TOriginalBlock = array [0 .. SizeOf(TFarJump) - 1] of Byte;

const
  THREAD_SUSPEND_RESUME = $0002;

function OpenThread(dwDesiredAccess: LongWord; bInheritHandle: LongBool; dwThreadId: LongWord): LongWord; stdcall; external 'kernel32.dll';
function NtWriteVirtualMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer;
  nSize: SIZE_T; var lpNumberOfBytesWritten: NativeUInt): Cardinal; stdcall; external 'ntdll.dll';
function NtReadVirtualMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer;
  nSize: SIZE_T; var lpNumberOfBytesRead: NativeUInt): Cardinal; stdcall; external 'ntdll.dll';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Заморозить все потоки процесса, кроме текущего:
procedure StopThreads;
var
  TlHelpHandle, CurrentThread, ThreadHandle, CurrentProcess: dword;
  ThreadEntry32: TThreadEntry32;
begin
  CurrentThread := GetCurrentThreadId;
  CurrentProcess := GetCurrentProcessId;
  TlHelpHandle := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if TlHelpHandle <> INVALID_HANDLE_VALUE then
  begin
    ThreadEntry32.dwSize := SizeOf(TThreadEntry32);
    if Thread32First(TlHelpHandle, ThreadEntry32) then
    repeat
      if (ThreadEntry32.th32ThreadID <> CurrentThread) and (ThreadEntry32.th32OwnerProcessID = CurrentProcess) then
      begin
        ThreadHandle := OpenThread(THREAD_SUSPEND_RESUME, false, ThreadEntry32.th32ThreadID);
        if ThreadHandle > 0 then
        begin
          SuspendThread(ThreadHandle);
          CloseHandle(ThreadHandle);
        end;
      end;
    until not Thread32Next(TlHelpHandle, ThreadEntry32);

    CloseHandle(TlHelpHandle);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Запустить все потоки процесса, кроме текущего:
procedure RunThreads;
var
  TlHelpHandle, CurrentThread, ThreadHandle, CurrentProcess: dword;
  ThreadEntry32: TThreadEntry32;
begin
  CurrentThread := GetCurrentThreadId;
  CurrentProcess := GetCurrentProcessId;
  TlHelpHandle := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if TlHelpHandle <> INVALID_HANDLE_VALUE then
  begin
    ThreadEntry32.dwSize := SizeOf(TThreadEntry32);
    if Thread32First(TlHelpHandle, ThreadEntry32) then
    repeat
      if (ThreadEntry32.th32ThreadID <> CurrentThread) and (ThreadEntry32.th32OwnerProcessID = CurrentProcess) then
      begin
        ThreadHandle := OpenThread(THREAD_SUSPEND_RESUME, false, ThreadEntry32.th32ThreadID);
        if ThreadHandle > 0 then
        begin
          ResumeThread(ThreadHandle);
          CloseHandle(ThreadHandle);
        end;
      end;
    until not Thread32Next(TlHelpHandle, ThreadEntry32);

    CloseHandle(TlHelpHandle);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Установка перехватчика:
function SetHook(OldProcAddress: Pointer; NewProcAddress: Pointer; out OriginalBlock: TOriginalBlock): Boolean;
var
  ReadBytes, WrittenBytes: NativeUInt;
  FarJump: TFarJump;
  OldProtect: Cardinal;
begin

{$IFDEF CPUX64}
  // x64:
  { 48 B8 [8 байт адреса] 50 C3 }
  FarJump.MovRaxCommand := $B848;           //  --+
  FarJump.MovRaxArgument := NewProcAddress; //  --+-->  mov RAX, NewProcAddress
  FarJump.PushRaxCommand := $50;            //  ----->  push RAX
  FarJump.RetCommand := $C3;                //  ----->  ret
{$ELSE}
  // х32:
  { 68 [4 байта адреса] C3 }
  FarJump.PushOp  := $68;                   //  --+
  FarJump.PushArg := NewProcAddress;        //  --+-->  push NewProcAddress
  FarJump.RetOp   := $C3;                   //  ----->  ret
{$ENDIF}

  StopThreads;
  VirtualProtect(OldProcAddress, SizeOf(TFarJump), PAGE_READWRITE, @OldProtect);
  FillChar(OriginalBlock, SizeOf(FarJump), #0);
  NtReadVirtualMemory(GetCurrentProcess, OldProcAddress, @OriginalBlock[0], SizeOf(FarJump), ReadBytes);
  NtWriteVirtualMemory(GetCurrentProcess, OldProcAddress, @FarJump, SizeOf(FarJump), WrittenBytes);
  Result := WrittenBytes <> 0;
  VirtualProtect(OldProcAddress, SizeOf(TFarJump), OldProtect, @OldProtect);
  RunThreads;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function UnHook(OriginalProcAddress: Pointer; OriginalBlock: TOriginalBlock): Boolean;
var
  WrittenBytes: NativeUInt;
  OldProtect: Cardinal;
begin
  StopThreads;
  VirtualProtect(OriginalProcAddress, SizeOf(TFarJump), PAGE_READWRITE, @OldProtect);
  NtWriteVirtualMemory(GetCurrentProcess, OriginalProcAddress, @OriginalBlock[0], SizeOf(TFarJump), WrittenBytes);
  Result := WrittenBytes <> 0;
  VirtualProtect(OriginalProcAddress, SizeOf(TFarJump), OldProtect, @OldProtect);
  RunThreads;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

var
  TrueWriteProcessMemory: function(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer;
  nSize: SIZE_T; var lpNumberOfBytesWritten: NativeUInt): BOOL; stdcall;

  OriginalBlock: TOriginalBlock;

function HookedWriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer;
  nSize: SIZE_T; var lpNumberOfBytesWritten: NativeUInt): BOOL; stdcall;
var
  ProcessID: LongWord;
  ProcessInfo: PROCESS_INFO;
begin
  UnHook(@TrueWriteProcessMemory, OriginalBlock);

  Result := False;

  ProcessID := HandleToProcessID(hProcess);
  if hProcess = 0 then Exit;
  GetProcessInfo(ProcessID, ProcessInfo);

  if (ProcessInfo.ProcessName <> 'java.exe') or (ProcessInfo.ProcessName <> 'javaw.exe') then
  begin
    Result := TrueWriteProcessMemory(hProcess, lpBaseAddress, lpBuffer, nSize, lpNumberOfBytesWritten);
  end
  else
  begin
    lpNumberOfBytesWritten := 0;
    Result := FALSE;
  end;

  SetHook(@TrueWriteProcessMemory, @HookedWriteProcessMemory, OriginalBlock);
end;


procedure DLLMain(dwReason: LongWord);
var
  LibHandle: THandle;
begin
  case dwReason of
    DLL_PROCESS_ATTACH:
    begin
      LibHandle := GetModuleHandle('kernel32.dll');
      if LibHandle = 0 then Exit;

      TrueWriteProcessMemory := GetProcAddress(LibHandle, 'WriteProcessMemory');

      SetHook(@TrueWriteProcessMemory, @HookedWriteProcessMemory, OriginalBlock);
    end;

    DLL_PROCESS_DETACH:
    begin
      UnHook(@TrueWriteProcessMemory, OriginalBlock);
    end;
  end;
end;



begin
  DllProc := @DLLMain;
  DllProc(DLL_PROCESS_ATTACH) ;
end.

