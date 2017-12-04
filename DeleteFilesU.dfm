object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Rename / Delete Files'
  ClientHeight = 526
  ClientWidth = 601
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    601
    526)
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar1: TStatusBar
    Left = 0
    Top = 507
    Width = 601
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 441
    Height = 493
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    Caption = 'pnlLeft'
    TabOrder = 1
    object Label1: TLabel
      Left = 0
      Top = 0
      Width = 441
      Height = 13
      Align = alTop
      Caption = 'Delete Files:'
      ExplicitWidth = 59
    end
    object Splitter: TSplitter
      Left = 0
      Top = 253
      Width = 441
      Height = 10
      Cursor = crVSplit
      Align = alTop
      Color = clBtnFace
      MinSize = 100
      ParentColor = False
      ExplicitTop = 234
      ExplicitWidth = 457
    end
    object edDeleteFiles: TMemo
      Left = 0
      Top = 13
      Width = 441
      Height = 240
      Align = alTop
      Lines.Strings = (
        'Paste full file paths or Drop files from Windows Explorer.'
        'Can use the following to INDEX a filename '
        
          '"<" and ">" and a number which is left padded to the length of t' +
          'he number...'
        ''
        'i.e.'
        'Readme<01>'
        ''
        'Would Renamethe file Readme.txt'
        'to'
        'Readme01.txt'
        ''
        
          'For Change File DateTime, this will change Creation, Modified an' +
          'd Accessed '
        
          'date to the date/time speicified... Can use 24hr time or AM/PM o' +
          'r NOW.'
        
          'NOTE: if the file is an image, Windows will display the Date Tak' +
          'en if that'
        'property Exists.'
        'Can use <01> in string. ZB: 12/22/2017 13:<01>:01  ')
      ScrollBars = ssBoth
      TabOrder = 0
    end
    object Panel2: TPanel
      Left = 0
      Top = 263
      Width = 441
      Height = 230
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlFilesDeleted'
      TabOrder = 1
      object Label2: TLabel
        Left = 0
        Top = 0
        Width = 441
        Height = 13
        Align = alTop
        Caption = 'Status:'
        ExplicitWidth = 35
      end
      object edStatus: TMemo
        Left = 0
        Top = 13
        Width = 441
        Height = 217
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
  end
  object btnDoIt: TBitBtn
    Left = 509
    Top = 19
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '&DoIt'
    Enabled = False
    TabOrder = 2
    OnClick = btnDoItClick
    Kind = bkIgnore
  end
  object btnAbort: TBitBtn
    Left = 509
    Top = 64
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Enabled = False
    TabOrder = 3
    OnClick = btnAbortClick
    Kind = bkAbort
  end
  object btnClose: TBitBtn
    Left = 518
    Top = 476
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    TabOrder = 4
    Kind = bkClose
  end
  object edTimer: TLabeledEdit
    Left = 463
    Top = 410
    Width = 75
    Height = 21
    Hint = '-1 to disable'
    Anchors = [akTop, akRight]
    EditLabel.Width = 30
    EditLabel.Height = 13
    EditLabel.Caption = 'Timer:'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 5
    Text = '100'
  end
  object cbxStopOnError: TCheckBox
    Left = 463
    Top = 373
    Width = 97
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'StopOnError'
    TabOrder = 6
  end
  object edAppendToFilename: TLabeledEdit
    Left = 455
    Top = 118
    Width = 129
    Height = 21
    Anchors = [akTop, akRight]
    EditLabel.Width = 81
    EditLabel.Height = 13
    EditLabel.Caption = 'Add to Filename:'
    Enabled = False
    TabOrder = 7
  end
  object rgMode: TRadioGroup
    Left = 455
    Top = 192
    Width = 138
    Height = 169
    Anchors = [akTop, akRight]
    Caption = 'Mode:'
    Items.Strings = (
      'Prefix String'
      'Append String'
      'Remove String'
      'Replace String'
      'Rename File'
      'Change File DateTime'
      'Delete File')
    TabOrder = 9
    OnClick = cbxAppendToFilename1Click
  end
  object edReplaceWithFilename: TLabeledEdit
    Left = 455
    Top = 158
    Width = 129
    Height = 21
    Anchors = [akTop, akRight]
    EditLabel.Width = 112
    EditLabel.Height = 13
    EditLabel.Caption = 'Replace With Filename:'
    Enabled = False
    TabOrder = 8
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 536
    Top = 419
  end
end
