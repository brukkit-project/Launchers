unit RegistryUtils;

interface

uses
  Windows, Registry;

function GetCurrentJavaPath: string;

// Запись параметров:
procedure SaveStringToRegistry(const Path, Name, Value: string);
procedure SaveBooleanToRegistry(const Path, Name: string; Value: Boolean);
procedure SaveNumberToRegistry(const Path, Name: string; Value: Integer);

// Чтение параметров:
function ReadStringFromRegistry(const Path, Name: string; DefaultValue: string = ''): string;
function ReadBooleanFromRegistry(const Path, Name: string; DefaultValue: Boolean = False): Boolean;
function ReadNumberFromRegistry(const Path, Name: string; DefaultValue: Integer = 0): Integer;

implementation

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetCurrentJavaPath: string;
var
  Reg: TRegistry;
  CurrentVersion: string;
begin
  Reg := TRegistry.Create;
  Reg.Access := KEY_WOW64_64KEY or KEY_ALL_ACCESS;
  Reg.RootKey := HKEY_LOCAL_MACHINE;

  Result := '';

  if Reg.OpenKey('SOFTWARE\JavaSoft\Java Runtime Environment', False) then
  begin
    CurrentVersion := Reg.ReadString('CurrentVersion');
    if CurrentVersion <> '' then
    begin
      Reg.CloseKey;

      if Reg.OpenKey('SOFTWARE\JavaSoft\Java Runtime Environment\' + CurrentVersion, false) then
      begin
        Result := Reg.ReadString('JavaHome') + '\bin';
      end;
    end;
  end;

  Reg.CloseKey;
  Reg.Free;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure SaveStringToRegistry(const Path, Name, Value: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.Access := KEY_WOW64_64KEY or KEY_ALL_ACCESS;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.OpenKey('SOFTWARE\' + Path, True) then
  begin
    Reg.WriteString(Name, Value);
  end;

  Reg.CloseKey;
  Reg.Free;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure SaveBooleanToRegistry(const Path, Name: string; Value: Boolean);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.Access := KEY_WOW64_64KEY or KEY_ALL_ACCESS;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.OpenKey('SOFTWARE\' + Path, True) then
  begin
    if Value then
      Reg.WriteString(Name, 'true')
    else
      Reg.WriteString(Name, 'false');
  end;

  Reg.CloseKey;
  Reg.Free;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure SaveNumberToRegistry(const Path, Name: string; Value: Integer);
var
  Reg: TRegistry;
  ValueStr: string;
begin
  Reg := TRegistry.Create;
  Reg.Access := KEY_WOW64_64KEY or KEY_ALL_ACCESS;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.OpenKey('SOFTWARE\' + Path, True) then
  begin
    Str(Value, ValueStr);
    Reg.WriteString(Name, ValueStr);
  end;

  Reg.CloseKey;
  Reg.Free;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function ReadStringFromRegistry(const Path, Name: string; DefaultValue: string = ''): string;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.Access := KEY_WOW64_64KEY or KEY_ALL_ACCESS;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.OpenKey('SOFTWARE\' + Path, False) then
  begin
    Result := Reg.ReadString(Name);
    if (Result = '') and (DefaultValue <> '') then Result := DefaultValue;
  end;

  Reg.CloseKey;
  Reg.Free;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function ReadBooleanFromRegistry(const Path, Name: string; DefaultValue: Boolean = False): Boolean;
var
  Reg: TRegistry;
  ValueStr: string;
begin
  Reg := TRegistry.Create;
  Reg.Access := KEY_WOW64_64KEY or KEY_ALL_ACCESS;
  Reg.RootKey := HKEY_CURRENT_USER;

  Result := DefaultValue;

  if Reg.OpenKey('SOFTWARE\' + Path, False) then
  begin
    ValueStr := Reg.ReadString(Name);
    if ValueStr = 'true' then
      Result := True
    else
      Result := False;
  end;

  Reg.CloseKey;
  Reg.Free;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function ReadNumberFromRegistry(const Path, Name: string; DefaultValue: Integer = 0): Integer;
var
  Reg: TRegistry;
  ValueStr: string;
  Code: LongWord;
begin
  Reg := TRegistry.Create;
  Reg.Access := KEY_WOW64_64KEY or KEY_ALL_ACCESS;
  Reg.RootKey := HKEY_CURRENT_USER;

  Result := DefaultValue;

  if Reg.OpenKey('SOFTWARE\' + Path, False) then
  begin
    ValueStr := Reg.ReadString(Name);
    if ValueStr <> '' then Val(ValueStr, Result, Code);
  end;

  Reg.CloseKey;
  Reg.Free;
end;

end.
