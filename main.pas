unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.DBChart,
  VCLTee.TeeSpline, SyncObjs, Math, Vcl.Menus, Vcl.ActnPopup, ZAbstractDataset,
  ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset,
  ZStoredProcedure;

type
  TForm1 = class(TForm)
    b_test: TButton;
    chart_right_side: TChart;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Series3: TLineSeries;
    Series4: TLineSeries;
    Series5: TLineSeries;
    l_chemical_right: TLabel;
    gb_right_side: TGroupBox;
    l_global_right: TLabel;
    TrayIcon: TTrayIcon;
    gb_left_side: TGroupBox;
    l_global_left: TLabel;
    l_chemical_left: TLabel;
    chart_left_side: TChart;
    series_max_red: TLineSeries;
    series_max_green: TLineSeries;
    series_current: TLineSeries;
    series_min_green: TLineSeries;
    series_min_red: TLineSeries;
    procedure FormCreate(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure TrayPopUpCloseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure b_testClick(Sender: TObject);

  private
    { Private declarations }
    // procedure TrayPopUpCloseClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  LastDate: TDateTime = 0;
  CurrentDir: string;
  HeadName: string = ' ���������� ��������� MC 250-5';
  Version: string = ' v0.0beta';
  DBFile: string = 'data.sdb';
  LogFile: string = 'app.log';
  PopupTray: TPopupMenu;
  TrayMark: bool = false;
  LowRedLeft, HighRedLeft, LowGreenLeft, HighGreenLeft, LowRedRight,
    HighRedRight, LowGreenRight, HighGreenRight: integer;
  LeftM: bool = false;
  RightM: bool = false;
  LimitsM: integer = 0;


{$DEFINE DEBUG}

function RolledMelting(InSide: integer): string;
function CarbonEquivalent(InHeat: string; InSide: integer): bool;
function HeatToIn(InHeat: string): string;
function CutChar(InData: string): string;
function CalculatingInMechanicalCharacteristics(InHeat: string; InSide: integer): string;
function TrayAppRun: bool;
function CheckAppRun: bool;
function ViewClear: bool;
function ShowTrayMessage(InTitle, InMessage: AnsiString; InFlag: integer): bool;
function GetDigits(InData: string): string;
function ErrorMessagesToCharts(InSide: integer; InError: bool): string;
function RepaceComma(InData: string): string;

implementation

uses
  settings, logging, sql, chart, thread_main;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  // �������� 1 ���������� ���������
  CheckAppRun;

  Form1.Caption := HeadName + Version;
  // ��������� � showmessage
  Application.Title := HeadName + Version;

  // ������� ����������
  CurrentDir := GetCurrentDir;
  // ����� ������ ������� ��� �������������� � ������
  FormatSettings.DecimalSeparator := '.';

  // ������ �� ��������� �����
  Form1.BorderStyle := bsToolWindow;
  Form1.BorderIcons := Form1.BorderIcons - [biMaximize];

  SaveLog('app' + #9#9 + 'start');

  // ������������� ����
  TrayAppRun;

  ViewClear;

  ConfigSettings(true);

  ConfigPostgresSetting(true);
  ConfigOracleSetting(true);

  ThreadMain.Start;
end;

procedure TForm1.b_testClick(Sender: TObject);
var
  HeatAll: string;
  i, Current: integer;
  t, ot: TDateTime;
  Grade: string; // ����� �����
  Section: string; // �������
  Standard: string; // ��������
  StrengthClass: string; // ���� ���������
  ReturnValue: string;
  c, mn, si: string;
  InSide: integer;
begin

  ViewClear;

  { DATE_IN_HIM, NPL, MST, GOST, C, MN, SI, S, CR, B' }
  // SqlWriteCemicalAnalysis('2013-07-01|233525|C�3��C|�C�� 3760-2006|0.199|0.92|0.014|0.027|0.022|0.0005');


  // -- for test
  { Heat:= '232371'; //������
    Grade:= '%��3����'; //����� �����
    Section:= '%10%'; //�������
    Standard:= '����%3760%2006'; //��������
    StrengthClass:= '%�500�%'; //���� ��������� }
  // Side := 2; //1 ������ - �� ������, 2 ����� - ������, ������� | ��5 0 ���� 1 ������
  // -- for test

  // RolledMelting(1);

  // HeatAll := HeatToString(AggregateHeatTableArray);

  // {$IFDEF DEBUG}
  // SaveLog('debug'+#9#9+'heat='+HeatAll);
  // {$ENDIF}

  try
//    SaveLog('info' + #9#9 + 'start calculation left side, heat -> '+left.Heat);
    HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(0), 0);
    if HeatAll <> '' then
      CarbonEquivalent(HeatAll, 0);
//    SaveLog('info' + #9#9 + 'end calculation left side, heat -> '+left.Heat);
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  try
    SaveLog('info' + #9#9 + 'start calculation right side, heat -> '+right.Heat);
    HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(1), 1);
    if HeatAll <> '' then
      CarbonEquivalent(HeatAll, 1);
    SaveLog('info' + #9#9 + 'end calculation right side, heat -> ' + right.Heat);
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;

function GetDigits(InData: string): string;
var
  digits: string;
  i: integer;
begin
  for i := 1 to length(InData) do
  begin
    if not(InData[i] in ['0' .. '9']) then
      digits := digits + '%'
    else
      digits := digits + InData[i];
  end;
  Result := digits;
end;

function RolledMelting(InSide: integer): string;
var
  i: integer;
  // -- Side - 1 ������ - �� ������, 2 ����� - ������, ������� | ��5 0 ���� 1 ������
  Grade: string; // ����� �����
  Section: string; // �������
  Standard: string; // ��������
  StrengthClass: string; // ���� ���������
  ReturnValue: string;
  PQueryCalculation: TZQuery;
begin
  PQueryCalculation := TZQuery.Create(nil);
  PQueryCalculation.Connection := PConnect;

  if InSide = 0 then
  begin
    Grade := left.Grade;
    Section := left.Section;
    Standard := left.Standard;
    StrengthClass := left.StrengthClass;
  end
  else
  begin
    Grade := right.Grade;
    Section := right.Section;
    Standard := right.Standard;
    StrengthClass := right.StrengthClass;
  end;

  // -- ��������� ���������� ������ �� ������ 125 ��� �������� ������
  PQueryCalculation.Close;
  PQueryCalculation.sql.Clear;
  PQueryCalculation.sql.Add('select heat from temperature_current');
  PQueryCalculation.sql.Add('where timestamp<=EXTRACT(EPOCH FROM now())');
  PQueryCalculation.sql.Add('and timestamp>=EXTRACT(EPOCH FROM now())-(2629743*10)');// timestamp 2629743 month * 10
//--  PQueryCalculation.sql.Add('and strength_class like '''+CutChar(StrengthClass)+'%''');
  PQueryCalculation.sql.Add('and grade like '''+CutChar(Grade)+'%''');
  PQueryCalculation.sql.Add('and section = '+CutChar(Section)+'');
//test comment perameter standard
  PQueryCalculation.sql.Add('and standard like '''+GetDigits(Standard)+'%''');
  PQueryCalculation.sql.Add('and side='+inttostr(InSide)+'');
  PQueryCalculation.sql.Add('LIMIT 125');
  Application.ProcessMessages; // ��������� �������� �� �������� ���������
  PQueryCalculation.Open;

{$IFDEF DEBUG}
  SaveLog('debug'+#9#9+'PQueryCalculation.SQL.Text -> '+PQueryCalculation.sql.Text);
{$ENDIF}
  i := 0;
  while not PQueryCalculation.Eof do
  begin
    if i = 0 then
      ReturnValue := ReturnValue + PQueryCalculation.FieldByName('heat').AsString
    else
      ReturnValue := ReturnValue + '|' + PQueryCalculation.FieldByName('heat').AsString;

    inc(i);
    PQueryCalculation.Next;
  end;

  FreeAndNil(PQueryCalculation);

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'Heat -> ' + ReturnValue);
{$ENDIF}
  Result := ReturnValue;
end;

function CarbonEquivalent(InHeat: string; InSide: integer): bool;
var
  CeMin, CeMax, CeAvg, CeMinP, CeMaxM, CeAvgP, CeAvgM, rangeMin: real;
  i, a, b, c, rangeM: integer;
  CeArray: TArray; // array of array of variant;
  CeMinHeat, CeHeatStringMin, CeHeatStringMax, CeHeatStringAvg: string;
  range: array of variant;
begin

  i := 0;
  a := 0;
  b := a;
  c := a;

  CeArray := SqlCarbonEquivalent(InHeat);

  CeMin := CeArray[0, 1]; // ����� ������ �������� �� �������
  CeMax := CeMin;
  For i := Low(CeArray) To High(CeArray) Do
  Begin
    If CeArray[i, 1] < CeMin Then
      CeMin := CeArray[i, 1];
    If CeArray[i, 1] > CeMax Then
      CeMax := CeArray[i, 1];
  End;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMin -> ' + floattostr(CeMin));
  SaveLog('debug' + #9#9 + 'CeMax -> ' + floattostr(CeMax));
{$ENDIF}
  CeAvg := (CeMin + CeMax) / 2;
  CeMinP := CeMin + 0.03;
  CeMaxM := CeMax - 0.03;
  CeAvgP := CeAvg + 0.015;
  CeAvgM := CeAvg - 0.015;

  For i := Low(CeArray) To High(CeArray) Do
  Begin
    If InRange(CeArray[i, 1], CeMin, CeMinP) then
    begin
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'CeMinRangeHeat -> ' + CeArray[i, 0]);
      SaveLog('debug' + #9#9 + 'CeMinRangeValue -> ' +
        floattostr(CeArray[i, 1]));
{$ENDIF}
      if a = 0 then
        CeHeatStringMin := CeArray[i, 0]
      else
        CeHeatStringMin := CeHeatStringMin + '|' + CeArray[i, 0];
      inc(a);
    end;

    if InRange(CeArray[i, 1], CeMaxM, CeMax) then
    begin
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'CeMaxRangeHeat -> ' + CeArray[i, 0]);
      SaveLog('debug' + #9#9 + 'CeMaxRangeValue -> ' +
        floattostr(CeArray[i, 1]));
{$ENDIF}
      if b = 0 then
        CeHeatStringMax := CeArray[i, 0]
      else
        CeHeatStringMax := CeHeatStringMax + '|' + CeArray[i, 0];
      inc(b);
    end;

    if InRange(CeArray[i, 1], CeAvgM, CeAvgP) then
    begin
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'CeAvgRangeHeat -> ' + CeArray[i, 0]);
      SaveLog('debug' + #9#9 + 'CeAvgRangeValue -> ' + floattostr(CeArray[i, 1]));
{$ENDIF}
      if c = 0 then
        CeHeatStringAvg := CeArray[i, 0]
      else
        CeHeatStringAvg := CeHeatStringAvg + '|' + CeArray[i, 0];
      inc(c);
    end;
  end;

  // -- report
  CalculatedData(InSide, 'ce_min_down=''' + FloatToStrF(CeMin, ffGeneral,6,0) + '''');
  CalculatedData(InSide, 'ce_min_up=''' + floattostr(CeMinP) + '''');
  CalculatedData(InSide, 'ce_max_down=''' + floattostr(CeMaxM) + '''');
  CalculatedData(InSide, 'ce_max_up=''' + floattostr(CeMax) + '''');
  CalculatedData(InSide, 'ce_avg=''' + floattostr(CeAvg) + '''');
  CalculatedData(InSide, 'ce_avg_down=''' + floattostr(CeAvgM) + '''');
  CalculatedData(InSide, 'ce_avg_up=''' + floattostr(CeAvgP) + '''');
  // -- report

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeInHeat -> ' + InHeat);
  SaveLog('debug' + #9#9 + 'CeMin -> ' + floattostr(CeMin));
  SaveLog('debug' + #9#9 + 'CeMax -> ' + floattostr(CeMax));
  SaveLog('debug' + #9#9 + 'CeAvg -> ' + floattostr(CeAvg));
  SaveLog('debug' + #9#9 + 'CeMinP -> ' + floattostr(CeMinP));
  SaveLog('debug' + #9#9 + 'CeMaxM -> ' + floattostr(CeMaxM));
  SaveLog('debug' + #9#9 + 'CeAvgP -> ' + floattostr(CeAvgP));
  SaveLog('debug' + #9#9 + 'CeAvgM -> ' + floattostr(CeAvgM));
{$ENDIF}
  if InSide = 0 then
  begin
    // -- �� �� ������� ������
    CeArray := SqlCarbonEquivalent('''' + left.Heat + '''');
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'Currentleft.Heat -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeLeft -> ' + floattostr(CeArray[0, 1]));
{$ENDIF}
  end
  else
  begin
    // -- �� �� ������� ������
    CeArray := SqlCarbonEquivalent('''' + right.Heat + '''');
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'Currentright.Heat -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeRight -> ' + floattostr(CeArray[0, 1]));
{$ENDIF}
  end;

  // -- ������� ������ � ������ �� ���������� ��������� min,max,avg
  if InRange(CeArray[0, 1], CeMin, CeMinP) and (CeHeatStringMin <> '') then
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'CurrentCeMinRange -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeMinRangeValue -> ' +
      floattostr(CeArray[0, 1]));
{$ENDIF}
  end;

  if InRange(CeArray[0, 1], CeMaxM, CeMax) and (CeHeatStringMax <> '') then
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'CurrentCeMaxRange -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeMaxRangeValue -> ' +
      floattostr(CeArray[0, 1]));
{$ENDIF}
  end;

  if InRange(CeArray[0, 1], CeAvgM, CeAvgP) and (CeHeatStringAvg <> '') then
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'CurrentCeAvgRange -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeAvgRangeValue -> ' +
      floattostr(CeArray[0, 1]));
{$ENDIF}
  end;

  SetLength(range, 4);
  range[0] := ABS(CeMinP - CeArray[0, 1]);
  range[1] := ABS(CeMaxM - CeArray[0, 1]);
  range[2] := ABS(CeAvgP - CeArray[0, 1]);
  range[3] := ABS(CeAvgM - CeArray[0, 1]);

  rangeMin := range[0];

  for i := low(range) To high(range) Do
    if range[i] < rangeMin then
      rangeMin := range[i];

  for i := low(range) To high(range) Do
  begin
    If range[i] = rangeMin Then
    begin
      if (i = 0) and (CeHeatStringMin <> '') then
      begin
        if InSide = 0 then
        begin
          CalculatingInMechanicalCharacteristics(CeHeatStringMin, 0);
{$IFDEF DEBUG}
          SaveLog('debug' + #9#9 + 'CeMinRangeleft.Heat -> ' + CeHeatStringMin);
{$ENDIF}
        end
        else
        begin
          CalculatingInMechanicalCharacteristics(CeHeatStringMin, 1);
{$IFDEF DEBUG}
          SaveLog('debug' + #9#9 + 'CeMinRangeright.Heat -> ' + CeHeatStringMin);
{$ENDIF}
        end;
      end;
      if (i = 3) and (CeHeatStringMax <> '') then
      begin
        if InSide = 0 then
        begin
          CalculatingInMechanicalCharacteristics(CeHeatStringMax, 0);
{$IFDEF DEBUG}
          SaveLog('debug' + #9#9 + 'CeMaxRangeleft.Heat -> ' + CeHeatStringMax);
{$ENDIF}
        end
        else
        begin
          CalculatingInMechanicalCharacteristics(CeHeatStringMax, 1);
{$IFDEF DEBUG}
          SaveLog('debug' + #9#9 + 'CeMaxRangeright.Heat -> ' + CeHeatStringMax);
{$ENDIF}
        end;
      end;
      if ((i = 1) or (i = 2)) and (CeHeatStringAvg <> '') then
      begin
        if InSide = 0 then
        begin
          CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 0);
{$IFDEF DEBUG}
          SaveLog('debug' + #9#9 + 'CeAvgRangeleft.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
        end
        else
        begin
          CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 1);
{$IFDEF DEBUG}
          SaveLog('debug' + #9#9 + 'CeAvgRangeright.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
        end;
      end;
    end;
  end;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeRangeMinValue -> ' + floattostr(rangeMin));
  SaveLog('debug' + #9#9 + 'rangeM -> ' + floattostr(rangeM));
{$ENDIF}
end;

function HeatToIn(InHeat: string): string;
var
  i: integer;
  AllHeat: string;
  st: TStringList;
begin
  st := TStringList.Create;
  st.Text := StringReplace(InHeat, '|', #13#10, [rfReplaceAll]);

  for i := 0 to st.Count - 1 do
  begin
    if i <> st.Count - 1 then
      st.Strings[i] := '''' + st.Strings[i] + '''' + ','
    else
      st.Strings[i] := '''' + st.Strings[i] + '''';

    AllHeat := AllHeat + '' + st.Strings[i] + '';
  end;
  st.Free;
  Result := AllHeat;
end;

function CalculatingInMechanicalCharacteristics(InHeat: string; InSide: integer): string;
var
  { yield point - ������ ���������
    rupture strength - ��������� ������������� }

  Grade: string; // ����� �����
  Section: string; // �������
  Standard: string; // ��������
  StrengthClass: string; // ���� ���������
  ReturnValue: string;
  PQueryCalculation: TZQuery;
  PQueryData: TZQuery;

  i, a, b, CoefficientCount, AdjustmentMin, AdjustmentMax,
  LimitRolledProductsMin, LimitRolledProductsMax, HeatCount: integer;
  m: bool;
  CoefficientYieldPointValue, CoefficientRuptureStrengthValue, MechanicsAvg,
    MechanicsStdDev, MechanicsMin, MechanicsMax, MechanicsDiff, CoefficientMin,
    CoefficientMax, TempAvg, TempStdDev, TempMin, TempMax, TempDiff, R: real;
  TypeRolledProducts, HeatAll, HeatWorks, HeatTableAll: WideString;
  HeatArray, HeatTableArray: Array of string;
  MechanicsArray, TempArray: Array of Double;
  st, HeatTmp: TStringList;
  c, mn, si, HeatMechanics: string;
begin

  if InHeat.IsEmpty then
  begin
    SaveLog('warning'+#9#9+'������� -> '+ErrorMessagesToCharts(InSide, true));
    SaveLog('warning'+#9#9 +'������������ ������ �� ����������� ������� ��� ������� �� ������ -> '+InHeat);
    exit;
  end;

  PQueryCalculation := TZQuery.Create(nil);
  PQueryCalculation.Connection := PConnect;
  PQueryData := TZQuery.Create(nil);
  PQueryData.Connection := PConnect;

  a := 0;
  b := a;

  if InSide = 0 then
  begin
    Grade := left.Grade;
    Section := left.Section;
    Standard := left.Standard;
    StrengthClass := left.StrengthClass;
    c := c_left;
    mn := mn_left;
    si := si_left;
  end
  else
  begin
    Grade := right.Grade;
    Section := right.Section;
    Standard := right.Standard;
    StrengthClass := right.StrengthClass;
    c := c_right;
    mn := mn_right;
    si := si_right;
  end;

  HeatAll := HeatToIn(InHeat);

//   ��� 3�� �������
    OraQuery.FetchAll := true;
    OraQuery.Close;
    OraQuery.SQL.Clear;
    OraQuery.SQL.Add('select * from');
    OraQuery.SQL.Add('(select n.nplav heat, n.mst grade, n.GOST standard');
    OraQuery.SQL.Add(',n.razm1 section, n.klass strength_class');
    OraQuery.SQL.Add(',v.limtek yield_point, v.limproch rupture_strength');
    OraQuery.SQL.Add(',ROW_NUMBER() OVER (PARTITION BY n.nplav ORDER BY n.data desc) AS number_row');
    OraQuery.SQL.Add('from czl_v v, czl_n n');
    //-- 305 = 10 month
    OraQuery.SQL.Add('where n.data<=sysdate and n.data>=sysdate-305');
    OraQuery.SQL.Add('and n.mst like translate('''+CutChar(Grade)+''','); //��������� Eng ����� ������� �� ��������
    OraQuery.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
    OraQuery.SQL.Add('and n.GOST like translate('''+CutChar(Standard)+''','); //��������� Eng ����� ������� �� ��������
    OraQuery.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
    OraQuery.SQL.Add('and n.razm1 = '+Section+'');
//--    OraQuery.SQL.Add('and n.klass like translate('''+CutChar(StrengthClass)+''','); //��������� Eng ����� ������� �� ��������
//--    OraQuery.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
    OraQuery.SQL.Add('and n.data=v.data and v.npart=n.npart');
    OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
    OraQuery.SQL.Add('and prizn=''*'' and ROWNUM <= 251');
    OraQuery.SQL.Add('and n.nplav in('+HeatAll+')');
    OraQuery.SQL.Add('order by n.data desc)');
    OraQuery.SQL.Add('where number_row <= 3');
    Application.ProcessMessages;//��������� �������� �� �������� ���������
    OraQuery.Open;

{$IFDEF DEBUG }
  SaveLog('debug'+#9#9+'OraQuery.SQL.Text -> '+OraQuery.SQL.Text);
  SaveLog('debug' + #9#9 + 'OraQuery.RecordCount -> '+inttostr(OraQuery.RecordCount));
{$ENDIF}

{  PQueryCalculation.Close;
  PQueryCalculation.sql.Clear;
  PQueryCalculation.sql.Add('select FIRST 251 noplav, begindt, gost, razm1, klass, limtek, limproch');
  PQueryCalculation.sql.Add('from mechanical');
  PQueryCalculation.sql.Add('where begindt<=current_date and begindt>=current_date-305');
  PQueryCalculation.sql.Add('and klass like '''+CutChar(StrengthClass)+'''');
//  PQueryCalculation.SQL.Add('and marka like '''+CutChar(Grade)+'''');
  PQueryCalculation.sql.Add('and razm1 like '''+CutChar(Section)+'%''');
  PQueryCalculation.sql.Add('and gost like '''+GetDigits(Standard)+'%''');
  PQueryCalculation.sql.Add('and side='+inttostr(InSide)+'');
  PQueryCalculation.sql.Add('and noplav in ('+HeatAll+')');
  PQueryCalculation.sql.Add('order by begindt desc');
  Application.ProcessMessages; // ��������� �������� �� �������� ���������
  PQueryCalculation.Open;}

//{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'PQueryCalculation.SQL.Text -> '+PQueryCalculation.sql.Text);
//  SaveLog('debug' + #9#9 + 'FQueryCalculation.AllRowsAffected -> '+inttostr(FQueryCalculation.AllRowsAffected.Selects));
//{$ENDIF}

//  if PQueryCalculation.AllRowsAffected.Selects < 5 then
  if OraQuery.RecordCount < 5 then
  begin
    SaveLog('warning' + #9#9 + '������� -> '+ErrorMessagesToCharts(InSide, true));
    SaveLog('warning' + #9#9 + '������������ ������ ��� ������� �� ������� -> '+HeatAll);
    exit;
  end;

  // -- new
  PQueryData.sql.Clear;
  PQueryData.sql.Add('SELECT n, k_yield_point, k_rupture_strength FROM coefficient');
  PQueryData.sql.Add('where n<='+inttostr(OraQuery.RecordCount)+'');
  PQueryData.sql.Add('order by n desc limit 1');
  PQueryData.Open;

  CoefficientCount := PQueryData.FieldByName('n').AsInteger;
  CoefficientYieldPointValue := PQueryData.FieldByName('k_yield_point').AsFloat;
  CoefficientRuptureStrengthValue := PQueryData.FieldByName('k_rupture_strength').AsFloat;

  // -- report
  CalculatedData(InSide, 'coefficient_count=''' + inttostr(CoefficientCount) + '''');
  CalculatedData(InSide, 'coefficient_yield_point_value=''' + floattostr(CoefficientYieldPointValue) + '''');
  CalculatedData(InSide, 'coefficient_rupture_strength_value=''' + floattostr(CoefficientRuptureStrengthValue) + '''');
  // -- report
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CoefficientCount -> ' + inttostr(CoefficientCount));
  SaveLog('debug' + #9#9 + 'CoefficientYieldPointValue -> ' + floattostr(CoefficientYieldPointValue));
  SaveLog('debug' + #9#9 + 'CoefficientRuptureStrengthValue -> ' + floattostr(CoefficientRuptureStrengthValue));
{$ENDIF}
  SQuery.Close;
  SQuery.sql.Clear;
  SQuery.sql.Add('CREATE TABLE IF NOT EXISTS mechanics');
  SQuery.sql.Add('(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
  SQuery.sql.Add(', heat VARCHAR(26),timestamp INTEGER(10), grade VARCHAR(16)');
  SQuery.sql.Add(', standard VARCHAR(16), section VARCHAR(16)');
  SQuery.sql.Add(', strength_class VARCHAR(16), yield_point NUMERIC(10,6)');
  SQuery.sql.Add(', rupture_strength NUMERIC(10,6), side NUMERIC(1,1) NOT NULL)');
  SQuery.ExecSQL;

  // -- clean table mechanics
  SQuery.Close;
  SQuery.sql.Clear;
  SQuery.sql.Add('delete from mechanics where side=' + inttostr(InSide) + '');
  SQuery.ExecSQL;

  i := 1;
  { ��� 3�� �������
    while not Module.OraQuery1.Eof do
    begin
    if i<=CoefficientCount then
    begin
    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('insert into mechanics (heat, timestamp, grade, standard');
    SQuery.SQL.Add(', section , strength_class, yield_point, rupture_strength, side)');
    SQuery.SQL.Add('values ('''+CutChar(Module.OraQuery1.FieldByName('heat').AsString)+''', strftime(''%s'', ''now''),'''+CutChar(Module.OraQuery1.FieldByName('grade').AsString)+'''');
    SQuery.SQL.Add(', '''+CutChar(Module.OraQuery1.FieldByName('standard').AsString)+''', '''+CutChar(Module.OraQuery1.FieldByName('section').AsString)+''', '''+CutChar(Module.OraQuery1.FieldByName('strength_class').AsString)+'''');
    SQuery.SQL.Add(', '''+CutChar(Module.OraQuery1.FieldByName('yield_point').AsString)+'''');
    SQuery.SQL.Add(', '''+CutChar(Module.OraQuery1.FieldByName('rupture_strength').AsString)+''', '''+inttostr(Side)+''')');
    SQuery.ExecSQL;
    end;
    inc(i);
    Module.OraQuery1.Next;
    end;
  }

{  while not FQueryCalculation.Eof do
  begin
    if i <= CoefficientCount then
    begin
      SQuery.Close;
      SQuery.sql.Clear;
      SQuery.sql.Add('insert into mechanics (heat, timestamp, grade, standard');
      SQuery.sql.Add(', section , strength_class, yield_point, rupture_strength, side)');
      SQuery.sql.Add('values (''' + FQueryCalculation.FieldByName('noplav').AsString+'''');
      SQuery.sql.Add(', strftime(''%s'', ''now'')');
      SQuery.sql.Add(', ''NULL''');
      SQuery.sql.Add(', '''+FQueryCalculation.FieldByName('gost').AsString+'''');
      SQuery.sql.Add(', '''+FQueryCalculation.FieldByName('razm1').AsString+'''');
      SQuery.sql.Add(', '''+FQueryCalculation.FieldByName('klass').AsString+'''');
      SQuery.sql.Add(', '''+FQueryCalculation.FieldByName('limtek').AsString+'''');
      SQuery.sql.Add(', '''+FQueryCalculation.FieldByName('limproch').AsString+'''');
      SQuery.sql.Add(', '''+inttostr(InSide)+''')');
      SQuery.ExecSQL;
    end;
    inc(i);
    FQueryCalculation.Next;
  end; }

{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'FQueryCalculation count mechanics -> '+inttostr(FQueryCalculation.AllRowsAffected.Selects));
{$ENDIF}

  while not OraQuery.Eof do
  begin
    if i <= CoefficientCount then
    begin
        if (OraQuery.FieldByName('heat').AsString <> HeatMechanics) or
           (HeatCount <= 3) then
        begin
          if HeatCount = 4 then
            HeatCount := 0;

          HeatMechanics := OraQuery.FieldByName('heat').AsString;
          inc(HeatCount);

          SQuery.Close;
          SQuery.sql.Clear;
          SQuery.sql.Add('insert into mechanics (heat, timestamp, grade, standard');
          SQuery.sql.Add(', section , strength_class, yield_point, rupture_strength, side)');
          SQuery.sql.Add('values (''' + OraQuery.FieldByName('heat').AsString+'''');
          SQuery.sql.Add(', strftime(''%s'', ''now'')');
          SQuery.sql.Add(', ''NULL''');
          SQuery.sql.Add(', '''+OraQuery.FieldByName('standard').AsString+'''');
          SQuery.sql.Add(', '''+OraQuery.FieldByName('section').AsString+'''');
          SQuery.sql.Add(', '''+OraQuery.FieldByName('strength_class').AsString+'''');
          SQuery.sql.Add(', '''+OraQuery.FieldByName('yield_point').AsString+'''');
          SQuery.sql.Add(', '''+OraQuery.FieldByName('rupture_strength').AsString+'''');
          SQuery.sql.Add(', '''+inttostr(InSide)+''')');
          SQuery.ExecSQL;
        end;
    end;
    inc(i);
    OraQuery.Next;
  end;

  // -- heat to works
  SQuery.Close;
  SQuery.sql.Clear;
  SQuery.sql.Add('select distinct heat from mechanics');
  SQuery.sql.Add('where side=' + inttostr(InSide) + '');
  SQuery.Open;

  i := 0;
  while not SQuery.Eof do
  begin
    if i = 0 then
      HeatAll := '''' + SQuery.FieldByName('heat').AsString + ''''
    else
      HeatAll := HeatAll+','+''''+SQuery.FieldByName('heat').AsString+'''';
    inc(i);
    SQuery.Next;
  end;

  // -- report
  CalculatedData(InSide, 'heat_to_work='''+StringReplace(HeatAll, '''', '', [rfReplaceAll])+'''');
  // -- report

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'HeatAll to works -> ' + HeatAll);
{$ENDIF}
  // -- heat to works
  // -- new
  // ����� �������� �� ������� technological_sample
  PQueryData.Close;
  PQueryData.sql.Clear;
  PQueryData.sql.Add('SELECT limit_min, limit_max, type FROM technological_sample');
  PQueryData.sql.Add('where strength_class like '''+StrengthClass+'''');
  PQueryData.sql.Add('and diameter_min >= '+Section+' and diameter_max >= '+Section+'');
  PQueryData.sql.Add('and c_min >= '+c+' and c_max >= '+c+'');
  PQueryData.sql.Add('and mn_min >= '+mn+' and mn_max >= '+mn+'');
  PQueryData.sql.Add('and si_min >= '+si+' and si_max >= '+si+'');
  PQueryData.sql.Add('limit 1');
  PQueryData.Open;

  if PQueryData.FieldByName('limit_min').IsNull then
  begin
    SaveLog('warning' + #9#9 + '������� -> '+ErrorMessagesToCharts(InSide, true));
    SaveLog('warning' + #9#9 + '������������ ������ �� ��������������� ���������� ��� -> '+InHeat);
    exit;
  end;

  LimitRolledProductsMin := PQueryData.FieldByName('limit_min').AsInteger;
  LimitRolledProductsMax := PQueryData.FieldByName('limit_max').AsInteger;
  TypeRolledProducts := PQueryData.FieldByName('type').AsString;

  // -- report
  CalculatedData(InSide, 'limit_rolled_products_min='''+inttostr(LimitRolledProductsMin)+'''');
  CalculatedData(InSide, 'limit_rolled_products_max='''+floattostr(LimitRolledProductsMax)+'''');
  CalculatedData(InSide, 'type_rolled_products='''+TypeRolledProducts+'''');
  // -- report

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'LimitRolledProductsMin -> '+inttostr(LimitRolledProductsMin));
  SaveLog('debug' + #9#9 + 'LimitRolledProductsMax -> '+inttostr(LimitRolledProductsMax));
  SaveLog('debug' + #9#9 + 'TypeRolledProducts -> ' + TypeRolledProducts);
  SaveLog('debug' + #9#9 + 'RolledProducts RecordCount -> '+inttostr(SQuery.RecordCount));
{$ENDIF}

  SQuery.Close;
  SQuery.sql.Clear;
  SQuery.sql.Add('SELECT * FROM mechanics');
  SQuery.sql.Add('where side=' + inttostr(InSide) + '');
  SQuery.Open;

  if SQuery.RecordCount < 1 then
  begin
    SaveLog('warning'+#9#9+'������� -> '+ErrorMessagesToCharts(InSide, true));
    SaveLog('warning'+#9#9+'������������ ������ �� ���. ���������� ��� ������� �� ������� -> '+HeatAll);
    exit;
  end;

  i := 0;
  while not SQuery.Eof do
  begin
    if i = length(MechanicsArray) then
      SetLength(MechanicsArray, i + 1);
    MechanicsArray[i] := SQuery.FieldByName(TypeRolledProducts).AsInteger;
    inc(i);
    SQuery.Next;
  end;

  MechanicsAvg := Mean(MechanicsArray);
  MechanicsStdDev := StdDev(MechanicsArray);
  if TypeRolledProducts = 'yield_point' then
  begin
    MechanicsMin := MechanicsAvg - MechanicsStdDev * CoefficientYieldPointValue;
    MechanicsMax := MechanicsAvg + MechanicsStdDev * CoefficientYieldPointValue;
  end;
  if TypeRolledProducts = 'rupture_strength' then
  begin
    MechanicsMin := MechanicsAvg - MechanicsStdDev *
      CoefficientRuptureStrengthValue;
    MechanicsMax := MechanicsAvg + MechanicsStdDev *
      CoefficientRuptureStrengthValue;
  end;

  MechanicsDiff := MechanicsMax - MechanicsMin;
  CoefficientMin := MechanicsMin - LimitRolledProductsMin;
  CoefficientMax := MechanicsMax - LimitRolledProductsMax;

  // -- report
  CalculatedData(InSide, 'mechanics_avg=''' + floattostr(MechanicsAvg) + '''');
  CalculatedData(InSide, 'mechanics_std_dev=''' + floattostr(MechanicsStdDev) + '''');
  CalculatedData(InSide, 'mechanics_min=''' + floattostr(MechanicsMin) + '''');
  CalculatedData(InSide, 'mechanics_max=''' + floattostr(MechanicsMax) + '''');
  CalculatedData(InSide, 'mechanics_diff=''' + floattostr(MechanicsDiff) + '''');
  CalculatedData(InSide, 'coefficient_min=''' + floattostr(CoefficientMin) + '''');
  CalculatedData(InSide, 'coefficient_max=''' + floattostr(CoefficientMax) + '''');
  // -- report

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'MechanicsAvg -> ' + floattostr(MechanicsAvg));
  SaveLog('debug' + #9#9 + 'MechanicsStdDev -> ' + floattostr(MechanicsStdDev));
  SaveLog('debug' + #9#9 + 'MechanicsMin -> ' + floattostr(MechanicsMin));
  SaveLog('debug' + #9#9 + 'MechanicsMax -> ' + floattostr(MechanicsMax));
  SaveLog('debug' + #9#9 + 'MechanicsDiff -> ' + floattostr(MechanicsDiff));
  SaveLog('debug' + #9#9 + 'CoefficientMin -> ' + floattostr(CoefficientMin));
  SaveLog('debug' + #9#9 + 'CoefficientMax -> ' + floattostr(CoefficientMax));
{$ENDIF}
  { ��� 3�� �������
    //�������� �������� ������ � ������������
    st := TStringList.Create;
    //  st.Text := StringReplace(RolledMelting(HeatAll),'|',#13#10,[rfReplaceAll]);

    for i:=0 to st.Count-1 do
    //  {$IFDEF DEBUG }
  // SaveLog('debug'+#9#9+'Firebird Table Name -> '+st.Strings[i]);
  // {$ENDIF}

  { a := 0;
    for i:=0 to st.Count-1 do
    begin
    Module.pFIBQuery1.Close;
    Module.pFIBQuery1.SQL.Clear;
    Module.pFIBQuery1.SQL.Add('SELECT noplav, cast(TMOUTL as integer) as temp from');
    Module.pFIBQuery1.SQL.Add(''+st.strings[i]+'');
    Module.pFIBQuery1.SQL.Add('where TMOUTL>250');
    Module.pFIBQuery1.ExecQuery;
    Module.pFIBQuery1.Transaction.Commit;

    while not Module.pFIBQuery1.Eof do
    begin
    if a = Length(TempArray) then SetLength(TempArray, a + 1);
    TempArray[a] := Module.pFIBQuery1.FieldByName('temp').AsInteger;
    inc(a);
    Module.pFIBQuery1.Next;
    end;
    end;

    st.Destroy;
  }

  PQueryCalculation.Close;
  PQueryCalculation.sql.Clear;
  PQueryCalculation.sql.Add('select t1.tid, t1.heat, t2.temperature from temperature_current t1');
  PQueryCalculation.sql.Add('LEFT OUTER JOIN');
  PQueryCalculation.sql.Add('temperature_historical t2');
  PQueryCalculation.sql.Add('on t1.tid=t2.tid');
  PQueryCalculation.sql.Add('where t1.heat in ('+HeatAll+')');
//  PQueryCalculation.sql.Add('and t1.strength_class like '''+CutChar(StrengthClass)+'''');
//  PQueryCalculation.SQL.Add('and t1.grade like '''+CutChar(Grade)+'''');
  PQueryCalculation.sql.Add('and t1.section = '+CutChar(Section)+'');
//test comment perameter standard
    PQueryCalculation.sql.Add('and t1.standard like '''+GetDigits(Standard)+'%''');
  PQueryCalculation.sql.Add('and t1.side='+inttostr(InSide)+'');
  Application.ProcessMessages; // ��������� �������� �� �������� ���������
  PQueryCalculation.Open;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'PQueryCalculation.SQL.Text -> ' + PQueryCalculation.sql.Text);
{$ENDIF}

  if PQueryCalculation.RecordCount < 1 then
  begin
    SaveLog('warning'+#9#9+'������� -> '+ErrorMessagesToCharts(InSide, true));
    SaveLog('warning'+#9#9+'������������ ������ �� ����������� ��� ������� �� ������� -> '+HeatAll);
    exit;
  end;

  a := 0;
  while not PQueryCalculation.Eof do
  begin
    if a = length(TempArray) then
      SetLength(TempArray, a + 1);
    TempArray[a] := PQueryCalculation.FieldByName('temperature').AsInteger;
    inc(a);
    PQueryCalculation.Next;
  end;

  FreeAndNil(PQueryCalculation);
  FreeAndNil(PQueryData);

  TempAvg := Mean(TempArray);
  TempStdDev := StdDev(TempArray);
  SetLength(TempArray, 0); // �������� ������ c ������������
  TempMin := TempAvg - TempStdDev;
  TempMax := TempAvg + TempStdDev;
  TempDiff := TempMax - TempMin;
  R := TempDiff / MechanicsDiff;
  AdjustmentMin := Round(CoefficientMin * R);
  AdjustmentMax := Round(CoefficientMax * R);

  // -- report
  CalculatedData(InSide, 'temp_avg=''' + floattostr(TempAvg) + '''');
  CalculatedData(InSide, 'temp_std_dev=''' + floattostr(TempStdDev) + '''');
  CalculatedData(InSide, 'temp_min=''' + floattostr(TempMin) + '''');
  CalculatedData(InSide, 'temp_max=''' + floattostr(TempMax) + '''');
  CalculatedData(InSide, 'temp_diff=''' + floattostr(TempDiff) + '''');
  CalculatedData(InSide, 'r=''' + floattostr(R) + '''');
  CalculatedData(InSide, 'adjustment_min=''' + inttostr(AdjustmentMin) + '''');
  CalculatedData(InSide, 'adjustment_max=''' + inttostr(AdjustmentMax) + '''');
  // -- report

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'TempAvg -> ' + floattostr(TempAvg));
  SaveLog('debug' + #9#9 + 'TempStdDev -> ' + floattostr(TempStdDev));
  SaveLog('debug' + #9#9 + 'TempMin -> ' + floattostr(TempMin));
  SaveLog('debug' + #9#9 + 'TempMax -> ' + floattostr(TempMax));
  SaveLog('debug' + #9#9 + 'TempDiff -> ' + floattostr(TempDiff));
  SaveLog('debug' + #9#9 + 'R -> ' + floattostr(R));
  SaveLog('debug' + #9#9 + 'AdjustmentMin -> ' + inttostr(AdjustmentMin));
  SaveLog('debug' + #9#9 + 'AdjustmentMax -> ' + inttostr(AdjustmentMax));
{$ENDIF}
  if (LimitsM = 0) or (LimitsM <> 1) then
  begin
    if InSide = 0 then
    begin
      // ����������� �������� �� 5 ��������
      LowRedLeft := Round(TempMax + AdjustmentMin) - 5;
      HighRedLeft := Round(TempMin + AdjustmentMax) + 5;
      // -- report
      CalculatedData(InSide, 'low_red=''' + inttostr(LowRedLeft) + '''');
      CalculatedData(InSide, 'high_red=''' + inttostr(HighRedLeft) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'LowRedLeft -> ' + inttostr(LowRedLeft));
      SaveLog('debug' + #9#9 + 'HighRedLeft -> ' + inttostr(HighRedLeft));
{$ENDIF}
    end
    else
    begin
      // ����������� �������� �� 5 ��������
      LowRedRight := Round(TempMax + AdjustmentMin) - 5;
      HighRedRight := Round(TempMin + AdjustmentMax) + 5;
      // -- report
      CalculatedData(InSide, 'low_red=''' + inttostr(LowRedRight) + '''');
      CalculatedData(InSide, 'high_red=''' + inttostr(HighRedRight) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'LowRedRight -> ' + inttostr(LowRedRight));
      SaveLog('debug' + #9#9 + 'HighRedRight -> ' + inttostr(HighRedRight));
{$ENDIF}
    end
  end
  else
  begin
    if InSide = 0 then
    begin
      LowGreenLeft := Round(TempMax + AdjustmentMin);
      HighGreenLeft := Round(TempMin + AdjustmentMax);
      LimitsM := 0;
      // -- report
      CalculatedData(InSide, 'low_green=''' + inttostr(LowGreenLeft) + '''');
      CalculatedData(InSide, 'high_green=''' + inttostr(HighGreenLeft) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'LowGreenLeft -> ' + inttostr(LowGreenLeft));
      SaveLog('debug' + #9#9 + 'HighGreenLeft -> ' + inttostr(HighGreenLeft));
{$ENDIF}
    end
    else
      LowGreenRight := Round(TempMax + AdjustmentMin);
    HighGreenRight := Round(TempMin + AdjustmentMax);
    LimitsM := 0;
    // -- report
    CalculatedData(InSide, 'low_green=''' + inttostr(LowGreenRight) + '''');
    CalculatedData(InSide, 'high_green=''' + inttostr(HighGreenRight) + '''');
    // -- report
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'LowGreenRight -> ' + inttostr(LowGreenRight));
    SaveLog('debug' + #9#9 + 'HighGreenRight -> ' + inttostr(HighGreenRight));
{$ENDIF}
  end;

  inc(LimitsM); // ������ 2�� �������

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'limitsM -> ' + inttostr(LimitsM));
{$ENDIF}
  // ���������� ������ �� ������� ������������� ������
  Result := HeatAll;
end;


function CutChar(InData: string): string;
begin
  InData := Trim(StringReplace(InData, ' ', '%', [rfReplaceAll]));
  InData := StringReplace(InData, '(', '%', [rfReplaceAll]);
  InData := StringReplace(InData, ')', '%', [rfReplaceAll]);
  InData := StringReplace(InData, '/', '%', [rfReplaceAll]);
  InData := StringReplace(InData, '\', '%', [rfReplaceAll]);
  InData := StringReplace(InData, ':', '%', [rfReplaceAll]);
  Result := StringReplace(InData, '-', '%', [rfReplaceAll]);
end;


function RepaceComma(InData: string): string;
begin
  Result := Trim(StringReplace(InData, ',', '.', [rfReplaceAll]));
end;


function ErrorMessagesToCharts(InSide: integer; InError: bool): string;
var
  msg: string;
begin
  if InError then
  begin
    msg := '������������ ������ ��� �������';
    if InSide = 0 then
    begin
      Form1.chart_left_side.SubTitle.Caption := msg;
      Form1.chart_left_side.SubTitle.Font.Color := clRed;
      Form1.chart_left_side.SubTitle.Font.Style := [fsBold];
      Result := '�����';
    end
    else
    begin
      Form1.chart_right_side.SubTitle.Caption := msg;
      Form1.chart_right_side.SubTitle.Font.Color := clRed;
      Form1.chart_right_side.SubTitle.Font.Style := [fsBold];
      Result := '������';
    end;
  end
  else
  begin
    if InSide = 0 then
      Form1.chart_left_side.SubTitle.Clear
    else
      Form1.chart_right_side.SubTitle.Clear;
  end;

end;


function ShowTrayMessage(InTitle, InMessage: AnsiString; InFlag: integer): bool;
begin
  {
    bfNone = 0
    bfInfo = 1
    bfWarning = 2
    bfError = 3
  }

  Form1.TrayIcon.BalloonTitle := InTitle;
  Form1.TrayIcon.BalloonHint := TimeToStr(NOW) + #9 + InMessage;
  Form1.TrayIcon.BalloonFlags := TBalloonFlags(InFlag);
  Form1.TrayIcon.BalloonTimeout := 10;
  Form1.TrayIcon.ShowBalloonHint;
  Form1.TrayIcon.OnBalloonClick := Form1.TrayIconClick;
end;


function TrayAppRun: bool;
begin
  PopupTray := TPopupMenu.Create(nil);
  Form1.TrayIcon.Hint := HeadName;
  Form1.TrayIcon.PopupMenu := PopupTray;
  PopupTray.Items.Add(NewItem('�����', 0, false, true, Form1.TrayPopUpCloseClick, 0, 'close'));
  Form1.TrayIcon.Visible := true;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := false;
  Form1.Hide;
end;


procedure TForm1.TrayPopUpCloseClick(Sender: TObject);
var
  buttonSelected: integer;
begin
  SaveLog('app' + #9#9 + 'close');

  ConfigPostgresSetting(false);
  ConfigOracleSetting(false);

  TrayIcon.Visible := false;
  // ��������� ����������
  TerminateProcess(GetCurrentProcess, 0);
end;


procedure TForm1.TrayIconClick(Sender: TObject);
begin
  if TrayMark then
  begin
    // ShowWindow(Wind, SW_SHOWNOACTIVATE);
    // SetForegroundWindow(Application.MainForm.Handle);
    Form1.show;
    TrayMark := false;
  end
  else
  begin
    // ShowWindow(Application.MainForm.Handle, SW_HIDE);
    // SetForegroundWindow(Application.MainForm.Handle);
    Form1.Hide;
    TrayMark := true;
  end

  // Trayicon1.Visible := False;
  // PopupTray.Items.Delete(0);
end;

function CheckAppRun: bool;
var
  hMutex: THandle;
begin
  // �������� 2 ��������� ���������
  hMutex := CreateMutex(0, true, 'QCRollingMill');
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    Application.Title := HeadName + Version;
    // ������ ����� � ������� ���������
    Application.ShowMainForm := false;
    showmessage('��������� ��������� ��� �������');

    CloseHandle(hMutex);
    TerminateProcess(GetCurrentProcess, 0);
  end;

end;

function ViewClear: bool;
var
  i: integer;
begin

  for i := 0 to Form1.ComponentCount - 1 do
  begin
    if (Form1.Components[i] is TLabel) then
    begin
      if copy(Form1.Components[i].Name, 1, 4) <> 'l_n_' then
        TLabel(Form1.FindComponent(Form1.Components[i].Name)).Caption := '';
    end;
  end;

  LowRedLeft := 0;
  HighRedLeft := 0;
  LowGreenLeft := 0;
  HighGreenLeft := 0;

  LowRedRight := 0;
  HighRedRight := 0;
  LowGreenRight := 0;
  HighGreenRight := 0;

end;

end.
