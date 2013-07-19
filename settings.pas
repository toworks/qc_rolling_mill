{

 CREATE TABLE settings (
    name  VARCHAR( 50 )   PRIMARY KEY
                          NOT NULL
                          UNIQUE,
    value VARCHAR( 256 )
);

INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::ip', 'localhost');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::user', 'sysdba');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::password', 'masterkey');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::db_name', 'C:\tmp\mc_250-5\MS5DB6.FDB');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::library', 'fbclient.dll');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::ip', 'krr-sql13');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::user', 'asutpadp');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::password', 'dc1');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::db_name', 'ovp68');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::dialect', 3);
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::port', 1521);
INSERT INTO [settings] ([name], [value]) VALUES ('::OPC::server_name', 'Krug.OPCServer.1');
INSERT INTO [settings] ([name], [value]) VALUES ('::OPC::tag_temp_left', 'VA.TE4_2');
INSERT INTO [settings] ([name], [value]) VALUES ('::OPC::tag_temp_right', 'VA.TE3_4');
INSERT INTO [settings] ([name], [value]) VALUES ('::RollingMill::number', 5);
INSERT INTO [settings] ([name], [value]) VALUES ('::TCP::remote_ip', 'localhost');
INSERT INTO [settings] ([name], [value]) VALUES ('::TCP::remote_port', 33322);

}

unit settings;

interface

uses
  SysUtils, Classes, Windows, ActiveX, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, ZAbstractRODataset, ZStoredProcedure;

type
  TSettings = class


  private
    { Private declarations }
  protected

  end;

var
   SettingsApp: TSettings;
   SConnect: TZConnection;
   SQuery: TZQuery;

   FbSqlConfigArray: Array[1..6] of String;
   OraSqlConfigArray: Array[1..5] of String;
   OpcConfigArray: Array[1..3] of String;
   RollingMillConfigArray: Array[1..3] of String;
   TcpConfigArray: Array[1..2] of String;

   {$DEFINE DEBUG}

   function ConfigSettings(InData: bool): bool;
   function SqlJournalMode: bool;
   function ReadConfigSettings: bool;


implementation

uses
  main, logging;



function ConfigSettings(InData: bool): bool;
var
  f: File of Word;
begin

  if InData then
   begin
      SConnect := TZConnection.Create(nil);
      SQuery := TZQuery.Create(nil);

      try
          SConnect.Database := CurrentDir+'\'+DBFile;
          SConnect.LibraryLocation := CurrentDir+'\sqlite3.dll';
          SConnect.Protocol := 'sqlite-3';
          SConnect.Connect;
          SQuery.Connection := SConnect;

          AssignFile(f, CurrentDir+'\'+DBFile);
          Reset(f);

          if FileSize(f) = 0 then
           begin
              SQuery.Close;
              SQuery.SQL.Clear;
              SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS settings');
              SQuery.SQL.Add('( name VARCHAR(50) PRIMARY KEY NOT NULL UNIQUE');
              SQuery.SQL.Add(', value VARCHAR(256) )');
              SQuery.ExecSQL;
           end;

          CloseFile(f);

          SqlJournalMode;

          ReadConfigSettings;
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
   end
  else
   begin
      SQuery.Destroy;
      SConnect.Destroy;
   end;

end;


function ReadConfigSettings: bool;
begin

    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('SELECT * FROM settings');
    SQuery.Open;


    while not SQuery.Eof do
     begin
      //fbsql
      if SQuery.FieldByName('name').AsString = '::FbSql::ip' then
        FbSqlConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::db_name' then
        FbSqlConfigArray[2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::library' then
        FbSqlConfigArray[3] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::dialect' then
        FbSqlConfigArray[4] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::user' then
        FbSqlConfigArray[5] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::password' then
        FbSqlConfigArray[6] := SQuery.FieldByName('value').AsString;

      //orasql
      if SQuery.FieldByName('name').AsString = '::OraSql::ip' then
        OraSqlConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::port' then
        OraSqlConfigArray[2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::db_name' then
        OraSqlConfigArray[3] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::user' then
        OraSqlConfigArray[4] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::password' then
        OraSqlConfigArray[5] := SQuery.FieldByName('value').AsString;

      //opc
      if SQuery.FieldByName('name').AsString = '::OPC::server_name' then
        OpcConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OPC::tag_temp_left' then
        OpcConfigArray[2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OPC::tag_temp_right' then
        OpcConfigArray[3] := SQuery.FieldByName('value').AsString;

      //rolling mill
      if SQuery.FieldByName('name').AsString = '::RollingMill::number' then
        RollingMillConfigArray[1] := SQuery.FieldByName('value').AsString;

      //tcp
      if SQuery.FieldByName('name').AsString = '::TCP::remote_ip' then
        TcpConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::TCP::remote_port' then
        TcpConfigArray[2] := SQuery.FieldByName('value').AsString;

        SQuery.Next;
     end;

end;


function SqlJournalMode: bool;
begin
  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('PRAGMA journal_mode');
  SQuery.Open;

  if SQuery.FieldByName('journal_mode').AsString <> 'wal' then
   begin
      try
          SQuery.Close;
          SQuery.SQL.Clear;
          SQuery.SQL.Add('PRAGMA journal_mode = wal');
          SQuery.ExecSQL;
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
   end;
end;





// ��� �������� ��������� ����� ����� �����������
initialization
  SettingsApp := TSettings.Create;

//��� �������� ��������� ������������
finalization
  SettingsApp.Destroy;

end.
