unit sql;

interface

uses
  SysUtils, Classes, Windows, ActiveX, FIB, FIBQuery, pFIBQuery, FIBDatabase,
  pFIBDatabase, pFIBErrorHandler, Data.DB, FIBDataSet, pFIBDataSet, DBAccess, Ora;

type
  TSql = class

  private
    { Private declarations }
  protected

  end;

var
  SqlService: TSql;
  pFIBDatabase1: TpFIBDatabase;
  FQueryChemical: TFIBQuery;
  pFIBTransaction1: TpFIBTransaction;
  OraQuery1: TOraQuery;
  OraSession1: TOraSession;

//  {$DEFINE DEBUG}

  function ConfigFirebirdSetting(InData: bool): bool;
  function ConfigOracleSetting(InData: bool): bool;


implementation

uses
  settings, logging, main;

function ConfigFirebirdSetting(InData: bool): bool;
begin
  if InData then
  begin
      try
        pFIBDatabase1 := TpFIBDatabase.Create(nil);
        FQueryChemical := TpFIBQuery.Create(nil);
        pFIBTransaction1 := TpFIBTransaction.Create(nil);
        pFIBTransaction1.DefaultDatabase := pFIBDatabase1;
        FQueryChemical.Database := pFIBDatabase1;
        FQueryChemical.Transaction := pFIBTransaction1;
        pFIBDatabase1.Connected := false;
        pFIBDatabase1.LibraryName := CurrentDir + '\' + FbSqlConfigArray[3];
        pFIBDatabase1.DBName := FbSqlConfigArray[1] + ':' + FbSqlConfigArray[2];
        pFIBDatabase1.ConnectParams.UserName := FbSqlConfigArray[5];
        pFIBDatabase1.ConnectParams.Password := FbSqlConfigArray[6];
        pFIBDatabase1.ConnectParams.CharSet := 'NONE';// 'UNICODE_FSS';//'UTF8';//'ASCII';//'WIN1251';
        pFIBDatabase1.SQLDialect := strtoint(FbSqlConfigArray[4]);
        pFIBDatabase1.UseLoginPrompt := false;
        pFIBDatabase1.Timeout := 0;
        pFIBDatabase1.Connected := true;
        pFIBDatabase1.AutoReconnect := true;
        pFIBTransaction1.Active := false;
        pFIBTransaction1.Timeout := 0;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      end;
  end
  else
  begin
        pFIBDatabase1.Free;
        pFIBTransaction1.Free;
  end;
end;


function ConfigOracleSetting(InData: bool): bool;
begin
  if InData then
  begin
      try
        OraSession1 := TOraSession.Create(nil);
        OraQuery1 := TOraQuery.Create(nil);
        OraSession1.Username := OraSqlConfigArray[4];
        OraSession1.Password := OraSqlConfigArray[5];
        OraSession1.Server := OraSqlConfigArray[1]+':'+
                              OraSqlConfigArray[2]+':'+
                              OraSqlConfigArray[3];//'krr-sql13:1521:ovp68';
        OraSession1.Options.Direct := true;
        OraSession1.Options.DateFormat := 'DD.MM.RRRR';//������ ���� ��.��.����
        OraSession1.Options.Charset := 'CL8MSWIN1251';// 'AL32UTF8';//CL8MSWIN1251
      //  OraSession1.Options.UseUnicode := true;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      end;
  end
  else
  begin
        OraSession1.Free;
        OraQuery1.Free;
  end;
end;

// ��� �������� ��������� ����� ����� �����������
initialization

SqlService := TSql.Create;


// ��� �������� ��������� ������������
finalization

SqlService.Destroy;

end.
