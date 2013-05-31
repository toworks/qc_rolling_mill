unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.DBChart,
  VCLTee.TeeSpline, SyncObjs, Math;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Chart1: TChart;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Series3: TLineSeries;
    Series4: TLineSeries;
    Series5: TLineSeries;
    l_n_carbon: TLabel;
    gb_chemical_analysis: TGroupBox;
    l_carbon: TLabel;
    l_n_manganese: TLabel;
    l_manganese: TLabel;
    l_n_silicium: TLabel;
    l_silicium: TLabel;
    l_n_chromium: TLabel;
    l_chromium: TLabel;
    gb_general_data: TGroupBox;
    l_n_heat: TLabel;
    l_heat: TLabel;
    l_n_grade: TLabel;
    l_grade: TLabel;
    l_n_c_equivalent: TLabel;
    l_c_equivalent: TLabel;
    l_n_temp: TLabel;
    l_temp: TLabel;
    Edit1: TEdit;
    l_n_section: TLabel;
    l_section: TLabel;
    l_n_standard: TLabel;
    l_standard: TLabel;
    l_n_strength_class: TLabel;
    l_strength_class: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
    LastDate: TDateTime = 0;
    CurrentDir: string;
    HeadName: string = '���������� ��������� MC 250-5';
    Version: string = '0.0alpha';
    DBFile: string = 'data.sdb';
    LogFile: string = 'app.log';
    m_chart: bool = false;
    i: integer = 0;
    //global
    Heat: string = ''; //������
    Grade: string = ''; //����� �����
    Section: string = ''; //�������
    Standard: string = ''; //��������
    StrengthClass: string = ''; //���� ���������
    Side: integer = 0; //������� 2 ����� - ������, 1 ������ - �� ������
    Temp: string = '';
    Ce: string = '';
    LowRed, HighRed, LowGreen, HighGreen: integer;
    limitsM: integer = 0;


type
    TArray = array of array of variant;
    THeatArray = array of array of variant;

    {$DEFINE DEBUG}

    function RolledMelting(InHeat: string): string;
    function CarbonEquivalent(InHeat: string): bool;
    function HeatToIn(InHeat: string): string;
//    function SqlCarbonEquivalent(InHeat: string): array of array of variant;
    function SqlCarbonEquivalent(InHeat: string): TArray;//array of array of variant;
    function CalculatingInMechanicalCharacteristics(InHeat: string): string;
    function CurrentHeat: bool;



implementation

uses
  sql_module, thread_chart, thread_sql, thread_sql_chemistry, chart, logging,
  settings;


{$R *.dfm}





procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.Caption := HeadName+' '+Version;;
  //��������� � showmessage
  Application.Title := HeadName+' '+Version;;

  //������� ����������
  CurrentDir := GetCurrentDir;

  SaveLog('start'+#9#9+'app');

  Form1.Chart1.Title.Caption := HeadName;

  ViewClear;

  LowRed := 0;
  HighRed := LowRed;
  LowGreen := LowRed;
  HighGreen := LowRed;

  ThreadChartInit;
//  ThreadSqlInit;
//  ThreadSqlChemistryInit;

end;



procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveLog('close'+#9#9+'app');
end;


procedure TForm1.Button1Click(Sender: TObject);
var
  HeatAll: string;
begin

    //-- for test
{    Heat:= '232371'; //������
    Grade:= '%��3����'; //����� �����
    Section:= '%10%'; //�������
    Standard:= '����%3760%2006'; //��������
    StrengthClass:= '%�500�%'; //���� ���������}
    Side := 2; //������� 2 ����� - ������, 1 ������ - �� ������
    //-- for test



//    RolledMelting('');
//  HeatAll := HeatToString(AggregateHeatTableArray);

//    {$IFDEF DEBUG}
//      SaveLog('debug'+#9#9+'heat='+HeatAll);
//    {$ENDIF}

  HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(''));

  CarbonEquivalent(HeatAll);

end;


function RolledMelting(InHeat: string): string;
var
  i: integer;
  ReturnValue: string;
begin

    i := 0;

    Application.ProcessMessages;//��������� �������� �� �������� ���������

//-- ��������� ���������� ������ �� ������ 125 ��� �������� ������
      DataModule1.pFIBQuery1.Close;
      DataModule1.pFIBQuery1.SQL.Clear;
  if InHeat <> '' then
    DataModule1.pFIBQuery1.SQL.Add('select distinct m.noplav, m.begindt')
  else
//    DataModule1.pFIBQuery1.SQL.Add('select FIRST 125 distinct m.noplav, m.begindt');
    DataModule1.pFIBQuery1.SQL.Add('select FIRST 3 distinct m.noplav, m.begindt');
        DataModule1.pFIBQuery1.SQL.Add(', ''P''||SUBSTRING(extract(year from max(m.begindt)) from cast(CHAR_LENGTH(extract(year from max(m.begindt)))-1 as integer))');
        DataModule1.pFIBQuery1.SQL.Add('||CASE WHEN CHAR_LENGTH(extract(month from max(m.begindt)))=1');
        DataModule1.pFIBQuery1.SQL.Add('then ''0''||extract(month from max(m.begindt)) ELSE extract(month from max(m.begindt))END');
        DataModule1.pFIBQuery1.SQL.Add('||CASE WHEN CHAR_LENGTH(extract(day from max(m.begindt)))=1');
        DataModule1.pFIBQuery1.SQL.Add('then ''0''||extract(day from max(m.begindt)) ELSE extract(day from max(m.begindt))END');
        DataModule1.pFIBQuery1.SQL.Add('||''N''||m.noplav as table_name');
        DataModule1.pFIBQuery1.SQL.Add('from melts m, mechanical mch');
        DataModule1.pFIBQuery1.SQL.Add('where m.noplav=mch.noplav');
        DataModule1.pFIBQuery1.SQL.Add('and CHAR_LENGTH(m.noplav)-1>0');
      if Side=2 then
        DataModule1.pFIBQuery1.SQL.Add('AND CAST(CAST(SUBSTRING(m.noplav from cast(CHAR_LENGTH(m.noplav)as integer)) AS INTEGER) / 2 AS INTEGER) * 2 = SUBSTRING(m.noplav from cast(CHAR_LENGTH(m.noplav)as integer))');
      if Side=1 then
        DataModule1.pFIBQuery1.SQL.Add('AND CAST(CAST(SUBSTRING(m.noplav from cast(CHAR_LENGTH(m.noplav)as integer)) AS INTEGER) / 2 AS INTEGER) * 2 <> SUBSTRING(m.noplav from cast(CHAR_LENGTH(m.noplav)as integer))');
        //-- 305 = 10 month
        DataModule1.pFIBQuery1.SQL.Add('and m.begindt<=current_date and m.begindt>=current_date-305');
  if InHeat <> '' then
    DataModule1.pFIBQuery1.SQL.Add('and m.noplav in ('+InHeat+')');
        DataModule1.pFIBQuery1.SQL.Add('and m.marka like '''+Grade+''' and m.standart like '''+Standard+'''');
        DataModule1.pFIBQuery1.SQL.Add('and mch.razm1 like '''+Section+''' and mch.KLPROCH like '''+StrengthClass+'''');
        DataModule1.pFIBQuery1.SQL.Add('group by m.noplav, m.begindt');
        DataModule1.pFIBQuery1.SQL.Add('order by m.begindt');
        DataModule1.pFIBQuery1.ExecQuery;

    while not DataModule1.pFIBQuery1.Eof do
     begin
      if i=0 then
       begin
          if InHeat = '' then
            ReturnValue := ReturnValue+DataModule1.pFIBQuery1.FieldByName('noplav').AsString
          else
            ReturnValue := ReturnValue+DataModule1.pFIBQuery1.FieldByName('table_name').AsString
       end
      else
       begin
          if InHeat = '' then
            ReturnValue := ReturnValue+'|'+DataModule1.pFIBQuery1.FieldByName('noplav').AsString
          else
            ReturnValue := ReturnValue+'|'+DataModule1.pFIBQuery1.FieldByName('table_name').AsString
       end;
      inc(i);
      DataModule1.pFIBQuery1.Next;
     end;
//-- ��������� ���������� ������ �� ������ 125 ��� �������� ������
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'Heat -> '+ReturnValue);
  {$ENDIF}
   Result := ReturnValue;
end;


function CarbonEquivalent(InHeat: string): bool;
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
    CeMinP := CeMin+((CeMin*0.03)/100);
    CeMaxM := CeMax-((CeMax*0.03)/100);
    CeAvgP := CeAvg+((CeAvg*0.015)/100);
    CeAvgM := CeAvg-((CeAvg*0.015)/100);

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

    //-- �� �� ������� ������
    CeArray := SqlCarbonEquivalent(''''+Heat+'''');
  {$IFDEF DEBUG}
     SaveLog('debug'+#9#9+'CurrentHeat -> '+CeArray[0,0]);
     SaveLog('debug'+#9#9+'CurrentCe -> '+floattostr(CeArray[0,1]));
  {$ENDIF}

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

{    for i:=low(range) To high(range) Do
     begin
        If range[i]=rangeMin Then
         begin
          if (i=0) and (CeHeatStringMin <> '') then
            begin
 }             CalculatingInMechanicalCharacteristics(CeHeatStringMin);
              {$IFDEF DEBUG}
                SaveLog('debug'+#9#9+'CeMinRangeHeat -> '+CeHeatStringMin);
              {$ENDIF}
{            end;
          if (i=3) and (CeHeatStringMax <> '') then
            begin
              CalculatingInMechanicalCharacteristics(CeHeatStringMax);
              {$IFDEF DEBUG}
//                SaveLog('debug'+#9#9+'CeMaxRangeHeat -> '+CeHeatStringMax);
//              {$ENDIF}
{            end;
          if ((i=1) or (i=2)) and (CeHeatStringAvg <> '') then
            begin
              CalculatingInMechanicalCharacteristics(CeHeatStringAvg);
              {$IFDEF DEBUG}
//                SaveLog('debug'+#9#9+'CeAvgRangeHeat -> '+CeHeatStringAvg);
//              {$ENDIF}
{            end;
         end;
     end;
}

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


function SqlCarbonEquivalent(InHeat: string): TArray;
var
  i: integer;
  HeatCeArray: TArray;
begin
    i:=0;

    DataModule1.OraQuery1.FetchAll := true;
    DataModule1.OraQuery1.Close;
    DataModule1.OraQuery1.SQL.Clear;
    DataModule1.OraQuery1.SQL.Add('select NPL, C+(MN/6)+(CR/5)+((SI+B)/10) as Ce');
    DataModule1.OraQuery1.SQL.Add('from him_steel');
    DataModule1.OraQuery1.SQL.Add('where DATE_IN_HIM<=sysdate');
    DataModule1.OraQuery1.SQL.Add('and DATE_IN_HIM>=sysdate-305'); //-- 305 = 10 month
    DataModule1.OraQuery1.SQL.Add('and NUMBER_TEST=''0''');
    DataModule1.OraQuery1.SQL.Add('and NPL in ('+InHeat+')');
    DataModule1.OraQuery1.SQL.Add('order by DATE_IN_HIM desc');
    DataModule1.OraQuery1.Open;

    while not DataModule1.OraQuery1.Eof do
     begin
        if i = Length(HeatCeArray) then SetLength(HeatCeArray, i+1, 2);
          HeatCeArray[i,0] := DataModule1.OraQuery1.FieldByName('NPL').AsString;
          HeatCeArray[i,1] := DataModule1.OraQuery1.FieldByName('Ce').AsFloat;
          inc(i);
          DataModule1.OraQuery1.Next;
    end;
//   for I := Low(iCeArray) to High(iCeArray) do
//    begin
//    {$IFDEF DEBUG}
//      SaveLog('debug'+#9#9+'00='+floattostr(iCeArray[i,0])+'|01='+floattostr(iCeArray[i,1]));
//    {$ENDIF}
//    end;

    Result := HeatCeArray;
end;


function CalculatingInMechanicalCharacteristics(InHeat: string): string;
var
  i, a, b,AdjustmentMin, AdjustmentMax: integer;
  m: bool;
  HeatAll, HeatWorks, HeatTableAll, index, CoefficientValue, avg, _stddev, min, max ,yield_point_diff: string;
  section_tmp, Cmin, Cmax, Tavg, TStdDev
  ,TdiffMin, TdiffMax, Tdiff, R: string;
  HeatArray, HeatTableArray: Array of string;
  TempArray: Array of Double;
  st, HeatTmp: TStringList;

begin

    i := 0;
    a := 0;
    b := a;

    HeatAll := HeatToIn(InHeat);

    Application.ProcessMessages;//��������� �������� �� �������� ���������

    DataModule1.OraQuery1.FetchAll := true;
    DataModule1.OraQuery1.Close;
    DataModule1.OraQuery1.SQL.Clear;
    DataModule1.OraQuery1.SQL.Add('select n.nplav, v.limtek, v.limproch from czl_v v, czl_n n');
    //-- 305 = 10 month
    DataModule1.OraQuery1.SQL.Add('where n.data<=sysdate and n.data>=sysdate-305');
    DataModule1.OraQuery1.SQL.Add('and n.mst like '''+Grade+''' and n.GOST like '''+Standard+'''');
    DataModule1.OraQuery1.SQL.Add('and n.razm1 like '''+Section+''' and n.klass like '''+StrengthClass+'''');
    DataModule1.OraQuery1.SQL.Add('and n.data=v.data and v.npart=n.npart');
    DataModule1.OraQuery1.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
    DataModule1.OraQuery1.SQL.Add('and prizn=''*'' and ROWNUM <= 251');
    DataModule1.OraQuery1.SQL.Add('and n.nplav in('+HeatAll+')');
    DataModule1.OraQuery1.SQL.Add('order by n.data desc');
    DataModule1.OraQuery1.Open;

form1.edit1.Text := 'ora 01';

    st := TStringList.Create;
    st.Text := StringReplace(InHeat,'|',#13#10,[rfReplaceAll]);

    HeatTmp := TStringList.Create;

    while not DataModule1.OraQuery1.Eof do
     begin
        for i:=0 to st.count-1 do
          begin
            if (st.Strings[i] = DataModule1.OraQuery1.FieldByName('nplav').AsString)
               and (-1 = HeatTmp.IndexOf(st.Strings[i])) then
             begin
                  HeatTmp.Add(st.Strings[i]);
              end;
          end;
      DataModule1.OraQuery1.Next;
     end;

    st.Destroy;

     for i:=0 to HeatTmp.Count-1 do
      begin
        if i=0 then
         begin
          HeatWorks := HeatWorks+HeatTmp.Strings[i];
         end
        else
          HeatWorks := HeatWorks+'|'+HeatTmp.Strings[i];
      end;

     HeatTmp.Destroy;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'HeatWorks -> '+HeatWorks);
  {$ENDIF}

    HeatAll := HeatToIn(HeatWorks);

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'HeatWorksIn -> '+HeatAll);
  {$ENDIF}

    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('SELECT max(id), n, k FROM yield_point where n<='+inttostr(DataModule1.OraQuery1.RecordCount)+'');
    SQuery.Open;

    index := SQuery.FieldByName('n').AsString;
    CoefficientValue := SQuery.FieldByName('k').AsString;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'cffcnt -> '+index);
    SaveLog('debug'+#9#9+'CoefficientValue -> '+CoefficientValue);
    SaveLog('debug'+#9#9+'Count -> '+inttostr(DataModule1.OraQuery1.RecordCount));
  {$ENDIF}

      st := TStringList.Create;
      st.Text := StringReplace(Standard,'%',#13#10,[rfReplaceAll]);
      Section_tmp := inttostr(strtoint(StringReplace(Section,'%','',[rfReplaceAll]))+15);//15 ��� �����, �� ������ ������

      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('SELECT yield_point_min, yield_point_max FROM rolled_products where standard like '''+st.Strings[0]+'%'+st.Strings[1]+'''');
      SQuery.SQL.Add('and strength_class like '''+StrengthClass+'''');
      SQuery.SQL.Add('and diameter_min >= '+Section_tmp+' and diameter_max >= '+Section_tmp+'');
      SQuery.Open;

    Application.ProcessMessages;//��������� �������� �� �������� ���������

    DataModule1.OraQuery1.FetchAll := true;
    DataModule1.OraQuery1.Close;
    DataModule1.OraQuery1.SQL.Clear;
    DataModule1.OraQuery1.SQL.Add('select AVG(ALL v.limtek) avg, (STDDEV(ALL v.limtek)) STDDEV from czl_v v, czl_n n');
    DataModule1.OraQuery1.SQL.Add('where n.data<=sysdate and n.data>=sysdate-305');
    DataModule1.OraQuery1.SQL.Add('and n.mst like '''+Grade+''' and n.GOST like '''+Standard+'''');
    DataModule1.OraQuery1.SQL.Add('and to_char(n.prof)||to_char(n.razm1) like '''+Section+''' and n.klass like '''+StrengthClass+'''');
    DataModule1.OraQuery1.SQL.Add('and n.data=v.data and v.npart=n.npart');
    DataModule1.OraQuery1.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
    DataModule1.OraQuery1.SQL.Add('and prizn=''*'' and ROWNUM <= '+index+'');
    DataModule1.OraQuery1.SQL.Add('and n.nplav in('+HeatAll+')');
    DataModule1.OraQuery1.SQL.Add('order by n.data desc');
    DataModule1.OraQuery1.Open;

     st.Destroy;

//  {$IFDEF DEBUG}
//    SaveLog('debug'+#9#9+DataModule1.OraQuery1.SQL.text);
//  {$ENDIF}

       form1.edit1.Text := '';


       avg := DataModule1.OraQuery1.FieldByName('avg').AsString;
       _stddev := DataModule1.OraQuery1.FieldByName('STDDEV').AsString;
       min := floattostr(DataModule1.OraQuery1.FieldByName('avg').AsFloat-
                     DataModule1.OraQuery1.FieldByName('STDDEV').AsFloat*
                     strtofloat(CoefficientValue));
       max := floattostr(DataModule1.OraQuery1.FieldByName('avg').AsFloat+
                     DataModule1.OraQuery1.FieldByName('STDDEV').AsFloat*
                     strtofloat(CoefficientValue));
       yield_point_diff := floattostr(strtofloat(max)-strtofloat(min));

       Cmin := floattostr(strtofloat(min)-SQuery.FieldByName('yield_point_min').AsInteger);
       Cmax := floattostr(strtofloat(max)-SQuery.FieldByName('yield_point_max').AsInteger);

    st := TStringList.Create;
    st.Text := StringReplace(RolledMelting(HeatAll),'|',#13#10,[rfReplaceAll]);

 //   for i:=0 to st.Count-1 do
//  {$IFDEF DEBUG}
//    SaveLog('debug'+#9#9+'table name='+st.Strings[i]);
//  {$ENDIF}

      for i:=0 to st.Count-1 do
       begin
          DataModule1.pFIBQuery1.Close;
          DataModule1.pFIBQuery1.SQL.Clear;
          DataModule1.pFIBQuery1.SQL.Add('SELECT noplav, cast(TMOUTL as integer) as temp from');
          DataModule1.pFIBQuery1.SQL.Add(''+st.strings[i]+'');
          DataModule1.pFIBQuery1.SQL.Add('where TMOUTL>250');
          DataModule1.pFIBQuery1.ExecQuery;

          while not DataModule1.pFIBQuery1.Eof do
           begin
            if a = Length(TempArray) then SetLength(TempArray, a + 1);
              TempArray[a] := DataModule1.pFIBQuery1.FieldByName('temp').AsInteger;
              inc(a);
              DataModule1.pFIBQuery1.Next;
           end;
       end;

    st.Destroy;

       Tavg := floattostr(Mean(TempArray));
       TStdDev := floattostr(StdDev(TempArray));
       TdiffMin :=  floattostr(strtofloat(Tavg) - strtofloat(TStdDev));
       TdiffMax := floattostr(strtofloat(Tavg) + strtofloat(TStdDev));
       Tdiff := floattostr(strtofloat(TdiffMax) - strtofloat(TdiffMin));

       R :=   floattostr(strtofloat(Tdiff) / strtofloat(yield_point_diff));

       AdjustmentMin := Round(strtofloat(Cmin) * strtofloat(R));
       AdjustmentMax := Round(strtofloat(Cmax) * strtofloat(R));

    if (limitsM = 0) or (limitsM <> 1) then
     begin
      LowRed := SQuery.FieldByName('yield_point_min').AsInteger+AdjustmentMin;
      HighRed := SQuery.FieldByName('yield_point_max').AsInteger+AdjustmentMax;
      {$IFDEF DEBUG}
        SaveLog('debug'+#9#9+'LowRed -> '+inttostr(LowRed));
        SaveLog('debug'+#9#9+'HighRed -> '+inttostr(HighRed));
      {$ENDIF}
     end
    else
     begin
      LowGreen := SQuery.FieldByName('yield_point_min').AsInteger+AdjustmentMin;
      HighGreen := SQuery.FieldByName('yield_point_max').AsInteger+AdjustmentMax;
      limitsM := 0;
      {$IFDEF DEBUG}
        SaveLog('debug'+#9#9+'LowGreen -> '+inttostr(LowGreen));
        SaveLog('debug'+#9#9+'HighGreen -> '+inttostr(HighGreen));
      {$ENDIF}
     end;

    inc(limitsM); //������ 2�� �������

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'limitsM -> '+inttostr(limitsM));
    SaveLog('debug'+#9#9+'avg -> '+avg);
    SaveLog('debug'+#9#9+'_stddev -> '+_stddev);
    SaveLog('debug'+#9#9+'min -> '+min);
    SaveLog('debug'+#9#9+'max -> '+max);
    SaveLog('debug'+#9#9+'yield_point_diff -> '+yield_point_diff);
    SaveLog('debug'+#9#9+'Cmin -> '+Cmin);
    SaveLog('debug'+#9#9+'Cmax ->'+Cmax);
    SaveLog('debug'+#9#9+'Tavg -> '+Tavg);
    SaveLog('debug'+#9#9+'TStdDev -> '+TStdDev);
    SaveLog('debug'+#9#9+'TdiffMin -> '+TdiffMin);
    SaveLog('debug'+#9#9+'TdiffMax -> '+TdiffMax);
    SaveLog('debug'+#9#9+'Tdiff -> '+Tdiff);
    SaveLog('debug'+#9#9+'R -> '+R);
    SaveLog('debug'+#9#9+'AdjustmentMin -> '+inttostr(AdjustmentMin));
    SaveLog('debug'+#9#9+'AdjustmentMax -> '+inttostr(adjustmentMax));
  {$ENDIF}

   //���������� ������ �� ������� ������������� ������
   Result := HeatAll;
end;


function CurrentHeat: bool;
begin
  DataModule1.pFIBQuery1.Close;
  DataModule1.pFIBQuery1.SQL.Clear;
  DataModule1.pFIBQuery1.SQL.Add('select *');
  DataModule1.pFIBQuery1.SQL.Add('FROM melts');
  DataModule1.pFIBQuery1.SQL.Add('where begindt=(select max(begindt) FROM melts)');
  DataModule1.pFIBQuery1.ExecQuery;
  DataModule1.pFIBQuery1.Transaction.Commit;

  Heat:= DataModule1.pFIBQuery1.FieldByName('NOPLAV').AsString; //������
  Grade:= '%'+DataModule1.pFIBQuery1.FieldByName('MARKA').AsString; //'%��3����'; //����� �����
  Section:= '%'+DataModule1.pFIBQuery1.FieldByName('RAZM1').AsString+'%'; //'%10%'; //�������
  Standard:= '����%3760%2006'; //��������
  StrengthClass:= '%�500�%'; //���� ���������

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CurrentHeat='+Heat);
    SaveLog('debug'+#9#9+'CurrentGrade='+Grade);
    SaveLog('debug'+#9#9+'CurrentSection='+Section);
    SaveLog('debug'+#9#9+'CurrentStandard='+Standard);
    SaveLog('debug'+#9#9+'CurrentStrengthClass='+StrengthClass);
  {$ENDIF}

end;






end.
