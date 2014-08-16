unit MultiserverUtils;

interface

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{$I Definitions.inc}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

uses
  Additions, LauncherSettings, StdCtrls;

procedure GetServerList(Response: string);
procedure SetLauncherSettings(ServerNumber: Byte);
procedure FillServerComboBox(var ComboBox: TComboBox);

type
  TServer = record
    Name: string;          // Имя сервера
    Folder: string;        // Папка в Minepath
    Natives: string;       // Папка для *.dll относительно Folder
    MineJar: string;       // Папка до клиента относительно Folder
    AssetsFolder: string;  // Папка до Assets относительно Folder
    MainClass: string;     // Главный класс
    ClientAddress: string; // Адрес Main.zip
    AssetsAddress: string; // Адрес Assets.zip
    GameVersion: string;   // Версия запускаемого клиента
    AssetIndex: string;    // Индекс для Assets
    TweakClass: string;    // Дополнительные параметры классов
    PrimaryIP: string;     // Основной IP обвязки и сервера
    SecondaryIP: string;   // Запасной IP обвязки и сервера
    Port: string;          // Порт обвязки
    BukkitPort: string;    // Порт сервера
  end;

var
  Servers: array of TServer;

{$IFDEF LOCAL_SERVERS_LIST}
  {$I LocalServersList.inc}
{$ENDIF}

implementation

// Получение списка серверов:
procedure GetServerList(Response: string);
var
  I: byte;

  ServersCountString: string;
  ServersCount: byte;

  ServerInfo: string;
begin
  ServersCountString := GetXMLParameter(Response, 'count');
  if Length(ServersCountString) = 0 then Exit;

  ServersCount := StrToInt(ServersCountString);
  if ServersCount = 0 then Exit;

  SetLength(Servers, ServersCount);

  for I := 1 to ServersCount do
  begin
    ServerInfo := GetXMLParameter(Response, 'server' + IntToStr(I));
    with Servers[I - 1] do
    begin
      Name := GetXMLParameter(ServerInfo, 'name');
      Folder := GetXMLParameter(ServerInfo, 'folder');
      MineJar := GetXMLParameter(ServerInfo, 'minejar_folder');
      Natives := GetXMLParameter(ServerInfo, 'natives');
      AssetsFolder := GetXMLParameter(ServerInfo, 'assets_folder');
      ClientAddress := GetXMLParameter(ServerInfo, 'client_address');
      AssetsAddress := GetXMLParameter(ServerInfo, 'assets_address');
      MainClass := GetXMLParameter(ServerInfo, 'main_class');
      GameVersion := GetXMLParameter(ServerInfo, 'game_version');
      AssetIndex := GetXMLParameter(ServerInfo, 'asset_index');
      PrimaryIP := GetXMLParameter(ServerInfo, 'primary_ip');
      SecondaryIP := GetXMLParameter(ServerInfo, 'secondary_ip');
      Port := GetXMLParameter(ServerInfo, 'serverport');
      BukkitPort := GetXMLParameter(ServerInfo, 'gameport');
      TweakClass := GetXMLParameter(ServerInfo, 'tweak_class');
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure SetLauncherSettings(ServerNumber: Byte);
begin
  MineJarFolder := Servers[ServerNumber].MineJar;
  NativesPath := Servers[ServerNumber].Natives;
  AssetsFolder := Servers[ServerNumber].AssetsFolder;
  ClientAddress := Servers[ServerNumber].ClientAddress;
  AssetsAddress := Servers[ServerNumber].AssetsAddress;
  MainClass := Servers[ServerNumber].MainClass;
  GameVersion := Servers[ServerNumber].GameVersion;
  AssetIndex := Servers[ServerNumber].AssetIndex;
  PrimaryIP := Servers[ServerNumber].PrimaryIP;
  SecondaryIP := Servers[ServerNumber].SecondaryIP;
  ServerPort := StrToInt(Servers[ServerNumber].Port);
  GamePort := Servers[ServerNumber].BukkitPort;
  TweakClass := Servers[ServerNumber].TweakClass;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure FillServerComboBox(var ComboBox: TComboBox);
var
  I: Byte;
  ServersCount: LongWord;
begin
  ServersCount := Length(Servers);
  ComboBox.Items.Clear;

  if ServersCount = 0 then Exit;

  for I := 0 to ServersCount - 1 do ComboBox.Items.Add(Servers[I].Name);

  ComboBox.ItemIndex := 0;
  ComboBox.OnSelect(ComboBox);
end;

end.
