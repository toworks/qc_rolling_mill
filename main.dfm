object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Form1'
  ClientHeight = 404
  ClientWidth = 572
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 479
    Top = 361
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Chart1: TChart
    Left = 8
    Top = 8
    Width = 546
    Height = 233
    Legend.Visible = False
    Title.Text.Strings = (
      'TChart')
    View3D = False
    TabOrder = 1
    ColorPaletteIndex = 13
    object Series1: TLineSeries
      Marks.Arrow.Visible = True
      Marks.Callout.Brush.Color = clBlack
      Marks.Callout.Arrow.Visible = True
      Marks.Visible = False
      Brush.BackColor = clDefault
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      Pointer.Visible = False
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object Series2: TLineSeries
      Marks.Arrow.Visible = True
      Marks.Callout.Brush.Color = clBlack
      Marks.Callout.Arrow.Visible = True
      Marks.Visible = False
      Brush.BackColor = clDefault
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      Pointer.Visible = False
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object Series3: TLineSeries
      Marks.Arrow.Visible = True
      Marks.Callout.Brush.Color = clBlack
      Marks.Callout.Arrow.Visible = True
      Marks.Visible = False
      Brush.BackColor = clDefault
      Pointer.Brush.Gradient.EndColor = 1330417
      Pointer.Gradient.EndColor = 1330417
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      Pointer.Visible = False
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object Series4: TLineSeries
      Marks.Arrow.Visible = True
      Marks.Callout.Brush.Color = clBlack
      Marks.Callout.Arrow.Visible = True
      Marks.Visible = False
      Brush.BackColor = clDefault
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      Pointer.Visible = False
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object Series5: TLineSeries
      Marks.Arrow.Visible = True
      Marks.Callout.Brush.Color = clBlack
      Marks.Callout.Arrow.Visible = True
      Marks.Visible = False
      Brush.BackColor = clDefault
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      Pointer.Visible = False
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
  end
  object gb_chemical_analysis: TGroupBox
    Left = 8
    Top = 247
    Width = 145
    Height = 106
    Caption = #1093#1080#1084#1080#1095#1077#1089#1082#1080#1081' '#1072#1085#1072#1083#1080#1079
    TabOrder = 2
    object l_n_carbon: TLabel
      Left = 15
      Top = 21
      Width = 56
      Height = 13
      Caption = #1091#1075#1083#1077#1088#1086#1076' '#1057':'
    end
    object l_carbon: TLabel
      Left = 77
      Top = 21
      Width = 41
      Height = 13
      Caption = 'l_carbon'
    end
    object l_n_manganese: TLabel
      Left = 3
      Top = 40
      Width = 68
      Height = 13
      Caption = #1084#1072#1088#1075#1072#1085#1077#1094' Mn:'
    end
    object l_manganese: TLabel
      Left = 77
      Top = 40
      Width = 63
      Height = 13
      Caption = 'l_manganese'
    end
    object l_n_silicium: TLabel
      Left = 14
      Top = 59
      Width = 57
      Height = 13
      Caption = #1082#1088#1077#1084#1085#1080#1081' Si:'
    end
    object l_silicium: TLabel
      Left = 77
      Top = 59
      Width = 40
      Height = 13
      Caption = 'l_silicium'
    end
    object l_n_chromium: TLabel
      Left = 29
      Top = 78
      Width = 42
      Height = 13
      Caption = #1093#1088#1086#1084' Cr:'
    end
    object l_chromium: TLabel
      Left = 77
      Top = 78
      Width = 53
      Height = 13
      Caption = 'l_chromium'
    end
  end
  object gb_general_data: TGroupBox
    Left = 159
    Top = 247
    Width = 234
    Height = 139
    Caption = #1086#1073#1097#1080#1077' '#1076#1072#1085#1085#1099#1077
    TabOrder = 3
    object l_n_heat: TLabel
      Left = 20
      Top = 21
      Width = 40
      Height = 13
      Caption = #1087#1083#1072#1074#1082#1072':'
    end
    object l_heat: TLabel
      Left = 66
      Top = 21
      Width = 30
      Height = 13
      Caption = 'l_heat'
    end
    object l_n_grade: TLabel
      Left = 26
      Top = 40
      Width = 34
      Height = 13
      Caption = #1084#1072#1088#1082#1072':'
    end
    object l_grade: TLabel
      Left = 66
      Top = 40
      Width = 36
      Height = 13
      Caption = 'l_grade'
    end
    object l_n_c_equivalent: TLabel
      Left = 140
      Top = 11
      Width = 16
      Height = 13
      Caption = 'C'#1101':'
    end
    object l_c_equivalent: TLabel
      Left = 162
      Top = 11
      Width = 69
      Height = 13
      Caption = 'l_c_equivalent'
    end
    object l_n_temp: TLabel
      Left = 142
      Top = 30
      Width = 14
      Height = 13
      Caption = #8304#1057':'
    end
    object l_temp: TLabel
      Left = 162
      Top = 30
      Width = 32
      Height = 13
      Caption = 'l_temp'
    end
    object l_n_section: TLabel
      Left = 12
      Top = 59
      Width = 48
      Height = 13
      Caption = #1087#1088#1086#1092#1080#1083#1100':'
    end
    object l_section: TLabel
      Left = 66
      Top = 59
      Width = 42
      Height = 13
      Caption = 'l_section'
    end
    object l_n_standard: TLabel
      Left = 8
      Top = 78
      Width = 52
      Height = 13
      Caption = #1089#1090#1072#1085#1076#1072#1088#1090':'
    end
    object l_standard: TLabel
      Left = 66
      Top = 78
      Width = 51
      Height = 13
      Caption = 'l_standard'
    end
    object l_n_strength_class: TLabel
      Left = 3
      Top = 97
      Width = 57
      Height = 26
      Caption = #1082#1083#1072#1089#1089' '#1087#1088#1086#1095#1085#1086#1089#1090#1080':'
      WordWrap = True
    end
    object l_strength_class: TLabel
      Left = 66
      Top = 110
      Width = 78
      Height = 13
      Caption = 'l_strength_class'
    end
  end
  object Edit1: TEdit
    Left = 433
    Top = 334
    Width = 121
    Height = 21
    TabOrder = 4
    Text = 'Edit1'
  end
end