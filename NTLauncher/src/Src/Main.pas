﻿unit Main;

interface

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{
  LauncherSettings.pas - Configurações do launcher
  Definitions.inc - sinalizadores de compilação condicional
}

{$I Definitions.inc}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms,
  ScktComp, ExtCtrls, StdCtrls, HTTPSend, BlckSock,
  Additions, RegistryUtils, LauncherSettings, HashUtils, FileAPI,
  Perimeter, SkinSystem, HWID, MinecraftLauncher, MultiserverUtils,
  PostRequest, Dialogs, Defence, PNGImage,
  ShellAPI, ComCtrls, Graphics, ProcessAPI;

type
  TMainForm = class(TForm)
    ClientSocket: TClientSocket;
    LoginEdit: TEdit;
    PasswordEdit: TEdit;
    MailEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    AuthButton: TButton;
    RegLabel: TLabel;
    AutoLoginCheckbox: TCheckBox;
    RAMEdit: TEdit;
    JavaEdit: TEdit;
    MainLabel: TLabel;
    MainSizeOfFileLabel: TLabel;
    MainDownloadedLabel: TLabel;
    MainSpeedLabel: TLabel;
    MainRemainingTimeLabel: TLabel;
    AssetsLabel: TLabel;
    AssetsSizeOfFileLabel: TLabel;
    AssetsDownloadedLabel: TLabel;
    AssetsSpeedLabel: TLabel;
    AssetsRemainingTimeLabel: TLabel;
    GameButton: TButton;
    DownloadMainButton: TButton;
    DownloadAssetsButton: TButton;
    SkinImage: TImage;
    CloakImage: TImage;
    ServerListComboBox: TComboBox;
    ChooseSkinButton: TButton;
    UploadSkinButton: TButton;
    ChooseCloakButton: TButton;
    UploadCloakButton: TButton;
    OpenLauncherFolder: TButton;
    OpenClientFolder: TButton;
    MainPageControl: TPageControl;
    AuthSheet: TTabSheet;
    GameSheet: TTabSheet;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    FreeRAMLabel: TLabel;
    DeauthLabel: TLabel;
    LauncherTitle: TLabel;
    Label7: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ClientSocketConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure GameButtonClick(Sender: TObject);
    procedure RegLabelClick(Sender: TObject);
    procedure AuthButtonClick(Sender: TObject);
    procedure SetupConnect;
    procedure DownloadMainButtonClick(Sender: TObject);
    procedure DownloadAssetsButtonClick(Sender: TObject);
    procedure ServerListComboBoxSelect(Sender: TObject);
    procedure ChooseSkinButtonClick(Sender: TObject);
    procedure ChooseCloakButtonClick(Sender: TObject);
    procedure UploadSkinButtonClick(Sender: TObject);
    procedure UploadCloakButtonClick(Sender: TObject);
    procedure OpenLauncherFolderClick(Sender: TObject);
    procedure OpenClientFolderClick(Sender: TObject);
    function CallProc(FunctionID: LongWord): Boolean;
    procedure RegLabelMouseEnter(Sender: TObject);
    procedure RegLabelMouseLeave(Sender: TObject);
    procedure RegLabelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RegLabelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DeauthLabelMouseEnter(Sender: TObject);
    procedure DeauthLabelMouseLeave(Sender: TObject);
    procedure DeauthLabelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DeauthLabelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DeauthLabelClick(Sender: TObject);
    procedure FreeRAMLabelClick(Sender: TObject);
    procedure MainRemainingTimeLabelClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

// Uma matriz de eventos para clientes de carga de tópicos:
var
  ArrayEvents: array [0..1] of THandle = (INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE);

const
  EVENT_MAIN   = 0;
  EVENT_ASSETS = 1;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Tipo do arquivo para download:
const
  ARCHIVE_MAIN   = 0;
  ARCHIVE_ASSETS = 1;

const
  DOWNLOAD_SUCCESS         = 0;
  DOWNLOAD_ACTIVE          = 1;
  DOWNLOAD_UNPACKING       = 2;
  DOWNLOAD_WAITING         = 3;
  DOWNLOAD_FILE_NOT_EXISTS = 4;

type
  TDownloadArchiveThread = class(TThread)
    protected
    ArchiveType: Byte;

    URL: string;
    Destination: string;

    FileSize: Integer;
    Downloaded: Integer;
    Speed: Single;
    RemainingTime: Single;

    Status: Byte;

    StartTimeCounter: Int64;
    OldTimeCounter: Int64;
    PerformanceFrequency: Int64;

    Accumulator: Integer;

    PlayAfterDownloading: Boolean;

    procedure Execute; override;
    procedure OnSockStatus(Sender: TObject; Reason: THookSocketReason; const Value: string);
    procedure UpdateForm;
  end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Tipo de imagens carregadas:
const
  IMAGE_SKIN  = 0;
  IMAGE_CLOAK = 1;

type
  TDownloadImageThread = class(TThread)
    protected
    ImageType: Byte;

    URL: string;
    HTTPClient: THTTPSend;
    procedure Execute; override;
    procedure UpdateForm;
  end;


// Constante tipo de conexão socket:
const
  TYPE_AUTH     = 0;
  TYPE_REG      = 1;
  TYPE_GAMEAUTH = 2;
  TYPE_BEACON   = 3;
  TYPE_DEAUTH   = 4;

var
  TypeOfConnection: Byte = TYPE_AUTH;

var
  Mainpath: string; // pasta do launcher
  Minepath: string; // pasta com o cliente

  // Variáveis ​​para armazenar maneira temporária a skin e capa de baixá-los para o s
  TempSkinPath: string;
  TempCloakPath: string;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{
procedure DoDoubleBuffering(Form: TForm);
var
  Component: TComponent;
begin
  Form.DoubleBuffered := True;
  for Component in Form do
    if (Component is TLabel) or
       (Component is TPanel) or
       (Component is TButton) or
       (Component is TImage) or
       (Component is TEdit) then TButton(Component).DoubleBuffered := True;
end;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TMainForm.FormCreate(Sender: TObject);
{$IFDEF LAUNCH_PERIMETER}
var
  PerimeterInputData: TPerimeterInputData;
{$ENDIF}
begin
  //DoDoubleBuffering(MainForm);

  {$IFDEF LAUNCH_PERIMETER}
    FillChar(PerimeterInputData, SizeOf(PerimeterInputData), #0);
    PerimeterInputData.ResistanceType := ShutdownProcess;
    PerimeterInputData.CheckingsType := LazyROM + ASM_A + ASM_B + IDP + WINAPI_BP + ZwSIT + ZwQIP;
    PerimeterInputData.MainFormHandle := Handle;
    PerimeterInputData.Interval := 300;
    InitPerimeter(PerimeterInputData);
  {$ENDIF}

  // Leia as configurações do Registro:
  LoginEdit.Text := ReadStringFromRegistry(RegistryPath, 'Login');
  PasswordEdit.Text := ReadStringFromRegistry(RegistryPath, 'Password');
  RAMEdit.Text := ReadStringFromRegistry(RegistryPath, 'RAM');

  {$IFDEF CUSTOM_JAVA}
  JavaEdit.Text := '### CUSTOM JAVA ###';
  {$ELSE}
    {$IFDEF DETECT_JAVA_PATH}
    JavaEdit.Text := ReadStringFromRegistry(RegistryPath, 'Java', GetCurrentJavaPath);
    {$ELSE}
    JavaEdit.Text := ReadStringFromRegistry(RegistryPath, 'Java', 'C:\Program Files\Java\jre8\bin');
    {$ENDIF}
  {$ENDIF}

  AutoLoginCheckbox.Checked := ReadBooleanFromRegistry(RegistryPath, 'AutoLogin');


  {$IFDEF MULTISERVER}
  ServerListComboBox.Visible := True;
  {$ENDIF}

  // Criar pinos eventos para fluxos de downloads:
  ArrayEvents[EVENT_MAIN] := CreateEvent(nil, TRUE, FALSE, nil);
  ArrayEvents[EVENT_ASSETS] := CreateEvent(nil, TRUE, FALSE, nil);
  SetEvent(ArrayEvents[EVENT_MAIN]);
  SetEvent(ArrayEvents[EVENT_ASSETS]);

  // Criar um caminho primário eo caminho para o cliente:
  Mainpath := GetSpecialFolderPath(26) + MainFolder;
  Minepath := Mainpath;

  // Se auto login vale a pena, então o login:
  TypeOfConnection := TYPE_AUTH;
  if AutoLoginCheckbox.Checked then
  begin
    AuthButton.OnClick(Self);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.AuthButtonClick(Sender: TObject);
begin
// Confira os dados:
  // Login:
  if Length(LoginEdit.Text) = 0 then
  begin
    MessageBox(Handle, 'Digite seu login!', 'Error!', MB_ICONERROR);
    Exit;
  end;

  if CheckSymbols(LoginEdit.Text) then
  begin
    MessageBox(Handle, 'Caracteres inválidos!', 'Error!', MB_ICONERROR);
    Exit;
  end;

  // Пароль:
  if Length(PasswordEdit.Text) = 0 then
  begin
    MessageBox(Handle, 'Digite a senha!', 'Error!', MB_ICONERROR);
    Exit;
  end;

  // Caracteres inválidos em uma verificação de senha, uma vez que que é criptografada.

  // E-mail:
  if TypeOfConnection = TYPE_REG then
  begin
    if Length(MailEdit.Text) = 0 then
    begin
      MessageBox(Handle, 'Digite seu login!', 'Error!', MB_ICONERROR);
      Exit;
    end;

    if CheckSymbols(MailEdit.Text) then
    begin
      MessageBox(Handle, 'Caracteres inválidos', 'Error!', MB_ICONERROR);
      Exit;
    end;

    if Pos('@', MailEdit.Text) = 0 then
    begin
      MessageBox(Handle, 'E-mail inválido!', 'Error!', MB_ICONERROR);
      Exit;
    end;
  end;

  SetupConnect;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.GameButtonClick(Sender: TObject);
begin
  TypeOfConnection := TYPE_GAMEAUTH;
  SetupConnect;
end;

procedure TMainForm.MainRemainingTimeLabelClick(Sender: TObject);
begin

end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Malha de conexão:
procedure TMainForm.SetupConnect;
begin
  // Configurar um soquete na conexão primária:
  ClientSocket.Host := PrimaryIP;
  ClientSocket.Port := ServerPort;

  try
    ClientSocket.Open;
  except
    ClientSocket.Close;

    // Falha na conexão com o IP principal, tente reconectar:
    try
      ClientSocket.Host := SecondaryIP;
      ClientSocket.Open;
    except
      ClientSocket.Close;
      MessageBox(Handle, 'Não foi possível se conectar!', 'Error!', MB_ICONERROR);
    end;
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// tracker:
procedure BeaconThreadProc;
begin
  TypeOfConnection := TYPE_BEACON;
  MainForm.SetupConnect;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Autorização:
procedure DeauthThreadProc;
begin
  TypeOfConnection := TYPE_DEAUTH;
  MainForm.SetupConnect;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TMainForm.ClientSocketConnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
  WinSocketStream: TWinSocketStream;
  Buffer: array [0..65534] of Char;

  Received: string;
  Response: string;

  DownloadSkin, DownloadCloak: TDownloadImageThread;

  MCData: TMinecraftData;
  MCProcessInfo: TMCProcessInfo;
begin
  // Criar um thread para lidar com a resposta do servidor:
  WinSocketStream := TWinSocketStream.Create(ClientSocket.Socket, 3000);

  // Envie uma mensagem:
  case TypeOfConnection of
    TYPE_AUTH:
      ClientSocket.Socket.SendText(
                                    GlobalSalt +
                                    '<type>auth</type>' +
                                    '<login>' + LoginEdit.Text + '</login>' +
                                    '<password>' + HashPassword(PasswordEdit.Text) + '</password>'
                                   );

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    TYPE_REG:
      ClientSocket.Socket.SendText(
                                    GlobalSalt +
                                    '<type>reg</type>' +
                                    '<login>' + LoginEdit.Text + '</login>' +
                                    '<password>' + HashPassword(PasswordEdit.Text) + '</password>' +
                                    '<mail>' + MailEdit.Text + '</mail>' +
                                    '<hwid>' + GetHWID + '</hwid>'
                                   );

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    TYPE_GAMEAUTH:
      ClientSocket.Socket.SendText(
                                    GlobalSalt +
                                    '<type>gameauth</type>' +
                                    '<login>' + LoginEdit.Text + '</login>' +
                                    '<password>' + HashPassword(PasswordEdit.Text) + '</password>' +
                                    '<md5>' + GetGameHash(Minepath) + '</md5>' +
                                    '<hwid>' + GetHWID + '</hwid>'
                                   );

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    TYPE_BEACON:
      ClientSocket.Socket.SendText(
                                    GlobalSalt +
                                    '<type>beacon</type>' +
                                    '<login>' + LoginEdit.Text + '</login>' +
                                    '<md5>' + GetGameHash(Minepath) + '</md5>'
                                   );

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    TYPE_DEAUTH:
      ClientSocket.Socket.SendText(
                                    GlobalSalt +
                                    '<type>deauth</type>' +
                                    '<login>' + LoginEdit.Text + '</login>'
                                   );

  end;


//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -


  // Aguardando resposta:
  if WinSocketStream.WaitForData(WinSocketStream.TimeOut) then
  begin
    WinSocketStream.Read(Buffer, 65535);
    Received := Buffer;

    // Verifique a versão do launcher:
    if TypeOfConnection = TYPE_AUTH then
    begin
      if StrToInt(GetXMLParameter(Received, 'version')) <> LauncherVersion then
      begin
        MessageBox(Handle, 'O seu launcher está desatualizado!' + #13#10 + 'Baixe a versão mais recente!', 'Error!', MB_ICONERROR);
        FreeAndNil(WinSocketStream);
        ClientSocket.Close;
        ExitProcess(0);
      end;
    end;

    // Launcher correto, seguimos em frente:
    Response := GetXMLParameter(Received, 'response');

    
    if Response = 'salt fault' then
      MessageBox(Handle, 'Erro interno!', 'Error!', MB_ICONERROR);


    if Response = 'incorrect data' then
      MessageBox(Handle, 'Caracteres inválidos!', 'Error!', MB_ICONERROR);


    if Response = 'bad login' then
      MessageBox(Handle, 'Nome de usuário ou senha inválida!', 'Error!', MB_ICONERROR);


    if Response = 'already exists' then
      MessageBox(Handle, 'Usuário já cadastrado!', 'Error!', MB_ICONERROR);


    if Response = 'distributor connection fail' then
      MessageBox(Handle, 'Não foi possível se conectar ao servidor!', 'Error!', MB_ICONERROR);

    if Response = 'bad checksum' then
    begin
      // Limpe a pasta do jogo:
      FlushGameFolder(Minepath);

      if not DirectoryExists(Minepath + '\assets') then
        DownloadAssetsButton.OnClick(GameButton);

      DownloadMainButton.OnClick(GameButton);
    end;

    if Response = 'success' then case TypeOfConnection of
      TYPE_AUTH:
      begin
        // Altere o painel para o PC:
        MainPageControl.TabIndex := 1;

        // Limpe as imagens carregadas e pagos:
        ClearImage(SkinImage);
        ClearImage(CloakImage);

        // Carrega a skin e a capa:
        DownloadSkin := TDownloadImageThread.Create(True);
        DownloadSkin.ImageType := IMAGE_SKIN;
        DownloadSkin.URL := SkinDownloadAddress + '/' + LoginEdit.Text + '.png';
        DownloadSkin.FreeOnTerminate := True;
        DownloadSkin.Priority := tpNormal;
        DownloadSkin.Resume;

        DownloadCloak := TDownloadImageThread.Create(True);
        DownloadCloak.ImageType := IMAGE_CLOAK;
        DownloadCloak.URL := CloakDownloadAddress + '/' + LoginEdit.Text + '.png';
        DownloadCloak.FreeOnTerminate := True;
        DownloadCloak.Priority := tpNormal;
        DownloadCloak.Resume;

        // Se múltiplo suporte ao servidor está habilitada, processa lista de servidores:
        {$IFDEF MULTISERVER}
          {$IFDEF LOCAL_SERVERS_LIST}
          GetServerList(LocalServersList);
          {$ELSE}
          GetServerList(Received);
          {$ENDIF}
        FillServerComboBox(ServerListComboBox);
        {$ENDIF}

        // Obter a quantidade de RAM livre:
        FreeRAMLabel.Caption := IntToStr(GetFreeMemory) + ' GB';

        // Salve as configurações no registro:
        SaveStringToRegistry(RegistryPath, 'Login', LoginEdit.Text);
        SaveStringToRegistry(RegistryPath, 'Password', PasswordEdit.Text);
        SaveBooleanToRegistry(RegistryPath, 'AutoLogin', AutoLoginCheckbox.Checked);
      end;

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

      TYPE_REG:
      begin
        MessageBox(Handle, 'Registo bem sucedido!', 'Sucesso!', MB_ICONASTERISK);
        RegLabel.OnClick(Sender);
      end;

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

      TYPE_GAMEAUTH:
      begin
        FillChar(MCData, SizeOf(MCData), #0);
        MCData.Minepath := Minepath;
        {$IFDEF CUSTOM_JAVA}
        MCData.Java := Minepath + '\' + JavaDir + '\' + JavaApp;
        {$ELSE}
        MCData.Java := JavaEdit.Text + '\' + JavaApp;
        {$ENDIF}
        MCData.JVMParams := JVMParams;
        MCData.Xms := RAMEdit.Text;
        MCData.Xmx := RAMEdit.Text;
        MCData.NativesPath := Minepath + '\' + NativesPath;
        MCData.CP := GetGameFileList(Minepath);
        MCData.MainClass := MainClass;
        MCData.LogonInfo := '--username ' + MainForm.LoginEdit.Text + ' ' +
                            '--server ' + ClientSocket.Host + ' ' +
                            '--port ' + GamePort;
        MCData.GameVersion := GameVersion;
        MCData.GameDir := Minepath;
        MCData.AssetsDir := Minepath + '\' + AssetsFolder;
        MCData.AssetIndex := AssetIndex;
        MCData.TweakClass := TweakClass;

        if not FileExists(MCData.Java) then
        begin
          FreeAndNil(WinSocketStream);
          ClientSocket.Close;
          MessageBox(Handle, PAnsiChar('Java não encontrado!' + #13#10 + 'Local informado:' + #13#10 + MCData.Java), 'Error!', MB_ICONERROR);
          Exit;
        end;

        // Salve as configurações no registro:
        SaveStringToRegistry(RegistryPath, 'RAM', RAMEdit.Text);
        SaveStringToRegistry(RegistryPath, 'Java', JavaEdit.Text);

        // Iniciando o jogo:
        ExecuteMinecraft(MCData, MCProcessInfo);

        {$IFDEF CONTROL_PROCESSES}
        // Inicie o processo de proteção:
        StartDefence(MCProcessInfo.Handle, MainForm.Handle, MCProcessInfo.ID, @DeauthThreadProc);
        {$ENDIF}

        {$IFDEF BEACON}
        // Rastreador de execução:
        StartBeacon(MCProcessInfo.Handle, BeaconDelay, @BeaconThreadProc);
        {$ENDIF}

        {$IFDEF EURISTIC_DEFENCE}
        // Execute clientes busca paralelas:
        StartEuristicDefence(MCProcessInfo.Handle, MCProcessInfo.ID, EuristicDelay);
        {$ENDIF}
      end;
    end;
  end;


  FreeAndNil(WinSocketStream);
  ClientSocket.Close;
end;







//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//
//           Características secundárias: peles, capa de chuva, extra. botão
//
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


procedure TMainForm.ServerListComboBoxSelect(Sender: TObject);
begin
  Minepath := Mainpath + '\' + Servers[ServerListComboBox.ItemIndex].Folder;
  SetLauncherSettings(ServerListComboBox.ItemIndex);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


procedure TMainForm.UploadCloakButtonClick(Sender: TObject);
var
  Data: Pointer;
  Size: LongWord;
begin
  if TempCloakPath = '' then
  begin
    MessageBox(Handle, 'A capa não foi selecionada!', 'Error!', MB_ICONERROR);
    Exit;
  end;

  if not FileExists(TempCloakPath) then
  begin
    MessageBox(Handle, 'A capa não foi encontrada!', 'Error!', MB_ICONERROR);
    Exit;
  end;

  Data := nil;
  Size := 0;

  AddPOSTField(Data, Size, 'user', LoginEdit.Text);
  AddPOSTFile(Data, Size, 'cloak', LoginEdit.Text, TempCloakPath, 'image/png');
  if HTTPPost(CloakUploadAddress, Data, Size) = 'OK' then
    MessageBox(Handle, 'Capa instalada com sucesso!', 'Sucesso!', MB_ICONASTERISK)
  else
    MessageBox(Handle, 'A capa não foi instalada!', 'Error!', MB_ICONERROR);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.UploadSkinButtonClick(Sender: TObject);
var
  Data: Pointer;
  Size: LongWord;
begin
  if TempSkinPath = '' then
  begin
    MessageBox(Handle, 'A skin não foi selecionada!', 'Error!', MB_ICONERROR);
    Exit;
  end;

  if not FileExists(TempSkinPath) then
  begin
    MessageBox(Handle, 'A skin não foi encontrada!', 'Error!', MB_ICONERROR);
    Exit;
  end;

  Data := nil;
  Size := 0;

  AddPOSTField(Data, Size, 'user', LoginEdit.Text);
  AddPOSTFile(Data, Size, 'skin', LoginEdit.Text, TempSkinPath, 'image/png');
  if HTTPPost(SkinUploadAddress, Data, Size) = 'OK' then
    MessageBox(Handle, 'A skin foi instalada com sucesso!', 'Sucesso!', MB_ICONASTERISK)
  else
    MessageBox(Handle, 'A skin não foi instalada!', 'Error!', MB_ICONERROR);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


procedure TMainForm.ChooseSkinButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  MemoryStream: TMemoryStream;
begin
  // Selecione uma skin:
  TempSkinPath := '';
  OpenDialog := TOpenDialog.Create(MainForm);
  OpenDialog.Filter := 'PNG|*.png';
  OpenDialog.Execute(Handle);
  TempSkinPath := OpenDialog.FileName;
  FreeAndNil(OpenDialog);

  if TempSkinPath = '' then Exit;

  // Desenhe uma skin:
  MemoryStream := TMemoryStream.Create;
  MemoryStream.LoadFromFile(TempSkinPath);
  DrawSkin(MemoryStream, SkinImage);
  FreeAndNil(MemoryStream);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.ChooseCloakButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  MemoryStream: TMemoryStream;
begin
  // Escolhe uma capa:
  TempCloakPath := '';
  OpenDialog := TOpenDialog.Create(MainForm);
  OpenDialog.Filter := 'PNG|*.png';
  OpenDialog.Execute(Handle);
  TempCloakPath := OpenDialog.FileName;
  FreeAndNil(OpenDialog);

  if TempCloakPath = '' then Exit;

  // Desenhe a capa:
  MemoryStream := TMemoryStream.Create;
  MemoryStream.LoadFromFile(TempCloakPath);
  DrawSkin(MemoryStream, CloakImage);
  FreeAndNil(MemoryStream);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


procedure TMainForm.DownloadMainButtonClick(Sender: TObject);
var
  DownloadMain: TDownloadArchiveThread;
begin
  GameButton.Visible := False;
  DownloadMainButton.Visible := False;

  DownloadMain := TDownloadArchiveThread.Create(True);
  DownloadMain.FreeOnTerminate := True;
  DownloadMain.Priority := tpNormal;
  DownloadMain.ArchiveType := ARCHIVE_MAIN;
  DownloadMain.URL := ClientAddress;
  DownloadMain.Destination := Minepath + '\' + ClientTempArchiveName;
  DownloadMain.PlayAfterDownloading := Sender = GameButton;
  ResetEvent(ArrayEvents[EVENT_MAIN]);
  DownloadMain.Resume;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DownloadAssetsButtonClick(Sender: TObject);
var
  DownloadAssets: TDownloadArchiveThread;
begin
  GameButton.Visible := False;
  DownloadAssetsButton.Visible := False;

  DownloadAssets := TDownloadArchiveThread.Create(True);
  DownloadAssets.FreeOnTerminate := True;
  DownloadAssets.Priority := tpNormal;
  DownloadAssets.ArchiveType := ARCHIVE_ASSETS;
  DownloadAssets.URL := AssetsAddress;
  DownloadAssets.Destination := Minepath + '\' + AssetsTempArchiveName;
  DownloadAssets.PlayAfterDownloading := False;
  ResetEvent(ArrayEvents[EVENT_ASSETS]);
  DownloadAssets.Resume;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                      Casacos, capas e download do cliente
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


function GetURLSize(URL: string): Cardinal;
var
  HTTPClient: THTTPSend;
  I: LongWord;
  TempStr: string;
begin
  Result := 0;
  HTTPClient := THTTPSend.Create;

  if HTTPClient.HTTPMethod('HEAD', URL) then
  begin
    for I := 0 to HTTPClient.Headers.Count - 1 do
    begin
      if Pos('content-length', LowerCase(HTTPClient.Headers[I])) <> 0 then
      begin
        TempStr:= copy(HTTPClient.Headers[I], 16, Length(HTTPClient.Headers[I]) - 15);
        Result := StrToInt(TempStr) + Length(HTTPClient.Headers.Text);
        Break;
      end;
    end;
  end;

  FreeAndNil(HTTPClient);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


{ TDownloadArchiveThread }

procedure TDownloadArchiveThread.Execute;
var
  HTTPClient: THTTPSend;
begin
  inherited;

  Downloaded := 0;
  Accumulator := 0;

  // Obter o tamanho do arquivo no servidor:
  FileSize := GetURLSize(URL);

  // Se não, digite:
  if FileSize = 0 then
  begin
    // Caixa de descarga:
    case ArchiveType of
      ARCHIVE_MAIN: SetEvent(ArrayEvents[EVENT_MAIN]);
      ARCHIVE_ASSETS: SetEvent(ArrayEvents[EVENT_ASSETS]);
    end;

    Status := DOWNLOAD_FILE_NOT_EXISTS;
    Synchronize(UpdateForm);
    Exit;
  end;

  // Tempo de Zasekaem:
  QueryPerformanceFrequency(PerformanceFrequency);
  QueryPerformanceCounter(OldTimeCounter);
  StartTimeCounter := OldTimeCounter;

  // Baixe o arquivo:
  HTTPClient := THTTPSend.Create;
  HTTPClient.Sock.OnStatus := OnSockStatus;
  HTTPClient.HTTPMethod('GET', URL);

  // Salvar o arquivo resultante e liberar a memória:
  CreatePath(ExtractFilePath(Destination));
  HTTPClient.Document.SaveToFile(Destination);
  FreeAndNil(HTTPClient);

  // Descompacte o arquivo:
  Status := DOWNLOAD_UNPACKING;
  Synchronize(UpdateForm);
  UnpackFile(Destination, ExtractFilePath(Destination));
  DeleteFile(Destination);

  // Envie o sinal para fora:
  Status := DOWNLOAD_WAITING;
  Synchronize(UpdateForm);

  // Caixa de descarga:
  case ArchiveType of
    ARCHIVE_MAIN: SetEvent(ArrayEvents[EVENT_MAIN]);
    ARCHIVE_ASSETS: SetEvent(ArrayEvents[EVENT_ASSETS]);
  end;

  // Estamos esperando o segundo segmento:
  WaitForMultipleObjects(2, @ArrayEvents[0], TRUE, INFINITE);

  Status := DOWNLOAD_SUCCESS;
  Synchronize(UpdateForm);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TDownloadArchiveThread.OnSockStatus(Sender: TObject;
  Reason: THookSocketReason; const Value: string);
var
  NewTimeCounter: Int64;
  TickDownloaded: Int64;
  MiddleSpeed: Single;
begin
  if Reason = HR_ReadCount then
  begin
    TickDownloaded := StrToInt(Value);
    Downloaded := Downloaded + TickDownloaded;

    Accumulator := Accumulator + TickDownloaded;

    // Dados de contagem, depois cada um recebeu um megabyte:
    if Accumulator > 1048576 then
    begin
      QueryPerformanceCounter(NewTimeCounter);
      Speed := (Accumulator * PerformanceFrequency) / (NewTimeCounter - OldTimeCounter);
      MiddleSpeed := (Downloaded * PerformanceFrequency) / (NewTimeCounter - StartTimeCounter);
      Speed := (Speed + MiddleSpeed) / 2;
      RemainingTime := (FileSize - Downloaded) / Speed;

      Status := DOWNLOAD_ACTIVE;
      Synchronize(UpdateForm);

      OldTimeCounter := NewTimeCounter;
      Accumulator := 0;
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TDownloadArchiveThread.UpdateForm;
begin
  case Status of
    DOWNLOAD_FILE_NOT_EXISTS:
      MessageBox(MainForm.Handle, PChar('O arquivo ' + URL + ' não existe!'), 'Error!', MB_ICONERROR);

    DOWNLOAD_ACTIVE:
    begin
      case ArchiveType of
        ARCHIVE_MAIN:
        with MainForm do
        begin
          MainSizeOfFileLabel.Caption := 'Tamanho do arquivo: ' + IntToStr(FileSize div 1048576) + ' MB';
          MainDownloadedLabel.Caption := 'Baixados: ' + IntToStr(Downloaded div 1048576) + ' MB';
          MainSpeedLabel.Caption := 'Velocidade: ' + FormatFloat('0.00', Speed / 1024) + ' KB/s';
          MainRemainingTimeLabel.Caption := 'Restando: ' + FormatFloat('0.00', RemainingTime) + ' seg';
        end;

        ARCHIVE_ASSETS:
        with MainForm do
        begin
          AssetsSizeOfFileLabel.Caption := 'Tamanho do arquivo: ' + IntToStr(FileSize div 1048576) + ' MB';
          AssetsDownloadedLabel.Caption := 'Baixados: ' + IntToStr(Downloaded div 1048576) + ' MB';
          AssetsSpeedLabel.Caption := 'Velocidade: ' + FormatFloat('0.00', Speed / 1024) + ' KB/s';
          AssetsRemainingTimeLabel.Caption := 'Restando: ' + FormatFloat('0.00', RemainingTime) + ' seg';
        end;
      end;
    end;

    DOWNLOAD_UNPACKING:
    begin
      case ArchiveType of
        ARCHIVE_MAIN:
        with MainForm do
        begin
          MainSizeOfFileLabel.Caption := 'Tamanho do arquivo: Extraindo...';
          MainDownloadedLabel.Caption := 'Baixados: Extraindo...';
          MainSpeedLabel.Caption := 'Velocidade: 0 KB/s';
          MainRemainingTimeLabel.Caption := 'Restando: 0 seg';
        end;

        ARCHIVE_ASSETS:
        with MainForm do
        begin
          AssetsSizeOfFileLabel.Caption := 'Tamanho do arquivo: Extraindo...';
          AssetsDownloadedLabel.Caption := 'Baixados: Extraindo...';
          AssetsSpeedLabel.Caption := 'Velocidade: 0 KB/s';
          AssetsRemainingTimeLabel.Caption := 'Restando: 0 seg';
        end;
      end;
    end;

    DOWNLOAD_WAITING:
    begin
      case ArchiveType of
        ARCHIVE_MAIN:
        with MainForm do
        begin
          MainSizeOfFileLabel.Caption := 'Tamanho do arquivo: Aguardando...';
          MainDownloadedLabel.Caption := 'Baixados: Aguardando...';
          MainSpeedLabel.Caption := 'Velocidade: 0 KB/s';
          MainRemainingTimeLabel.Caption := 'Restando: 0 seg';
        end;

        ARCHIVE_ASSETS:
        with MainForm do
        begin
          AssetsSizeOfFileLabel.Caption := 'Tamanho do arquivo: Aguardando...';
          AssetsDownloadedLabel.Caption := 'Baixados: Aguardando...';
          AssetsSpeedLabel.Caption := 'Velocidade: 0 KB/s';
          AssetsRemainingTimeLabel.Caption := 'Restando: 0 seg';
        end;
      end;
    end;

    DOWNLOAD_SUCCESS:
    begin
      case ArchiveType of
        ARCHIVE_MAIN:
        with MainForm do
        begin
          MainSizeOfFileLabel.Caption := 'Tamanho do arquivo: 0 MB';
          MainDownloadedLabel.Caption := 'Baixados: 0 МB';
          MainSpeedLabel.Caption := 'Velocidade: 0 KB/s';
          MainRemainingTimeLabel.Caption := 'Restando: 0 seg';

          DownloadMainButton.Visible := True;
        end;

        ARCHIVE_ASSETS:
        with MainForm do
        begin
          AssetsSizeOfFileLabel.Caption := 'Tamanho do arquvio: 0 МB';
          AssetsDownloadedLabel.Caption := 'Baixados: 0 МB';
          AssetsSpeedLabel.Caption := 'Velocidade: 0 KB/s';
          AssetsRemainingTimeLabel.Caption := 'Restando: 0 seg';

          DownloadAssetsButton.Visible := True;
        end;
      end;

      MainForm.GameButton.Visible := True;

      if PlayAfterDownloading then MainForm.GameButton.OnClick(MainForm);

    end;
  end;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

{ TDownloadImageThread }

procedure TDownloadImageThread.Execute;
const
  PNGSignature: Cardinal = $474E5089;
begin
  inherited;
  HTTPClient := THTTPSend.Create;
  HTTPClient.HTTPMethod('GET', URL);

  // Se pelo menos algo que baixamos, em seguida, verificar a assinatura:
  if HTTPClient.Document.Size > 0 then
  begin
    // Se este arquivo é um PNG, em seguida, desenhe uma pele ou capa:
    if Cardinal(HTTPClient.Document.Memory^) = PNGSignature then
    begin
      Synchronize(UpdateForm);
    end;
  end;

  FreeAndNil(HTTPClient);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TDownloadImageThread.UpdateForm;
begin
  case ImageType of
    IMAGE_SKIN: DrawSkin(HTTPClient.Document, MainForm.SkinImage);
    IMAGE_CLOAK: DrawCloak(HTTPClient.Document, MainForm.CloakImage);
  end;
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


procedure TMainForm.OpenClientFolderClick(Sender: TObject);
begin
  CreatePath(Minepath);
  ShellExecute(Handle, nil, PAnsiChar(Minepath), nil, nil, SW_SHOWNORMAL);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.OpenLauncherFolderClick(Sender: TObject);
begin
  ShellExecute(Handle, nil, '', nil, nil, SW_SHOWNORMAL);
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


function EmptyWorkingSet(Handle: THandle): Boolean; stdcall; external 'psapi.dll';

procedure TMainForm.FreeRAMLabelClick(Sender: TObject);
var
  ProcessList: TProcessList;
  ProcessHandle: THandle;
  ProcessesCount: LongWord;
  I: LongWord;
  OldRAM, NewRAM, Delta: Int64;
begin
  OldRAM := GetFreeMemory;

  GetProcessList(ProcessList);
  ProcessesCount := Length(ProcessList);

  for I := 0 to ProcessesCount - 1 do
  begin
    ProcessHandle := ProcessIDtoHandle(ProcessList[I].th32ProcessID);
    if ProcessHandle = INVALID_HANDLE_VALUE then Continue;
    EmptyWorkingSet(ProcessHandle);
    CloseHandle(ProcessHandle);
  end;

  NewRAM := GetFreeMemory;
  Delta := NewRAM - OldRAM;

  MessageBox(
              Handle,
              PAnsiChar(
              'A memória foi limpa!' + #13#10 + #13#10 +
              ' - Antes: ' + IntToStr(OldRAM) + ' МB' + #13#10 +
              ' - Agora: ' + IntToStr(NewRAM) + ' МB' + #13#10 +
              ' - Liberados: ' + IntToStr(Delta) + ' МB'
              ),
              'Sucesso!',
              MB_ICONASTERISK
             );
end;



//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//
//
//
//                    Forma de Processamento de design
//
//
//
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH






procedure TMainForm.RegLabelClick(Sender: TObject);
begin
  case TypeOfConnection of
    TYPE_AUTH:
    begin
      TypeOfConnection := TYPE_REG;

      // Alterar area de cadastro:
      MailEdit.Visible := True;
      Label3.Visible := True;
      AuthButton.Caption := 'Cadastrar';
      RegLabel.Caption := 'Já possuo uma conta';
    end;

    TYPE_REG:
    begin
      TypeOfConnection := TYPE_AUTH;

      // Alterar area de login:
      MailEdit.Visible := False;
      Label3.Visible := False;
      AuthButton.Caption := 'Entrar';
      RegLabel.Caption := 'Quero me cadastrar';
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.RegLabelMouseEnter(Sender: TObject);
begin
  RegLabel.Font.Color := clRed;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.RegLabelMouseLeave(Sender: TObject);
begin
  RegLabel.Font.Color := clHotLight;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.RegLabelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  RegLabel.Font.Style := RegLabel.Font.Style - [fsUnderline];
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.RegLabelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  RegLabel.Font.Style := RegLabel.Font.Style + [fsUnderline];
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


procedure TMainForm.DeauthLabelClick(Sender: TObject);
begin
  MainPageControl.TabIndex := 0;
  SaveBooleanToRegistry(RegistryPath, 'AutoLogin', False);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeauthLabelMouseEnter(Sender: TObject);
begin
  DeauthLabel.Font.Color := clRed;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeauthLabelMouseLeave(Sender: TObject);
begin
  DeauthLabel.Font.Color := clHotLight;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeauthLabelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  DeauthLabel.Font.Style := DeauthLabel.Font.Style - [fsUnderline];
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeauthLabelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  DeauthLabel.Font.Style := DeauthLabel.Font.Style + [fsUnderline];
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


const
  ID_AUTH = 0;
  ID_GAME = 1;
  ID_AUTOLOGIN = 2;
  ID_SELF_FOLDER = 3;
  ID_GAME_FOLDER = 4;
  ID_CHOOSE_SKIN = 5;
  ID_UPLOAD_SKIN = 6;
  ID_CHOOSE_CLOAK = 7;
  ID_UPLOAD_CLOAK = 8;
  ID_DOWNLOAD_MAIN = 9;
  ID_DOWNLOAD_ASSETS = 10;
  ID_CHOOSE_SERVER = 11;


function TMainForm.CallProc(FunctionID: LongWord): Boolean;
begin
  Result := True;
  case FunctionID of
    ID_AUTH: AuthButton.Click;
    ID_GAME: GameButton.Click;
    ID_AUTOLOGIN: AutoLoginCheckbox.OnClick(Self);
    ID_SELF_FOLDER: OpenLauncherFolder.Click;
    ID_GAME_FOLDER: OpenClientFolder.Click;
    ID_CHOOSE_SKIN: ChooseSkinButton.Click;
    ID_UPLOAD_SKIN: UploadSkinButton.Click;
    ID_CHOOSE_CLOAK: ChooseCloakButton.Click;
    ID_UPLOAD_CLOAK: UploadCloakButton.Click;
    ID_DOWNLOAD_MAIN: DownloadMainButton.Click;
    ID_DOWNLOAD_ASSETS: DownloadAssetsButton.Click;
    ID_CHOOSE_SERVER: ServerListComboBox.OnSelect(Self);
  else
    Result := False;
  end;
end;

end.
