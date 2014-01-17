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
INSERT INTO [settings] ([name], [value]) VALUES ('::TCP::remote_port', 33333);

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

   OraSqlConfigArray: Array[1..5] of String;
   TcpConfigArray: Array[1..2] of String;

//   {$DEFINE DEBUG}

   function ConfigSettings(InData: bool): bool;
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

        ReadConfigSettings;

      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
      end;
   end
  else
   begin
      SQuery.Destroy;
      SConnect.Destroy;
   end;

end;


function ReadConfigSettings: bool;
var
  i: integer;
begin

    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('SELECT * FROM settings');
    SQuery.Open;


    while not SQuery.Eof do
     begin
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

      //tcp
      if SQuery.FieldByName('name').AsString = '::TCP::remote_ip' then
        TcpConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::TCP::remote_port' then
        TcpConfigArray[2] := SQuery.FieldByName('value').AsString;


        SQuery.Next;
     end;

end;



// При загрузке программы класс будет создаваться
initialization
  SettingsApp := TSettings.Create;

//При закрытии программы уничтожаться
finalization
  SettingsApp.Destroy;

end.
