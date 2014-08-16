unit FileAPI;

interface

procedure CreatePath(EndDir: string);
{
  ������ �������� ��������� �� ��������� �������� ������������.
  ����������� �����������: "\" � "/"
}

function ExtractFileDir(Path: string): string;
{
  ��������� ���� � �����. ����������� �����������: "\" � "/"
}

function ExtractFileName(Path: string): string;
{
  ��������� ��� �����. ����������� �����������: "\" � "/"
}

function ExtractHost(Path: string): string;
{
  ��������� ��� ����� �� �������� ������.
  http://site.ru/folder/script.php  -->  site.ru
}

function ExtractObject(Path: string): string;
{
  ��������� ��� ������� �� �������� ������:
  http://site.ru/folder/script.php  -->  folder/script.php
}

implementation

function CreateDirectory(
                          PathName: PChar;
                          lpSecurityAttributes: Pointer
                         ): LongBool; stdcall; external 'kernel32.dll' name 'CreateDirectoryA';

// ��������� ������ � �������� �������� � ��������:
// ����������� ����������� "\" � "/"

// ������ �������� ����� �� �������� ��������� ����� ������������:
procedure CreatePath(EndDir: string);
var
  I: LongWord;
  PathLen: LongWord;
  TempPath: string;
begin
  PathLen := Length(EndDir);
  if (EndDir[PathLen] = '\') or (EndDir[PathLen] = '/') then Dec(PathLen);
  TempPath := Copy(EndDir, 0, 3);
  for I := 4 to PathLen do
  begin
    if (EndDir[I] = '\') or (EndDir[I] = '/') then CreateDirectory(PAnsiChar(TempPath), nil);
    TempPath := TempPath + EndDir[I];
  end;
  CreateDirectory(PAnsiChar(TempPath), nil);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// �������� �������, � ������� ����� ����:
function ExtractFileDir(Path: string): string;
var
  I: LongWord;
  PathLen: LongWord;
begin
  PathLen := Length(Path);
  I := PathLen;
  while (I <> 0) and (Path[I] <> '\') and (Path[I] <> '/') do Dec(I);
  Result := Copy(Path, 0, I);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// �������� ��� �����:
function ExtractFileName(Path: string): string;
var
  I: LongWord;
  PathLen: LongWord;
begin
  PathLen := Length(Path);
  I := PathLen;
  while (Path[I] <> '\') and (Path[I] <> '/') and (I <> 0) do Dec(I);
  Result := Copy(Path, I + 1, PathLen - I);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// ��������� ��� �����:
// http://site.ru/folder/script.php  -->  site.ru
function ExtractHost(Path: string): string;
var
  I: LongWord;
  PathLen: LongWord;
begin
  PathLen := Length(Path);
  I := 8; // ����� "http://"
  while (I <= PathLen) and (Path[I] <> '\') and (Path[I] <> '/') do Inc(I);
  Result := Copy(Path, 8, I - 8);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// ��������� ��� �������:
// http://site.ru/folder/script.php  -->  folder/script.php
function ExtractObject(Path: string): string;
var
  I: LongWord;
  PathLen: LongWord;
begin
  PathLen := Length(Path);
  I := 8;
  while (I <= PathLen) and (Path[I] <> '\') and (Path[I] <> '/') do Inc(I);
  Result := Copy(Path, I + 1, PathLen - I);
end;


end.
