unit sql;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset, ZDbcIntfs, IBConnection, sqldb,
  mssqlconn, sqldblib, DateUtils, FileUtil;

type
TMeltingCharacteristics = Record
  tid_           : string[50];
  heat_          : string[50];
  grade_         : string[50];
  StrengthClass_ : string[50];
  section_       : string[50];
  standard_      : string[50];
  rolling_mill_  : string[1];
  temperature_   : string[50];
  side_          : string[1];
  recordid_      : string[50];
end;


var
  FConnectOld: TIBConnection;
  FTransactionOld: TSQLTransaction;
  FQueryOld: TSQLQuery;
  FConnect: array [2..5] of TZConnection;
  FQuery: array [2..5] of TZQuery;

//  {$DEFINE DEBUG}

  function ConfigFirebirdSettingToOldIB(InData: boolean): boolean;
  function ConfigFirebirdSetting(InData: boolean; InRollingMill: integer): boolean;
//  function ConfigFirebirdSetting(InData: boolean): boolean;
//  function ConfigMsSetting(InData: boolean): boolean;
  function ReadSql(InRollingMill: integer): boolean;
  procedure ReadSqlOld;
  function MSSqlWrite(InData: TMeltingCharacteristics): boolean;

implementation

uses
    settings, thread_main;


function ConfigFirebirdSettingToOldIB(InData: boolean): boolean;
begin
  if InData then
  begin
      try
        FConnectOld := TIBConnection.Create(nil);
        FTransactionOld := TSQLTransaction.Create(nil);
        FQueryOld := TSQLQuery.Create(nil);
        FTransactionOld.Database := FConnectOld;
        FTransactionOld.Params.Append('isc_tpb_read_committed');
        FTransactionOld.Params.Append('isc_tpb_concurrency');
        FTransactionOld.Params.Append('isc_tpb_nowait');
        FTransactionOld.Action := caCommit;
        FQueryOld.Database := FConnectOld;
        FQueryOld.Transaction := FTransactionOld;
        FConnectOld.Connected := false;
        FConnectOld.DatabaseName := FbSqlSettings[1].db_name;
        FConnectOld.Dialect := strtoint(FbSqlSettings[1].dialect);
        FConnectOld.HostName := FbSqlSettings[1].ip;
        FConnectOld.UserName := FbSqlSettings[1].user;
        FConnectOld.Password := FbSqlSettings[1].password;
        FConnectOld.LoginPrompt := false;
        FConnectOld.Transaction := FTransactionOld;
        FConnectOld.Connected := true;
        FbSqlSettings[1].configured := true;
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      end;
  end
  else
  begin
        FbSqlSettings[1].configured := false;
        FreeAndNil(FTransactionOld);
        FreeAndNil(FQueryOld);
        FreeAndNil(FConnectOld);
  end;

end;


function ConfigFirebirdSetting(InData: boolean; InRollingMill: integer): boolean;
begin
  if InData then
  begin
      try
        FConnect[InRollingMill] := TZConnection.Create(nil);
        FQuery[InRollingMill] := TZQuery.Create(nil);
        FConnect[InRollingMill].LibraryLocation := '.\fbclient.dll';// отказался от полных путей не читает
        FConnect[InRollingMill].Protocol := 'firebird-2.5';
        FConnect[InRollingMill].Database := FbSqlSettings[InRollingMill].db_name;
        FConnect[InRollingMill].HostName := FbSqlSettings[InRollingMill].ip;
        FConnect[InRollingMill].User := FbSqlSettings[InRollingMill].user;
        FConnect[InRollingMill].Password := FbSqlSettings[InRollingMill].password;
        FConnect[InRollingMill].ReadOnly := True;
        FConnect[InRollingMill].LoginPrompt := false;
        FConnect[InRollingMill].Port := 3050;
        FConnect[InRollingMill].AutoCommit := False;
        FConnect[InRollingMill].TransactIsolationLevel := tiReadCommitted;
        with FConnect[InRollingMill].Properties do
        begin
             Add('Dialect='+FbSqlSettings[InRollingMill].dialect);
             Add('isc_tpb_read_committed');
             Add('isc_tpb_concurrency');              // Needed for multiuser environments
             Add('isc_tpb_nowait');                   // Needed for multiuser environments
             Add('timeout=3');
//             Add('codepage=NONE');
//             Add('controls_cp=CP_UTF8');
//             Add('AutoEncodeStrings=ON');
//             Add('codepage=win1251');
//             Add('client_encoding=UTF8');
        end;
        FConnect[InRollingMill].Connect;
        FbSqlSettings[InRollingMill].configured := true;
        FQuery[InRollingMill].Connection := FConnect[InRollingMill];
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      end;
  end
  else
  begin
        FbSqlSettings[InRollingMill].configured := false;
        FreeAndNil(FQuery[InRollingMill]);
        FreeAndNil(FConnect[InRollingMill]);
  end;

end;


function ReadSql(InRollingMill: integer): boolean;
var
  heat, recordid, table_name: string;
  tid, heat_local, grade, standard, StrengthClassLeft, StrengthClassRight,
  SectionLeft, SectionRight: string;
  timestamp: TDateTime;
  TempLeft, TempRight: integer;
  OutToSql: TMeltingCharacteristics;
  str: TStringList;
begin
  try
      FQuery[InRollingMill].Close;
      FQuery[InRollingMill].SQL.Clear;
      FQuery[InRollingMill].SQL.Add('select FIRST 1 begindt, NOPLAV as heat,');
      FQuery[InRollingMill].SQL.Add('MARKA as grade, STANDART as standard');
      FQuery[InRollingMill].SQL.Add('FROM melts where state=1 order by begindt desc');
      FQuery[InRollingMill].Open;
  except
    on E: Exception do begin
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      ConfigFirebirdSetting(false, InRollingMill);
      exit;
    end;
  end;

  try
    heat := FQuery[InRollingMill].FieldByName('heat').AsString;
    grade := FQuery[InRollingMill].FieldByName('grade').AsString;
    standard := FQuery[InRollingMill].FieldByName('standard').AsString;

    heat_local := StringReplace(heat,'-','_', [rfReplaceAll]);
    timestamp := FQuery[InRollingMill].FieldByName('begindt').AsDateTime;
    table_name := 'P'+FormatDateTime('yymmdd', timestamp)+'N'+heat_local
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

  try
      FQuery[InRollingMill].Close;
      FQuery[InRollingMill].SQL.Clear;
      FQuery[InRollingMill].SQL.Add('select *');
      FQuery[InRollingMill].SQL.Add('FROM '+table_name);
      FQuery[InRollingMill].SQL.Add('where recordid=(select max(recordid)');
      FQuery[InRollingMill].SQL.Add('FROM '+table_name+')');
      FQuery[InRollingMill].Open;
  except
    on E: Exception do begin
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      ConfigFirebirdSetting(false, InRollingMill);
      exit;
    end;
  end;

  try
     tid := inttostr(DateTimeToUnix(timestamp));
     str := TStringList.Create;
     recordid := FQuery[InRollingMill].FieldByName('recordid').AsString;
     str.Text := StringReplace(FQuery[InRollingMill].FieldByName('SECL').AsString, '_', #13#10, [rfReplaceAll]);
     SectionLeft := str.Strings[0];
     StrengthClassLeft := UpperCase(str.Strings[1]);
     str.Free;
     str := TStringList.Create;
     str.Text := StringReplace(FQuery[InRollingMill].FieldByName('SECR').AsString, '_', #13#10, [rfReplaceAll]);
     SectionRight := str.Strings[0];
     StrengthClassRight := UpperCase(str.Strings[1]);
     str.Free;
     TempLeft := FQuery[InRollingMill].FieldByName('TMOUTL').AsInteger;
     TempRight := FQuery[InRollingMill].FieldByName('TMOUTR').AsInteger;
  except
    on E: Exception do begin
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      exit;
    end;
  end;

  {$IFDEF DEBUG}
    SaveLog.Log(etDebug, 'tid -> '+tid);
    SaveLog.Log(etDebug, 'heat -> '+heat);
    SaveLog.Log(etDebug, 'grade -> '+grade);
    SaveLog.Log(etDebug, 'standard -> '+standard);
    SaveLog.Log(etDebug, 'recordid -> '+recordid);
    SaveLog.Log(etDebug, 'SectionLeft -> '+SectionLeft);
    SaveLog.Log(etDebug, 'StrengthClassLeft -> '+StrengthClassLeft);
    SaveLog.Log(etDebug, 'TempLeft -> '+inttostr(TempLeft));
    SaveLog.Log(etDebug, 'SectionRight -> '+SectionRight);
    SaveLog.Log(etDebug, 'StrengthClassRight -> '+StrengthClassRight);
    SaveLog.Log(etDebug, 'TempRight -> '+inttostr(TempRight));
    SaveLog.Log(etDebug, 'rolling mill -> '+inttostr(InRollingMill));
  {$ENDIF}


  with OutToSql do begin
       tid_ := tid;
       heat_ := heat;
       grade_ := grade;
       StrengthClass_ := StrengthClassLeft;
       section_ := SectionLeft;
       standard_ := standard;
       rolling_mill_ := inttostr(InRollingMill);
       if 250 < TempLeft then
          temperature_ := inttostr(TempLeft)
       else
          temperature_ := '0';
       side_ := '0';
       recordid_ := recordid;
  end;
  MSSqlWrite(OutToSql);
  //free memory
  Finalize(OutToSql);
  FillChar(OutToSql,sizeof(OutToSql),0);

  with OutToSql do begin
       tid_ := tid;
       heat_ := heat;
       grade_ := grade;
       StrengthClass_ := StrengthClassRight;
       section_ := SectionRight;
       standard_ := standard;
       rolling_mill_ := inttostr(InRollingMill);
       if 250 < TempRight then
          temperature_ := inttostr(TempRight)
       else
          temperature_ := '0';
       side_ := '1';
       recordid_ := recordid;
  end;
  MSSqlWrite(OutToSql);
  //free memory
  Finalize(OutToSql);
  FillChar(OutToSql,sizeof(OutToSql),0);
end;


procedure ReadSqlOld;
var
   heat, recordid, table_name: string;
   tid, heat_local, grade, standard, StrengthClassLeft, StrengthClassRight,
   SectionLeft, SectionRight: string;
   timestamp: TDateTime;
   TempLeft, TempRight: integer;
   OutToSql: TMeltingCharacteristics;
   str: TStringList;
begin
  {$IFDEF DEBUG}
    SaveLog.Log(etDebug, 'configured -> '+booltostr(FbSqlSettings[1].configured));
  {$ENDIF}
  try
      FTransactionOld.Active:=false;
      FQueryOld.Close;
      FQueryOld.SQL.Clear;
      FQueryOld.SQL.Add('select BEGINDT, NOPLAV as heat,');
      FQueryOld.SQL.Add('MARKA as grade, KLASS as standard');
      FQueryOld.SQL.Add('FROM melts where state=1');
      FQueryOld.Open;
  except
    on E: Exception do begin
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      ConfigFirebirdSettingToOldIB(false);
      exit;
    end;
  end;

  try
    heat := FQueryOld.FieldByName('heat').AsString;
    grade := FQueryOld.FieldByName('grade').AsString;
    standard := FQueryOld.FieldByName('standard').AsString;

    heat_local := StringReplace(heat,'-','_', [rfReplaceAll]);
    timestamp := FQueryOld.FieldByName('begindt').AsDateTime;
    table_name := 'PARAMS'+heat_local;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

  try
      FTransactionOld.Active:=false;
      FQueryOld.Close;
      FQueryOld.SQL.Clear;
      FQueryOld.SQL.Add('select *');
      FQueryOld.SQL.Add('FROM '+table_name);
      FQueryOld.SQL.Add('where recordid=(select max(recordid)');
      FQueryOld.SQL.Add('FROM '+table_name+')');
      FQueryOld.Open;
  except
    on E: Exception do begin
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      ConfigFirebirdSettingToOldIB(false);
      exit;
    end;
  end;

  try
     tid := inttostr(DateTimeToUnix(timestamp));
     str := TStringList.Create;
     recordid := FQueryOld.FieldByName('recordid').AsString;
     str.Text := StringReplace(FQueryOld.FieldByName('SECTIONL').AsString, '_', #13#10, [rfReplaceAll]);
     SectionLeft := str.Strings[0];
     StrengthClassLeft := UpperCase(str.Strings[1]);
     str.Free;
     str := TStringList.Create;
     str.Text := StringReplace(FQueryOld.FieldByName('SECTIONR').AsString, '_', #13#10, [rfReplaceAll]);
     SectionRight := str.Strings[0];
     StrengthClassRight := UpperCase(str.Strings[1]);
     str.Free;
     TempLeft := FQueryOld.FieldByName('TOTPL').AsInteger;
     TempRight := FQueryOld.FieldByName('TOTPP').AsInteger;
  except
    on E: Exception do begin
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      exit;
    end;
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'tid -> '+tid);
  SaveLog.Log(etDebug, 'heat -> '+heat);
  SaveLog.Log(etDebug, 'grade -> '+grade);
  SaveLog.Log(etDebug, 'standard -> '+standard);
  SaveLog.Log(etDebug, 'recordid -> '+recordid);
  SaveLog.Log(etDebug, 'SectionLeft -> '+SectionLeft);
  SaveLog.Log(etDebug, 'StrengthClassLeft -> '+StrengthClassLeft);
  SaveLog.Log(etDebug, 'TempLeft -> '+inttostr(TempLeft));
  SaveLog.Log(etDebug, 'SectionRight -> '+SectionRight);
  SaveLog.Log(etDebug, 'StrengthClassRight -> '+StrengthClassRight);
  SaveLog.Log(etDebug, 'TempRight -> '+inttostr(TempRight));
  SaveLog.Log(etDebug, 'rolling mill -> 1');//+inttostr(InRollingMill));
{$ENDIF}

  with OutToSql do begin
       tid_ := tid;
       heat_ := heat;
       grade_ := grade;
       StrengthClass_ := StrengthClassLeft;
       section_ := SectionLeft;
       standard_ := standard;
       rolling_mill_ := '1';
       if 250 < TempLeft then
          temperature_ := inttostr(TempLeft)
       else
          temperature_ := '0';
       side_ := '0';
       recordid_ := recordid;
  end;
  MSSqlWrite(OutToSql);
  //free memory
  Finalize(OutToSql);
  FillChar(OutToSql,sizeof(OutToSql),0);

  with OutToSql do begin
       tid_ := tid;
       heat_ := heat;
       grade_ := grade;
       StrengthClass_ := StrengthClassRight;
       section_ := SectionRight;
       standard_ := standard;
       rolling_mill_ := '1';
       if 250 < TempRight then
          temperature_ := inttostr(TempRight)
       else
          temperature_ := '0';
       side_ := '1';
       recordid_ := recordid;
  end;
  MSSqlWrite(OutToSql);
  //free memory
  Finalize(OutToSql);
  FillChar(OutToSql,sizeof(OutToSql),0);
end;


function MSSqlWrite(InData: TMeltingCharacteristics): boolean;
var
   MSDBLibraryLoader: TSQLDBLibraryLoader;
   MSConnection: TMSSQLConnection;
   MSQuery: TSQLQuery;
   MSTransaction: TSQLTransaction;
begin

{$IFDEF DEBUG}
    SaveLog.Log(etDebug, 'ms tid -> '+InData.tid_);
    SaveLog.Log(etDebug, 'ms heat -> '+InData.heat_);
    SaveLog.Log(etDebug, 'ms grade -> '+InData.grade_);
    SaveLog.Log(etDebug, 'ms StrengthClass -> '+InData.StrengthClass_);
    SaveLog.Log(etDebug, 'ms recordid -> '+InData.recordid_);
    SaveLog.Log(etDebug, 'ms section -> '+InData.section_);
    SaveLog.Log(etDebug, 'ms standard -> '+InData.standard_);
    SaveLog.Log(etDebug, 'ms temperature -> '+InData.temperature_);
    SaveLog.Log(etDebug, 'ms side -> '+InData.side_);
    SaveLog.Log(etDebug, 'ms rolling_mill -> '+InData.rolling_mill_);
{$ENDIF}

{    MSConnect := TZConnection.Create(nil);
    MSQuery := TZQuery.Create(nil);}

    MSDBLibraryLoader := TSQLDBLibraryLoader.Create(nil);
    MSConnection := TMSSQLConnection.Create(nil);
    MSQuery := TSQLQuery.Create(nil);
    MSTransaction := TSQLTransaction.Create(nil);

    try
       MSDBLibraryLoader.ConnectionType := 'MSSQLServer';
       MSDBLibraryLoader.LibraryName := '.\'+MsSqlSettings.lib;

       MSConnection.DatabaseName := MsSqlSettings.db_name;
       MSConnection.HostName := MsSqlSettings.ip;
       MSConnection.Transaction := MSTransaction;
       MSConnection.CharSet := 'UTF-8';
       MSConnection.Params.Add('AutoCommit=true'); //без опции через время не
                                                   //проходят транзакции

       MSTransaction.DataBase := MSConnection;
       MSTransaction.Action := caCommit;

       MSQuery.DataBase := MSConnection;
       MSQuery.Transaction := MSTransaction;

{       MSConnect.LibraryLocation := '.\'+MsSqlSettings.lib;
       MSConnect.Protocol := 'FreeTDS_MsSQL>=2005';
       //BD надо перевести в кодировку Cyrillic_General_CI_AS для отображения кирилицы
{       ALTER DATABASE [KRR-PA-MGT-QCRollingMill] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
       ALTER DATABASE [KRR-PA-MGT-QCRollingMill] COLLATE Cyrillic_General_CI_AS
       ALTER DATABASE [KRR-PA-MGT-QCRollingMill] SET MULTI_USER}
//       MSConnect.ControlsCodePage :=  cCP_UTF8;//cCP_UTF8;
//       MSConnect.AutoEncodeStrings := False;
//       MSConnect.ClientCodePage := 'CP866';//'WIN1251';
       MSConnect.HostName := MsSqlSettings.ip;
       MSConnect.Port := MsSqlSettings.port;
       MSConnect.User := MsSqlSettings.user;
       MSConnect.Password := MsSqlSettings.password;
       MSConnect.Database := MsSqlSettings.db_name;

       MSConnect.Connect;
       MSQuery.Connection := MSConnect;}
    except
      on E : Exception do
        SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
    end;

    try
       MSDBLibraryLoader.Enabled := true;
       MSConnection.Connected := true;
       MSQuery.Close;
       MSQuery.SQL.Clear;
       MSQuery.SQL.Add('UPDATE temperature_current SET heat='''+UTF8Encode(InData.heat_)+''',');
       MSQuery.SQL.Add('grade='''+UTF8Encode(InData.grade_)+''',');
       MSQuery.SQL.Add('strength_class='''+UTF8Encode(InData.StrengthClass_)+''',');
       MSQuery.SQL.Add('section='+InData.section_+', standard='''+UTF8Encode(InData.standard_)+''',');
       MSQuery.SQL.Add('temperature='+InData.temperature_+'');
       MSQuery.SQL.Add('where tid='+InData.tid_+' and rolling_mill='+InData.rolling_mill_+' and side='+InData.side_+'');
       MSQuery.SQL.Add('IF @@ROWCOUNT=0');
       MSQuery.SQL.Add('INSERT INTO temperature_current (tid, [timestamp], ');
       MSQuery.SQL.Add('rolling_mill, heat, grade, strength_class, section, ');
       MSQuery.SQL.Add('standard, side, temperature) values ( ');
       MSQuery.SQL.Add(''+InData.tid_+', datediff(ss, ''1970/01/01'', GETDATE()),');
       MSQuery.SQL.Add(''+InData.rolling_mill_+', '''+UTF8Encode(InData.heat_)+''', ');
       MSQuery.SQL.Add(''''+UTF8Encode(InData.grade_)+''', '''+UTF8Encode(InData.StrengthClass_)+''', ');
       MSQuery.SQL.Add(''+InData.section_+', '''+UTF8Encode(InData.standard_)+''', ');
       MSQuery.SQL.Add(''+InData.side_+', '+InData.temperature_+' ) ');
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQuery.SQL.Text -> '+MSQuery.SQL.Text);
{$ENDIF}}
       MSQuery.ExecSQL;
    except
      on E : Exception do
        SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
    end;

    FreeAndNil(MSDBLibraryLoader);
    FreeAndNil(MSConnection);
    FreeAndNil(MSQuery);
    FreeAndNil(MSTransaction);
    //free memory
    Finalize(InData);
    FillChar(InData,sizeof(InData),0);
end;




end.

