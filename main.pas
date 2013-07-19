unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.DBChart,
  VCLTee.TeeSpline, SyncObjs, Math, Vcl.Menus, Vcl.ActnPopup, ZAbstractDataset,
  ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset, ZStoredProcedure;

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
    l_n_right_side: TLabel;
    gb_left_side: TGroupBox;
    l_global_left: TLabel;
    l_n_left_side: TLabel;
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
//    procedure TrayPopUpCloseClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
    LastDate: TDateTime = 0;
    CurrentDir: string;
    HeadName: string = '���������� ��������� MC 250-5';
    Version: string = ' v0.0alpha';
    DBFile: string = 'data.sdb';
    LogFile: string = 'app.log';
    PopupTray: TPopupMenu;
    TrayMark: bool = false;
    LowRedLeft, HighRedLeft, LowGreenLeft,
    HighGreenLeft, LowRedRight, HighRedRight, LowGreenRight, HighGreenRight: integer;
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
    function ErrorMessagesToCarts(InSide: integer; InError: bool): string;


implementation

uses
  settings, logging, sql_module, sql, chart, thread_opc, tcp_send_read, thread_main;


{$R *.dfm}





procedure TForm1.FormCreate(Sender: TObject);
begin
  //�������� 1 ���������� ���������
  CheckAppRun;

  Form1.Caption := HeadName+Version;
  //��������� � showmessage
  Application.Title := HeadName+Version;

  //������� ����������
  CurrentDir := GetCurrentDir;

  //������ �� ��������� �����
  Form1.BorderStyle := bsToolWindow;
  Form1.BorderIcons := Form1.BorderIcons - [biMaximize];

  SaveLog('app'+#9#9+'start');

  //������������� ����
  TrayAppRun;

  ViewClear;

  ConfigSettings(true);

  ConfigOPCServer(true);
  ThreadOpc.Start;

  TcpConfig(true);

  ThreadMain.Start;
end;


procedure TForm1.b_testClick(Sender: TObject);
var
  HeatAll: string;
  i, Current: integer;
  t,ot: TDateTime;
begin

  ViewClear;


{ DATE_IN_HIM, NPL, MST, GOST, C, MN, SI, S, CR, B' }
//SqlWriteCemicalAnalysis('2013-07-01|233525|C�3��C|�C�� 3760-2006|0.199|0.92|0.014|0.027|0.022|0.0005');


    //-- for test
{    Heat:= '232371'; //������
    Grade:= '%��3����'; //����� �����
    Section:= '%10%'; //�������
    Standard:= '����%3760%2006'; //��������
    StrengthClass:= '%�500�%'; //���� ���������}
//    Side := 2; //1 ������ - �� ������, 2 ����� - ������, ������� | ��5 0 ���� 1 ������
    //-- for test

//    RolledMelting(1);

//  HeatAll := HeatToString(AggregateHeatTableArray);

//    {$IFDEF DEBUG}
//      SaveLog('debug'+#9#9+'heat='+HeatAll);
//    {$ENDIF}


      try
        SaveLog('info'+#9#9+'start calculation left side');
        HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(0),0);
        CarbonEquivalent(HeatAll,0);
        SaveLog('info'+#9#9+'end calculation left side');
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;

      try
        SaveLog('info'+#9#9+'start calculation right side');
        HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(1),1);
        CarbonEquivalent(HeatAll,1);
        SaveLog('info'+#9#9+'end calculation right side');
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
end;


function GetDigits(InData: string): string;
var
  digits: string;
  i: integer;
begin
  for i:=1 to length(InData) do
  begin
    if not (InData[i] in ['0'..'9']) then
       digits := digits+'%'
    else
       digits := digits+InData[i];
  end;
  Result := digits;
end;


function RolledMelting(InSide: integer): string;
var
  i: integer;
//-- Side - 1 ������ - �� ������, 2 ����� - ������, ������� | ��5 0 ���� 1 ������
  Grade: string; //����� �����
  Section: string; //�������
  Standard: string; //��������
  StrengthClass: string; //���� ���������
  ReturnValue: string;
begin

  i := 0;

  if InSide = 0 then
   begin
      Grade := GradeLeft;
      Section := SectionLeft;
      Standard := StandardLeft;
      StrengthClass := StrengthClassLeft;
   end
  else
   begin
      Grade := GradeRight;
      Section := SectionRight;
      Standard := StandardRight;
      StrengthClass := StrengthClassRight;
   end;

{ ��� 3�� �������
//-- ��������� ���������� ������ �� ������ 125 ��� �������� ������
      Module.pFIBQuery1.Close;
      Module.pFIBQuery1.SQL.Clear;
  if InHeat <> '' then
    Module.pFIBQuery1.SQL.Add('select distinct m.noplav, m.begindt')
  else
//    Module.pFIBQuery1.SQL.Add('select FIRST 125 distinct m.noplav, m.begindt');
    Module.pFIBQuery1.SQL.Add('select FIRST 3 distinct m.noplav, m.begindt');
        Module.pFIBQuery1.SQL.Add(', ''P''||SUBSTRING(extract(year from max(m.begindt)) from cast(CHAR_LENGTH(extract(year from max(m.begindt)))-1 as integer))');
        Module.pFIBQuery1.SQL.Add('||CASE WHEN CHAR_LENGTH(extract(month from max(m.begindt)))=1');
        Module.pFIBQuery1.SQL.Add('then ''0''||extract(month from max(m.begindt)) ELSE extract(month from max(m.begindt))END');
        Module.pFIBQuery1.SQL.Add('||CASE WHEN CHAR_LENGTH(extract(day from max(m.begindt)))=1');
        Module.pFIBQuery1.SQL.Add('then ''0''||extract(day from max(m.begindt)) ELSE extract(day from max(m.begindt))END');
        Module.pFIBQuery1.SQL.Add('||''N''||m.noplav as table_name');
        Module.pFIBQuery1.SQL.Add('from melts m, mechanical mch');
        Module.pFIBQuery1.SQL.Add('where m.noplav=mch.noplav');
        Module.pFIBQuery1.SQL.Add('and CHAR_LENGTH(m.noplav)-1>0');
        //�� ������ ������������, ����� (������), ������ (�� ������) �����
      if Side=2 then
        Module.pFIBQuery1.SQL.Add('AND CAST(CAST(SUBSTRING(mch.nopart from cast(CHAR_LENGTH(mch.nopart)as integer)) AS INTEGER) / 2 AS INTEGER) * 2 = SUBSTRING(mch.nopart from cast(CHAR_LENGTH(mch.nopart)as integer))');
      if Side=1 then
        Module.pFIBQuery1.SQL.Add('AND CAST(CAST(SUBSTRING(mch.nopart from cast(CHAR_LENGTH(mch.nopart)as integer)) AS INTEGER) / 2 AS INTEGER) * 2 <> SUBSTRING(mch.nopart from cast(CHAR_LENGTH(mch.nopart)as integer))');
        //-- 305 = 10 month
        Module.pFIBQuery1.SQL.Add('and m.begindt<=current_date and m.begindt>=current_date-305');
  if InHeat <> '' then
    Module.pFIBQuery1.SQL.Add('and m.noplav in ('+InHeat+')');
        Module.pFIBQuery1.SQL.Add('and m.marka like '''+Grade+''' and m.standart like '''+Standard+'''');
        Module.pFIBQuery1.SQL.Add('and mch.razm1 like '''+Section+''' and mch.KLPROCH like '''+StrengthClass+'''');
        Module.pFIBQuery1.SQL.Add('group by m.noplav, m.begindt');
        Module.pFIBQuery1.SQL.Add('order by m.begindt');
        Module.pFIBQuery1.ExecQuery;
}

  //-- ��������� ���������� ������ �� ������ 125 ��� �������� ������
  Module.pFIBQuery1.Close;
  Module.pFIBQuery1.SQL.Clear;
  Module.pFIBQuery1.SQL.Add('select FIRST 125 noplav, begindt');
  Module.pFIBQuery1.SQL.Add('from melts');
  Module.pFIBQuery1.SQL.Add('where begindt<=current_date and begindt>=current_date-305');
  Module.pFIBQuery1.SQL.Add('and klass like '''+CutChar(StrengthClass)+'%''');
  Module.pFIBQuery1.SQL.Add('and marka like '''+CutChar(Grade)+'%''');
  Module.pFIBQuery1.SQL.Add('and razm1 like '''+CutChar(Section)+'%''');
  Module.pFIBQuery1.SQL.Add('and standart like '''+GetDigits(Standard)+'%''');
  Module.pFIBQuery1.SQL.Add('and side='+inttostr(InSide)+'');
  Module.pFIBQuery1.SQL.Add('order by begindt desc');
  Application.ProcessMessages;//��������� �������� �� �������� ���������
  Module.pFIBQuery1.ExecQuery;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'Module.pFIBQuery1.SQL.Text -> '+Module.pFIBQuery1.SQL.Text);
  {$ENDIF}

  while not Module.pFIBQuery1.Eof do
  begin
    if i=0 then
      ReturnValue := ReturnValue+Module.pFIBQuery1.FieldByName('noplav').AsString
    else
      ReturnValue := ReturnValue+'|'+Module.pFIBQuery1.FieldByName('noplav').AsString;

    inc(i);
    Module.pFIBQuery1.Next;
  end;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'Heat -> '+ReturnValue);
  {$ENDIF}

  Result := ReturnValue;
end;


function CarbonEquivalent(InHeat: string; InSide: integer): bool;
var
  CeMin, CeMax, CeAvg, CeMinP, CeMaxM, CeAvgP, CeAvgM,rangeMin: real;
  i,a,b,c,rangeM: integer;
  CeArray: TArray;//array of array of variant;
  CeMinHeat, CeHeatStringMin, CeHeatStringMax, CeHeatStringAvg: string;
  range: array of variant;
begin

    i:=0;
    a:=0;
    b:=a;
    c:=a;

    CeArray := SqlCarbonEquivalent(InHeat);


    CeMin := CeArray[0,1]; //����� ������ �������� �� �������
    CeMax := CeMin;
    For i:=Low(CeArray) To High(CeArray) Do
     Begin
        If CeArray[i,1]<CeMin Then CeMin:=CeArray[i,1];
        If CeArray[i,1]>CeMax Then CeMax:=CeArray[i,1];
     End;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeMin -> '+floattostr(CeMin));
    SaveLog('debug'+#9#9+'CeMax -> '+floattostr(CeMax));
  {$ENDIF}

    CeAvg := (CeMin+CeMAX)/2;
    CeMinP := CeMin+0.03;
    CeMaxM := CeMax-0.03;
    CeAvgP := CeAvg+0.015;
    CeAvgM := CeAvg-0.015;

    For i:=Low(CeArray) To High(CeArray) Do
     Begin
        If InRange(CeArray[i,1], CeMin, CeMinP) then
         begin
            {$IFDEF DEBUG}
                SaveLog('debug'+#9#9+'CeMinRangeHeat -> '+CeArray[i,0]);
                SaveLog('debug'+#9#9+'CeMinRangeValue -> '+floattostr(CeArray[i,1]));
            {$ENDIF}
            if a = 0 then
               CeHeatStringMin := CeArray[i,0]
            else
               CeHeatStringMin := CeHeatStringMin+'|'+CeArray[i,0];
            inc(a);
         end;

        if InRange(CeArray[i,1], CeMaxM, CeMax) then
         begin
            {$IFDEF DEBUG}
                SaveLog('debug'+#9#9+'CeMaxRangeHeat -> '+CeArray[i,0]);
                SaveLog('debug'+#9#9+'CeMaxRangeValue -> '+floattostr(CeArray[i,1]));
            {$ENDIF}
            if b = 0 then
               CeHeatStringMax := CeArray[i,0]
            else
               CeHeatStringMax := CeHeatStringMax+'|'+CeArray[i,0];
            inc(b);
         end;

        if InRange(CeArray[i,1], CeAvgM, CeAvgP) then
         begin
            {$IFDEF DEBUG}
                SaveLog('debug'+#9#9+'CeAvgRangeHeat -> '+CeArray[i,0]);
                SaveLog('debug'+#9#9+'CeAvgRangeValue -> '+floattostr(CeArray[i,1]));
            {$ENDIF}
            if c = 0 then
               CeHeatStringAvg := CeArray[i,0]
            else
               CeHeatStringAvg := CeHeatStringAvg+'|'+CeArray[i,0];
            inc(c);
         end;
     End;


  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeInHeat -> '+InHeat);
    SaveLog('debug'+#9#9+'CeMin -> '+floattostr(CeMin));
    SaveLog('debug'+#9#9+'CeMax -> '+floattostr(CeMax));
    SaveLog('debug'+#9#9+'CeAvg -> '+floattostr(CeAvg));
    SaveLog('debug'+#9#9+'CeMinP -> '+floattostr(CeMinP));
    SaveLog('debug'+#9#9+'CeMaxM -> '+floattostr(CeMaxM));
    SaveLog('debug'+#9#9+'CeAvgP -> '+floattostr(CeAvgP));
    SaveLog('debug'+#9#9+'CeAvgM -> '+floattostr(CeAvgM));
  {$ENDIF}

  if InSide = 0 then
  begin
    //-- �� �� ������� ������
    CeArray := SqlCarbonEquivalent(''''+HeatLeft+'''');
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CurrentHeatLeft -> '+CeArray[0,0]);
    SaveLog('debug'+#9#9+'CurrentCeLeft -> '+floattostr(CeArray[0,1]));
  {$ENDIF}
  end
  else
  begin
    //-- �� �� ������� ������
    CeArray := SqlCarbonEquivalent(''''+HeatRight+'''');
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CurrentHeatRight -> '+CeArray[0,0]);
    SaveLog('debug'+#9#9+'CurrentCeRight -> '+floattostr(CeArray[0,1]));
  {$ENDIF}
  end;

  //-- ������� ������ � ������� ���������� ��������� min,max,avg
  if InRange(CeArray[0,1], CeMin, CeMinP) and (CeHeatStringMin <> '') then
   begin
      {$IFDEF DEBUG}
        SaveLog('debug'+#9#9+'CurrentCeMinRange -> '+CeArray[0,0]);
        SaveLog('debug'+#9#9+'CurrentCeMinRangeValue -> '+floattostr(CeArray[0,1]));
      {$ENDIF}
   end;

  if InRange(CeArray[0,1], CeMaxM, CeMax) and (CeHeatStringMax <> '') then
   begin
      {$IFDEF DEBUG}
         SaveLog('debug'+#9#9+'CurrentCeMaxRange -> '+CeArray[0,0]);
         SaveLog('debug'+#9#9+'CurrentCeMaxRangeValue -> '+floattostr(CeArray[0,1]));
      {$ENDIF}
   end;

  if InRange(CeArray[0,1], CeAvgM, CeAvgP) and (CeHeatStringAvg <> '') then
   begin
      {$IFDEF DEBUG}
         SaveLog('debug'+#9#9+'CurrentCeAvgRange -> '+CeArray[0,0]);
         SaveLog('debug'+#9#9+'CurrentCeAvgRangeValue -> '+floattostr(CeArray[0,1]));
      {$ENDIF}
   end;

    SetLength(range, 4);
    range[0] := ABS(CeMinP - CeArray[0,1]);
    range[1] := ABS(CeMaxM - CeArray[0,1]);
    range[2] := ABS(CeAvgP - CeArray[0,1]);
    range[3] := ABS(CeAvgM - CeArray[0,1]);

    rangeMin := range[0];

    for i:=low(range) To high(range) Do
     begin
        If range[i]<rangeMin Then rangeMin:=range[i];
     end;

    for i:=low(range) To high(range) Do
     begin
        If range[i]=rangeMin Then
         begin
          if (i=0) and (CeHeatStringMin <> '') then
            begin
                if InSide = 0 then
                begin
                  CalculatingInMechanicalCharacteristics(CeHeatStringMin,0);
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeMinRangeHeatLeft -> '+CeHeatStringMin);
  {$ENDIF}
                end
                else
                begin
                  CalculatingInMechanicalCharacteristics(CeHeatStringMin,1);
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeMinRangeHeatRight -> '+CeHeatStringMin);
  {$ENDIF}
                end;
            end;
          if (i=3) and (CeHeatStringMax <> '') then
            begin
                if InSide = 0 then
                begin
                  CalculatingInMechanicalCharacteristics(CeHeatStringMax,0);
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeMaxRangeHeatLeft -> '+CeHeatStringMax);
  {$ENDIF}
                end
                else
                begin
                  CalculatingInMechanicalCharacteristics(CeHeatStringMax,1);
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeMaxRangeHeatRight -> '+CeHeatStringMax);
  {$ENDIF}
                end;
            end;
          if ((i=1) or (i=2)) and (CeHeatStringAvg <> '') then
            begin
                if InSide = 0 then
                begin
                  CalculatingInMechanicalCharacteristics(CeHeatStringAvg,0);
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeAvgRangeHeatLeft -> '+CeHeatStringAvg);
  {$ENDIF}
                end
                else
                begin
                  CalculatingInMechanicalCharacteristics(CeHeatStringAvg,1);
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeAvgRangeHeatRight -> '+CeHeatStringAvg);
  {$ENDIF}
                end;
            end;
         end;
     end;


  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CeRangeMinValue -> '+floattostr(rangeMin));
    SaveLog('debug'+#9#9+'rangeM -> '+floattostr(rangeM));
  {$ENDIF}

end;


function HeatToIn(InHeat: string): string;
var
  i: integer;
  AllHeat: string;
  st: TStringList;
begin
    st := TStringList.Create;
    st.Text := StringReplace(InHeat,'|',#13#10,[rfReplaceAll]);

    for i:=0 to st.Count-1 do
     begin
       if i <> st.Count-1 then
         st.Strings[i] := ''''+st.Strings[i]+''''+','
       else
         st.Strings[i] := ''''+st.Strings[i]+'''';

       AllHeat := AllHeat+''+st.Strings[i]+'';
     end;
    st.Free;
    Result := AllHeat;
end;


function CalculatingInMechanicalCharacteristics(InHeat: string; InSide: integer): string;
var
  Grade: string; //����� �����
  Section: string; //�������
  Standard: string; //��������
  StrengthClass: string; //���� ���������
  ReturnValue: string;
//  SCalcQuery: TZQuery;

  i, a, b, CoefficientCount, AdjustmentMin, AdjustmentMax, YieldPointTableMin,
  YieldPointTableMax: integer;
  m: bool;
  CoefficientValue, YieldPointAvg, YieldPointStdDev, YieldPointMin,
  YieldPointMax, YieldPointDiff, CoefficientMin, CoefficientMax,
  TempAvg, TempStdDev, TempMin, TempMax, TempDiff, R: real;
  HeatAll, HeatWorks, HeatTableAll: WideString;
  section_tmp: string;
  HeatArray, HeatTableArray: Array of string;
  YieldPointArray, TempArray: Array of Double;
  st, HeatTmp: TStringList;
begin
  // sql query for calculation
{  SCalcQuery := TZQuery.Create(nil);
  try
        SCalcQuery.Connection := SConnect;
  except
      on E : Exception do
        SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
}
  a := 0;
  b := a;

  if InSide = 0 then
   begin
      Grade := GradeLeft;
      Section := SectionLeft;
      Standard := StandardLeft;
      StrengthClass := StrengthClassLeft;
   end
  else
   begin
      Grade := GradeRight;
      Section := SectionRight;
      Standard := StandardRight;
      StrengthClass := StrengthClassRight;
   end;

  HeatAll := HeatToIn(InHeat);

{ ��� 3�� �������
    Application.ProcessMessages;//��������� �������� �� �������� ���������

    Module.OraQuery1.FetchAll := true;
    Module.OraQuery1.Close;
    Module.OraQuery1.SQL.Clear;
    Module.OraQuery1.SQL.Add('select n.nplav heat, n.mst grade, n.GOST standard');
    Module.OraQuery1.SQL.Add(',n.razm1 section, n.klass strength_class');
    Module.OraQuery1.SQL.Add(',v.limtek yield_point, v.limproch rupture_strength');
    Module.OraQuery1.SQL.Add('from czl_v v, czl_n n');
    //-- 305 = 10 month
    Module.OraQuery1.SQL.Add('where n.data<=sysdate and n.data>=sysdate-305');
    Module.OraQuery1.SQL.Add('and n.mst like translate('''+Grade+''','); //��������� Eng ����� ������� �� ��������
    Module.OraQuery1.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
    Module.OraQuery1.SQL.Add('and n.GOST like translate('''+Standard+''','); //��������� Eng ����� ������� �� ��������
    Module.OraQuery1.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
    Module.OraQuery1.SQL.Add('and n.razm1 like '''+Section+'''');
    Module.OraQuery1.SQL.Add('and n.klass like translate('''+StrengthClass+''','); //��������� Eng ����� ������� �� ��������
    Module.OraQuery1.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
    Module.OraQuery1.SQL.Add('and n.data=v.data and v.npart=n.npart');
    Module.OraQuery1.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
    Module.OraQuery1.SQL.Add('and prizn=''*'' and ROWNUM <= 251');
    Module.OraQuery1.SQL.Add('and n.nplav in('+HeatAll+')');
    Module.OraQuery1.SQL.Add('order by n.data desc');
    Module.OraQuery1.Open;

//  {$IFDEF DEBUG}
//    SaveLog('debug'+#9#9+'OraQuery1.SQL.Text -> '+Module.OraQuery1.SQL.Text);
//  {$ENDIF}

  Module.pFIBQuery1.Close;
  Module.pFIBQuery1.SQL.Clear;
  Module.pFIBQuery1.SQL.Add('select FIRST 251 noplav, begindt, gost, razm1, klass, limtek, limproch');
  Module.pFIBQuery1.SQL.Add('from mechanical');
  Module.pFIBQuery1.SQL.Add('where begindt<=current_date and begindt>=current_date-305');
  Module.pFIBQuery1.SQL.Add('and klass like '''+CutChar(StrengthClass)+'%''');
//  Module.pFIBQuery1.SQL.Add('and marka like '''+CutChar(Grade)+'%''');
  Module.pFIBQuery1.SQL.Add('and razm1 like '''+CutChar(Section)+'%''');
  Module.pFIBQuery1.SQL.Add('and gost like '''+GetDigits(Standard)+'%''');
  Module.pFIBQuery1.SQL.Add('and side='+inttostr(InSide)+'');
  Module.pFIBQuery1.SQL.Add('and noplav in ('+HeatAll+')');
  Module.pFIBQuery1.SQL.Add('order by begindt desc');
  Application.ProcessMessages;//��������� �������� �� �������� ���������
  Module.pFIBQuery1.ExecQuery;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'pFIBQuery1.SQL.Text -> '+Module.pFIBQuery1.SQL.Text);
    SaveLog('debug'+#9#9+'pFIBQuery1.AllRowsAffected -> '+inttostr(Module.pFIBQuery1.AllRowsAffected.Selects));
  {$ENDIF}

  if Module.pFIBQuery1.AllRowsAffected.Selects < 5 then
  begin
    SaveLog('warning'+#9#9+'������� -> '+ErrorMessagesToCarts(InSide, true));
    SaveLog('warning'+#9#9+'������������ ������ ��� ������� �� ������� -> '+HeatAll);
    exit;
  end;


//-- new
  SQuery.Close;
  SQuery.SQL.Clear;
  //Settings.SQuery.SQL.Add('SELECT max(id), n, k FROM coefficient_yield_point where n<='+inttostr(Module.OraQuery1.RecordCount)+'');
  SQuery.SQL.Add('SELECT max(id), n, k FROM coefficient_yield_point where n<='+inttostr(Module.pFIBQuery1.AllRowsAffected.Selects)+'');
  SQuery.Open;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'SQuery.SQL.Text -> '+SQuery.SQL.Text);
  {$ENDIF}

  CoefficientCount := SQuery.FieldByName('n').AsInteger;
  CoefficientValue := SQuery.FieldByName('k').AsFloat;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CoefficientCount -> '+inttostr(CoefficientCount));
    SaveLog('debug'+#9#9+'CoefficientValue -> '+floattostr(CoefficientValue));
    SaveLog('debug'+#9#9+'SQuery.RecordCount -> '+inttostr(SQuery.RecordCount));
  {$ENDIF}

  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS mechanics');
  SQuery.SQL.Add('(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
  SQuery.SQL.Add(', heat VARCHAR(26),timestamp INTEGER(10), grade VARCHAR(16)');
  SQuery.SQL.Add(', standard VARCHAR(16), section VARCHAR(16)');
  SQuery.SQL.Add(', strength_class VARCHAR(16), yield_point NUMERIC(10,6)');
  SQuery.SQL.Add(', rupture_strength NUMERIC(10,6), side NUMERIC(1,1) NOT NULL)');
  SQuery.ExecSQL;

  //-- clean table mechanics
  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('delete from mechanics where side='+inttostr(InSide)+'');
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
  while not Module.pFIBQuery1.Eof do
   begin
    if i<=CoefficientCount then
     begin
        SQuery.Close;
        SQuery.SQL.Clear;
        SQuery.SQL.Add('insert into mechanics (heat, timestamp, grade, standard');
        SQuery.SQL.Add(', section , strength_class, yield_point, rupture_strength, side)');
        SQuery.SQL.Add('values ('''+Module.pFIBQuery1.FieldByName('noplav').AsString+'''');
        SQuery.SQL.Add(', strftime(''%s'', ''now'')');
        SQuery.SQL.Add(', ''NULL''');
        SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('gost').AsString+'''');
        SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('razm1').AsString+'''');
        SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('klass').AsString+'''');
        SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('limtek').AsString+'''');
        SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('limproch').AsString+'''');
        SQuery.SQL.Add(', '''+inttostr(InSide)+''')');
        SQuery.ExecSQL;
     end;
    inc(i);
    Module.pFIBQuery1.Next;
   end;

  //-- heat to works
  SQuery.Close;
  SQuery.SQL.Clear;
//  SQuery.SQL.Add('select group_concat(''''''''||heat||'''''''', '','' ) heat from (select distinct heat from mechanics) heat');
  SQuery.SQL.Add('select distinct heat from mechanics');
  SQuery.Open;

//  HeatAll := SQuery.FieldByName('heat').AsString;

  i:=0;
  while not SQuery.Eof do
  begin
    if i=0 then
      HeatAll := ''''+SQuery.FieldByName('heat').AsString+''''
    else
      HeatAll := HeatAll+','+''''+SQuery.FieldByName('heat').AsString+'''';
    inc(i);
    SQuery.Next;
  end;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'HeatAll to works -> '+HeatAll);
  {$ENDIF}

  //-- heat to works
  SQuery.Close;
  SQuery.SQL.Clear;
//  SQuery.SQL.Add('SELECT max(id), n, k FROM coefficient_yield_point where n<='+inttostr(Module.OraQuery1.RecordCount)+'');
  SQuery.SQL.Add('SELECT max(id), n, k FROM coefficient_yield_point where n<='+inttostr(Module.pFIBQuery1.AllRowsAffected.Selects)+'');
  SQuery.Open;

//-- new

  //����� �������� �� ������� rolled_products
//  st := TStringList.Create;
//  st.Text := StringReplace(Standard,'%',#13#10,[rfReplaceAll]);
//  Section_tmp := inttostr(strtoint(StringReplace(Section,'%','',[rfReplaceAll]))+15);//15 ��� �����, �� ������ ������

  SQuery.Close;
  SQuery.SQL.Clear;
//  SQuery.SQL.Add('SELECT yield_point_min, yield_point_max FROM rolled_products where standard like '''+st.Strings[0]+'%'+st.Strings[1]+'''');
  SQuery.SQL.Add('SELECT yield_point_min, yield_point_max FROM rolled_products');
  SQuery.SQL.Add('where standard like '''+GetDigits(Standard)+'%''');
  SQuery.SQL.Add('and strength_class like '''+StrengthClass+'%''');
//  SQuery.SQL.Add('and diameter_min >= '+Section_tmp+' and diameter_max >= '+Section_tmp+'');
  SQuery.SQL.Add('and diameter_min >= '+Section+' and diameter_max >= '+Section+'');
  SQuery.Open;

//  st.Destroy;

  YieldPointTableMin := SQuery.FieldByName('yield_point_min').AsInteger;
  YieldPointTableMax := SQuery.FieldByName('yield_point_max').AsInteger;

  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT * FROM mechanics');
  SQuery.Open;

  i := 0;
  while not SQuery.Eof do
   begin
    if i = Length(YieldPointArray) then SetLength(YieldPointArray, i+1);
    YieldPointArray[i] := SQuery.FieldByName('yield_point').AsInteger;
    inc(i);
    SQuery.Next;
   end;

  YieldPointAvg := Mean(YieldPointArray);
  YieldPointStdDev := StdDev(YieldPointArray);
  YieldPointMin := YieldPointAvg-YieldPointStdDev*CoefficientValue;
  YieldPointMax := YieldPointAvg+YieldPointStdDev*CoefficientValue;
  YieldPointDiff := YieldPointMax-YieldPointMin;
  CoefficientMin := YieldPointMin-YieldPointTableMin;
  CoefficientMax := YieldPointMax-YieldPointTableMax;


  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'YieldPointAvg -> '+floattostr(YieldPointAvg));
    SaveLog('debug'+#9#9+'YieldPointStdDev -> '+floattostr(YieldPointStdDev));
    SaveLog('debug'+#9#9+'YieldPointMin -> '+floattostr(YieldPointMin));
    SaveLog('debug'+#9#9+'YieldPointMax -> '+floattostr(YieldPointMax));
    SaveLog('debug'+#9#9+'YieldPointDiff -> '+floattostr(YieldPointDiff));
    SaveLog('debug'+#9#9+'CoefficientMin -> '+floattostr(CoefficientMin));
    SaveLog('debug'+#9#9+'CoefficientMax -> '+floattostr(CoefficientMax));
  {$ENDIF}

{ ��� 3�� �������
  //�������� �������� ������ � ������������
  st := TStringList.Create;
//  st.Text := StringReplace(RolledMelting(HeatAll),'|',#13#10,[rfReplaceAll]);

  for i:=0 to st.Count-1 do
//  {$IFDEF DEBUG}
//    SaveLog('debug'+#9#9+'Firebird Table Name -> '+st.Strings[i]);
//  {$ENDIF}

{  a := 0;
  for i:=0 to st.Count-1 do
   begin
      Module.pFIBQuery1.Close;
      Module.pFIBQuery1.SQL.Clear;
      Module.pFIBQuery1.SQL.Add('SELECT noplav, cast(TMOUTL as integer) as temp from');
      Module.pFIBQuery1.SQL.Add(''+st.strings[i]+'');
      Module.pFIBQuery1.SQL.Add('where TMOUTL>250');
      Module.pFIBQuery1.ExecQuery;

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


  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT heat, temperature from temperature');
  SQuery.SQL.Add('where heat in ('+HeatAll+')');
//  SQuery.SQL.Add('and grade like '''+Grade+'''');
//  SQuery.SQL.Add('and strength_class like '''+StrengthClass+'''');
  SQuery.SQL.Add('and standard like '''+GetDigits(Standard)+'''');
  SQuery.SQL.Add('and section like '''+Section+'''');
  SQuery.SQL.Add('and side='+inttostr(InSide)+'');
  SQuery.Open;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'SQuery.SQL.Text -> '+SQuery.SQL.Text);
  {$ENDIF}

  if SQuery.RecordCount < 1 then
  begin
    SaveLog('warning'+#9#9+'������� -> '+ErrorMessagesToCarts(InSide, true));
    SaveLog('warning'+#9#9+'������������ ������ ��� ������� �� ������� -> '+HeatAll);
    exit;
  end;

  a := 0;
  while not SQuery.Eof do
  begin
    if a = Length(TempArray) then SetLength(TempArray, a + 1);
    TempArray[a] := SQuery.FieldByName('temperature').AsInteger;
    inc(a);
    SQuery.Next;
  end;

  TempAvg := Mean(TempArray);
  TempStdDev := StdDev(TempArray);
  SetLength(TempArray,0);//�������� ������ c ������������
  TempMin := TempAvg - TempStdDev;
  TempMax := TempAvg + TempStdDev;
  TempDiff := TempMax - TempMin;
  R := TempDiff / YieldPointDiff;
  AdjustmentMin := Round(CoefficientMin * R);
  AdjustmentMax := Round(CoefficientMax * R);

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'TempAvg -> '+floattostr(TempAvg));
    SaveLog('debug'+#9#9+'TempStdDev -> '+floattostr(TempStdDev));
    SaveLog('debug'+#9#9+'TempMin -> '+floattostr(TempMin));
    SaveLog('debug'+#9#9+'TempMax -> '+floattostr(TempMax));
    SaveLog('debug'+#9#9+'TempDiff -> '+floattostr(TempDiff));
    SaveLog('debug'+#9#9+'R -> '+floattostr(R));
    SaveLog('debug'+#9#9+'AdjustmentMin -> '+inttostr(AdjustmentMin));
    SaveLog('debug'+#9#9+'AdjustmentMax -> '+inttostr(adjustmentMax));
  {$ENDIF}

  if (limitsM = 0) or (limitsM <> 1) then
  begin
      if InSide = 0 then
      begin
          //����������� �������� �� 5 ��������
          LowRedLeft := Round(TempMax+AdjustmentMin)-5;
          HighRedLeft := Round(TempMin+AdjustmentMax)+5;
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'LowRedLeft -> '+inttostr(LowRedLeft));
    SaveLog('debug'+#9#9+'HighRedLeft -> '+inttostr(HighRedLeft));
  {$ENDIF}
      end
      else
      begin
          //����������� �������� �� 5 ��������
          LowRedRight := Round(TempMax+AdjustmentMin)-5;
          HighRedRight := Round(TempMin+AdjustmentMax)+5;
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'LowRedRight -> '+inttostr(LowRedRight));
    SaveLog('debug'+#9#9+'HighRedRight -> '+inttostr(HighRedRight));
  {$ENDIF}
      end
  end
  else
  begin
      if InSide = 0 then
      begin
          LowGreenLeft := Round(TempMax+AdjustmentMin);
          HighGreenLeft := Round(TempMin+AdjustmentMax);
          limitsM := 0;
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'LowGreenLeft -> '+inttostr(LowGreenLeft));
    SaveLog('debug'+#9#9+'HighGreenLeft -> '+inttostr(HighGreenLeft));
  {$ENDIF}
      end
      else
          LowGreenRight := Round(TempMax+AdjustmentMin);
          HighGreenRight := Round(TempMin+AdjustmentMax);
          limitsM := 0;
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'LowGreenRight -> '+inttostr(LowGreenRight));
    SaveLog('debug'+#9#9+'HighGreenRight -> '+inttostr(HighGreenRight));
  {$ENDIF}
  end;

  inc(limitsM); //������ 2�� �������

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'limitsM -> '+inttostr(limitsM));
  {$ENDIF}

   //���������� ������ �� ������� ������������� ������
   Result := HeatAll;
end;


function CutChar(InData: string): string;
begin
  InData := Trim(StringReplace(InData,' ','%',[rfReplaceAll]));
  InData := StringReplace(InData,'(','%',[rfReplaceAll]);
  InData := StringReplace(InData,')','%',[rfReplaceAll]);
  InData := StringReplace(InData,'/','%',[rfReplaceAll]);
  InData := StringReplace(InData,'\','%',[rfReplaceAll]);
  InData := StringReplace(InData,':','%',[rfReplaceAll]);
  result := StringReplace(InData,'-','%',[rfReplaceAll]);
end;


function ErrorMessagesToCarts(InSide: integer; InError: bool): string;
var
  msg: string;
begin
    if InError then
    begin
        msg := '������������ ������ ��� �������';
        if InSide = 0 then
        begin
          form1.chart_left_side.SubTitle.Caption := msg;
          form1.chart_left_side.SubTitle.Font.Color := clRed;
          form1.chart_left_side.SubTitle.Font.Style := [fsBold];
          Result := '�����';
        end
        else
        begin
          form1.chart_right_side.SubTitle.Caption := msg;
          form1.chart_right_side.SubTitle.Font.Color := clRed;
          form1.chart_right_side.SubTitle.Font.Style := [fsBold];
          Result := '������';
        end;
    end
    else
    begin
        if Side = 0 then
          form1.chart_left_side.SubTitle.Clear
        else
          form1.chart_right_side.SubTitle.Clear;
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

  form1.TrayIcon.BalloonTitle := InTitle;
  form1.TrayIcon.BalloonHint := TimeToStr(NOW)+#9+InMessage;
  form1.TrayIcon.BalloonFlags := TBalloonFlags(InFlag);
  form1.TrayIcon.BalloonTimeout := 10;
  form1.TrayIcon.ShowBalloonHint;
  form1.TrayIcon.OnBalloonClick := form1.TrayIconClick;
end;


function TrayAppRun: bool;
begin
    PopupTray := TPopupMenu.Create(nil);
    Form1.Trayicon.Hint := HeadName;
    Form1.Trayicon.PopupMenu := PopupTray;
    PopupTray.Items.Add(NewItem('�����', 0, False, True, Form1.TrayPopUpCloseClick, 0, 'close'));
    Form1.Trayicon.Visible := True;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := False;
    Form1.Hide;
end;


procedure TForm1.TrayPopUpCloseClick(Sender: TObject);
var
  buttonSelected: Integer;
begin
  //��������� OPC
  ConfigOPCServer(false);

  TcpConfig(false);

  SaveLog('app'+#9#9+'close');

  Trayicon.Visible := false;
  //��������� ����������
  TerminateProcess(GetCurrentProcess, 0);
end;


procedure TForm1.TrayIconClick(Sender: TObject);
begin
    if TrayMark then
     begin
//        ShowWindow(Wind, SW_SHOWNOACTIVATE);
//        SetForegroundWindow(Application.MainForm.Handle);
        form1.show;
        TrayMark := false;
     end
    else
     begin
//        ShowWindow(Application.MainForm.Handle, SW_HIDE);
//        SetForegroundWindow(Application.MainForm.Handle);
        form1.hide;
        TrayMark := true;
     end

//    Trayicon1.Visible := False;
//    PopupTray.Items.Delete(0);
end;


function CheckAppRun: bool;
var
  hMutex : THandle;
begin
    // �������� 2 ��������� ���������
    hMutex := CreateMutex(0, true , 'QCRollingMill');
    if GetLastError = ERROR_ALREADY_EXISTS then
     begin
        Application.Title := HeadName+Version;
        //������ ����� � ������� ���������
        Application.ShowMainForm:=false;
        showmessage('��������� ��������� ��� �������');

        CloseHandle(hMutex);
        TerminateProcess(GetCurrentProcess, 0);
     end;

end;


function ViewClear: bool;
var
  i: integer;
begin

  for i:=0 to form1.ComponentCount - 1 do
   begin
    if (form1.Components[i] is Tlabel) then
      begin
        if copy(form1.Components[i].Name,1,4) <> 'l_n_' then
          Tlabel(Form1.FindComponent(form1.Components[i].Name)).Caption := '';
      end;
   end;

  LowRedLeft := 0;
  HighRedLeft := 0;
  LowGreenLeft:= 0;
  HighGreenLeft := 0;

  LowRedRight := 0;
  HighRedRight := 0;
  LowGreenRight := 0;
  HighGreenRight := 0;

end;




end.
