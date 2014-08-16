unit FileAPI;

interface

procedure CreatePath(EndDir: string);
{
  Создаёт иерархию каталогов до конечного каталога включительно.
  Допускаются разделители: "\" и "/"
}

function ExtractFileDir(Path: string): string;
{
  Извлекает путь к файлу. Допускаются разделители: "\" и "/"
}

function ExtractFileName(Path: string): string;
{
  Извлекает имя файла. Допускаются разделители: "\" и "/"
}

function ExtractHost(Path: string): string;
{
  Извлекает имя хоста из сетевого адреса.
  http://site.ru/folder/script.php  -->  site.ru
}

function ExtractObject(Path: string): string;
{
  Извлекает имя объекта из сетевого адреса:
  http://site.ru/folder/script.php  -->  folder/script.php
}

implementation

function CreateDirectory(
                          PathName: PChar;
                          lpSecurityAttributes: Pointer
                         ): LongBool; stdcall; external 'kernel32.dll' name 'CreateDirectoryA';

// Процедуры работы с файловой системой и адресами:
// Допускаются разделители "\" и "/"

// Создаёт иерархию папок до конечной указанной папки включительно:
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

// Получает каталог, в котором лежит файл:
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

// Получает имя файла:
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

// Извлекает имя хоста:
// http://site.ru/folder/script.php  -->  site.ru
function ExtractHost(Path: string): string;
var
  I: LongWord;
  PathLen: LongWord;
begin
  PathLen := Length(Path);
  I := 8; // Длина "http://"
  while (I <= PathLen) and (Path[I] <> '\') and (Path[I] <> '/') do Inc(I);
  Result := Copy(Path, 8, I - 8);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Извлекает имя объекта:
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
