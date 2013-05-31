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

   FbSqlConfigArray: Array[1..6, 1..6] of String;
   OraSqlConfigArray: Array[1..5, 1..5] of String;

   {$DEFINE DEBUG}

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
          SQuery.SQL.Add('CREATE TABLE setting_sql (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
          SQuery.SQL.Add(', sql VARCHAR(50) NOT NULL, host VARCHAR(50) NOT NULL');
          SQuery.SQL.Add(', user VARCHAR(50), password VARCHAR(50)');
          SQuery.SQL.Add(', db_name VARCHAR(50) NOT NULL, library VARCHAR(50))');
          SQuery.ExecSQL;
       end;

      CloseFile(f);


      ReadConfigSettings;
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
      //fbsql
      if SQuery.FieldByName('name').AsString = '::FbSql::ip' then
        FbSqlConfigArray[1,1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::db_name' then
        FbSqlConfigArray[1,2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::library' then
        FbSqlConfigArray[1,3] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::dialect' then
        FbSqlConfigArray[1,4] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::user' then
        FbSqlConfigArray[1,5] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::password' then
        FbSqlConfigArray[1,6] := SQuery.FieldByName('value').AsString;

      //orasql
      if SQuery.FieldByName('name').AsString = '::OraSql::ip' then
        OraSqlConfigArray[1,1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::port' then
        OraSqlConfigArray[1,2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::db_name' then
        OraSqlConfigArray[1,3] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::user' then
        OraSqlConfigArray[1,4] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::password' then
        OraSqlConfigArray[1,5] := SQuery.FieldByName('value').AsString;



        SQuery.Next;
     end;

end;


// ��� �������� ��������� ����� ����� �����������
initialization
  SettingsApp := TSettings.Create;

//��� �������� ��������� ������������
finalization
  SettingsApp.Destroy;

end.