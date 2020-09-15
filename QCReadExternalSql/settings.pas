{

  CREATE TABLE settings (
  name  VARCHAR( 50 )   PRIMARY KEY
  NOT NULL
  UNIQUE,
  value VARCHAR( 256 )
  );
}

unit settings;

interface

uses
  SysUtils, Classes, EventLog, ZConnection, ZDataset, versioninfo, FileUtil;

type
  TSettings = class
  private
    { Private declarations }
  public
    Constructor Create; overload;
    Destructor Destroy; override;
  end;

  TFbSql = Record
    ip            : string[20];
    db_name       : string[255];
    dialect       : string[1];
    user          : string[50];
    password      : string[50];
    lib           : string[50];
    port          : integer;
    enable        : integer;
    configured    : boolean;
  end;


var
  SaveLog: TEventLog;
  CurrentDir: string;
  DaemonDescription: string = 'управление качеством - сбор данных MC 250';
  DaemonName: string;
  Version: string;
  Info: TVersionInfo;

  DBFile: string = 'data.sdb';

  SettingsApp: TSettings;
  SConnect: TZConnection;
  SQuery: TZQuery;
  ErrorSettings: boolean = false;

  FbSqlSettings: Array [1..5] of TFbSql;
  MsSqlSettings: TFbSql;
  FbLibrary: string;

// {$DEFINE DEBUG}

function ConfigSettings(InData: boolean): boolean;
function SqlJournalMode: boolean;
function ReadConfigSettings: boolean;

implementation

{uses
  logging;}


constructor TSettings.Create;
begin
  inherited Create;
  SaveLog := TEventLog.Create(nil);
  SaveLog.LogType := ltFile;
  SaveLog.DefaultEventType := etDebug;
  SaveLog.AppendContent := true;
  SaveLog.FileName := ChangeFileExt(ParamStr(0), '.log');
  //текуща¤ дириктори¤
  CurrentDir := SysToUtf8(ExtractFilePath(ParamStr(0)));
  DaemonName := ChangeFileExt(ExtractFileName(ParamStr(0)), '' );
  ConfigSettings(true);
  Info := TVersionInfo.Create;
  Info.Load(HInstance);
  Version := Info.ProductVersion+'   build('+Info.FileVersion+')';
end;


destructor TSettings.Destroy;
begin
  ConfigSettings(false);
  inherited Destroy;
end;


function ConfigSettings(InData: boolean): boolean;
begin

  if InData then
  begin
    SConnect := TZConnection.Create(nil);
    SQuery := TZQuery.Create(nil);

    try
      SConnect.Database := CurrentDir + '\' + DBFile;
      SConnect.LibraryLocation := '.\sqlite3.dll';// отказалс¤ от полных путей не читает
      SConnect.Protocol := 'sqlite-3';
      SConnect.Connect;
      SQuery.Connection := SConnect;

      try
         SQuery.Close;
         SQuery.SQL.Clear;
         SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS settings');
         SQuery.SQL.Add('( name VARCHAR(50) PRIMARY KEY NOT NULL UNIQUE');
         SQuery.SQL.Add(', value VARCHAR(256) )');
         SQuery.ExecSQL;
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
      end;

//      SqlJournalMode;

      ReadConfigSettings;
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end
  else
  begin
    FreeAndNil(SQuery);
    FreeAndNil(SConnect);
  end;

end;

function ReadConfigSettings: boolean;
var
  i: integer;
begin

  try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('SELECT * FROM settings');
      SQuery.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

  while not SQuery.Eof do
  begin
    // fbsql for all rolling mill
    for i:=1 to 5 do begin
      if SQuery.FieldByName('name').AsString = '::FbSql::rm'+inttostr(i)+'::ip' then
        FbSqlSettings[i].ip := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::rm'+inttostr(i)+'::db_name' then
        FbSqlSettings[i].db_name := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::rm'+inttostr(i)+'::dialect' then
        FbSqlSettings[i].dialect := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::rm'+inttostr(i)+'::user' then
        FbSqlSettings[i].user := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::rm'+inttostr(i)+'::password' then
        FbSqlSettings[i].password := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::rm'+inttostr(i)+'::enable' then
        FbSqlSettings[i].enable := SQuery.FieldByName('value').AsInteger;
    end;

    // mssql
    if SQuery.FieldByName('name').AsString = '::MsSql::ip' then
      MsSqlSettings.ip := SQuery.FieldByName('value').AsString;
    if SQuery.FieldByName('name').AsString = '::MsSql::db_name' then
      MsSqlSettings.db_name := SQuery.FieldByName('value').AsString;
    if SQuery.FieldByName('name').AsString = '::MsSql::user' then
      MsSqlSettings.user := SQuery.FieldByName('value').AsString;
    if SQuery.FieldByName('name').AsString = '::MsSql::password' then
      MsSqlSettings.password := SQuery.FieldByName('value').AsString;
    if SQuery.FieldByName('name').AsString = '::MsSql::library' then
      MsSqlSettings.lib := SQuery.FieldByName('value').AsString;
    if SQuery.FieldByName('name').AsString = '::MsSql::port' then
      MsSqlSettings.port := SQuery.FieldByName('value').AsInteger;

  {$IFDEF DEBUG}
    for i:=1 to 5 do begin
        SaveLog.Log(etDebug, 'sql setting rm'+inttostr(i)+' ip -> '+FbSqlSettings[i].ip);
        SaveLog.Log(etDebug, 'sql setting rm'+inttostr(i)+' db_name -> '+FbSqlSettings[i].db_name);
        SaveLog.Log(etDebug, 'sql setting rm'+inttostr(i)+' dialect -> '+FbSqlSettings[i].dialect);
        SaveLog.Log(etDebug, 'sql setting rm'+inttostr(i)+' user -> '+FbSqlSettings[i].user);
        SaveLog.Log(etDebug, 'sql setting rm'+inttostr(i)+' password -> '+FbSqlSettings[i].password);
        SaveLog.Log(etDebug, 'sql setting rm'+inttostr(i)+' enable -> '+inttostr(FbSqlSettings[i].enable));
    end;
  {$ENDIF}

    SQuery.Next;
  end;

end;

function SqlJournalMode: boolean;
begin
  try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('PRAGMA journal_mode');
      SQuery.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

  if SQuery.FieldByName('journal_mode').AsString <> 'wal' then
  begin
    try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('PRAGMA journal_mode = wal');
      SQuery.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end;
end;

// ѕри загрузке программы класс будет создаватьс¤
initialization
SettingsApp := TSettings.Create;


// ѕри закрытии программы уничтожатьс¤
finalization
SettingsApp.Destroy;

end.


