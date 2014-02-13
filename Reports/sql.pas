unit sql;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Dialogs, Forms, Data.DB, ZAbstractDataset,
  ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset, ZStoredProcedure;

var
  PConnect: TZConnection;
  PQuery: TZQuery;
  DataSource: TDataSource;
  function ConfigPostgresSetting(InData: bool): bool;
  function SqlCalculatedData: bool;
  function SqlTemperature: bool;

implementation

uses
  main, settings;




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
        DataSource := TDataSource.Create(nil);
    except
      on E: Exception do
        Showmessage('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end
  else
  begin
      FreeAndNil(DataSource);
      FreeAndNil(PQuery);
      FreeAndNil(PConnect);
  end;
end;


function SqlCalculatedData: bool;
begin
  try
    PQuery.Close;
    PQuery.SQL.Clear;
    PQuery.SQL.Add('SELECT cast(to_char(TO_TIMESTAMP(t2.timestamp), ''YYYY-MM-DD HH24:MI:SS'') as varchar(20)) as timestamp');
    PQuery.SQL.Add(', t1.heat, t1.section');
    PQuery.SQL.Add(', cast(case t1.side when 0 then ''�����'' else ''������'' end as varchar(10)) as side');
    PQuery.SQL.Add(', cast(case t2.step when 0 then ''�������'' else ''�������'' end as varchar(10)) as step');
    PQuery.SQL.Add(', t2.coefficient_yield_point_value');
    PQuery.SQL.Add(', t2.coefficient_rupture_strength_value');
    PQuery.SQL.Add(', t2.heat_to_work');
    PQuery.SQL.Add(', t2.limit_rolled_products_min');
    PQuery.SQL.Add(', t2.limit_rolled_products_max');
    PQuery.SQL.Add(', cast(case t2.type_rolled_products when ''yield_point'' then');
    PQuery.SQL.Add('''������ ���������'' else ''��������� �������������'' end as varchar(30)) as type_rolled_products');
    PQuery.SQL.Add(', t2.mechanics_avg');
    PQuery.SQL.Add(', t2.mechanics_std_dev');
    PQuery.SQL.Add(', t2.mechanics_min');
    PQuery.SQL.Add(', t2.mechanics_max');
    PQuery.SQL.Add(', t2.mechanics_diff');
    PQuery.SQL.Add(', t2.coefficient_min');
    PQuery.SQL.Add(', t2.coefficient_max');
    PQuery.SQL.Add(', t2.temp_avg');
    PQuery.SQL.Add(', t2.temp_std_dev');
    PQuery.SQL.Add(', t2.temp_min');
    PQuery.SQL.Add(', t2.temp_max');
    PQuery.SQL.Add(', t2.temp_diff');
    PQuery.SQL.Add(', t2.r');
    PQuery.SQL.Add(', t2.adjustment_min');
    PQuery.SQL.Add(', t2.adjustment_max');
    PQuery.SQL.Add(', t2.low');
    PQuery.SQL.Add(', t2.high');
    PQuery.SQL.Add(', t2.ce_min_down');
    PQuery.SQL.Add(', t2.ce_min_up');
    PQuery.SQL.Add(', t2.ce_max_down');
    PQuery.SQL.Add(', t2.ce_max_up');
    PQuery.SQL.Add(', t2.ce_avg');
    PQuery.SQL.Add(', t2.ce_avg_down');
    PQuery.SQL.Add(', t2.ce_avg_up');
    PQuery.SQL.Add(', t2.ce_category');
    PQuery.SQL.Add('from temperature_current t1');
    PQuery.SQL.Add('INNER JOIN');
    PQuery.SQL.Add('calculated_data t2');
    PQuery.SQL.Add('on t1.tid=t2.cid');
    if trim(form1.e_heat.Text) <> '' then
        PQuery.SQL.Add('where t1.heat = '''+trim(form1.e_heat.Text)+'''');
    PQuery.SQL.Add('order by t1.tid desc, t2.step asc');
    PQuery.Open;
  except
    on E: Exception do
      Showmessage('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;


function SqlTemperature: bool;
begin
  try
    PQuery.Close;
    PQuery.SQL.Clear;
    PQuery.SQL.Add('SELECT cast(to_char(TO_TIMESTAMP(t2.timestamp), ''YYYY-MM-DD HH24:MI:SS'') as varchar(20)) as timestamp');
    PQuery.SQL.Add(', t1.heat, t1.section');
    PQuery.SQL.Add(', cast(case t1.side when 0 then ''�����'' else ''������'' end as varchar(10)) as side');
    PQuery.SQL.Add(', t2.temperature');
    PQuery.SQL.Add('from temperature_current t1');
    PQuery.SQL.Add('INNER JOIN');
    PQuery.SQL.Add('temperature_historical t2');
    PQuery.SQL.Add('on t1.tid=t2.tid');
    PQuery.SQL.Add('where t1.heat = '''+trim(form1.e_heat.Text)+'''');
    PQuery.SQL.Add('order by t1.tid desc');
    PQuery.Open;
  except
    on E: Exception do
      Showmessage('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;




end.

