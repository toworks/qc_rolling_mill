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
    Temp: string = '';
    Ce: string = '';

type
    TArray = array of array of variant;

    {$DEFINE DEBUG}

    function CarbonEquivalent(InHeat: string): bool;
    function InsertQualityManagement(InData, InData2, InData3, InData4: string): bool;
    function HeatToString(var InHeatArray: TArray): string;
//    function SqlCarbonEquivalent(InHeat: string): array of array of variant;
    function SqlCarbonEquivalent(InHeat: string): TArray;//array of array of variant;
    function CalculatingInMechanicalCharacteristics(var InHeatArray: TArray): bool;




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


//  ThreadChartInit;
//  ThreadSqlInit;
//  ThreadSqlChemistryInit;

end;



procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveLog('close'+#9#9+'app');
end;


procedure TForm1.Button1Click(Sender: TObject);
var
  i: integer;
  AggregateHeatTableArray: TArray;
begin

    i := 0;

    //-- for test
    Heat:= '232371'; //������
    Grade:= '%��3����'; //����� �����
    Section:= '%10%'; //�������
    Standard:= '����%3760%2006'; //��������
    StrengthClass:= '%�500�%'; //���� ���������
    //-- for test

    Application.ProcessMessages;//��������� �������� �� �������� ���������

//-- ��������� ���������� ������ �� ������ 125
    DataModule1.pFIBQuery1.Close;
    DataModule1.pFIBQuery1.SQL.Clear;
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
    DataModule1.pFIBQuery1.SQL.Add('AND CAST(CAST(SUBSTRING(m.noplav from cast(CHAR_LENGTH(m.noplav)as integer)) AS INTEGER) / 2 AS INTEGER) * 2 = SUBSTRING(m.noplav from cast(CHAR_LENGTH(m.noplav)as integer))');
    //-- 305 = 10 month
    DataModule1.pFIBQuery1.SQL.Add('and m.begindt<=current_date and m.begindt>=current_date-305');
    DataModule1.pFIBQuery1.SQL.Add('and m.marka like '''+Grade+''' and m.standart like '''+Standard+'''');
    DataModule1.pFIBQuery1.SQL.Add('and mch.razm1 like '''+Section+''' and mch.KLPROCH like '''+StrengthClass+'''');
    DataModule1.pFIBQuery1.SQL.Add('group by m.noplav, m.begindt');
    DataModule1.pFIBQuery1.SQL.Add('order by m.begindt');
    DataModule1.pFIBQuery1.ExecQuery;


    while not DataModule1.pFIBQuery1.Eof do
     begin
        // AggregateHeatTableArray 0 - heat column(noplav), 1 - name table column(table_name)
        if i = Length(AggregateHeatTableArray) then SetLength(AggregateHeatTableArray, i+1, 2);
        AggregateHeatTableArray[i,0] := DataModule1.pFIBQuery1.FieldByName('noplav').AsString;
        AggregateHeatTableArray[i,1] := DataModule1.pFIBQuery1.FieldByName('table_name').AsString;
        inc(i);
        DataModule1.pFIBQuery1.Next;
     end;

//   for i:=Low(AggregateHeatTableArray) to High(AggregateHeatTableArray) do
//    begin
//    {$IFDEF DEBUG}
//      SaveLog('debug'+#9#9+'heat='+AggregateHeatTableArray[i,0]+#9+
//              'table name ='+AggregateHeatTableArray[i,1]);
//    {$ENDIF}
//    end;

//-- ��������� ���������� ������ �� ������ 125

//  HeatAll := HeatToString(AggregateHeatTableArray);

//    {$IFDEF DEBUG}
//      SaveLog('debug'+#9#9+'heat='+HeatAll);
//    {$ENDIF}

  CalculatingInMechanicalCharacteristics(AggregateHeatTableArray);

//  CarbonEquivalent(HeatAll);

end;


function InsertQualityManagement(InData, InData2, InData3, InData4: string): bool;
begin
//  if m_sql = false then
//   begin
   DataModule1.pFIBDatabase1.Connected := false;
   DataModule1.pFIBDatabase1.LibraryName := '.\fbclient.dll';
   DataModule1.pFIBDatabase1.DBName := 'localhost:c:\tmp\mc_250-5\Ms250-5.fdb';
   DataModule1.pFIBDatabase1.ConnectParams.UserName := 'sysdba';
   DataModule1.pFIBDatabase1.ConnectParams.Password := 'masterkey';
   DataModule1.pFIBDatabase1.SQLDialect := 3;
   DataModule1.pFIBDatabase1.UseLoginPrompt := false;
   DataModule1.pFIBDatabase1.Timeout := 0;
   DataModule1.pFIBDatabase1.Connected := true;
   DataModule1.pFIBTransaction1.Active := false;
   DataModule1.pFIBTransaction1.Timeout := 0;
   DataModule1.pFIBQuery1.Database := DataModule1.pFIBDatabase1;
   DataModule1.pFIBQuery1.Transaction := DataModule1.pFIBTransaction1;
//   m_sql := true;
//  end;


   DataModule1.pFIBQuery1.Close;
   DataModule1.pFIBQuery1.SQL.Clear;
   DataModule1.pFIBQuery1.SQL.Add('UPDATE or INSERT INTO QUALITY_MANAGEMENT');
   DataModule1.pFIBQuery1.SQL.Add('(id, heat, grade, CARBON_EQUIVALENT, datetime)');
   DataModule1.pFIBQuery1.SQL.Add('values (GEN_ID(GEN_QUALITY_MANAGEMENT_ID, 1), '''+InData+''', '''+InData2+''', '''+InData3+''', '''+InData4+''')');
   DataModule1.pFIBQuery1.SQL.Add('matching (heat)');



    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+DataModule1.pFIBQuery1.SQL.Text);
    {$ENDIF}

   DataModule1.pFIBQuery1.ExecQuery;
   DataModule1.pFIBQuery1.Transaction.Commit;
   m_chart := false;//��������� ������ ����������
end;


function CarbonEquivalent(InHeat: string): bool;
var
  CeMin, CeMax, CeAvg, CeMinP, CeMaxM, CeAvgP, CeAvgM,rangeMin: real;
  i,a,b,c,rangeM: integer;
  CeArray: TArray;//array of array of variant;
  CeMinHeat: string;
  CeHeatArrayMin, CeHeatArrayMax, CeHeatArrayAvg, range: array of variant;
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
      SaveLog('debug'+#9#9+'CeMinDiapozon='+floattostr(CeArray[i,0])+'|'+floattostr(CeArray[i,1]));
  {$ENDIF}
            if a = Length(CeHeatArrayMin) then SetLength(CeHeatArrayMin, a+1);
             CeHeatArrayMin[a] := CeArray[i,0];
             inc(a);
         end;

        if InRange(CeArray[i,1], CeMaxM, CeMax) then
         begin
  {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'CeMaxDiapozon='+floattostr(CeArray[i,0])+'|'+floattostr(CeArray[i,1]));
  {$ENDIF}
            if b = Length(CeHeatArrayMax) then SetLength(CeHeatArrayMax, b+1);
             CeHeatArrayMax[b] := CeArray[i,0];
             inc(b);
         end;

        if InRange(CeArray[i,1], CeAvgM, CeAvgP) then
         begin
  {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'CeAvgDiapozon='+floattostr(CeArray[i,0])+'|'+floattostr(CeArray[i,1]));
  {$ENDIF}
            if c = Length(CeHeatArrayAvg) then SetLength(CeHeatArrayAvg, c+1);
             CeHeatArrayAvg[c] := CeArray[i,0];
             inc(c);
         end;
     End;


  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+InHeat+#9+'CeMin='+floattostr(CeMin)+#9+
            'CeMax='+floattostr(CeMax)+#9+'CeAvg='+floattostr(CeAvg)+#9+
            'CeMinP='+floattostr(CeMinP)+#9+'CeMaxM='+floattostr(CeMaxM)+#9+
            'CeAvgP='+floattostr(CeAvgP)+#9+'CeAvgM='+floattostr(CeAvgM));
  {$ENDIF}


    CeArray := SqlCarbonEquivalent(''''+Heat+'''');

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CurrHeat='+CeArray[0,0]+#9+'CurrCe='+floattostr(CeArray[0,1]));
  {$ENDIF}

          If InRange(CeArray[0,1], CeMin, CeMinP) then
         begin
  {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'CurrCeMinDiapozon='+floattostr(CeArray[0,0])+'|'+floattostr(CeArray[0,1]));
  {$ENDIF}
         end;

        if InRange(CeArray[0,1], CeMaxM, CeMax) then
         begin
  {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'CurrCeMaxDiapozon='+floattostr(CeArray[0,0])+'|'+floattostr(CeArray[0,1]));
  {$ENDIF}
         end;

        if InRange(CeArray[0,1], CeAvgM, CeAvgP) then
         begin
  {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'CurrCeAvgDiapozon='+floattostr(CeArray[0,0])+'|'+floattostr(CeArray[0,1]));
  {$ENDIF}

         end;


        SetLength(range, 4);
        range[0] := ABS(CeMinP - CeArray[0,1]);
        range[1] := ABS(CeMaxM - CeArray[0,1]);
        range[2] := ABS(CeAvgP - CeArray[0,1]);
        range[3] := ABS(CeAvgM - CeArray[0,1]);

    rangeMin := range[0];

    For i:=low(range) To high(range) Do
     Begin
        If range[i]<rangeMin Then rangeMin:=range[i];
     End;

    For i:=low(range) To high(range) Do
     Begin
        If range[i]=rangeMin Then
         begin
          if i=0 then
//            CeArray := SqlCarbonEquivalent(CeHeatArrayMin);
          if (i=1) or (i=2) then
//            CeArray := SqlCarbonEquivalent(CeHeatArrayAvg);
          if i=3 then
//            CeArray := SqlCarbonEquivalent(CeHeatArrayMax);
         end;

     End;



  {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'CeminP-='+floattostr(range[0])+'|CeminP-='+floattostr(range[1])
              +'|CeAvgP-='+floattostr(range[2])+'|CeAvgM-='+floattostr(range[3])
              +'|CeMMMMMM-='+floattostr(rangeMin)+'|rangeM-='+floattostr(rangeM));
  {$ENDIF}


end;


function HeatToString(var InHeatArray: TArray): string;
var
  i: integer;
  AllHeat: string;
begin
    for i:=Low(InHeatArray) to High(InHeatArray) do
     begin
       if i <> High(InHeatArray) then
         InHeatArray[i,0] := ''''+InHeatArray[i,0]+''''+','
       else
         InHeatArray[i,0] := ''''+InHeatArray[i,0]+'''';

       AllHeat := AllHeat+''+InHeatArray[i,0]+'';
     end;
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
    DataModule1.OraQuery1.SQL.Add('where DATE_IN_HIM>=cast(''01.01.13'' as date)');
    DataModule1.OraQuery1.SQL.Add('and DATE_IN_HIM<=cast(''12.05.13'' as date)');
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


function CalculatingInMechanicalCharacteristics(var InHeatArray: TArray): bool;
var
  i, a: integer;
  m: bool;
  HeatAll, HeatTableAll, index, CoefficientValue, avg, _stddev, min, max ,yield_point_diff: string;
  grade, section, standard, StrengthClass, section_tmp, Cmin, Cmax, Tavg, TStdDev
  ,TdiffMin, TdiffMax, Tdiff, R, adjustmentMin, adjustmentMax: string;
  HeatArray, HeatTableArray: Array of string;
  TempArray: Array of Double;
  st: TStringList;
begin

    i := 0;
    a := 0;

    HeatAll := HeatToString(InHeatArray);

    DataModule1.OraQuery1.FetchAll := true;
    DataModule1.OraQuery1.Close;
    DataModule1.OraQuery1.SQL.Clear;
    DataModule1.OraQuery1.SQL.Add('select v.limtek, v.limproch from czl_v v, czl_n n');
    DataModule1.OraQuery1.SQL.Add('where n.data>=cast(''01.01.13'' as date) and n.data<=cast(''12.05.13'' as date) and n.mst like '''+Grade+''' and n.GOST like '''+Standard+'''');
    DataModule1.OraQuery1.SQL.Add('and n.razm1 like '''+Section+''' and n.klass like '''+StrengthClass+'''');
    DataModule1.OraQuery1.SQL.Add('and n.data=v.data and v.npart=n.npart');
    DataModule1.OraQuery1.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
    DataModule1.OraQuery1.SQL.Add('and prizn=''*'' and ROWNUM <= 251');
    DataModule1.OraQuery1.SQL.Add('and n.nplav in('+HeatAll+')');
    DataModule1.OraQuery1.SQL.Add('order by n.data desc');
    DataModule1.OraQuery1.Open;

    form1.edit1.Text := 'ora 01';

    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'heat='+HeatAll);
    {$ENDIF}


exit;

    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('SELECT max(id), n, k FROM yield_point where n<='+inttostr(DataModule1.OraQuery1.RecordCount)+'');
    SQuery.Open;

    index := SQuery.FieldByName('n').AsString;
    CoefficientValue := SQuery.FieldByName('k').AsString;

  {$IFDEF DEBUG}
    SaveLog('array'+#9#9+'cffcnt='+index+#9+'value='+CoefficientValue+#9+'count='+inttostr(DataModule1.OraQuery1.RecordCount));
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


       DataModule1.OraQuery1.FetchAll := true;
       DataModule1.OraQuery1.Close;
       DataModule1.OraQuery1.SQL.Clear;
{       DataModule1.OraQuery1.SQL.Add('select AVG(ALL v.limtek) avg,  (STDDEV(ALL v.limtek)) STDDEV from czl_v v, czl_n n');
       DataModule1.OraQuery1.SQL.Add('where n.data>=sysdate-365 and n.mst=''SAE1008�(B)'' and n.GOST=''ASTM A510M-06''');
       DataModule1.OraQuery1.SQL.Add('and to_char(n.prof)||to_char(n.razm1)=''��8'' and n.klass is null');
       DataModule1.OraQuery1.SQL.Add('and v.YEAR=n.YEAR and n.data=v.data and v.npart=n.npart');
       DataModule1.OraQuery1.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
       DataModule1.OraQuery1.SQL.Add('and prizn=''*'' and ROWNUM <= '+index+' order by n.DATA desc');}
       DataModule1.OraQuery1.SQL.Add('select AVG(ALL v.limtek) avg, (STDDEV(ALL v.limtek)) STDDEV from czl_v v, czl_n n');
//       DataModule1.OraQuery1.SQL.Add('where n.data>=sysdate-365 and n.mst='''+Grade+''' and n.GOST='''+Standard+'''');
       DataModule1.OraQuery1.SQL.Add('where n.data>=cast(''01.01.13'' as date) and n.data<=cast(''12.05.13'' as date) and n.mst like '''+Grade+''' and n.GOST like '''+Standard+'''');
       DataModule1.OraQuery1.SQL.Add('and to_char(n.prof)||to_char(n.razm1) like '''+Section+''' and n.klass like '''+StrengthClass+'''');
       DataModule1.OraQuery1.SQL.Add('and n.data=v.data and v.npart=n.npart');
       DataModule1.OraQuery1.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
       DataModule1.OraQuery1.SQL.Add('and prizn=''*'' and ROWNUM <= '+index+'');
       DataModule1.OraQuery1.SQL.Add('and n.nplav in('+HeatAll+')');
       DataModule1.OraQuery1.SQL.Add('order by n.data desc');
       DataModule1.OraQuery1.Open;

//  {$IFDEF DEBUG}
//    SaveLog('debug'+#9#9+DataModule1.OraQuery1.SQL.text);
//  {$ENDIF}

       form1.edit1.Text := '';

{        while not DataModule1.OraQuery1.Eof do
          begin
            SQuery.Close;
            SQuery.SQL.Clear;
            SQuery.SQL.Add('insert into SIT heat, timestamp,grade, standard, section');
            SQuery.SQL.Add(', strength_class, c, mn, si, cr, batch_number, flow_limit, rupture_strength');
            SQuery.ExecSQL;
          end;}


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


{      for I := Low(InHeatTableArray) to High(InHeatTableArray) do
       begin
          DataModule1.pFIBQuery1.Close;
          DataModule1.pFIBQuery1.SQL.Clear;
          DataModule1.pFIBQuery1.SQL.Add('SELECT noplav, cast(TMOUTL as integer) as temp from');
          DataModule1.pFIBQuery1.SQL.Add(''+InHeatTableArray[i]+'');
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
 }
       Tavg := floattostr(Mean(TempArray));
       TStdDev := floattostr(StdDev(TempArray));
       TdiffMin :=  floattostr(strtofloat(Tavg) - strtofloat(TStdDev));
       TdiffMax := floattostr(strtofloat(Tavg) + strtofloat(TStdDev));
       Tdiff := floattostr(strtofloat(TdiffMax) - strtofloat(TdiffMin));

       R :=   floattostr(strtofloat(Tdiff) / strtofloat(yield_point_diff));
       adjustmentMin := floattostr(strtofloat(Cmin) * strtofloat(R));
       adjustmentMax := floattostr(strtofloat(Cmax) * strtofloat(R));

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'avg='+avg+#9+'_stddev='+_stddev+#9+'min='+min+#9+'max='+max+#9+'yield_point_diff='+yield_point_diff
            +#9+'Cmin='+Cmin+#9+'Cmax='+Cmax+#9+'Tavg='+Tavg+#9+'TStdDev='+TStdDev
            +#9+'TdiffMin='+TdiffMin+#9+'TdiffMax='+TdiffMax+#9+'Tdiff='+Tdiff
            +#9+'R='+R+#9+'adjustmentMin='+adjustmentMin+#9+'adjustmentMax='+adjustmentMax);
  {$ENDIF}

end;




end.