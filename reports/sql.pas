unit sql;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, mssqlconn, sqldblib, ZConnection, ZDataset,
  ZCompatibility, DateUtils, FileUtil, db;

type
  TArrayArrayVariant = array of array of variant;


var
{  OraQuery: TZQuery;
  OraConnect: TZConnection;}
  MSDBLibraryLoader: TSQLDBLibraryLoader;
  MSConnection: TMSSQLConnection;
  MSQuery: TSQLQuery;
  MSTransaction: TSQLTransaction;
  DataSource: TDataSource;

  {$DEFINE DEBUG}

{  function ConfigOracleSetting(InData: boolean): boolean;}
  function ConfigMsSetting(InData: boolean): boolean;
  function SqlCalculatedData: boolean;
  function SqlTemperature: boolean;

implementation

uses
    settings, gui;


{function ConfigOracleSetting(InData: boolean): boolean;
var
  ConnectString : String;
begin
  if InData then
  begin
        OraConnect := TZConnection.Create(nil);
        OraQuery := TZQuery.Create(nil);

      try
         ConnectString:='(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = '
                +OraSqlSettings.ip+')(PORT = '+inttostr(OraSqlSettings.port)
                +'))) (CONNECT_DATA = (SERVICE_NAME = '+
                OraSqlSettings.db_name+')))';
         OraConnect.Database := ConnectString;
         OraConnect.LibraryLocation := '.\oci.dll';// отказался от полных путей не читает
         OraConnect.Protocol := 'oracle';
         OraConnect.User := OraSqlSettings.user;
         OraConnect.Password := OraSqlSettings.password;
         OraConnect.AutoEncodeStrings := true;// перекодировка с сервера в клиент
         OraConnect.ClientCodepage := 'CL8MSWIN1251';// кодировка на сервере
         OraConnect.ControlsCodePage := cCP_UTF8;// кодировка на клиенте
         // or
{         OraConnect.Properties.Add('AutoEncodeStrings=ON');// перекодировка с сервера в клиент
         OraConnect.Properties.Add('codepage=CL8MSWIN1251"');// кодировка на сервере
         OraConnect.Properties.Add('controls_cp=CP_UTF8');// кодировка на клиенте}
         OraConnect.Connect;
         OraQuery.Connection := OraConnect;
         OraSqlSettings.configured := true;
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      end;
  end
  else
  begin
        FreeAndNil(OraConnect);
        FreeAndNil(OraQuery);
  end;
end;}


function ConfigMsSetting(InData: boolean): boolean;
begin
  if InData then
  begin
      try
         MSDBLibraryLoader := TSQLDBLibraryLoader.Create(nil);
         MSConnection := TMSSQLConnection.Create(nil);
         MSQuery := TSQLQuery.Create(nil);
         MSTransaction := TSQLTransaction.Create(nil);

         MSDBLibraryLoader.ConnectionType := 'MSSQLServer';
         MSDBLibraryLoader.LibraryName := '.\'+MsSqlSettings.lib;

         MSConnection.DatabaseName := MsSqlSettings.db_name;

         MSConnection.HostName := MsSqlSettings.ip;
         MSConnection.Transaction := MSTransaction;
         MSConnection.CharSet := 'UTF-8';
         MSConnection.Params.Add('AutoCommit=true');

         MSTransaction.DataBase := MSConnection;
         MSTransaction.Action := caCommit;

         MSQuery.DataBase := MSConnection;
         MSQuery.Transaction := MSTransaction;

         DataSource := TDataSource.Create(nil);
         MsSqlSettings.configured := true;
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end
  else
  begin
      FreeAndNil(DataSource);
      FreeAndNil(MSDBLibraryLoader);
      FreeAndNil(MSConnection);
      FreeAndNil(MSQuery);
      FreeAndNil(MSTransaction);
  end;
end;

function SqlCalculatedData: boolean;
begin
  try
    MSQuery.PacketRecords := -1;  //FetchAll

    MSDBLibraryLoader.Enabled := true;
    MSConnection.Connected := true;
    MSQuery.Close;
    MSQuery.SQL.Clear;
    MSQuery.SQL.Add('SELECT dateadd(s, t1.timestamp, ''01/01/1970'') as timestamp');
    MSQuery.SQL.Add(', t1.heat, t1.section');
    MSQuery.SQL.Add(', cast(''МС 250-'' as nvarchar(10))+cast(t1.rolling_mill as nvarchar(10)) as rolling_mill');
    MSQuery.SQL.Add(', cast(case t1.side when 0 then ''Левая'' else ''Правая'' end as nvarchar(10)) as side');
    MSQuery.SQL.Add(', cast(case t2.step when 0 then ''Красный'' else ''Зеленый'' end as nvarchar(10)) as step');
    MSQuery.SQL.Add(', t2.coefficient_yield_point_value');
    MSQuery.SQL.Add(', t2.coefficient_rupture_strength_value');
    MSQuery.SQL.Add(', t2.heat_to_work');
    MSQuery.SQL.Add(', t2.limit_rolled_products_min');
    MSQuery.SQL.Add(', t2.limit_rolled_products_max');
    MSQuery.SQL.Add(', cast(case t2.type_rolled_products when ''yield_point'' then');
    MSQuery.SQL.Add('''предел текучести'' else ''временное сопротивление'' end as nvarchar(30)) as type_rolled_products');
    MSQuery.SQL.Add(', t2.mechanics_avg');
    MSQuery.SQL.Add(', t2.mechanics_std_dev');
    MSQuery.SQL.Add(', t2.mechanics_min');
    MSQuery.SQL.Add(', t2.mechanics_max');
    MSQuery.SQL.Add(', t2.mechanics_diff');
    MSQuery.SQL.Add(', t2.coefficient_min');
    MSQuery.SQL.Add(', t2.coefficient_max');
    MSQuery.SQL.Add(', t2.temp_avg');
    MSQuery.SQL.Add(', t2.temp_std_dev');
    MSQuery.SQL.Add(', t2.temp_min');
    MSQuery.SQL.Add(', t2.temp_max');
    MSQuery.SQL.Add(', t2.temp_diff');
    MSQuery.SQL.Add(', t2.r');
    MSQuery.SQL.Add(', t2.adjustment_min');
    MSQuery.SQL.Add(', t2.adjustment_max');
    MSQuery.SQL.Add(', t2.low');
    MSQuery.SQL.Add(', t2.high');
    MSQuery.SQL.Add(', t2.ce_min_down');
    MSQuery.SQL.Add(', t2.ce_min_up');
    MSQuery.SQL.Add(', t2.ce_max_down');
    MSQuery.SQL.Add(', t2.ce_max_up');
    MSQuery.SQL.Add(', t2.ce_avg');
    MSQuery.SQL.Add(', t2.ce_avg_down');
    MSQuery.SQL.Add(', t2.ce_avg_up');
    MSQuery.SQL.Add(', cast(case t2.ce_category when ''min'' then ''мин''');
    MSQuery.SQL.Add('when ''max'' then ''мах'' when ''avg'' then ''сред''');
    MSQuery.SQL.Add('end as nvarchar(10)) as ce_category');
    MSQuery.SQL.Add('from temperature_current t1');
    MSQuery.SQL.Add('INNER JOIN');
    MSQuery.SQL.Add('calculated_data t2');
    MSQuery.SQL.Add('on t1.tid=t2.cid');
    { поменять на выбраный стан }
    MSQuery.SQL.Add('and t1.rolling_mill=t2.rolling_mill');
    MSQuery.SQL.Add('and t1.side=t2.side');
    if trim(form1.e_heat.Text) <> '' then
        MSQuery.SQL.Add('where t1.heat = '''+trim(form1.e_heat.Text)+'''');
    MSQuery.SQL.Add('and t1.rolling_mill = '+rolling_mill+'');
    MSQuery.SQL.Add('order by t1.timestamp desc, t1.tid desc, t2.step asc');
    MSQuery.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;
end;


function SqlTemperature: boolean;
begin
  try
    MSQuery.PacketRecords := -1;  //FetchAll

    MSDBLibraryLoader.Enabled := true;
    MSConnection.Connected := true;
    MSQuery.Close;
    MSQuery.SQL.Clear;
    MSQuery.SQL.Add('SELECT dateadd(s, t2.timestamp, ''01/01/1970'') as timestamp');
    MSQuery.SQL.Add(', t1.heat, t1.section');
    MSQuery.SQL.Add(', cast(''МС 250-'' as nvarchar(10))+cast(t1.rolling_mill as nvarchar(10)) as rolling_mill');
    MSQuery.SQL.Add(', cast(case t1.side when 0 then ''Левая'' else ''Правая'' end as nvarchar(10)) as side');
    MSQuery.SQL.Add(', t2.temperature');
    MSQuery.SQL.Add('from temperature_current t1');
    MSQuery.SQL.Add('INNER JOIN');
    MSQuery.SQL.Add('temperature_historical t2');
    MSQuery.SQL.Add('on t1.tid=t2.tid');
    { поменять на выбраный стан }
    MSQuery.SQL.Add('and t1.rolling_mill=t2.rolling_mill');
    MSQuery.SQL.Add('and t1.side=t2.side');
    MSQuery.SQL.Add('where t1.heat = '''+trim(form1.e_heat.Text)+'''');
    MSQuery.SQL.Add('and t1.rolling_mill = '+rolling_mill+'');
    MSQuery.SQL.Add('and t1.side = '+side+'');
    MSQuery.SQL.Add('order by t1.tid desc');
    MSQuery.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;
end;





end.
