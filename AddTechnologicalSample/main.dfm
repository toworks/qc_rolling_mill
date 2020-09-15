object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 292
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
  object l_n_standard: TLabel
    Left = 11
    Top = 164
    Width = 50
    Height = 13
    Caption = #1057#1090#1072#1085#1076#1072#1088#1090
  end
  object l_n_strength_class: TLabel
    Left = 218
    Top = 137
    Width = 85
    Height = 13
    Caption = #1050#1083#1072#1089#1089' '#1087#1088#1086#1095#1085#1086#1089#1090#1080
  end
  object l_n_diameter_min: TLabel
    Left = 158
    Top = 191
    Width = 63
    Height = 13
    Caption = #1044#1080#1072#1084#1077#1090#1088' min'
  end
  object l_n_diameter_max: TLabel
    Left = 154
    Top = 218
    Width = 67
    Height = 13
    Caption = #1044#1080#1072#1084#1077#1090#1088' max'
  end
  object l_n_limit_min: TLabel
    Left = 312
    Top = 191
    Width = 57
    Height = 13
    Caption = #1055#1088#1077#1076#1077#1083' min'
  end
  object l_n_limit_max: TLabel
    Left = 308
    Top = 218
    Width = 61
    Height = 13
    Caption = #1055#1088#1077#1076#1077#1083' max'
  end
  object l_n_type: TLabel
    Left = 43
    Top = 243
    Width = 18
    Height = 16
    Caption = #1058#1080#1087
  end
  object l_n_c_max: TLabel
    Left = 410
    Top = 164
    Width = 30
    Height = 13
    Caption = 'C max'
  end
  object l_n_grade: TLabel
    Left = 29
    Top = 137
    Width = 32
    Height = 13
    Caption = #1052#1072#1088#1082#1072
  end
  object l_n_c_min: TLabel
    Left = 414
    Top = 137
    Width = 26
    Height = 13
    Caption = 'C min'
  end
  object l_n_mn_max: TLabel
    Left = 530
    Top = 164
    Width = 37
    Height = 13
    Caption = 'Mn max'
  end
  object l_n_mn_min: TLabel
    Left = 534
    Top = 137
    Width = 33
    Height = 13
    Caption = 'Mn min'
  end
  object l_n_si_max: TLabel
    Left = 30
    Top = 218
    Width = 31
    Height = 13
    Caption = 'Si max'
  end
  object l_n_si_min: TLabel
    Left = 34
    Top = 191
    Width = 27
    Height = 13
    Caption = 'Si min'
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 8
    Width = 625
    Height = 120
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnCellClick = DBGrid1CellClick
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'numeric'
        Title.Alignment = taCenter
        Width = 50
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'grade'
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'standard'
        Title.Alignment = taCenter
        Width = 100
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'strength_class'
        Title.Alignment = taCenter
        Width = 100
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'c_min'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'c_max'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'mn_min'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'mn_max'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'si_min'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'si_max'
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'diameter_min'
        Title.Alignment = taCenter
        Width = 100
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'diameter_max'
        Title.Alignment = taCenter
        Width = 100
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'limit_min'
        Title.Alignment = taCenter
        Width = 100
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'limit_max'
        Title.Alignment = taCenter
        Width = 100
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'type'
        Title.Alignment = taCenter
        Width = 120
        Visible = True
      end>
  end
  object e_standard: TEdit
    Left = 67
    Top = 161
    Width = 121
    Height = 21
    TabOrder = 1
    OnClick = e_standardClick
  end
  object e_strength_class: TEdit
    Left = 309
    Top = 134
    Width = 60
    Height = 21
    TabOrder = 2
    OnClick = e_strength_classClick
  end
  object e_diameter_min: TEdit
    Left = 227
    Top = 188
    Width = 60
    Height = 21
    TabOrder = 3
    OnClick = e_diameter_minClick
  end
  object e_diameter_max: TEdit
    Left = 227
    Top = 215
    Width = 60
    Height = 21
    TabOrder = 4
    OnClick = e_diameter_maxClick
  end
  object e_limit_min: TEdit
    Left = 375
    Top = 188
    Width = 60
    Height = 21
    TabOrder = 5
    OnClick = e_limit_minClick
  end
  object e_limit_max: TEdit
    Left = 375
    Top = 215
    Width = 60
    Height = 21
    TabOrder = 6
    OnClick = e_limit_maxClick
  end
  object rb_yield_point: TRadioButton
    Left = 67
    Top = 242
    Width = 113
    Height = 20
    Caption = #1087#1088#1077#1076#1077#1083' '#1090#1077#1082#1091#1095#1077#1089#1090#1080
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 7
    OnClick = rb_yield_pointClick
  end
  object rb_rupture_strength: TRadioButton
    Left = 67
    Top = 265
    Width = 159
    Height = 20
    Caption = #1074#1088#1077#1084#1077#1085#1085#1086#1077' '#1089#1086#1087#1088#1086#1090#1080#1074#1083#1077#1085#1080#1077
    TabOrder = 8
    OnClick = rb_rupture_strengthClick
  end
  object b_action: TButton
    Left = 518
    Top = 263
    Width = 115
    Height = 21
    Caption = #1074#1099#1087#1086#1083#1085#1080#1090#1100
    TabOrder = 10
    OnClick = b_actionClick
  end
  object cb_add_update_delete: TComboBox
    Left = 518
    Top = 236
    Width = 114
    Height = 21
    TabOrder = 9
  end
  object e_c_max: TEdit
    Left = 446
    Top = 161
    Width = 60
    Height = 21
    TabOrder = 11
    OnClick = e_c_maxClick
  end
  object e_grade: TEdit
    Left = 67
    Top = 134
    Width = 121
    Height = 21
    TabOrder = 12
    OnClick = e_gradeClick
  end
  object e_c_min: TEdit
    Left = 446
    Top = 134
    Width = 60
    Height = 21
    TabOrder = 13
    OnClick = e_c_minClick
  end
  object e_mn_max: TEdit
    Left = 573
    Top = 161
    Width = 60
    Height = 21
    TabOrder = 14
    OnClick = e_mn_maxClick
  end
  object e_mn_min: TEdit
    Left = 573
    Top = 134
    Width = 60
    Height = 21
    TabOrder = 15
    OnClick = e_mn_minClick
  end
  object e_si_max: TEdit
    Left = 67
    Top = 215
    Width = 60
    Height = 21
    TabOrder = 16
    OnClick = e_si_maxClick
  end
  object e_si_min: TEdit
    Left = 67
    Top = 188
    Width = 60
    Height = 21
    TabOrder = 17
    OnClick = e_si_minClick
  end
end
