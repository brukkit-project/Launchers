unit PostRequest;

interface

procedure AddPOSTField(var Data: pointer; var Size: LongWord; Param, Value: string);
procedure AddPOSTFile(var Data: pointer; var Size: LongWord; Param, Value, FilePath, ContentType: string);
function HTTPPost(ScriptAddress: string; Data: pointer; Size: LongWord): string;

implementation

uses
  Windows, WinInet;

const
  AgentName: PAnsiChar = 'Internet Client';
  lpPOST: PAnsiChar = 'POST';
  lpGET: PAnsiChar = 'GET';
  HTTPVer: PAnsiChar = 'HTTP/1.1';
  Boundary: string = 'DisIsUniqueBoundary4POSTRequestYouShouldUseInYourFuckingApps';

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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Добавляет в запрос текстовое поле:
procedure AddPOSTField(var Data: pointer; var Size: LongWord; Param, Value: string);
var
  NewMemSize: LongWord;
  NewPtr: pointer;
  StrData: string;
  DataLen: LongWord;
begin
  StrData := '';
  if Size <> 0 then StrData := StrData + #13#10;
  StrData := StrData + '--' + Boundary + #13#10;
  StrData := StrData + 'Content-Disposition: form-data; name="' + Param + '"' + #13#10;
  StrData := StrData + #13#10;
  StrData := StrData + Value;

  DataLen := Length(StrData);
  NewMemSize := Size + DataLen;

  if Size = 0 then
    GetMem(Data, NewMemSize)
  else
    ReallocMem(Data, NewMemSize);

// Установили указатель на конец старого блока и записали данные:
  NewPtr := Pointer(LongWord(Data) + Size);
  Move((@StrData[1])^, NewPtr^, DataLen);

  Size := NewMemSize;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Добавляет в запрос файл:
procedure AddPOSTFile(var Data: pointer; var Size: LongWord; Param, Value, FilePath, ContentType: string);
var
  hFile: THandle;
  FileSize, ReadBytes: LongWord;
  Buffer: pointer;

  NewMemSize: LongWord;
  NewPtr: pointer;
  StrData: string;
  DataLen: LongWord;
begin
  hFile := CreateFile(PAnsiChar(FilePath), GENERIC_READ, 0, nil, OPEN_EXISTING, 128, 0);
  FileSize := GetFileSize(hFile, nil);
  GetMem(Buffer, FileSize);

  ReadFile(hFile, Buffer^, FileSize, ReadBytes, nil);
  CloseHandle(hFile);

  StrData := '';
  if Size <> 0 then StrData := StrData + #13#10;
  StrData := StrData + '--' + Boundary + #13#10;
  StrData := StrData + 'Content-Disposition: form-data; name="' + Param + '"; filename="' + Value + '"' + #13#10;
  StrData := StrData + 'Content-Type: ' + ContentType + #13#10;
  StrData := StrData + #13#10;
  DataLen := Length(StrData);

  NewMemSize := Size + DataLen + ReadBytes;

  if Size = 0 then
    GetMem(Data, NewMemSize)
  else
    ReallocMem(Data, NewMemSize);

// Установили указатель на конец старого блока и записали данные:
  NewPtr := Pointer(LongWord(Data) + Size);
  Move((@StrData[1])^, NewPtr^, DataLen);

  NewPtr := Pointer(LongWord(NewPtr) + DataLen);
  Move(Buffer^, NewPtr^, ReadBytes);

  FreeMem(Buffer);
  Size := NewMemSize;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Выполнение запроса:
function HTTPPost(ScriptAddress: string; Data: pointer; Size: LongWord): string;
var
  hInet, hConnect, hRequest: hInternet;
  ReceivedBytes: LongWord;
  Buffer: pointer;
  Response: string;
  Host: PAnsiChar;
  ScriptName: PAnsiChar;

  StrData: string;
  NewPtr: pointer;
  NewMemSize: LongWord;
  DataLen: LongWord;
const
  Header: string = 'Content-Type: multipart/form-data; boundary=';
  ReceiverSize: LongWord = 512;
begin
  Host := PAnsiChar(ExtractHost(ScriptAddress));
  ScriptName := PAnsiChar(ExtractObject(ScriptAddress));

  // Устанавливаем соединение:
  hInet := InternetOpen(@AgentName[1], 0, nil, nil, 0);
  hConnect := InternetConnect(hInet, Host, 80, nil, nil, 3, 0, 0);
  hRequest := HTTPOpenRequest(hConnect, lpPOST, ScriptName, HTTPVer, nil, nil, $4000000 + $100 + $80000000 + $800, 0);

  // Посылаем запрос:
  if Size = 0 then
  begin
    Result := '[PEACE OF SHIT]: Error at sending request: send data not present!';
    Exit;
  end;

  StrData := #13#10 + '--' + Boundary + '--'; // Завершаем Boundary до вида "--boundary--"

  DataLen := LongWord(Length(StrData));
  NewMemSize := DataLen + Size;
  ReallocMem(Data, NewMemSize);
  NewPtr := Pointer(LongWord(Data) + Size);
  Move((@StrData[1])^, NewPtr^, DataLen);

  HTTPSendRequest(hRequest, PAnsiChar(Header + Boundary), Length(Header + Boundary), Data, NewMemSize);
  FreeMem(Data);

  // Получаем ответ:
  GetMem(Buffer, ReceiverSize);

  Response := '';

  repeat
    InternetReadFile(hRequest, Buffer, ReceiverSize, ReceivedBytes);
    if ReceivedBytes <> 0 then Response := Response + Copy(PAnsiChar(Buffer), 0, ReceivedBytes);
  until ReceivedBytes = 0;

  FreeMem(Buffer);

  InternetCloseHandle(hRequest);
  InternetCloseHandle(hConnect);
  InternetCloseHandle(hInet);

  Result := Response;
end;

end.
