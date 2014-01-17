{
  1 ������ - �� ������, 2 ����� - ������, ������� | ��5 0 ���� 1 ������
}
unit sql;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Graphics, Forms, DBAccess, Ora,
  ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset,
  ZStoredProcedure;

type
  TArray = array of array of variant;
  // THeatArray = array of array of variant;
  TIdHeat = Record
    tid           : integer;
    Heat          : string[26]; // ������
    Grade         : string[50]; // ����� �����
    Section       : string[50]; // �������
    Standard      : string[50]; // ��������
    StrengthClass : string[50]; // ���� ���������
  end;

var
  // global
  OraQuery: TOraQuery;
  OraSession: TOraSession;
  PConnect: TZConnection;
  PQuery: TZQuery;
  left, right: TIdHeat;

  c_left: string = '';
  mn_left: string = '';
  cr_left: string = '';
  si_left: string = '';
  b_left: string = '';
  ce_left: string = '';
  MarkerLeft: bool = false;

  c_right: string = '';
  mn_right: string = '';
  cr_right: string = '';
  si_right: string = '';
  b_right: string = '';
  ce_right: string = '';
  MarkerRight: bool = false;

  function ConfigOracleSetting(InData: bool): bool;
  function ConfigPostgresSetting(InData: bool): bool;

function SqlReadCurrentHeat: bool;
function ViewCurrentData: bool;
function SqlCarbonEquivalent(InHeat: string): TArray;
// array of array of variant;
function CalculatedData(InSide: integer; InData: string): bool;


// {$DEFINE DEBUG}

implementation

uses
  main, logging, settings, chart;




function ConfigPostgresSetting(InData: bool): bool;
begin
  if InData then
  begin
    PConnect := TZConnection.Create(nil);
    PQuery := TZQuery.Create(nil);

    try
        PConnect.LibraryLocation := CurrentDir + '\'+ PgSqlConfigArray[3];
        PConnect.Protocol := 'postgresql-9';
        PConnect.HostName := PgSqlConfigArray[1];
        PConnect.Port := strtoint(PgSqlConfigArray[6]);
        PConnect.User := PgSqlConfigArray[4];
        PConnect.Password := PgSqlConfigArray[5];
        PConnect.Database := PgSqlConfigArray[2];
        PConnect.Connect;
        PQuery.Connection := PConnect;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end
  else
  begin
      FreeAndNil(PQuery);
      FreeAndNil(PConnect);
  end;
end;


function ConfigOracleSetting(InData: bool): bool;
begin
  if InData then
  begin
      try
        OraSession := TOraSession.Create(nil);
        OraQuery := TOraQuery.Create(nil);
        OraSession.Username := OraSqlConfigArray[4];
        OraSession.Password := OraSqlConfigArray[5];
        OraSession.Server := OraSqlConfigArray[1]+':'+
                             OraSqlConfigArray[2]+':'+
                             OraSqlConfigArray[3];//'krr-sql13:1521:ovp68';
        OraSession.Options.Direct := true;
        OraSession.Options.DateFormat := 'DD.MM.RRRR';//������ ���� ��.��.����
        OraSession.Options.Charset := 'CL8MSWIN1251';// 'AL32UTF8';//CL8MSWIN1251
      //  OraSession.Options.UseUnicode := true;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      end;
  end
  else
  begin
        FreeAndNil(OraSession);
        FreeAndNil(OraQuery);
  end;
end;










function SqlReadCurrentHeat: bool;
var
  i: integer;
  OldHeatLeft, OldHeatRight, HeatAll: string;
begin

  OldHeatLeft := left.Heat;
  OldHeatRight := right.Heat;

  for i := 0 to 1 do
  begin
    // side left=0, side right=1
    PQuery.Close;
    PQuery.sql.Clear;
    PQuery.sql.Add('select t1.heat, t1.strength_class, t1.section,');
    PQuery.sql.Add('t2.grade, t2.standard, t2.c, t2.mn, t2.cr, t2.si, t2.b,');
    PQuery.sql.Add('t2.c+(t2.mn/6)+(t2.cr/5)+((t2.si+t2.b)/10) as ce');
    PQuery.sql.Add('FROM temperature_current t1');
    PQuery.sql.Add('LEFT OUTER JOIN');
    PQuery.sql.Add('chemical_analysis t2');
    PQuery.sql.Add('on t1.heat=t2.heat');
    PQuery.sql.Add('where t1.side='+inttostr(i)+'');
    PQuery.sql.Add('order by t1.timestamp desc LIMIT 1');
    Application.ProcessMessages; // ��������� �������� �� �������� ���������
    PQuery.Open;

    if i = 0 then
    begin
      left.Heat := PQuery.FieldByName('heat').AsString;
      left.Grade := PQuery.FieldByName('grade').AsString;
      left.StrengthClass := PQuery.FieldByName('strength_class').AsString;
      left.Section := PQuery.FieldByName('section').AsString;
      left.Standard := PQuery.FieldByName('standard').AsString;

      c_left := PQuery.FieldByName('c').AsString;
      mn_left := PQuery.FieldByName('mn').AsString;
      cr_left := PQuery.FieldByName('cr').AsString;
      si_left := PQuery.FieldByName('si').AsString;
      b_left := PQuery.FieldByName('b').AsString;
      ce_left := copy(PQuery.FieldByName('ce').AsString, 1,
                 pos(',', PQuery.FieldByName('ce').AsString) + 3);
                 // ���� �� ���� ����������

      // ����� ������ ������������� ������
      if OldHeatLeft <> left.Heat then
      begin
        MarkerLeft := true;
        LowRedLeft := 0;
        HighRedLeft := 0;
        LowGreenLeft := 0;
        HighGreenLeft := 0;
      end;

    end
    else
    begin
      right.Heat := PQuery.FieldByName('heat').AsString;
      right.Grade := PQuery.FieldByName('grade').AsString;
      right.StrengthClass := PQuery.FieldByName('strength_class').AsString;
      right.Section := PQuery.FieldByName('section').AsString;
      right.Standard := PQuery.FieldByName('standard').AsString;

      c_right := PQuery.FieldByName('c').AsString;
      mn_right := PQuery.FieldByName('mn').AsString;
      cr_right := PQuery.FieldByName('cr').AsString;
      si_right := PQuery.FieldByName('si').AsString;
      b_right := PQuery.FieldByName('b').AsString;
      ce_right := copy(PQuery.FieldByName('ce').AsString, 1,
                  pos(',', PQuery.FieldByName('ce').AsString) + 3);
                  // ���� �� ���� ����������

      // ����� ������ ������������� ������
      if OldHeatRight <> right.Heat then
      begin
        MarkerRight := true;
        LowRedRight := 0;
        HighRedRight := 0;
        LowGreenRight := 0;
        HighGreenRight := 0;
      end;

    end;

  end;

  if MarkerLeft or MarkerRight then
    ViewCurrentData;

  if MarkerLeft and not ce_left.IsEmpty then
  begin
    try
      MarkerLeft := false;
      SaveLog('info'+#9#9+'start calculation left side, heat -> '+left.Heat);
      CalculatedData(0, 'timestamp=EXTRACT(EPOCH FROM now())');
      HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(0), 0);
      if not HeatAll.IsEmpty then
        CarbonEquivalent(HeatAll, 0);
      SaveLog('info'+#9#9+'end calculation left side, heat -> '+left.Heat);
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end;

  if MarkerRight and not ce_right.IsEmpty then
  begin
    try
      MarkerRight := false;
      SaveLog('info'+#9#9+'start calculation right side, heat -> '+right.Heat);
      CalculatedData(1, 'timestamp=EXTRACT(EPOCH FROM now())');
      HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(1), 1);
      if not HeatAll.IsEmpty then
        CarbonEquivalent(HeatAll, 1);
      SaveLog('info' + #9#9 + 'end calculation right side, heat -> '+right.Heat);
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end;
end;

function ViewCurrentData: bool;
begin
  // side left
  form1.l_global_left.Caption := '������: ' + left.Heat + ' | ' + '�����: ' +
    left.Grade + ' | ' + '����� ���������: ' + left.StrengthClass + ' | ' +
    '�������: ' + left.Section + ' | ' + '��������: ' + left.Standard;
  form1.l_chemical_left.Caption := '���������� ������' + #9 + 'C: ' + c_left +
    ' | ' + 'Mn: ' + mn_left + ' | ' + 'Cr: ' + cr_left + ' | ' + 'Si: ' +
    si_left + ' | ' + 'B: ' + b_left + ' | ' + 'Ce: ' + ce_left;

  // side right
  form1.l_global_right.Caption := '������: ' + right.Heat + ' | ' + '�����: ' +
    right.Grade + ' | ' + '����� ���������: ' + right.StrengthClass + ' | ' +
    '�������: ' + right.Section + ' | ' + '��������: ' + right.Standard;
  form1.l_chemical_right.Caption := '���������� ������' + #9 + 'C: ' + c_right +
    ' | ' + 'Mn: ' + mn_right + ' | ' + 'Cr: ' + cr_right + ' | ' + 'Si: ' +
    si_right + ' | ' + 'B: ' + b_right + ' | ' + 'Ce: ' + ce_right;
end;


function SqlCarbonEquivalent(InHeat: string): TArray;
var
  i: integer;
  HeatCeArray: TArray;
  PQueryCe: TZQuery;
begin
  PQueryCe := TZQuery.Create(nil);
  PQueryCe.Connection := PConnect;


  { ��� 3�� �������
    Module.OraQuery1.FetchAll := true;
    Module.OraQuery1.Close;
    Module.OraQuery1.SQL.Clear;
    Module.OraQuery1.SQL.Add('select NPL, C+(MN/6)+(CR/5)+((SI+B)/10) as Ce');
    Module.OraQuery1.SQL.Add('from him_steel');
    Module.OraQuery1.SQL.Add('where DATE_IN_HIM<=sysdate');
    Module.OraQuery1.SQL.Add('and DATE_IN_HIM>=sysdate-305'); //-- 305 = 10 month
    Module.OraQuery1.SQL.Add('and NUMBER_TEST=''0''');
    Module.OraQuery1.SQL.Add('and NPL in ('+InHeat+')');
    Module.OraQuery1.SQL.Add('order by DATE_IN_HIM desc');
    Module.OraQuery1.Open;

    i:=0;
    while not Module.OraQuery1.Eof do
    begin
    if i = Length(HeatCeArray) then SetLength(HeatCeArray, i+1, 2);
    HeatCeArray[i,0] := Module.OraQuery1.FieldByName('NPL').AsString;
    HeatCeArray[i,1] := Module.OraQuery1.FieldByName('Ce').AsFloat;
    inc(i);
    Module.OraQuery1.Next;
    end;
  }

  PQueryCe.Close;
  PQueryCe.sql.Clear;
  PQueryCe.sql.Add('select heat, c+(mn/6)+(cr/5)+((si+b)/10) as ce');
  PQueryCe.sql.Add('from chemical_analysis');
  PQueryCe.sql.Add('where heat in ('+InHeat+')');
  PQueryCe.sql.Add('order by timestamp desc');
  Application.ProcessMessages; // ��������� �������� �� �������� ���������
  PQueryCe.Open;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'ce -> FQueryCe.SQL.Text -> ' + FQueryCe.sql.Text);
{$ENDIF}
  i := 0;
  while not PQueryCe.Eof do
  begin
    if i = Length(HeatCeArray) then
      SetLength(HeatCeArray, i + 1, 2);
    HeatCeArray[i, 0] := PQueryCe.FieldByName('heat').AsString;
    HeatCeArray[i, 1] := PQueryCe.FieldByName('ce').AsFloat;
    inc(i);
    PQueryCe.Next;
  end;

  PQueryCe.Free;

  for i := Low(HeatCeArray) to High(HeatCeArray) do
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'heat for ce -> ' + floattostr(HeatCeArray[i, 0]));
    SaveLog('debug' + #9#9 + 'ce -> ' + floattostr(HeatCeArray[i, 1]));
{$ENDIF}
  end;

  Result := HeatCeArray;
end;

function CalculatedData(InSide: integer; InData: string): bool;
var
  PQueryCalculatedData: TZQuery;
  tid, heat: string;
begin
  PQueryCalculatedData := TZQuery.Create(nil);
  PQueryCalculatedData.Connection := PConnect;

{  try
    // ������� ������ ������ 10 ������� 2629743(���� �����)*10
    PQueryCalculatedData.Close;
    PQueryCalculatedData.sql.Clear;
    PQueryCalculatedData.sql.Add('DELETE FROM reports');
    PQueryCalculatedData.sql.Add
      ('where timestamp<(strftime(''%s'',''now'')-(2629743*10))');
    SQueryReport.ExecSQL;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;}

  if InSide = 0 then
    heat := left.Heat
  else
    heat := right.Heat;

  PQueryCalculatedData.Close;
  PQueryCalculatedData.sql.Clear;
  PQueryCalculatedData.sql.Add('select tid FROM temperature_current');
  PQueryCalculatedData.sql.Add('where heat=''' + heat + '''');
  PQueryCalculatedData.sql.Add('and side=' + inttostr(InSide) + '');
  PQueryCalculatedData.sql.Add('ORDER BY timestamp desc LIMIT 1');
  PQueryCalculatedData.Open;

  tid := PQueryCalculatedData.FieldByName('tid').AsString;

  PQueryCalculatedData.Close;
  PQueryCalculatedData.sql.Clear;
  PQueryCalculatedData.sql.Add('select cid FROM calculated_data');
  PQueryCalculatedData.sql.Add('where cid='+tid+'');
  PQueryCalculatedData.Open;

  if PQueryCalculatedData.FieldByName('cid').IsNull then
  begin
    PQueryCalculatedData.Close;
    PQueryCalculatedData.sql.Clear;
    PQueryCalculatedData.sql.Add('INSERT INTO calculated_data (cid)');
    PQueryCalculatedData.sql.Add('VALUES ('+tid+')');
    PQueryCalculatedData.ExecSQL;
  end;
//  else
  begin
    PQueryCalculatedData.Close;
    PQueryCalculatedData.sql.Clear;
    PQueryCalculatedData.sql.Add('UPDATE calculated_data SET ' + InData + '');
    PQueryCalculatedData.sql.Add('where cid='+tid+'');
    PQueryCalculatedData.ExecSQL;
  end;

  FreeAndNil(PQueryCalculatedData);

end;

end.
