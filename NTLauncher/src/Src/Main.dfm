object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Launcher Beta'
  ClientHeight = 460
  ClientWidth = 595
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object MainPageControl: TPageControl
    Left = -4
    Top = -3
    Width = 602
    Height = 466
    ActivePage = AuthSheet
    MultiLine = True
    TabOrder = 0
    TabPosition = tpBottom
    object AuthSheet: TTabSheet
      Caption = 'Inicio'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Calibri'
      Font.Style = []
      ParentFont = False
      ExplicitLeft = 8
      object Label1: TLabel
        Left = 152
        Top = 159
        Width = 32
        Height = 14
        Caption = 'Login:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Calibri'
        Font.Style = []
        ParentFont = False
      end
      object Label2: TLabel
        Left = 152
        Top = 198
        Width = 37
        Height = 14
        Caption = 'Senha:'
      end
      object Label3: TLabel
        Left = 152
        Top = 236
        Width = 38
        Height = 14
        Caption = 'E-mail:'
        Visible = False
      end
      object RegLabel: TLabel
        Left = 151
        Top = 301
        Width = 107
        Height = 14
        Caption = 'Quero me cadastrar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHotLight
        Font.Height = -12
        Font.Name = 'Calibri'
        Font.Style = [fsUnderline]
        ParentFont = False
        OnClick = RegLabelClick
        OnMouseDown = RegLabelMouseDown
        OnMouseUp = RegLabelMouseUp
        OnMouseEnter = RegLabelMouseEnter
        OnMouseLeave = RegLabelMouseLeave
      end
      object LauncherTitle: TLabel
        Left = 144
        Top = 57
        Width = 294
        Height = 50
        Caption = 'Launcher Beta'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -45
        Font.Name = 'HeliosThin'
        Font.Style = []
        ParentFont = False
      end
      object Label7: TLabel
        Left = 453
        Top = 423
        Width = 138
        Height = 14
        Caption = ' Por Brukkit.org (remova-me)'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object AuthButton: TButton
        Left = 150
        Top = 320
        Width = 294
        Height = 44
        Caption = 'Entrar'
        TabOrder = 0
        OnClick = AuthButtonClick
      end
      object AutoLoginCheckbox: TCheckBox
        Left = 334
        Top = 299
        Width = 106
        Height = 17
        Caption = 'Lembrar Login'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Calibri'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
      end
      object LoginEdit: TEdit
        Left = 208
        Top = 153
        Width = 235
        Height = 27
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
      end
      object MailEdit: TEdit
        Left = 208
        Top = 229
        Width = 235
        Height = 27
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Visible = False
      end
      object PasswordEdit: TEdit
        Left = 208
        Top = 191
        Width = 235
        Height = 27
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = []
        ParentFont = False
        PasswordChar = #8226
        TabOrder = 4
      end
    end
    object GameSheet: TTabSheet
      Caption = 'Config'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Calibri'
      Font.Style = []
      ImageIndex = 1
      ParentFont = False
      object CloakImage: TImage
        Left = 198
        Top = 200
        Width = 56
        Height = 78
        Stretch = True
      end
      object SkinImage: TImage
        Left = 64
        Top = 138
        Width = 70
        Height = 140
      end
      object Label4: TLabel
        Left = 38
        Top = 72
        Width = 26
        Height = 14
        Caption = 'Java:'
      end
      object Label5: TLabel
        Left = 39
        Top = 101
        Width = 27
        Height = 14
        Caption = 'RAM:'
      end
      object Label6: TLabel
        Left = 141
        Top = 104
        Width = 62
        Height = 14
        Caption = 'Disponivel:'
      end
      object FreeRAMLabel: TLabel
        Left = 208
        Top = 104
        Width = 24
        Height = 14
        Caption = '0 GB'
        OnClick = FreeRAMLabelClick
      end
      object AssetsSpeedLabel: TLabel
        Left = 374
        Top = 296
        Width = 100
        Height = 14
        Caption = 'Velocidade: 0 KB/s'
      end
      object MainSpeedLabel: TLabel
        Left = 374
        Top = 148
        Width = 100
        Height = 14
        Caption = 'Velocidade: 0 KB/s'
      end
      object MainSizeOfFileLabel: TLabel
        Left = 374
        Top = 104
        Width = 143
        Height = 14
        Caption = 'Tamanho do arquivo: 0 MB'
      end
      object MainLabel: TLabel
        Left = 356
        Top = 72
        Width = 31
        Height = 14
        Caption = 'Main:'
      end
      object MainDownloadedLabel: TLabel
        Left = 374
        Top = 126
        Width = 82
        Height = 14
        Caption = 'Baixados: 0 MB'
      end
      object MainRemainingTimeLabel: TLabel
        Left = 374
        Top = 170
        Width = 86
        Height = 14
        Caption = 'Restando: 0 seg'
        OnClick = MainRemainingTimeLabelClick
      end
      object AssetsSizeOfFileLabel: TLabel
        Left = 374
        Top = 252
        Width = 143
        Height = 14
        Caption = 'Tamanho do arquivo: 0 MB'
      end
      object AssetsRemainingTimeLabel: TLabel
        Left = 374
        Top = 318
        Width = 86
        Height = 14
        Caption = 'Restando: 0 seg'
      end
      object AssetsLabel: TLabel
        Left = 356
        Top = 220
        Width = 39
        Height = 14
        Caption = 'Assets:'
      end
      object AssetsDownloadedLabel: TLabel
        Left = 374
        Top = 274
        Width = 82
        Height = 14
        Caption = 'Baixados: 0 MB'
      end
      object DeauthLabel: TLabel
        Left = 471
        Top = 14
        Width = 81
        Height = 14
        Caption = 'Voltar ao Login'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHotLight
        Font.Height = -12
        Font.Name = 'Calibri'
        Font.Style = [fsUnderline]
        ParentFont = False
        OnClick = DeauthLabelClick
        OnMouseDown = DeauthLabelMouseDown
        OnMouseUp = DeauthLabelMouseUp
        OnMouseEnter = DeauthLabelMouseEnter
        OnMouseLeave = DeauthLabelMouseLeave
      end
      object ChooseCloakButton: TButton
        Left = 171
        Top = 286
        Width = 108
        Height = 25
        Caption = 'Selecionar Capa'
        TabOrder = 0
        OnClick = ChooseCloakButtonClick
      end
      object ChooseSkinButton: TButton
        Left = 47
        Top = 286
        Width = 108
        Height = 25
        Caption = 'Selecionar Skin'
        TabOrder = 1
        OnClick = ChooseSkinButtonClick
      end
      object GameButton: TButton
        Left = 152
        Top = 379
        Width = 309
        Height = 40
        Caption = 'Aplicar'
        TabOrder = 2
        OnClick = GameButtonClick
      end
      object JavaEdit: TEdit
        Left = 79
        Top = 69
        Width = 191
        Height = 22
        TabOrder = 3
        Text = 'E:\Program Files\Java\jre8\bin'
      end
      object OpenClientFolder: TButton
        Left = 170
        Top = 19
        Width = 147
        Height = 34
        Caption = 'Pasta do Jogo'
        TabOrder = 4
        OnClick = OpenClientFolderClick
      end
      object OpenLauncherFolder: TButton
        Left = 16
        Top = 19
        Width = 147
        Height = 34
        Caption = 'Pasta do Launcher'
        TabOrder = 5
        OnClick = OpenLauncherFolderClick
      end
      object RAMEdit: TEdit
        Left = 79
        Top = 100
        Width = 45
        Height = 22
        TabOrder = 6
        Text = '1024'
      end
      object ServerListComboBox: TComboBox
        Left = 278
        Top = 351
        Width = 182
        Height = 22
        Style = csDropDownList
        ItemHeight = 14
        TabOrder = 7
        Visible = False
        OnSelect = ServerListComboBoxSelect
      end
      object UploadCloakButton: TButton
        Left = 171
        Top = 312
        Width = 108
        Height = 25
        Caption = 'Instalar Capa'
        TabOrder = 8
        OnClick = UploadCloakButtonClick
      end
      object UploadSkinButton: TButton
        Left = 47
        Top = 312
        Width = 108
        Height = 25
        Caption = 'Instalar Skin'
        TabOrder = 9
        OnClick = UploadSkinButtonClick
      end
      object DownloadMainButton: TButton
        Left = 400
        Top = 68
        Width = 75
        Height = 25
        Caption = 'Baixar'
        TabOrder = 10
        OnClick = DownloadMainButtonClick
      end
      object DownloadAssetsButton: TButton
        Left = 400
        Top = 215
        Width = 75
        Height = 25
        Caption = 'Baixar'
        TabOrder = 11
        OnClick = DownloadAssetsButtonClick
      end
    end
  end
  object ClientSocket: TClientSocket
    Active = False
    ClientType = ctBlocking
    Port = 0
    OnConnect = ClientSocketConnect
    Left = 11
    Top = 399
  end
end
