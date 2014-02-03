{
  1 правая - не четная, 2 левая - четная, сторона | мс5 0 лева 1 правая
}
unit sql;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Graphics, Forms, System.Variants,
  ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset,
  ZStoredProcedure;

type
  TIdHeat = Record
    tid           : integer;
    Heat          : string[26]; // плавка
    Grade         : string[50]; // марка стали
    Section       : string[50]; // профиль
    Standard      : string[50]; // стандарт
    StrengthClass : string[50]; // клас прочности
    c             : string[50];
    mn            : string[50];
    cr            : string[50];
    si            : string[50];
    b             : string[50];
    ce            : string[50];
    old_tid       : integer; // стара плавка
    marker        : bool;
    temperature   : integer;
    timestamp     : integer;
    LowRed        : integer;
    HighRed       : integer;
    LowGreen      : integer;
    HighGreen     : integer;
    constructor Create(_tid: integer; _Heat, _Grade, _Section, _Standard, _StrengthClass,
                      _c, _mn, _cr, _si, _b, _ce: string; _old_tid: integer; _marker: bool;
                      _temperature, _timestamp, _LowRed, _HighRed, _LowGreen, _HighGreen
                      : integer);
  end;

var
  PConnect: TZConnection;
  PQuery: TZQuery;
  left, right: TIdHeat;


  function ConfigPostgresSetting(InData: bool): bool;
  function SqlReadCurrentHeat: bool;
  function ViewCurrentData: bool;
  function ReadLastHeat(InTid, InSide: integer): integer;

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
        SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end
  else
  begin
      FreeAndNil(PQuery);
      FreeAndNil(PConnect);
  end;
end;


function SqlReadCurrentHeat: bool;
var
  i: integer;
begin

  for i := 0 to 1 do
  begin
    // side left=0, side right=1
    PQuery.Close;
    PQuery.sql.Clear;
    PQuery.sql.Add('select t1.tid, t1.heat, t1.strength_class, t1.section,');
    PQuery.sql.Add('t1.temperature, t1.timestamp,');
    PQuery.sql.Add('t2.grade, t2.standard, t2.c, t2.mn, t2.cr, t2.si, t2.b,');
    PQuery.sql.Add('cast(t2.c+(mn/6)+(cr/5)+((si+b)/10) as numeric(4,2))||'' (''||t4.ce_category||'')'' as ce,');
    PQuery.sql.Add('t3.low as low_red, t3.high as high_red, t4.low as low_green, t4.high as high_green');
    PQuery.sql.Add('FROM temperature_current t1');
    PQuery.sql.Add('LEFT OUTER JOIN');
    PQuery.sql.Add('chemical_analysis t2');
    PQuery.sql.Add('on t1.heat=t2.heat');
    PQuery.sql.Add('LEFT OUTER JOIN');
    PQuery.sql.Add('calculated_data t3');
    PQuery.sql.Add('on t1.tid=t3.cid');
    PQuery.sql.Add('and t3.step = 0');
    PQuery.sql.Add('LEFT OUTER JOIN');
    PQuery.sql.Add('calculated_data t4');
    PQuery.sql.Add('on t1.tid=t4.cid');
    PQuery.sql.Add('and t4.step = 1');
    PQuery.sql.Add('where t1.side='+inttostr(i)+'');
    PQuery.sql.Add('order by t1.timestamp desc LIMIT 1');
    PQuery.Open;

    if i = 0 then
    begin
      left.tid := PQuery.FieldByName('tid').AsInteger;
      left.Heat := PQuery.FieldByName('heat').AsString;
      left.Grade := PQuery.FieldByName('grade').AsString;
      left.StrengthClass := PQuery.FieldByName('strength_class').AsString;
      left.Section := PQuery.FieldByName('section').AsString;
      left.Standard := PQuery.FieldByName('standard').AsString;

      left.c := PQuery.FieldByName('c').AsString;
      left.mn := PQuery.FieldByName('mn').AsString;
      left.cr := PQuery.FieldByName('cr').AsString;
      left.si := PQuery.FieldByName('si').AsString;
      left.b := PQuery.FieldByName('b').AsString;
      left.ce := PQuery.FieldByName('ce').AsString;

      left.temperature := PQuery.FieldByName('temperature').AsInteger;
      left.timestamp := PQuery.FieldByName('timestamp').AsInteger;
      left.LowRed := PQuery.FieldByName('low_red').AsInteger;
      left.HighRed := PQuery.FieldByName('high_red').AsInteger;
      left.LowGreen := PQuery.FieldByName('low_green').AsInteger;
      left.HighGreen := PQuery.FieldByName('high_green').AsInteger;

      if  left.old_tid = 0 then
        left.old_tid := ReadLastHeat(left.tid, i);

      // новая плавка устанавливаем маркер
      if left.old_tid <> left.tid then
      begin
        left.old_tid := left.tid;
        left.marker := true;
        left.LowRed := 0;
        left.HighRed := 0;
        left.LowGreen := 0;
        left.HighGreen := 0;
      end;

    end
    else
    begin
      right.tid := PQuery.FieldByName('tid').AsInteger;
      right.Heat := PQuery.FieldByName('heat').AsString;
      right.Grade := PQuery.FieldByName('grade').AsString;
      right.StrengthClass := PQuery.FieldByName('strength_class').AsString;
      right.Section := PQuery.FieldByName('section').AsString;
      right.Standard := PQuery.FieldByName('standard').AsString;

      right.c := PQuery.FieldByName('c').AsString;
      right.mn := PQuery.FieldByName('mn').AsString;
      right.cr := PQuery.FieldByName('cr').AsString;
      right.si := PQuery.FieldByName('si').AsString;
      right.b := PQuery.FieldByName('b').AsString;
      right.ce := PQuery.FieldByName('ce').AsString;

      right.temperature := PQuery.FieldByName('temperature').AsInteger;
      right.timestamp := PQuery.FieldByName('timestamp').AsInteger;
      right.LowRed := PQuery.FieldByName('low_red').AsInteger;
      right.HighRed := PQuery.FieldByName('high_red').AsInteger;
      right.LowGreen := PQuery.FieldByName('low_green').AsInteger;
      right.HighGreen := PQuery.FieldByName('high_green').AsInteger;

      if right.old_tid = 0 then
        right.old_tid := ReadLastHeat(right.tid, i);

      // новая плавка устанавливаем маркер
      if right.old_tid <> right.tid then
      begin
        right.old_tid := right.tid;
        right.marker := true;
        right.LowRed := 0;
        right.HighRed := 0;
        right.LowGreen := 0;
        right.HighGreen := 0;
      end;

    end;

  end;


  ViewCurrentData;

  if left.marker then
  begin
      left.marker := false;
      ShowTrayMessage('информация','новая плавка: '+left.heat,1);
  end;

  if right.marker then
  begin
      right.marker := false;
      ShowTrayMessage('информация','новая плавка: '+right.heat,1);
  end;
end;


function ViewCurrentData: bool;
begin
  // side left
  form1.l_global_left.Caption := 'плавка: ' + left.Heat + ' | ' + 'марка: ' +
    left.Grade + ' | ' + 'класс прочности: ' + left.StrengthClass + ' | ' +
    'профиль: ' + left.Section + ' | ' + 'стандарт: ' + left.Standard;
  form1.l_chemical_left.Caption := 'химический анализ' + #9 + 'C: ' + left.c +
    ' | ' + 'Mn: ' + left.mn + ' | ' + 'Si: ' + left.si + ' | ' +
    'Cr: ' + left.cr + ' | ' + 'B: ' + left.b + ' | ' + 'Ce: ' + left.ce;

  // side right
  form1.l_global_right.Caption := 'плавка: ' + right.Heat + ' | ' + 'марка: ' +
    right.Grade + ' | ' + 'класс прочности: ' + right.StrengthClass + ' | ' +
    'профиль: ' + right.Section + ' | ' + 'стандарт: ' + right.Standard;
  form1.l_chemical_right.Caption := 'химический анализ' + #9 + 'C: ' + right.c +
    ' | ' + 'Mn: ' + right.mn + ' | ' + 'Si: ' + right.si + ' | ' +
    'Cr: ' + right.cr + ' | ' + 'B: ' + right.b + ' | ' + 'Ce: ' + right.ce;
end;


function ReadLastHeat(InTid, InSide: integer): integer;
var
  tid: integer;
begin
  try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('SELECT * FROM settings');
      SQuery.Open;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;

  while not SQuery.Eof do
  begin
      if SQuery.FieldByName('name').AsString = '::tid::side'+inttostr(InSide) then
          tid := SQuery.FieldByName('value').AsInteger;
        SQuery.Next;
  end;

  if tid <> InTid then
  begin
      try
          SQuery.Close;
          SQuery.SQL.Clear;
          SQuery.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
          SQuery.SQL.Add('VALUES (''::tid::side'+inttostr(InSide)+''',');
          SQuery.SQL.Add(''''+inttostr(InTid)+''')');
          SQuery.ExecSQL;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
      end;
      result := InTid;
  end
  else
      result := tid
end;


constructor TIdHeat.Create(_tid: integer; _Heat, _Grade, _Section, _Standard, _StrengthClass,
                      _c, _mn, _cr, _si, _b, _ce: string; _old_tid: integer; _marker: bool;
                      _temperature, _timestamp, _LowRed, _HighRed, _LowGreen, _HighGreen
                      : integer);
begin
    tid           := _tid;
    Heat          := _Heat; // плавка
    Grade         := _Grade; // марка стали
    Section       := _Section; // профиль
    Standard      := _Standard; // стандарт
    StrengthClass := _StrengthClass; // клас прочности
    c             := _c;
    mn            := _mn;
    cr            := _cr;
    si            := _si;
    b             := _b;
    ce            := _ce;
    old_tid       := _old_tid; // стара плавка
    marker        := _marker;
    temperature   := _temperature;
    timestamp     := _timestamp;
    LowRed        := _LowRed;
    HighRed       := _HighRed;
    LowGreen      := _LowGreen;
    HighGreen     := _HighGreen;
end;


// При загрузке программы класс будет создаваться
initialization
left := TIdHeat.Create(0,'','','','','','','','','','','',0,false,0,0,0,0,0,0);
right := TIdHeat.Create(0,'','','','','','','','','','','',0,false,0,0,0,0,0,0);

// При закрытии программы уничтожаться
finalization
FreeAndNil(left);
FreeAndNil(right);

end.
