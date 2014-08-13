unit sql;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, mssqlconn, sqldblib, ZConnection, ZDataset,
  ZCompatibility, DateUtils, FileUtil;

{type

end;}

var
  OraQuery: TZQuery;
  OraConnect: TZConnection;
  MSDBLibraryLoader: TSQLDBLibraryLoader;
  MSConnection: TMSSQLConnection;
  MSQuery: TSQLQuery;
  MSTransaction: TSQLTransaction;

//  {$DEFINE DEBUG}

  function ConfigOracleSetting(InData: boolean): boolean;
  function ConfigMsSetting(InData: boolean): boolean;
  function ReadSaveOldData(InData, InRollingMill, InSide: string): boolean;
  function SqlGetCurrentHeat: boolean;
  function SqlCurrentData(InSide: integer): boolean;
  function GetChemicalAnalysis(InHeat: string; InSide: integer): boolean;


implementation

uses
    settings, gui, thread_heat;


function ConfigOracleSetting(InData: boolean): boolean;
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
        OraSqlSettings.configured := false;
        FreeAndNil(OraConnect);
        FreeAndNil(OraQuery);
  end;
end;


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
         MsSqlSettings.configured := true;
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end
  else
  begin
      MsSqlSettings.configured := false;
      FreeAndNil(MSDBLibraryLoader);
      FreeAndNil(MSConnection);
      FreeAndNil(MSQuery);
      FreeAndNil(MSTransaction);
  end;
end;


function ReadSaveOldData(InData, InRollingMill, InSide: string): boolean;
var
  SQueryRSOH: TZQuery;
begin
  SQueryRSOH := TZQuery.Create(nil);
  SQueryRSOH.Connection := SConnect;

  if InData = 'read' then begin
    try
       SQueryRSOH.Close;
       SQueryRSOH.SQL.Clear;
       SQueryRSOH.SQL.Add('SELECT * FROM settings');
       SQueryRSOH.Open;
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
    end;

    while not SQueryRSOH.Eof do
    begin
       if SQueryRSOH.FieldByName('name').AsString =
          '::heat::rm'+InRollingMill+'::side'+InSide then begin
          if InSide = '0' then
             left.old_tid := SQueryRSOH.FieldByName('value').AsInteger
          else
             right.old_tid := SQueryRSOH.FieldByName('value').AsInteger
       end;

       if SQueryRSOH.FieldByName('name').AsString =
          '::marker::rm'+InRollingMill+'::side'+InSide then begin
          if InSide = '0' then
             left.marker := strtoint(SQueryRSOH.FieldByName('value').AsString)
          else
             right.marker := strtoint(SQueryRSOH.FieldByName('value').AsString);
       end;

       SQueryRSOH.Next;
    end;
  end else begin
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::heat::rm'+InRollingMill+'::side'+InSide+''',');
        if InSide = '0' then
           SQueryRSOH.SQL.Add(''''+inttostr(left.old_tid)+''')')
        else
           SQueryRSOH.SQL.Add(''''+inttostr(right.old_tid)+''')');
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
    end;
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::marker::rm'+InRollingMill+'::side'+InSide+''',');
        if InSide = '0' then
           SQueryRSOH.SQL.Add(''''+inttostr(left.marker)+''')')
        else
           SQueryRSOH.SQL.Add(''''+inttostr(right.marker)+''')');
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
    end;
  end;

  FreeAndNil(SQueryRSOH);
end;


function SqlGetCurrentHeat: boolean;
begin
  try
	MSQuery.PacketRecords := -1;  //FetchAll

	MSDBLibraryLoader.Enabled := true;
	MSConnection.Connected := true;
	MSQuery.Close;
	MSQuery.SQL.Clear;
	MSQuery.SQL.Add('select top 2 * from temperature_current');
	MSQuery.SQL.Add('where rolling_mill='+rolling_mill+'');
	MSQuery.SQL.Add('and side in (0,1)');
	MSQuery.SQL.Add('order by timestamp desc');
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQuery.SQL.Text -> '+MSQuery.SQL.Text);
{$ENDIF}
	MSQuery.Open;
  except
	on E: Exception do
	  SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

  while not MSQuery.EOF do begin
    if MSQuery.FieldByName('side').AsInteger = 0 then begin
      left.tid := MSQuery.FieldByName('tid').AsInteger;
      left.Heat := MSQuery.FieldByName('heat').AsString;
      left.Grade := MSQuery.FieldByName('grade').AsString;
      left.StrengthClass := MSQuery.FieldByName('strength_class').AsString;
      left.Section := MSQuery.FieldByName('section').AsString;
      left.Standard := MSQuery.FieldByName('standard').AsString;
      left.temperature := MSQuery.FieldByName('temperature').AsInteger;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'left tid -> '+MSQuery.FieldByName('tid').AsString);
  SaveLog.Log(etDebug, 'left heat -> '+UTF8Decode(MSQuery.FieldByName('heat').AsString));
  SaveLog.Log(etDebug, 'left grade -> '+UTF8Decode(MSQuery.FieldByName('grade').AsString));
  SaveLog.Log(etDebug, 'left strength_class -> '+UTF8Decode(MSQuery.FieldByName('strength_class').AsString));
  SaveLog.Log(etDebug, 'left section -> '+UTF8Decode(MSQuery.FieldByName('section').AsString));
  SaveLog.Log(etDebug, 'left temperature -> '+UTF8Decode(MSQuery.FieldByName('temperature').AsString));
{$ENDIF}
    end else begin
      right.tid := MSQuery.FieldByName('tid').AsInteger;
      right.Heat := MSQuery.FieldByName('heat').AsString;
      right.Grade := MSQuery.FieldByName('grade').AsString;
      right.StrengthClass := MSQuery.FieldByName('strength_class').AsString;
      right.Section := MSQuery.FieldByName('section').AsString;
      right.Standard := MSQuery.FieldByName('standard').AsString;
      right.temperature := MSQuery.FieldByName('temperature').AsInteger;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'right tid -> '+MSQuery.FieldByName('tid').AsString);
  SaveLog.Log(etDebug, 'right heat -> '+UTF8Decode(MSQuery.FieldByName('heat').AsString));
  SaveLog.Log(etDebug, 'right grade -> '+UTF8Decode(MSQuery.FieldByName('grade').AsString));
  SaveLog.Log(etDebug, 'right strength_class -> '+UTF8Decode(MSQuery.FieldByName('strength_class').AsString));
  SaveLog.Log(etDebug, 'right section -> '+UTF8Decode(MSQuery.FieldByName('section').AsString));
  SaveLog.Log(etDebug, 'right temperature -> '+UTF8Decode(MSQuery.FieldByName('temperature').AsString));
{$ENDIF}
    end;
    MSQuery.Next;
  end;
end;


function SqlCurrentData(InSide: integer): boolean;
begin
  try
	MSQuery.PacketRecords := -1;  //FetchAll

	MSDBLibraryLoader.Enabled := true;
	MSConnection.Connected := true;
	MSQuery.Close;
	MSQuery.SQL.Clear;
	MSQuery.SQL.Add('select step, low, high');
        MSQuery.SQL.Add(', cast(case ce_category when ''min'' then ''мин''');
        MSQuery.SQL.Add('when ''max'' then ''мах'' when ''avg'' then ''сред''');
        MSQuery.SQL.Add('end as nvarchar(10)) as ce_category');
	MSQuery.SQL.Add('from calculated_data');
        if InSide = 0 then
           MSQuery.SQL.Add('where cid='+inttostr(left.tid)+'')
        else
           MSQuery.SQL.Add('where cid='+inttostr(right.tid)+'');
{{$IFDEF DEBUG}
  MSQuery.SQL.Add('where cid=1403261908');
{$ENDIF}}
      	MSQuery.SQL.Add('and rolling_mill='+rolling_mill+'');
	MSQuery.SQL.Add('and side='+inttostr(InSide)+'');
	MSQuery.SQL.Add('order by timestamp desc');
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQuery.SQL.Text -> '+UTF8Decode(MSQuery.SQL.Text));
{$ENDIF}
	MSQuery.Open;
  except
	on E: Exception do
	  SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

  while not MSQuery.EOF do begin
       if MSQuery.FieldByName('step').AsInteger = 0 then begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'step -> '+MSQuery.FieldByName('step').AsString);
{$ENDIF}
          if Inside = 0 then begin
             if not MSQuery.FieldByName('low').IsNull then
                left.LowRed := MSQuery.FieldByName('low').AsInteger;
             if not MSQuery.FieldByName('high').IsNull then
	        left.HighRed := MSQuery.FieldByName('high').AsInteger;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'side -> '+inttostr(InSide));
  SaveLog.Log(etDebug, 'left LowRed -> '+MSQuery.FieldByName('low').AsString);
  SaveLog.Log(etDebug, 'left HighRed -> '+MSQuery.FieldByName('high').AsString);
{$ENDIF}
          end else begin
             if not MSQuery.FieldByName('low').IsNull then
                right.LowRed := MSQuery.FieldByName('low').AsInteger;
             if not MSQuery.FieldByName('high').IsNull then
 	        right.HighRed := MSQuery.FieldByName('high').AsInteger;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'side -> '+inttostr(InSide));
  SaveLog.Log(etDebug, 'right LowRed -> '+MSQuery.FieldByName('low').AsString);
  SaveLog.Log(etDebug, 'right HighRed -> '+MSQuery.FieldByName('high').AsString);
{$ENDIF}
          end;
       end else begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'step -> '+MSQuery.FieldByName('step').AsString);
{$ENDIF}
          if Inside = 0 then begin
             if not MSQuery.FieldByName('low').IsNull then
                left.LowGreen := MSQuery.FieldByName('low').AsInteger;
             if not MSQuery.FieldByName('high').IsNull then
                left.HighGreen := MSQuery.FieldByName('high').AsInteger;
             if not MSQuery.FieldByName('ce_category').IsNull then
                left.ce_category := '('+MSQuery.FieldByName('ce_category').AsString+')';
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'side -> '+inttostr(InSide));
  SaveLog.Log(etDebug, 'left LowGreen -> '+MSQuery.FieldByName('low').AsString);
  SaveLog.Log(etDebug, 'left HighGreen -> '+MSQuery.FieldByName('high').AsString);
{$ENDIF}
          end else begin
             if not MSQuery.FieldByName('low').IsNull then
                right.LowGreen := MSQuery.FieldByName('low').AsInteger;
             if not MSQuery.FieldByName('high').IsNull then
                right.HighGreen := MSQuery.FieldByName('high').AsInteger;
             if not MSQuery.FieldByName('ce_category').IsNull then
                right.ce_category := '('+MSQuery.FieldByName('ce_category').AsString+')';
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'side -> '+inttostr(InSide));
  SaveLog.Log(etDebug, 'right LowGreen -> '+MSQuery.FieldByName('low').AsString);
  SaveLog.Log(etDebug, 'right HighGreen -> '+MSQuery.FieldByName('high').AsString);
{$ENDIF}
          end;
       end;
       MSQuery.Next;
  end;

end;


function GetChemicalAnalysis(InHeat: string; InSide: integer): boolean;
begin
  try
      OraQuery.Close;
      OraQuery.SQL.Clear;
      OraQuery.SQL.Add('select DATE_IN_HIM');
      OraQuery.SQL.Add(', NPL, MST, GOST, C, MN, SI, S, CR, B,');
      OraQuery.SQL.Add('cast(c+(mn/6)+(cr/5)+((si+b)/10) as numeric(4,2)) as ce');
      OraQuery.SQL.Add('from him_steel');
      OraQuery.SQL.Add('where DATE_IN_HIM>=sysdate-300'); //-- 300 = 10 month
      OraQuery.SQL.Add('and NUMBER_TEST=''0''');
      OraQuery.SQL.Add('and NPL in ('''+InHeat+''')');
      OraQuery.SQL.Add('order by DATE_IN_HIM desc');
      OraQuery.Open;
  except
    on E : Exception do
      begin
        SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
        ConfigOracleSetting(false);
        exit;
      end;
  end;

  //если находим
  if not OraQuery.FieldByName('NPL').IsNull then
  begin
       if InSide = 0 then begin
          left.c := OraQuery.FieldByName('c').AsString;
          left.mn := OraQuery.FieldByName('mn').AsString;
          left.cr := OraQuery.FieldByName('cr').AsString;
          left.si := OraQuery.FieldByName('si').AsString;
          left.b := OraQuery.FieldByName('b').AsString;
          left.ce := OraQuery.FieldByName('ce').AsString;
       end else begin
          right.c := OraQuery.FieldByName('c').AsString;
          right.mn := OraQuery.FieldByName('mn').AsString;
          right.cr := OraQuery.FieldByName('cr').AsString;
          right.si := OraQuery.FieldByName('si').AsString;
          right.b := OraQuery.FieldByName('b').AsString;
          right.ce := OraQuery.FieldByName('ce').AsString;
       end;

       SaveLog.Log(etInfo, 'chemical analysis heat -> '+InHeat+
               OraQuery.FieldByName('c').AsString+#9+OraQuery.FieldByName('mn').AsString+#9+
               OraQuery.FieldByName('cr').AsString+#9+OraQuery.FieldByName('si').AsString+#9+
               OraQuery.FieldByName('b').AsString+#9+OraQuery.FieldByName('ce').AsString);
  end;
end;



end.

