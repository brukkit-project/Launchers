unit HookAPI;

interface

uses
  Windows;

const
  SE_DEBUG_NAME = 'SeDebugPrivilege';


type
{$IFDEF CPUX64}
  NativeUInt = UInt64;
{$ELSE}
  NativeUInt = LongWord;
{$ENDIF}

// ��������� ����������� ���������� (��� ��������� SE_DEBUG_NAME) - �������� �������:
function NTSetPrivilege(sPrivilege: string; bEnabled: Boolean): Boolean;


{
  �������� ���������:

    �������� ���������:
      ProcessHandle - ����� ��������, � ������� ����� �������� ��������
      ModulePath - ���������� ���� � ���������� ����������

    �������������� ���������:
      LLAddress - ����� LoadLibraryA
      ETAddress - ����� ExitThread
}
function InjectDll32(ProcessID: LongWord; ModulePath: PAnsiChar; LLAddress: LongWord = 0; ETAddress: LongWord = 0): Boolean;
function InjectDll64(ProcessID: LongWord; ModulePath: PAnsiChar; LLAddress: UInt64 = 0; ETAddress: UInt64 = 0): Boolean;


{
  �������� ���������:

    �������� ���������:
      ProcessHandle - ����� ��������, � ������� ����� �������� ��������
      ModuleName - ��� ����������� ����������

    �������������� ���������:
      GMHAddress - ����� GetModuleHandleA
      FLAddress - ����� FreeLibrary
      ETAddress - ����� ExitThread
}
function UnloadDll32(ProcessID: LongWord; ModulePath: PAnsiChar; GMHAddress: LongWord = 0; FLAddress: LongWord = 0; ETAddress: LongWord = 0): Boolean;
function UnloadDll64(ProcessID: LongWord; ModuleName: PAnsiChar; GMHAddress: UInt64 = 0; FLAddress: UInt64 = 0; ETAddress: UInt64 = 0): Boolean;

// �������� ���� �������� �� ���������:
procedure InjectFunction(ProcessID: LongWord; InjectedFunction: Pointer; InjectedFunctionSize: NativeUInt);

// �������� �������������� ������� ������:
function EmptyWorkingSet(Handle: NativeUInt): LongBool; stdcall; external 'psapi.dll';

implementation

type
  NTStatus = LongWord;

function NtWriteVirtualMemory(
                               ProcessHandle: THandle;
                               BaseAddress: NativeUInt;
                               Buffer: Pointer;
                               BufferLength: NativeUInt;
                               out ReturnLength: NativeUInt
                              ): NTStatus; stdcall; external 'ntdll.dll';


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// ��������� ���������� ��� ������ � ������ ����������:
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


(* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// ������������ �������:
procedure LoadHookLib32;
const
  HookLib: PAnsiChar = 'HookLib.dll';
asm
  push HookLib
  call LoadLibraryA

  xor eax, eax
  push eax
  call ExitThread
end;

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *)

// �������� � 32�-������ ��������:
function InjectDll32(ProcessID: LongWord; ModulePath: PAnsiChar; LLAddress: LongWord = 0; ETAddress: LongWord = 0): Boolean;
var
  ProcessHandle: NativeUInt;
  Memory: Pointer;
  Code: LongWord;
  BytesWritten: NativeUInt;
  ThreadId: LongWord;
  hThread: LongWord;
  hKernel32: LongWord;

  // ��������� ��������� ���� ������������� � ������� ����������:
  Inject: packed record
    // LL* = LoadLibrary:
    LLPushCommand: Byte;
    LLPushArgument: LongWord;
    LLCallCommand: Word;
    LLCallAddr: LongWord;

    // ET* = ExitThread:
    ETPushCommand: Byte;
    ETPushArgument: LongWord;
    ETCallCommand: Word;
    ETCallAddr: LongWord;

    AddrLoadLibrary: LongWord;
    AddrExitThread: LongWord;
    LibraryName: array [0..MAX_PATH] of AnsiChar;
  end;
begin
  Result := false;

  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessID);
  if ProcessHandle = 0 then Exit;

  // �������� ������ � ��������� ��������, ���� ������� ��� ������ ���������� ������������:
  Memory := VirtualAllocEx(ProcessHandle, nil, SizeOf(Inject), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  if Memory = nil then Exit;

  Code := LongWord(Memory);
  FillChar(Inject, SizeOf(Inject), #0);

// LoadLibraryA:
  Inject.LLPushCommand    := $68;
  Inject.LLPushArgument   := Code + 30;
  Inject.LLCallCommand    := $15FF;
  Inject.LLCallAddr       := Code + 22;

// ExitThread:
  Inject.ETPushCommand := $68;
  Inject.ETPushArgument  := 0;
  Inject.ETCallCommand := $15FF;
  Inject.ETCallAddr := Code + 26;

  hKernel32 := GetModuleHandle('kernel32.dll');

  if LLAddress = 0 then
    Inject.AddrLoadLibrary := LongWord(GetProcAddress(hKernel32, 'LoadLibraryA'))
  else
    Inject.AddrLoadLibrary := LLAddress;

  if ETAddress = 0 then
    Inject.AddrExitThread  := LongWord(GetProcAddress(hKernel32, 'ExitThread'))
  else
    Inject.AddrExitThread := ETAddress;

  Move(ModulePath^, Inject.LibraryName, Length(ModulePath));

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

  // ���������� �������� ��� � ���������� ������:
  if NtWriteVirtualMemory(ProcessHandle, NativeUInt(Memory), @Inject, SizeOf(Inject), BytesWritten) <> 0 then Exit;

  // ��������� �������� ��� � ��������� ������:
  hThread := CreateRemoteThread(ProcessHandle, nil, 0, Memory, nil, 0, ThreadId);

  if hThread = 0 then
  begin
    VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);
    EmptyWorkingSet(ProcessHandle);
    CloseHandle(ProcessHandle);
    Exit;
  end;

  WaitForSingleObject(hThread, INFINITE);
  VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);

  CloseHandle(hThread);
  EmptyWorkingSet(ProcessHandle);
  CloseHandle(ProcessHandle);

  Result := True;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// �������� ���������� �� 32�-������ ���������:
function UnloadDll32(ProcessID: LongWord; ModulePath: PAnsiChar; GMHAddress: LongWord = 0; FLAddress: LongWord = 0; ETAddress: LongWord = 0): Boolean;
var
  ProcessHandle: NativeUInt;
  Memory: Pointer;
  Code: LongWord;
  BytesWritten: NativeUInt;
  ThreadId: LongWord;
  hThread: LongWord;
  hKernel32: LongWord;

  // ��������� ��������� ���� ������������� � ������� ����������:
  Inject: packed record
    // GMH* = GetModuleHandle:
    GMHPushCommand: Byte;
    GMHPushArgument: LongWord;
    GMHCallCommand: Word;
    GMHCallAddr: LongWord;

    // FL* = FreeLibrary:
    FLPushEax: Byte;
    FLCallCommand: Word;
    FLCallAddr: LongWord;

    // ET* = ExitThread:
    ETPushCommand: Byte;
    ETPushArgument: LongWord;
    ETCallCommand: Word;
    ETCallAddr: LongWord;

    AddrGetModuleHandle: LongWord;
    AddrLoadLibrary: LongWord;
    AddrExitThread: LongWord;
    LibraryName: array [0..MAX_PATH] of AnsiChar;
  end;
begin
  Result := false;

  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessID);
  if ProcessHandle = 0 then Exit;

  // �������� ������ � ��������� ��������, ���� ������� ��� ������ ���������� ������������:
  Memory := VirtualAllocEx(ProcessHandle, nil, SizeOf(Inject), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  if Memory = nil then Exit;

  Code := LongWord(Memory);
  FillChar(Inject, SizeOf(Inject), #0);

// GetModuleHandleA:
  Inject.GMHPushCommand    := $68;
  Inject.GMHPushArgument   := Code + 41;
  Inject.GMHCallCommand    := $15FF;
  Inject.GMHCallAddr       := Code + 29;

// FreeLibrary:
  Inject.FLPushEax    := $50;
  Inject.FLCallCommand    := $15FF;
  Inject.FLCallAddr       := Code + 33;

// ExitThread:
  Inject.ETPushCommand := $68;
  Inject.ETPushArgument  := 0;
  Inject.ETCallCommand := $15FF;
  Inject.ETCallAddr := Code + 37;

  hKernel32 := GetModuleHandle('kernel32.dll');

  if GMHAddress = 0 then
    Inject.AddrGetModuleHandle := LongWord(GetProcAddress(hKernel32, 'GetModuleHandleA'))
  else
    Inject.AddrGetModuleHandle := GMHAddress;

  if FLAddress = 0 then
    Inject.AddrLoadLibrary := LongWord(GetProcAddress(hKernel32, 'FreeLibrary'))
  else
    Inject.AddrLoadLibrary := FLAddress;

  if ETAddress = 0 then
    Inject.AddrExitThread  := LongWord(GetProcAddress(hKernel32, 'ExitThread'))
  else
    Inject.AddrExitThread := ETAddress;

  Move(ModulePath^, Inject.LibraryName, Length(ModulePath));

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

  // ���������� �������� ��� � ���������� ������:
  if NtWriteVirtualMemory(ProcessHandle, NativeUInt(Memory), @Inject, SizeOf(Inject), BytesWritten) <> 0 then Exit;

  // ��������� �������� ��� � ��������� ������:
  hThread := CreateRemoteThread(ProcessHandle, nil, 0, Memory, nil, 0, ThreadId);

  if hThread = 0 then
  begin
    VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);
    EmptyWorkingSet(ProcessHandle);
    CloseHandle(ProcessHandle);
    Exit;
  end;

  WaitForSingleObject(hThread, INFINITE);
  VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);

  CloseHandle(hThread);
  EmptyWorkingSet(ProcessHandle);
  CloseHandle(ProcessHandle);

  Result := True;
end;


(* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


{
  �������� ���������� � �64-�������:

  RCX - ������ ��������
  RDX - ������ ��������
  R8 - ������ ��������
  R9 - �������� ��������

  ��������� ����� ���� � ������������ � ����������� � ������

  ���� ���������� ����������� ��� ����� � �������:

  asm
    push rbp
    sub rsp, $20
    mov rbp, rsp

    ...

    lea rsp, [rbp+$20]
    pop rbp
    ret
  end;
}

// ������������ �������:
procedure LoadHookLib64;
const
  HookLib: PAnsiChar = 'HookLib.dll';
asm
  push rbp
  sub rsp, $20
  mov rbp, rsp

  mov rcx, HookLib
  call LoadLibraryA

  mov rcx, $0000000000000000
  call ExitThread

  lea rsp, [rbp+$20]
  pop rbp
  ret
end;

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *)


// �������� � 64�-������ ��������:
function InjectDll64(ProcessID: LongWord; ModulePath: PAnsiChar; LLAddress: UInt64 = 0; ETAddress: UInt64 = 0): Boolean;
var
  ProcessHandle: NativeUInt;
  Memory: Pointer;
  Code: UInt64;
  BytesWritten: NativeUInt;
  ThreadId: LongWord;
  hThread: LongWord;
  hKernel32: NativeUInt;

  // ��������� ��������� ���� ������������� � ������� ����������:
  Inject: packed record
    AlignStackAtStart: UInt64;

    // LL* = LoadLibrary:
    LLMovRaxCommand: Word;
    LLMovRaxArgument: UInt64;
    LLMovRaxData: array [0..2] of Byte;
    LLMovRcxCommand: Word;
    LLMovRcxArgument: UInt64;
    LLCallRax: array [0..2] of Byte;

    // ET* = ExitThread:
    ETMovRaxCommand: Word;
    ETMovRaxArgument: UInt64;
    ETMovRaxData: array [0..2] of Byte;
    ETMovRcxCommand: Word;
    ETMovRcxArgument: UInt64;
    ETCallRax: array [0..2] of Byte;

    AlignStackAtEnd: UInt64;

    AddrLoadLibrary: UInt64;
    AddrExitThread: UInt64;
    LibraryName: array [0..MAX_PATH] of AnsiChar;
  end;
begin
  Result := false;

  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessID);
  if ProcessHandle = 0 then Exit;

// �������� ������ � ��������� ��������, ���� ������� ��� ������ ���������� ������������:
  Memory := VirtualAllocEx(ProcessHandle, nil, SizeOf(Inject), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  if Memory = nil then Exit;

  Code := UInt64(Memory);
  FillChar(Inject, SizeOf(Inject), #0);

// ����������� 64�-������ ����:
  Inject.AlignStackAtStart := $E5894820EC834855;

{
   + - - - - - - - - - - - +
   |  RAX - ����� �������  |
   |  RCX - ���������      |
   + - - - - - - - - - - - +
}

// LoadLibraryA:
  Inject.LLMovRaxCommand := $B848;
  Inject.LLMovRaxArgument := Code + 68; // Code + �������� �� ������ LoadLibraryA

  Inject.LLMovRaxData[0] := $48; //  ---+
  Inject.LLMovRaxData[1] := $8B; //  ---+--->  mov RAX, [RAX]
  Inject.LLMovRaxData[2] := $00; //  ---+

  Inject.LLMovRcxCommand := $B948;
  Inject.LLMovRcxArgument := Code + 84; // Code + �������� �� ������ ���� � ����������

  Inject.LLCallRax[0] := $48;
  Inject.LLCallRax[1] := $FF;
  Inject.LLCallRax[2] := $D0;

// ExitThread:
  Inject.ETMovRaxCommand := $B848;
  Inject.ETMovRaxArgument := Code + 76; // Code + �������� �� ������ ExitThread

  Inject.ETMovRaxData[0] := $48; //  ---+
  Inject.ETMovRaxData[1] := $8B; //  ---+--->  mov RAX, [RAX]
  Inject.ETMovRaxData[2] := $00; //  ---+

  Inject.ETMovRcxCommand := $B948;
  Inject.ETMovRcxArgument := $0000000000000000; // ExitCode = 0

  Inject.ETCallRax[0] := $48;
  Inject.ETCallRax[1] := $FF;
  Inject.ETCallRax[2] := $D0;

// ����������� 64�-������ ����:
  Inject.AlignStackAtEnd := $90C3C35D20658D48;


// ���������� ������ ���������:
  hKernel32 := LoadLibrary('kernel32.dll');

  if LLAddress = 0 then
    Inject.AddrLoadLibrary := UInt64(GetProcAddress(hKernel32, 'LoadLibraryA'))
  else
    Inject.AddrLoadLibrary := LLAddress;

  if ETAddress = 0 then
    Inject.AddrExitThread  := UInt64(GetProcAddress(hKernel32, 'ExitThread'))
  else
    Inject.AddrExitThread := ETAddress;

  Move(ModulePath^, Inject.LibraryName, Length(ModulePath));

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

  // ���������� �������� ��� � ���������� ������:
  if NtWriteVirtualMemory(ProcessHandle, NativeUInt(Memory), @Inject, SizeOf(Inject), BytesWritten) <> 0 then Exit;

  // ��������� �������� ��� � ��������� ������:
  hThread := CreateRemoteThread(ProcessHandle, nil, 0, Memory, nil, 0, ThreadId);

  if hThread = 0 then
  begin
    VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);
    EmptyWorkingSet(ProcessHandle);
    CloseHandle(ProcessHandle);
    Exit;
  end;

  WaitForSingleObject(hThread, INFINITE);
  VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);

  CloseHandle(hThread);
  EmptyWorkingSet(ProcessHandle);
  CloseHandle(ProcessHandle);

  Result := True;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// �������� ���������� �� 64�-������ ���������:
function UnloadDll64(ProcessID: LongWord; ModuleName: PAnsiChar; GMHAddress: UInt64 = 0; FLAddress: UInt64 = 0; ETAddress: UInt64 = 0): Boolean;
var
  ProcessHandle: NativeUInt;
  Memory: Pointer;
  Code: UInt64;
  BytesWritten: NativeUInt;
  ThreadId: LongWord;
  hThread: LongWord;
  hKernel32: NativeUInt;

  // ��������� ��������� ���� ������������� � ������� ����������:
  Inject: packed record
    AlignStackAtStart: UInt64;            // 8

    // GMH* = GetModuleHandle:
    GMHMovRaxCommand: Word;               // 2
    GMHMovRaxArgument: UInt64;            // 8
    GMHMovRaxData: array [0..2] of Byte;  // 3
    GMHMovRcxCommand: Word;               // 2
    GMHMovRcxArgument: UInt64;            // 8
    GMHCallRax: array [0..2] of Byte;     // 3

    // FL* = FreeLibrary:
    FLMovRcxRax: array [0..2] of Byte;    // 3
    FLMovRaxCommand: Word;                // 2
    FLMovRaxArgument: UInt64;             // 8
    FLMovRaxData: array [0..2] of Byte;   // 3
    FLCallRax: array [0..2] of Byte;      // 3

    // ET* = ExitThread:
    ETMovRaxCommand: Word;                // 2
    ETMovRaxArgument: UInt64;             // 8
    ETMovRaxData: array [0..2] of Byte;   // 3
    ETMovRcxCommand: Word;                // 2
    ETMovRcxArgument: UInt64;             // 8
    ETCallRax: array [0..2] of Byte;      // 3

    AlignStackAtEnd: UInt64;              // 8

    AddrGetModuleHandle: UInt64;          // 8
    AddrFreeLibrary: UInt64;              // 8
    AddrExitThread: UInt64;               // 8
    LibraryName: array [0..MAX_PATH] of AnsiChar;
  end;
begin
  Result := false;

  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessID);
  if ProcessHandle = 0 then Exit;

// �������� ������ � ��������� ��������, ���� ������� ��� ������ ���������� ������������:
  Memory := VirtualAllocEx(ProcessHandle, nil, SizeOf(Inject), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  if Memory = nil then Exit;

  Code := UInt64(Memory);
  FillChar(Inject, SizeOf(Inject), #0);

// ����������� 64�-������ ����:
  Inject.AlignStackAtStart := $E5894820EC834855;

{
   + - - - - - - - - - - - +
   |  RAX - ����� �������  |
   |  RCX - ���������      |
   + - - - - - - - - - - - +
}

// GetModuleHandleA:
  Inject.GMHMovRaxCommand := $B848;
  Inject.GMHMovRaxArgument := Code + 87; // Code + �������� �� ������ GetModuleHandleA

  Inject.GMHMovRaxData[0] := $48; //  ---+
  Inject.GMHMovRaxData[1] := $8B; //  ---+--->  mov RAX, [RAX]
  Inject.GMHMovRaxData[2] := $00; //  ---+

  Inject.GMHMovRcxCommand := $B948;
  Inject.GMHMovRcxArgument := Code + 111; // Code + �������� �� ������ ����� ����������

  Inject.GMHCallRax[0] := $48;
  Inject.GMHCallRax[1] := $FF;
  Inject.GMHCallRax[2] := $D0;

// FreeLibrary:
  Inject.FLMovRcxRax[0] := $48; //  ---+
  Inject.FLMovRcxRax[1] := $89; //  ---+--->  mov RCX, RAX
  Inject.FLMovRcxRax[2] := $C1; //  ---+

  Inject.FLMovRaxCommand := $B848;
  Inject.FLMovRaxArgument := Code + 95; // Code + �������� �� ������ FreeLibrary

  Inject.FLMovRaxData[0] := $48; //  ---+
  Inject.FLMovRaxData[1] := $8B; //  ---+--->  mov RAX, [RAX]
  Inject.FLMovRaxData[2] := $00; //  ---+

  Inject.FLCallRax[0] := $48;
  Inject.FLCallRax[1] := $FF;
  Inject.FLCallRax[2] := $D0;

// ExitThread:
  Inject.ETMovRaxCommand := $B848;
  Inject.ETMovRaxArgument := Code + 103; // Code + �������� �� ������ ExitThread

  Inject.ETMovRaxData[0] := $48; //  ---+
  Inject.ETMovRaxData[1] := $8B; //  ---+--->  mov RAX, [RAX]
  Inject.ETMovRaxData[2] := $00; //  ---+

  Inject.ETMovRcxCommand := $B948;
  Inject.ETMovRcxArgument := $0000000000000000; // ExitCode = 0

  Inject.ETCallRax[0] := $48;
  Inject.ETCallRax[1] := $FF;
  Inject.ETCallRax[2] := $D0;

// ����������� 64�-������ ����:
  Inject.AlignStackAtEnd := $90C3C35D20658D48;


// ���������� ������ ���������:
  hKernel32 := LoadLibrary('kernel32.dll');

  if GMHAddress = 0 then
    Inject.AddrGetModuleHandle := UInt64(GetProcAddress(hKernel32, 'GetModuleHandleA'))
  else
    Inject.AddrGetModuleHandle := GMHAddress;

  if FLAddress = 0 then
    Inject.AddrFreeLibrary := UInt64(GetProcAddress(hKernel32, 'FreeLibrary'))
  else
    Inject.AddrFreeLibrary := FLAddress;

  if ETAddress = 0 then
    Inject.AddrExitThread  := UInt64(GetProcAddress(hKernel32, 'ExitThread'))
  else
    Inject.AddrExitThread := ETAddress;

  Move(ModuleName^, Inject.LibraryName, Length(ModuleName));

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

  // ���������� �������� ��� � ���������� ������:
  if NtWriteVirtualMemory(ProcessHandle, NativeUInt(Memory), @Inject, SizeOf(Inject), BytesWritten) <> 0 then Exit;

  // ��������� �������� ��� � ��������� ������:
  hThread := CreateRemoteThread(ProcessHandle, nil, 0, Memory, nil, 0, ThreadId);

  if hThread = 0 then
  begin
    VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);
    EmptyWorkingSet(ProcessHandle);
    CloseHandle(ProcessHandle);
    Exit;
  end;

  WaitForSingleObject(hThread, INFINITE);
  VirtualFreeEx(ProcessHandle, Memory, 0, MEM_RELEASE);

  CloseHandle(hThread);
  EmptyWorkingSet(ProcessHandle);
  CloseHandle(ProcessHandle);

  Result := True;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// �������� ���� �������� �� ���������:
procedure InjectFunction(ProcessID: LongWord; InjectedFunction: Pointer; InjectedFunctionSize: NativeUInt);
var
  hProcess: NativeUInt;
  RemoteThreadBaseAddress: Pointer;
  BytesWritten: NativeUInt;
  RemoteThreadHandle: NativeUInt;
  RemoteThreadID: LongWord;
begin
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessID);
  if hProcess = 0 then
  begin
    MessageBox(0, '�� ������� ������� ������� ��� ������!', '������!', MB_ICONERROR);
    Exit;
  end;

  // ������ ������ � ��������:
  RemoteThreadBaseAddress := VirtualAllocEx(hProcess, nil, InjectedFunctionSize, MEM_COMMIT + MEM_RESERVE, PAGE_EXECUTE_READWRITE);

  // ����� � ������ ��� ���:
  NtWriteVirtualMemory(hProcess, NativeUInt(RemoteThreadBaseAddress), InjectedFunction, InjectedFunctionSize, BytesWritten);
  if InjectedFunctionSize <> BytesWritten then
  begin
    MessageBox(0, '�� ������� �������� ��� � ������ ��������� ��������!', '������!', MB_ICONERROR);
    VirtualFreeEx(hProcess, RemoteThreadBaseAddress, InjectedFunctionSize, MEM_RELEASE);
    Exit;
  end;

  RemoteThreadHandle := CreateRemoteThread(hProcess, nil, 0, RemoteThreadBaseAddress, nil, 0, RemoteThreadID);
  if RemoteThreadHandle = 0 then
  begin
    MessageBox(0, '�� ������� ��������� ����� � �������� ��������!', '������!', MB_ICONERROR);
    VirtualFreeEx(hProcess, RemoteThreadBaseAddress, InjectedFunctionSize, MEM_RELEASE);
    Exit;
  end;
end;


end.
