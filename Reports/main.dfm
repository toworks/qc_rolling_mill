object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 284
  ClientWidth = 641
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
  PixelsPerInch = 96
  TextHeight = 13
  object l_n_heat: TLabel
    Left = 198
    Top = 239
    Width = 36
    Height = 13
    Caption = #1087#1083#1072#1074#1082#1072
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 8
    Width = 625
    Height = 222
    Color = clBtnFace
    ReadOnly = True
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDrawDataCell = DBGrid1DrawDataCell
    OnDrawColumnCell = DBGrid1DrawColumnCell
  end
  object b_action: TButton
    Left = 518
    Top = 255
    Width = 115
    Height = 21
    Caption = #1074#1099#1087#1086#1083#1085#1080#1090#1100
    TabOrder = 1
    OnClick = b_actionClick
  end
  object rb_calculated_data: TRadioButton
    Left = 399
    Top = 236
    Width = 113
    Height = 17
    Caption = #1088#1072#1089#1095#1077#1090#1085#1099#1077' '#1076#1072#1085#1085#1099#1077
    TabOrder = 2
    OnClick = rb_calculated_dataClick
  end
  object rb_temperature: TRadioButton
    Left = 399
    Top = 259
    Width = 113
    Height = 17
    Caption = #1090#1077#1084#1087#1077#1088#1072#1090#1091#1088#1072
    TabOrder = 3
  end
  object e_heat: TEdit
    Left = 240
    Top = 236
    Width = 121
    Height = 21
    TabOrder = 4
    OnChange = e_heatChange
  end
  object cb_export: TCheckBox
    Left = 198
    Top = 263
    Width = 97
    Height = 17
    Caption = #1101#1082#1089#1087#1086#1088#1090' '#1074' '#1092#1072#1081#1083
    TabOrder = 5
  end
end
