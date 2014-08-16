unit Additions;

interface


type
  TMemoryStatusEx = record
    dwLength: LongWord;
    dwMemoryLoad: LongWord;
    ullTotalPhys: Int64;
    ullAvailPhys: Int64;
    ullTotalPageFile: Int64;
    ullAvailPageFile: Int64;
    ullTotalVirtual: Int64;
    ullAvailVirtual: Int64;
    ullAvailExtendedVirtual: Int64;
  end;

procedure GlobalMemoryStatusEx(var lpBuffer: TMemoryStatusEx); stdcall; external 'kernel32.dll' name 'GlobalMemoryStatusEx';

function GetFreeMemory: Int64;
function DeleteDirectory(Directory: string): Boolean;
function GetSpecialFolderPath(folder: integer): string;
function GetXMLParameter(Data: string; Param: string): string;
function IntToStr(Value: LongWord): string;
function StrToInt(Value: string): integer;
function Is64BitWindows: Boolean;
procedure UnpackFile(SourceFile, DestinationFolder: string);
function CheckSymbols(Input: string): Boolean;

implementation

uses
  Windows, ShFolder, SysUtils, TlHelp32, ShellAPI, cHash, Classes, fwZipReader;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetFreeMemory: Int64;
var
  lpBuffer: TMemoryStatusEx;
begin
  lpBuffer.dwLength := SizeOf(lpBuffer);
  GlobalMemoryStatusEx(lpBuffer);
  Result := lpBuffer.ullAvailPhys div 1048576;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function DeleteDirectory(Directory: string): Boolean;
var
  FileOpStruct: TSHFileOpStruct;
begin
  ZeroMemory(@FileOpStruct, SizeOf(FileOpStruct));
  with FileOpStruct do
  begin
    wFunc  := FO_DELETE;
    fFlags := FOF_SILENT or FOF_NOCONFIRMATION;
    pFrom  := PChar(Directory + #0);
  end;
  Result := (0 = ShFileOperation(FileOpStruct));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetSpecialFolderPath(Folder: Integer): string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0,folder,0,SHGFP_TYPE_CURRENT,@path[0])) then
    Result := path
  else
    Result := '';
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetXMLParameter(Data: string; Param: string): string;
var
  PosStart, PosEnd: Word;
  StartParam, EndParam: string;
begin
  Result := '';
  StartParam := '<'+Param+'>';
  EndParam := '</'+Param+'>';
  PosStart := Pos(StartParam, Data);
  PosEnd := Pos(EndParam, Data);

  if PosStart = 0 then Exit;
  if PosEnd <= PosStart then Exit;

  PosStart := PosStart + Length(StartParam);
  Result := Copy(Data, PosStart, PosEnd - PosStart);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function IntToStr(Value: LongWord): string;
begin
  Str(Value, Result);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function StrToInt(Value: string): integer;
var
  Code: integer;
begin
  Val(Value, Result, Code);
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


procedure UnpackFile(SourceFile, DestinationFolder: string);
var
  Reader: TFwZipReader;
begin
  Reader := TFwZipReader.Create;
  Reader.LoadFromFile(SourceFile);
  Reader.ExtractAll(DestinationFolder);
  FreeAndNil(Reader);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Проверка на запрещённые символы:
function CheckSymbols(Input: string): Boolean;
var
  C: Char;
begin
  Result := False;
  for C in Input do
    if C in ['/', '\', ':', '?', '|', '*', '"', '<', '>', ' '] then
    begin
      Result := True;
      Exit;
    end;
end;

end.
