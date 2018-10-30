object fmMain: TfmMain
  Left = 414
  Top = 115
  Width = 702
  Height = 549
  Caption = 'TCRM '#20358#22238#38651#35338#24687#30332#36865#20013#24515
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Consolas'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 18
  object ListBox1: TListBox
    Left = 0
    Top = 127
    Width = 694
    Height = 364
    Align = alClient
    BevelOuter = bvNone
    ItemHeight = 18
    TabOrder = 1
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 694
    Height = 127
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 15
      Top = 16
      Width = 88
      Height = 18
      Caption = 'Real Server'
    end
    object Label2: TLabel
      Left = 15
      Top = 49
      Width = 32
      Height = 18
      Caption = 'Port'
    end
    object Label3: TLabel
      Left = 303
      Top = 16
      Width = 56
      Height = 18
      Caption = 'Monitor'
    end
    object bvl1: TBevel
      Left = 17
      Top = 79
      Width = 330
      Height = 8
      Shape = bsTopLine
    end
    object Label4: TLabel
      Left = 15
      Top = 94
      Width = 64
      Height = 18
      Caption = 'TCRM SQL'
    end
    object Edit_Host: TEdit
      Left = 114
      Top = 12
      Width = 139
      Height = 26
      TabOrder = 0
      Text = '10.1.1.212'
    end
    object Edit_Port: TEdit
      Left = 114
      Top = 45
      Width = 139
      Height = 26
      TabOrder = 2
      Text = '9311'
    end
    object ListBox_Monitor: TListBox
      Left = 372
      Top = 12
      Width = 295
      Height = 97
      ItemHeight = 18
      Items.Strings = (
        'WICSIPHE')
      TabOrder = 1
    end
    object Edit_SQL: TEdit
      Left = 114
      Top = 90
      Width = 139
      Height = 26
      TabOrder = 3
      Text = '127.0.0.1'
    end
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 491
    Width = 694
    Height = 27
    Align = alBottom
    Smooth = True
    Step = 1
    TabOrder = 2
  end
  object TcrmConn: TADOConnection
    ConnectionString = 
      'Provider=SQLOLEDB.1;Password=hellotcrm;Persist Security Info=Tru' +
      'e;User ID=tcrm;Initial Catalog=WCRM;Data Source=10.1.2.7'
    KeepConnection = False
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 27
    Top = 168
  end
  object qrChangLog: TADOQuery
    Connection = TcrmConn
    Parameters = <>
    Left = 66
    Top = 168
  end
  object JcThreadTimer1: TJcThreadTimer
    Interval = 1000
    OnTimer = JcThreadTimer1Timer
    Left = 108
    Top = 168
  end
  object JcVersionInfo1: TJcVersionInfo
    Left = 153
    Top = 168
  end
  object RzTrayIcon1: TRzTrayIcon
    PopupMenu = PopupMenu1
    Left = 200
    Top = 168
  end
  object PopupMenu1: TPopupMenu
    Left = 244
    Top = 168
    object N1: TMenuItem
      Caption = #32080#26463
      OnClick = N1Click
    end
  end
  object IdTCPClient_Phone: TIdTCPClient
    ConnectTimeout = 0
    IPVersion = Id_IPv4
    Port = 0
    ReadTimeout = 0
    Left = 32
    Top = 212
  end
end
