unit sql;

interface

uses
  SysUtils, Classes, Windows, ActiveX, DBAccess, Ora, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, ZAbstractRODataset;

type
  TSql = class

  private
    { Private declarations }
  protected

  end;

type
  TArray = array of array of variant;

var
  SqlService: TSql;
  OraQuery: TOraQuery;
  OraSession: TOraSession;
  PConnect: TZConnection;
  PQuery: TZQuery;

//  {$DEFINE DEBUG}

  function ConfigOracleSetting(InData: bool): bool;
  function ConfigPostgresSetting(InData: bool): bool;
  function RolledMelting(InSide: integer): string;
  function SqlCarbonEquivalent(InHeat: string): TArray;
  function CalculatedData(InSide: integer; InData: string): bool;

implementation

uses
  settings, logging, main, thread_calculated_data;



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
  PQueryCalculation.sql.Add('and standard like '''+GetDigits(Standard)+'%''');
  PQueryCalculation.sql.Add('and side='+inttostr(InSide)+'');
  PQueryCalculation.sql.Add('LIMIT 125');
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




// ��� �������� ��������� ����� ����� �����������
initialization

SqlService := TSql.Create;


// ��� �������� ��������� ������������
finalization

SqlService.Destroy;

end.
