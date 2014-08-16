unit OOPSocketsTCP;

interface

uses
  Windows, WinSock;

function InitWinSock: Integer;
function DNStoIP(Host: AnsiString): AnsiString;
function GetIP: AnsiString;

// Клиентский сокет:
type

  TClientSocketInfo = record
    Socket: TSocket;
    ConnectionHost: AnsiString;
    ConnectionIP: AnsiString;
    ConnectionPort: Word;
    ConnectionStatus: Boolean;
    ListenStatus: Boolean;
  end;

  TClientEventsData = record
    ClientSocket: TSocket;
    ServerHost: AnsiString;
    ServerIP: AnsiString;
    ServerPort: Word;
    ReceivedData: Pointer;
    ReceivedDataSize: LongWord;
  end;
  PClientEventsData = ^TClientEventsData;

  TClientEvents = record
    OnConnect: procedure (SocketData: PClientEventsData);
    OnStartListen: procedure (SocketData: PClientEventsData);
    OnRead: procedure (SocketData: PClientEventsData);
    OnDisconnect: procedure (SocketData: PClientEventsData);
  end;

  TClientSocketTCP = class
    private
      SocketInfo: TClientSocketInfo;

      procedure ListenThread;
    public
      Events: TClientEvents;
      Timeout: Cardinal;

      constructor Create;
      procedure ListenSocket;
      procedure ConnectToServer(ServerAddress: AnsiString; Port: Word);
      procedure Send(Data: Pointer; Size: Word);
      procedure Disconnect;
      destructor Destroy; override;

      property ConnectionStatus: Boolean read SocketInfo.ConnectionStatus;
      property ListenStatus: Boolean read SocketInfo.ListenStatus;
      property ConnectionHost: AnsiString read SocketInfo.ConnectionHost;
      property ConnectionIP: AnsiString read SocketInfo.ConnectionIP;
      property ConnectionPort: Word read SocketInfo.ConnectionPort;
  end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function SendDataToSocket(Socket: TSocket; Data: pointer; Size: LongWord): Integer;
procedure DestroySocket(var Socket: TSocket);
procedure FreeWinSock;

implementation

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

function InitWinSock: Integer;
var
  WSAData: TWSAData;
begin
  Result := WSAStartup($202, WSAData);
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

function DNStoIP(Host: AnsiString): AnsiString;
var
  HostEnt: PHostEnt;
begin
  Result := '';
  HostEnt := GetHostByName(PAnsiChar(Host));
  if HostEnt = nil then Exit;
  Result := inet_ntoa(PInAddr(HostEnt^.h_addr_list^)^);
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

function GetIP: AnsiString;
var
  WSAData: TWSAData;
  P: PHostEnt;
  Buf: array [0..127] of Char;
begin
  Result := '';

  if (WSAStartup($202, wsaData) = 0) and (GetHostName(@Buf, 128) = 0) then
    try
      P := GetHostByName(@Buf);

      if P <> nil then
      Result := inet_ntoa(PInAddr(p^.h_addr_list^)^);
    finally
      WSACleanup;
    end;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

{ TClientSocketTCP }

constructor TClientSocketTCP.Create;
begin
  FillChar(Events, SizeOf(Events), #0);
  FillChar(SocketInfo, SizeOf(SocketInfo), #0);
  Timeout := 0;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TClientSocketTCP.ListenThread;
var
  ClientEventsData: TClientEventsData;
  Buffer: pointer;
  Size: integer;
const
  BufferSize = 65536;
begin
  // Слушаем сокет:
  SocketInfo.ListenStatus := True;

  // Заполняем структуру событий:
  FillChar(ClientEventsData, SizeOf(ClientEventsData), #0);
  ClientEventsData.ClientSocket := SocketInfo.Socket;
  ClientEventsData.ServerHost := SocketInfo.ConnectionHost;
  ClientEventsData.ServerIP := SocketInfo.ConnectionIP;
  ClientEventsData.ServerPort := SocketInfo.ConnectionPort;

  if @Events.OnStartListen <> nil then
    Events.OnStartListen(@ClientEventsData);

  GetMem(Buffer, BufferSize);
  repeat
    FillChar(Buffer^, BufferSize, #0);
    Size := Recv(SocketInfo.Socket, Buffer^, BufferSize, 0);
    if (Size = SOCKET_ERROR) or (Size = 0) then Break;

    ClientEventsData.ReceivedData := Buffer;
    ClientEventsData.ReceivedDataSize := Size;

    if @Events.OnRead <> nil then
      Events.OnRead(@ClientEventsData);
  until Size = SOCKET_ERROR;
  FreeMem(Buffer, BufferSize);

  ClientEventsData.ReceivedData := nil;
  ClientEventsData.ReceivedDataSize := 0;

  // Сокет закрыт:
  SocketInfo.ListenStatus := False;
  SocketInfo.ConnectionStatus := False;

  if @Events.OnDisconnect <> nil then
    Events.OnDisconnect(@ClientEventsData);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TClientSocketTCP.ListenSocket;
var
  ThreadID: LongWord;
begin
  BeginThread(nil, 0, @TClientSocketTCP.ListenThread, Self, 0, ThreadID);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TClientSocketTCP.ConnectToServer(ServerAddress: AnsiString; Port: Word);
var
  SockAddr: TSockAddr;

  FDSetW: TFDSet;
  FDSetE: TFDSet;
  TimeVal: TTimeVal;
  NonBlockingMode: integer;

  ClientEventsData: TClientEventsData;
begin
  // Создаём сокет:
  SocketInfo.Socket := Socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
  if SocketInfo.Socket = INVALID_SOCKET then Exit;

  SocketInfo.ConnectionHost := ServerAddress;
  // Преобразуем DNS в IP на всякий случай (IP -> IP тоже работает):
  ServerAddress := DNStoIP(ServerAddress);
  SocketInfo.ConnectionIP := ServerAddress;
  SocketInfo.ConnectionPort := Port;

  // Структура с информацией о подключении:
  FillChar(SockAddr, SizeOf(TSockAddr), 0);
  SockAddr.sin_family := AF_INET;
  SockAddr.sin_port := htons(Port);
  SockAddr.sin_addr.S_addr := inet_addr(PAnsiChar(ServerAddress));

  // Пытаемся подключиться:
  if Timeout > 0 then
  begin
    NonBlockingMode := 1;
    IoCtlSocket(SocketInfo.Socket, FIONBIO, NonBlockingMode);
    if Connect(SocketInfo.Socket, SockAddr, SizeOf(TSockAddr)) <> 0 then
    begin
      FD_ZERO(FDSetW);
      FD_ZERO(FDSetE);
      FD_SET(SocketInfo.Socket, FDSetW);
      FD_SET(SocketInfo.Socket, FDSetE);
      TimeVal.tv_sec := Timeout div 1000;
      TimeVal.tv_usec := (Timeout mod 1000) * 1000;
      Select(0, nil, @FDSetW, @FDSetE, @TimeVal);
      if not FD_ISSET(SocketInfo.Socket, FDSetW) then SocketInfo.ConnectionStatus := false;
    end;
    NonBlockingMode := 0;
    IoCtlSocket(SocketInfo.Socket, FIONBIO, NonBlockingMode);
  end
  else
  begin
    if Connect(SocketInfo.Socket, SockAddr, SizeOf(TSockAddr)) = 0 then SocketInfo.ConnectionStatus := true;
  end;

  if (SocketInfo.ConnectionStatus) and (@Events.OnConnect <> nil) then
  begin
    FillChar(ClientEventsData, SizeOf(ClientEventsData), #0);
    ClientEventsData.ClientSocket := SocketInfo.Socket;
    ClientEventsData.ServerHost := SocketInfo.ConnectionHost;
    ClientEventsData.ServerIP := SocketInfo.ConnectionIP;
    ClientEventsData.ServerPort := SocketInfo.ConnectionPort;

    Events.OnConnect(@ClientEventsData);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TClientSocketTCP.Send(Data: Pointer; Size: Word);
begin
  if SocketInfo.ConnectionStatus then
    SendDataToSocket(SocketInfo.Socket, Data, Size);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TClientSocketTCP.Disconnect;
begin
  DestroySocket(SocketInfo.Socket);
  SocketInfo.ConnectionStatus := False;
  SocketInfo.ListenStatus := False;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


destructor TClientSocketTCP.Destroy;
begin
  Disconnect;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

function SendDataToSocket(Socket: TSocket; Data: pointer; Size: LongWord): Integer;
begin
  Result := Send(Socket, Data^, Size, 0);
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure DestroySocket(var Socket: TSocket);
begin
  Shutdown(Socket, SD_BOTH);
  CloseSocket(Socket);
  Socket := INVALID_SOCKET;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure FreeWinSock;
begin
  WSACleanup;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

initialization
begin
  InitWinSock;
end;

finalization
begin
  FreeWinSock;
end;

end.
