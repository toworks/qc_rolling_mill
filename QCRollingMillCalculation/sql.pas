unit sql;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, mssqlconn, sqldblib, ZConnection, ZDataset,
  ZCompatibility, DateUtils, FileUtil;

type
  TArrayArrayVariant = array of array of variant;


var
  OraQuery: TZQuery;
  OraConnect: TZConnection;
  MSDBLibraryLoader: TSQLDBLibraryLoader;
  MSConnection: TMSSQLConnection;
  MSQuery: TSQLQuery;
  MSTransaction: TSQLTransaction;

  {$DEFINE DEBUG}

  function ConfigOracleSetting(InData: boolean): boolean;
  function ConfigMsSetting(InData: boolean): boolean;

  function RolledMelting(InSide: integer): string;
  function SqlCarbonEquivalent(InHeat: string): TArrayArrayVariant;
  function CalculatedData(InSide: integer; InData: string): boolean;

implementation

uses
    settings, thread_calculated_data;


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


function RolledMelting(InSide: integer): string;
var
  i: integer;
  // -- Side - 1 правая - не четная, 2 левая - четная, сторона | мс5 0 лева 1 правая
  main : TIdHeat;
  heats: string;
  ReturnValue: string;
  MSQueryCalculation: TSQLQuery;
  c_min, c_max, mn_min, mn_max, si_min, si_max: real;
begin
  main := TIdHeat.Create;
  {$IFDEF DEBUG}
    SaveLog.Log(etDebug, 'empty main.Grade -> '+main.Grade);
    SaveLog.Log(etDebug, 'empty main.Section -> '+main.Section);
    SaveLog.Log(etDebug, 'empty main.Standard -> '+main.Standard);
    SaveLog.Log(etDebug, 'empty main.StrengthClass -> '+main.StrengthClass);
    SaveLog.Log(etDebug, 'empty main.RollingMill -> '+main.RollingMill);
    SaveLog.Log(etDebug, 'empty main.c -> '+main.c);
    SaveLog.Log(etDebug, 'empty main.mn    -> '+main.mn);
    SaveLog.Log(etDebug, 'empty main.si -> '+main.si);
  {$ENDIF}

  MSQueryCalculation := TSQLQuery.Create(nil);
  MSQueryCalculation.DataBase := MSConnection;
  MSQueryCalculation.Transaction := MSTransaction;
  MSQueryCalculation.PacketRecords := -1;  //FetchAll

  if InSide = 0 then
  begin
    main.Grade := left.Grade;
    main.Section := left.Section;
    main.Standard := left.Standard;
    main.StrengthClass := left.StrengthClass;
    main.RollingMill := left.RollingMill;
    main.c :=  left.c;
    main.mn := left.mn;
    main.si := left.si;
  end
  else
  begin
    main.Grade := right.Grade;
    main.Section := right.Section;
    main.Standard := right.Standard;
    main.StrengthClass := right.StrengthClass;
    main.RollingMill := right.RollingMill;
    main.c := right.c;
    main.mn := right.mn;
    main.si := right.si;
  end;

  try
     // определяем параметры текущей плавки
     MSDBLibraryLoader.Enabled := true;
     MSConnection.Connected := true;
     MSQueryCalculation.Close;
     MSQueryCalculation.sql.Clear;
     MSQueryCalculation.sql.Add('select * FROM technological_sample');
     MSQueryCalculation.sql.Add('where dbo.translate(strength_class, ');
     MSQueryCalculation.sql.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
     MSQueryCalculation.sql.Add('= dbo.translate('''+main.StrengthClass+''', ');
     MSQueryCalculation.sql.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
     MSQueryCalculation.sql.Add('and section_min <= '+main.Section+' and section_max >= '+main.Section+'');
     MSQueryCalculation.sql.Add('and c_min <= '+main.c+' and c_max >= '+main.c+'');
     MSQueryCalculation.sql.Add('and mn_min <= '+main.mn+' and mn_max >= '+main.mn+'');
     MSQueryCalculation.sql.Add('and si_min <= '+main.si+' and si_max >= '+main.si+'');
     MSQueryCalculation.sql.Add('and rolling_mill='+main.RollingMill+'');
     MSQueryCalculation.Open;
  except
   on E: Exception do
     SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculation.SQL.Text -> '+UTF8Decode(MSQueryCalculation.sql.Text));
{$ENDIF}

  if MSQueryCalculation.RecordCount >= 1 then begin
     if InSide = 0 then
        left.technological_sample := MSQueryCalculation.FieldByName('id').AsInteger
     else
        right.technological_sample := MSQueryCalculation.FieldByName('id').AsInteger;

     c_min := MSQueryCalculation.FieldByName('c_min').AsFloat;
     c_max := MSQueryCalculation.FieldByName('c_max').AsFloat;
     mn_min := MSQueryCalculation.FieldByName('mn_min').AsFloat;
     mn_max := MSQueryCalculation.FieldByName('mn_max').AsFloat;
     si_min := MSQueryCalculation.FieldByName('si_min').AsFloat;
     si_max := MSQueryCalculation.FieldByName('si_max').AsFloat;
  end else begin
     SaveLog.Log(etWarning, 'нет данных в таблице technological_sample');
     exit;
  end;

{$IFDEF DEBUG}
  if InSide = 0 then
  SaveLog.Log(etDebug, 'left.technological_sample -> '+inttostr(left.technological_sample))
  else
  SaveLog.Log(etDebug, 'right.technological_sample -> '+inttostr(right.technological_sample));
  SaveLog.Log(etDebug, 'c_min -> '+floattostr(c_min)+#9+'c_max -> '+floattostr(c_max)+#9+'mn_min -> '+floattostr(mn_min)+#9+
                       'mn_max -> '+floattostr(mn_max)+#9+'si_min -> '+floattostr(si_min)+#9+'si_max -> '+floattostr(si_max));
{$ENDIF}
  try
     // получаем все прокатанные плавки
     MSDBLibraryLoader.Enabled := true;
     MSConnection.Connected := true;
     MSQueryCalculation.Close;
     MSQueryCalculation.sql.Clear;
{     MSQueryCalculation.sql.Add('select * FROM temperature_current');}
     { OCI_ERROR: ORA-01795: maximum number of expressions IN a list is 1000 }
     MSQueryCalculation.sql.Add('select * FROM ('); //1000 но последних 10 плавок
     MSQueryCalculation.sql.Add('select top 1010 ROW_NUMBER() OVER(ORDER BY timestamp DESC) AS row_num, * FROM temperature_current');
     MSQueryCalculation.sql.Add('where dbo.translate(strength_class, ');
     MSQueryCalculation.sql.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
     MSQueryCalculation.sql.Add('= dbo.translate('''+main.StrengthClass+''', ');
     MSQueryCalculation.sql.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
     MSQueryCalculation.sql.Add('and section = '+main.Section+'');
     MSQueryCalculation.sql.Add('and side = '+inttostr(InSide)+'');
     MSQueryCalculation.sql.Add('and rolling_mill = '+main.RollingMill+'');
     MSQueryCalculation.sql.Add('order by timestamp desc) t1');
     MSQueryCalculation.sql.Add('where t1.row_num NOT BETWEEN 1 AND 10');
     MSQueryCalculation.Open;
  except
   on E: Exception do
     SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculation.SQL.Text -> '+UTF8Decode(MSQueryCalculation.sql.Text));
  SaveLog.Log(etDebug, 'MSQueryCalculation.RecordCount -> '+inttostr(MSQueryCalculation.RecordCount));
{$ENDIF}

  if MSQueryCalculation.RecordCount >= 1 then begin
     i := 0;
     while not MSQueryCalculation.Eof do
     begin
          inc(i);
          if not (i = MSQueryCalculation.RecordCount) then
             heats := heats+''''+MSQueryCalculation.FieldByName('heat').AsString+''','
          else
              heats := heats+''''+MSQueryCalculation.FieldByName('heat').AsString+'''';
          MSQueryCalculation.Next;
     end;
  end else begin
     SaveLog.Log(etWarning, 'нет данных по плавкам в таблице temperature_current');
     exit;
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'heats -> '+heats);
  SaveLog.Log(etDebug, 'count -> '+inttostr(i));
{$ENDIF}

  try
     OraQuery.Close;
     OraQuery.SQL.Clear;
     OraQuery.SQL.Add('select DATE_IN_HIM');
     OraQuery.SQL.Add(', NPL, MST, GOST, C, MN, SI, S, CR, B');
     OraQuery.SQL.Add('from him_steel');
     OraQuery.SQL.Add('where DATE_IN_HIM>=sysdate-300'); //-- 300 = 10 month
     OraQuery.SQL.Add('and NUMBER_TEST=''0''');
     OraQuery.SQL.Add('and NPL in ('+heats+')');
     OraQuery.SQL.Add('order by DATE_IN_HIM desc');
     OraQuery.Open;
     OraQuery.FetchAll;
  except
   on E: Exception do
   begin
     SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
     ConfigOracleSetting(false);
        if InSide = 0 then
           left.marker := 0
        else
           right.marker := 0;
        ReadSaveOldData('save', main.RollingMill, inttostr(InSide));
     exit;
   end;
  end;

  i := 0;
  while not OraQuery.Eof do
  begin
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'NPL -> '+OraQuery.FieldByName('NPL').AsString);
  SaveLog.Log(etDebug, 'MST -> '+UTF8Decode(OraQuery.FieldByName('MST').AsString));
  SaveLog.Log(etDebug, 'c_min = '+floattostr(c_min)+' c = '+floattostr(OraQuery.FieldByName('c').AsFloat)+' c_max = '+floattostr(c_max));
  SaveLog.Log(etDebug, 'mn_min = '+floattostr(mn_min)+' mn = '+floattostr(OraQuery.FieldByName('mn').AsFloat)+' mn_max = '+floattostr(mn_max));
  SaveLog.Log(etDebug, 'si_min = '+floattostr(si_min)+' si = '+floattostr(OraQuery.FieldByName('si').AsFloat)+' si_max = '+floattostr(si_max));
{$ENDIF}}
      // получение прокатаных плавок не больше 125 или согласно плавки
      if (c_min <= OraQuery.FieldByName('c').AsFloat) and
         (c_max >= OraQuery.FieldByName('c').AsFloat) and
         (mn_min <= OraQuery.FieldByName('mn').AsFloat) and
         (mn_max >= OraQuery.FieldByName('mn').AsFloat) and
         (si_min <= OraQuery.FieldByName('si').AsFloat) and
         (si_max >= OraQuery.FieldByName('si').AsFloat) then begin
             ReturnValue := ReturnValue+''''+OraQuery.FieldByName('NPL').AsString+''',';
             inc(i);
             if i >= 125 then
                break;
      end;
      OraQuery.Next;
   end;

   if i > 5 then
      delete(ReturnValue, Length(ReturnValue),1)
   else
      SetLength(ReturnValue, 0);

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'heat oracle count -> '+inttostr(i));
  SaveLog.Log(etDebug, 'heat -> '+ReturnValue);
{$ENDIF}

  FreeAndNil(MSQueryCalculation);
  FreeAndNil(main);
  Result := ReturnValue;
end;


function SqlCarbonEquivalent(InHeat: string): TArrayArrayVariant;
var
  i: integer;
  HeatCeArray: TArrayArrayVariant;
begin
  try
     OraQuery.Close;
     OraQuery.SQL.Clear;
     OraQuery.SQL.Add('select NPL as heat');
     OraQuery.SQL.Add(', C+(MN/6)+(CR/5)+((SI+B)/10) as ce');
     OraQuery.SQL.Add('from him_steel');
     OraQuery.SQL.Add('where DATE_IN_HIM>=sysdate-300'); //-- 300 = 10 month
     OraQuery.SQL.Add('and NUMBER_TEST=''0''');
     OraQuery.SQL.Add('and NPL in ('+InHeat+')');
     OraQuery.SQL.Add('order by DATE_IN_HIM desc');
     OraQuery.Open;
     OraQuery.FetchAll;
  except
   on E: Exception do
   begin
     SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
     ConfigOracleSetting(false);
     exit;
   end;
  end;

{{  PQueryCe.Close;
  PQueryCe.Sql.Clear;
  PQueryCe.Sql.Add('select heat, c+(mn/6)+(cr/5)+((si+b)/10) as ce');
  PQueryCe.Sql.Add('from chemical_analysis');
  PQueryCe.Sql.Add('where heat in ('+InHeat+')');
  PQueryCe.Sql.Add('order by timestamp desc');
  PQueryCe.Open;}}

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'ce -> OraQuery.SQL.Text -> ' + UTF8Decode(OraQuery.sql.Text));
{$ENDIF}

  i := 0;
  while not OraQuery.Eof do
  begin
    if i = Length(HeatCeArray) then
      SetLength(HeatCeArray, i + 1, 2);
    HeatCeArray[i, 0] := OraQuery.FieldByName('heat').AsString;
    HeatCeArray[i, 1] := OraQuery.FieldByName('ce').AsFloat;
    inc(i);
    OraQuery.Next;
  end;

  for i := Low(HeatCeArray) to High(HeatCeArray) do
  begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'heat for ce -> ' + HeatCeArray[i, 0]);
  SaveLog.Log(etDebug, 'ce -> ' + floattostr(HeatCeArray[i, 1]));
{$ENDIF}
  end;

  Result := HeatCeArray;
end;


function CalculatedData(InSide: integer; InData: string): boolean;
var
  MSQueryCalculatedData: TSQLQuery;
  main : TIdHeat;
begin
  main := TIdHeat.Create;

  MSQueryCalculatedData := TSQLQuery.Create(nil);
  MSQueryCalculatedData.DataBase := MSConnection;
  MSQueryCalculatedData.Transaction := MSTransaction;
  MSQueryCalculatedData.PacketRecords := -1;  //FetchAll

  if InSide = 0 then
  begin
    main.Heat := left.Heat;
    main.step := left.step;
    main.RollingMill := left.RollingMill;
  end
  else
  begin
    main.Heat := right.Heat;
    main.step := right.step;
    main.RollingMill := right.RollingMill;
  end;

  MSDBLibraryLoader.Enabled := true;
  MSConnection.Connected := true;
  MSQueryCalculatedData.Close;
  MSQueryCalculatedData.sql.Clear;
  MSQueryCalculatedData.sql.Add('select TOP 1 tid FROM temperature_current');
  MSQueryCalculatedData.sql.Add('where heat='''+main.Heat+'''');
  MSQueryCalculatedData.sql.Add('and rolling_mill='+main.RollingMill+'');
  MSQueryCalculatedData.sql.Add('and side='+inttostr(InSide)+'');
  MSQueryCalculatedData.sql.Add('ORDER BY timestamp desc');
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculatedData temperature_current -> '+MSQueryCalculatedData.sql.Text);
{$ENDIF}}
  MSQueryCalculatedData.Open;

  main.tid := MSQueryCalculatedData.FieldByName('tid').AsInteger;

  // delete report recalculated
  if InData = '' then
  begin
    MSDBLibraryLoader.Enabled := true;
    MSConnection.Connected := true;
    MSQueryCalculatedData.Close;
    MSQueryCalculatedData.sql.Clear;
    MSQueryCalculatedData.sql.Add('DELETE FROM calculated_data');
    MSQueryCalculatedData.sql.Add('where cid='+inttostr(main.tid)+'');
    MSQueryCalculatedData.sql.Add('and rolling_mill='+main.RollingMill+'');
    MSQueryCalculatedData.sql.Add('and side='+inttostr(InSide)+'');
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculatedData DELETE -> '+MSQueryCalculatedData.sql.Text);
{$ENDIF}}
    MSQueryCalculatedData.ExecSQL;
    exit;
  end;

  MSDBLibraryLoader.Enabled := true;
  MSConnection.Connected := true;
  MSQueryCalculatedData.Close;
  MSQueryCalculatedData.sql.Clear;
  MSQueryCalculatedData.sql.Add('select cid FROM calculated_data');
  MSQueryCalculatedData.sql.Add('where cid='+inttostr(main.tid)+'');
  MSQueryCalculatedData.sql.Add('and rolling_mill='+main.RollingMill+'');
  MSQueryCalculatedData.sql.Add('and side='+inttostr(InSide)+'');
  MSQueryCalculatedData.sql.Add('and step='+inttostr(main.step)+'');
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculatedData calculated_data -> '+MSQueryCalculatedData.sql.Text);
{$ENDIF}}
  MSQueryCalculatedData.Open;

  if MSQueryCalculatedData.FieldByName('cid').IsNull then
  begin
    MSDBLibraryLoader.Enabled := true;
    MSConnection.Connected := true;
    MSQueryCalculatedData.Close;
    MSQueryCalculatedData.sql.Clear;
    MSQueryCalculatedData.sql.Add('INSERT INTO calculated_data (cid, rolling_mill,');
    MSQueryCalculatedData.sql.Add('side, step)');
    MSQueryCalculatedData.sql.Add('VALUES ('+inttostr(main.tid)+', '+main.RollingMill+',');
    MSQueryCalculatedData.sql.Add(''+inttostr(InSide)+', '+inttostr(main.step)+')');
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculatedData INSERT -> '+MSQueryCalculatedData.sql.Text);
{$ENDIF}}
    MSQueryCalculatedData.ExecSQL;
  end;
//  else
  begin
    MSDBLibraryLoader.Enabled := true;
    MSConnection.Connected := true;
    MSQueryCalculatedData.Close;
    MSQueryCalculatedData.sql.Clear;
    MSQueryCalculatedData.sql.Add('UPDATE calculated_data SET ' + InData + '');
    MSQueryCalculatedData.sql.Add('where cid='+inttostr(main.tid)+'');
    MSQueryCalculatedData.sql.Add('and rolling_mill='+main.RollingMill+'');
    MSQueryCalculatedData.sql.Add('and side='+inttostr(InSide)+'');
    MSQueryCalculatedData.sql.Add('and step='+inttostr(main.step)+'');
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculatedData  UPDATE -> '+MSQueryCalculatedData.sql.Text);
{$ENDIF}}
    MSQueryCalculatedData.ExecSQL;
  end;

  FreeAndNil(main);
  FreeAndNil(MSQueryCalculatedData);

end;





end.

