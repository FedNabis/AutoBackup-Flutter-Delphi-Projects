object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Flutter Auto Backup'
  ClientHeight = 620
  ClientWidth = 880
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 180
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 876
    object lblRoot: TLabel
      Left = 8
      Top = 8
      Width = 151
      Height = 15
      Caption = #1042#1099#1073#1077#1088#1080#1090#1077' '#1048#1089#1093#1086#1076#1085#1099#1077' '#1087#1072#1087#1082#1080':'
    end
    object lblBackup: TLabel
      Left = 8
      Top = 85
      Width = 39
      Height = 15
      Caption = 'Backup'
    end
    object lblInterval: TLabel
      Left = 263
      Top = 156
      Width = 85
      Height = 15
      Caption = #1048#1085#1090#1077#1088#1074#1072#1083' ('#1089#1077#1082'):'
    end
    object lblIntervalValue: TLabel
      Left = 532
      Top = 156
      Width = 12
      Height = 15
      Caption = '20'
    end
    object lblZipInterval: TLabel
      Left = 8
      Top = 156
      Width = 108
      Height = 15
      Caption = 'ZIP '#1080#1085#1090#1077#1088#1074#1072#1083' ('#1084#1080#1085'):'
    end
    object lblZipIntervalValue: TLabel
      Left = 228
      Top = 156
      Width = 6
      Height = 15
      Caption = '5'
    end
    object listRoots: TListBox
      Left = 8
      Top = 24
      Width = 560
      Height = 60
      ItemHeight = 15
      TabOrder = 0
    end
    object btnAddRoot: TButton
      Left = 576
      Top = 24
      Width = 32
      Height = 23
      Caption = '+'
      TabOrder = 1
      OnClick = btnAddRootClick
    end
    object btnRemoveRoot: TButton
      Left = 576
      Top = 50
      Width = 32
      Height = 23
      Caption = '-'
      TabOrder = 2
      OnClick = btnRemoveRootClick
    end
    object edtBackup: TEdit
      Left = 8
      Top = 104
      Width = 560
      Height = 23
      TabOrder = 3
    end
    object btnBrowseBackup: TButton
      Left = 574
      Top = 104
      Width = 32
      Height = 23
      Caption = '...'
      TabOrder = 4
      OnClick = btnBrowseBackupClick
    end
    object btnScan: TButton
      Left = 632
      Top = 24
      Width = 100
      Height = 23
      Caption = #1057#1082#1072#1085#1080#1088#1086#1074#1072#1090#1100
      TabOrder = 5
      OnClick = btnScanClick
    end
    object btnSave: TButton
      Left = 632
      Top = 52
      Width = 100
      Height = 23
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
      TabOrder = 6
      OnClick = btnSaveClick
    end
    object btnBackupNow: TButton
      Left = 744
      Top = 24
      Width = 120
      Height = 23
      Caption = #1041#1101#1082#1072#1087' '#1089#1077#1081#1095#1072#1089
      TabOrder = 7
      OnClick = btnBackupNowClick
    end
    object btnForceAll: TButton
      Left = 744
      Top = 52
      Width = 120
      Height = 23
      Caption = #1041#1101#1082#1072#1087' ('#1074#1089#1077')'
      TabOrder = 8
      OnClick = btnForceAllClick
    end
    object btnResetHashes: TButton
      Left = 744
      Top = 80
      Width = 120
      Height = 23
      Caption = #1057#1073#1088#1086#1089' '#1093#1077#1096#1077#1081
      TabOrder = 9
      OnClick = btnResetHashesClick
    end
    object chkAutoStart: TCheckBox
      Left = 720
      Top = 133
      Width = 144
      Height = 17
      Caption = #1040#1074#1090#1086#1079#1072#1087#1091#1089#1082' Windows'
      TabOrder = 16
      OnClick = chkAutoStartClick
    end
    object chkZip: TCheckBox
      Left = 656
      Top = 157
      Width = 58
      Height = 17
      Caption = 'ZIP'
      TabOrder = 10
    end
    object trackInterval: TTrackBar
      Left = 354
      Top = 154
      Width = 172
      Height = 20
      Max = 600
      Min = 5
      Position = 20
      TabOrder = 10
      OnChange = trackIntervalChange
    end
    object btnSelectAll: TButton
      Left = 632
      Top = 104
      Width = 68
      Height = 23
      Caption = #1042#1089#1077
      TabOrder = 11
      OnClick = btnSelectAllClick
    end
    object btnSelectNone: TButton
      Left = 704
      Top = 104
      Width = 68
      Height = 23
      Caption = #1053#1077#1090
      TabOrder = 12
      OnClick = btnSelectNoneClick
    end
    object btnRefreshProjects: TButton
      Left = 776
      Top = 104
      Width = 88
      Height = 23
      Caption = #1054#1073#1085#1086#1074#1080#1090#1100
      TabOrder = 13
      OnClick = btnRefreshProjectsClick
    end
    object chkMinimizeToTray: TCheckBox
      Left = 720
      Top = 156
      Width = 97
      Height = 17
      Caption = #1042' '#1090#1088#1077#1081
      TabOrder = 14
      OnClick = chkMinimizeToTrayClick
    end
    object trackZipInterval: TTrackBar
      Left = 122
      Top = 154
      Width = 100
      Height = 20
      Max = 60
      Min = 1
      Position = 5
      TabOrder = 15
      OnChange = trackZipIntervalChange
    end
    object lblLanguage: TLabel
      Left = 720
      Top = 180
      Width = 84
      Height = 13
      Caption = 'Язык / Language:'
    end
    object cmbLanguage: TComboBox
      Left = 720
      Top = 199
      Width = 120
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 16
      OnChange = cmbLanguageChange
      Items.Strings = (
        'Русский'
        'English')
    end
  end
  object chklistProjects: TCheckListBox
    Left = 0
    Top = 180
    Width = 300
    Height = 440
    Align = alLeft
    ItemHeight = 17
    TabOrder = 1
    ExplicitHeight = 439
  end
  object MemoLog: TMemo
    Left = 300
    Top = 180
    Width = 580
    Height = 440
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 2
    ExplicitWidth = 576
    ExplicitHeight = 439
  end
  object TimerScan: TTimer
    Interval = 20000
    OnTimer = TimerScanTimer
    Left = 824
    Top = 8
  end
  object TrayIcon: TTrayIcon
    PopupMenu = PopupTray
    OnDblClick = TrayIconDblClick
    Left = 792
    Top = 8
  end
  object PopupTray: TPopupMenu
    Left = 760
    Top = 8
    object miRestore: TMenuItem
      Caption = #1042#1086#1089#1089#1090#1072#1085#1086#1074#1080#1090#1100
      OnClick = miRestoreClick
    end
    object miExit: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = miExitClick
    end
  end
end
