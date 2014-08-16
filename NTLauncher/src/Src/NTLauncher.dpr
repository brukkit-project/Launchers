program NTLauncher;

uses
  Forms,
  Classes,
  Windows,
  Main in 'Main.pas' {MainForm},
  RegistryUtils in 'RegistryUtils.pas',
  LauncherSettings in 'LauncherSettings.pas',
  HashUtils in 'HashUtils.pas',
  cHash in 'HashModules\cHash.pas',
  Additions in 'Additions.pas',
  FileAPI in 'FileAPI.pas',
  blcksock in 'Synapse\blcksock.pas',
  httpsend in 'Synapse\httpsend.pas',
  synacode in 'Synapse\synacode.pas',
  synafpc in 'Synapse\synafpc.pas',
  synaip in 'Synapse\synaip.pas',
  synautil in 'Synapse\synautil.pas',
  synsock in 'Synapse\synsock.pas',
  FWZipConsts in 'ZipModules\FWZipConsts.pas',
  FWZipCrc32 in 'ZipModules\FWZipCrc32.pas',
  FWZipCrypt in 'ZipModules\FWZipCrypt.pas',
  FWZipReader in 'ZipModules\FWZipReader.pas',
  FWZipStream in 'ZipModules\FWZipStream.pas',
  FWZipZLib in 'ZipModules\FWZipZLib.pas',
  ZLibEx in 'ZipModules\ZLibEx.pas',
  ZLibExApi in 'ZipModules\ZLibExApi.pas',
  ZLibExGZ in 'ZipModules\ZLibExGZ.pas',
  zlibpas in 'ZipModules\zlibpas.pas',
  SkinSystem in 'SkinSystem.pas',
  pngextra in 'PNGModules\pngextra.pas',
  pngimage in 'PNGModules\pngimage.pas',
  pnglang in 'PNGModules\pnglang.pas',
  HWID in 'HWID.pas',
  MinecraftLauncher in 'MinecraftLauncher.pas',
  Perimeter in 'Perimeter.pas',
  MultiserverUtils in 'MultiserverUtils.pas',
  PostRequest in 'PostRequest.pas',
  Defence in 'Defence.pas';

{$R *.res}
{$R Font.res}
{$SETPEFLAGS $0001 or $0002 or $0004 or $0008 or $0010 or $0020 or $0200 or $0400 or $0800 or $1000}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function LoadResourceFont(Instance: THandle; FontName: String; ResType: PChar = RT_RCDATA): THandle;
var
  Res: TResourceStream;
  Count: Integer;
begin
  Res:= TResourceStream.Create(Instance, FontName, ResType);
  try
    Result := AddFontMemResourceEx(Res.Memory, Res.Size, nil, @Count);
  finally
    Res.Free;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure FreeResourceFont(Font: THandle);
begin
  RemoveFontMemResourceEx(Font);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

var
  HeliosThinFont: THandle;

begin
  HeliosThinFont := LoadResourceFont(hInstance, 'HELIOSTHIN', RT_RCDATA);

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

  FreeResourceFont(HeliosThinFont);
end.
