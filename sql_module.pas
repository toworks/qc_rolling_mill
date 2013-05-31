unit sql_module;

interface

uses
  System.SysUtils, System.Classes, Messages, Windows, Graphics, Dialogs, FIB, FIBQuery, pFIBQuery,
  FIBDatabase, pFIBDatabase, pFIBErrorHandler, Data.DB, FIBDataSet, pFIBDataSet,
  Data.Win.ADODB, MemDS, DBAccess, Ora, ZAbstractDataset,
  ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset,
  ZStoredProcedure;

type
  TDataModule1 = class(TDataModule)
    pFIBDatabase1: TpFIBDatabase;
    pFibErrorHandler1: TpFibErrorHandler;
    pFIBDataSet1: TpFIBDataSet;
    pFIBQuery1: TpFIBQuery;
    pFIBTransaction1: TpFIBTransaction;
    OraSession1: TOraSession;
    OraQuery1: TOraQuery;


    procedure pFibErrorHandler1FIBErrorEvent(Sender: TObject;
      ErrorValue: EFIBError; KindIBError: TKindIBError; var DoRaise: Boolean);
    procedure DataModuleCreate(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
    DataModule1: TDataModule1;
    SConnect: TZConnection;
    SQuery: TZQuery;
    FConnect: TZConnection;
    FQuery: TZQuery;

    {$DEFINE DEBUG}

    function FbInit: bool;
    function OraDbInit: bool;
    function SQLiteInit: bool;


implementation

uses
  main, logging, settings;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}






function FbInit: bool;
begin

{    DataModule1.pFIBDatabase1.LibraryName := '.\fbclient.dll';
    DataModule1.pFIBDatabase1.DBName := 'localhost:c:\tmp\mc_250-5\Ms250-5.fdb';
    DataModule1.pFIBDatabase1.ConnectParams.UserName := 'sysdba';
    DataModule1.pFIBDatabase1.ConnectParams.Password := 'masterkey';
    DataModule1.pFIBDatabase1.SQLDialect := 3;
    DataModule1.pFIBDatabase1.UseLoginPrompt := false;
    DataModule1.pFIBDatabase1.Timeout := 0;
    DataModule1.pFIBDatabase1.Connected := true;
    DataModule1.pFIBTransaction1.Active := false;
    DataModule1.pFIBTransaction1.Timeout := 0;
    DataModule1.pFIBQuery1.Database := DataModule1.pFIBDatabase1;
    DataModule1.pFIBQuery1.Transaction := DataModule1.pFIBTransaction1;
 }
{      DataModule1.ZConnection1.Database := 'e:\termo\db\TERMOMS3SPC1.FDB';
    DataModule1.ZConnection1.HostName := '10.21.115.4';
    DataModule1.ZConnection1.Port := 3050;
    DataModule1.ZConnection1.User := 'sysdba';
    DataModule1.ZConnection1.Password := 'masterkey';
    DataModule1.ZConnection1.LibraryLocation := CurrentDir+'\fbclient.dll';
    DataModule1.ZConnection1.Protocol := 'firebird-2.0';
    DataModule1.ZConnection1.Connect;
    DataModule1.ZReadOnlyQuery1.Connection := DataModule1.ZConnection1;

    DataModule1.ZReadOnlyQuery1.Close;
    DataModule1.ZReadOnlyQuery1.SQL.Clear;
    DataModule1.ZReadOnlyQuery1.SQL.Add('select *');
    DataModule1.ZReadOnlyQuery1.SQL.Add('FROM melts');
    DataModule1.ZReadOnlyQuery1.SQL.Add('where begindt=(select max(begindt) FROM melts)');
    DataModule1.ZReadOnlyQuery1.Open;

    edit1.Text := DataModule1.ZReadOnlyQuery1.FieldByName('NOPLAV').AsString;
 }

    DataModule1.pFIBDatabase1.Connected := false;
    DataModule1.pFIBDatabase1.LibraryName := '.\'+FbSqlConfigArray[1,3];
    DataModule1.pFIBDatabase1.DBName := FbSqlConfigArray[1,1]+':'+FbSqlConfigArray[1,2];
    DataModule1.pFIBDatabase1.ConnectParams.UserName := FbSqlConfigArray[1,5];
    DataModule1.pFIBDatabase1.ConnectParams.Password := FbSqlConfigArray[1,6];
    DataModule1.pFIBDatabase1.SQLDialect := strtoint(FbSqlConfigArray[1,4]);
    DataModule1.pFIBDatabase1.UseLoginPrompt := false;
    DataModule1.pFIBDatabase1.Timeout := 0;
    DataModule1.pFIBDatabase1.Connected := true;
    DataModule1.pFIBTransaction1.Active := false;
    DataModule1.pFIBTransaction1.Timeout := 0;
    DataModule1.pFIBQuery1.Database := DataModule1.pFIBDatabase1;
    DataModule1.pFIBQuery1.Transaction := DataModule1.pFIBTransaction1;

end;


procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  ConfigSettings(true);
  FbInit;
  OraDbInit;
  SQLiteInit;
end;


function OraDbInit: bool;
begin
  DataModule1.OraSession1.Username := OraSqlConfigArray[1,4];
  DataModule1.OraSession1.Password := OraSqlConfigArray[1,5];
  DataModule1.OraSession1.Server := OraSqlConfigArray[1,1]+':'+OraSqlConfigArray[1,2]+
                                    ':'+OraSqlConfigArray[1,3];//'krr-sql13:1521:ovp68';
  DataModule1.OraSession1.Options.Direct := true;
  DataModule1.OraSession1.Options.DateFormat := 'DD.MM.RR';//������ ���� ��.��.��
  DataModule1.OraSession1.Options.Charset := 'CL8MSWIN1251';// 'AL32UTF8';//CL8MSWIN1251
//  DataModule1.OraSession1.Options.UseUnicode := true;
end;


procedure TDataModule1.pFibErrorHandler1FIBErrorEvent(Sender: TObject;
  ErrorValue: EFIBError; KindIBError: TKindIBError; var DoRaise: Boolean);
begin
    if KindIBError = keLostConnect then
        showmessage('lost connect');
end;


function SQLiteInit: bool;
var
  f: File of Word;
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
{      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('CREATE TABLE SIT (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
      SQuery.SQL.Add(', heat VARCHAR(26), timestamp date, grade VARCHAR(16)');
      SQuery.SQL.Add(', standard VARCHAR(16), section VARCHAR(16)');
      SQuery.SQL.Add(', strength_class VARCHAR(16), c NUMERIC(10,6)');
      SQuery.SQL.Add(', mn NUMERIC(10,6), si NUMERIC(10,6), cr NUMERIC(10,6)');
      SQuery.SQL.Add(', batch_number INTEGER, flow_limit NUMERIC(10,6), rupture_strength NUMERIC(10,6))');
      SQuery.ExecSQL;}

      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('CREATE TABLE setting_sql (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
      SQuery.SQL.Add(', sql VARCHAR(50) NOT NULL, host VARCHAR(50) NOT NULL');
      SQuery.SQL.Add(', user VARCHAR(50), password VARCHAR(50)');
      SQuery.SQL.Add(', db_name VARCHAR(50) NOT NULL, library VARCHAR(50))');
      SQuery.ExecSQL;
   end;

  CloseFile(f);

end;



end.