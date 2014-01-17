unit sql;

interface

uses
  SysUtils, Classes, Windows, ActiveX, FIB, FIBQuery, pFIBQuery, FIBDatabase,
  pFIBDatabase, pFIBErrorHandler, Data.DB, FIBDataSet, pFIBDataSet;

type
  TSql = class

  private
    { Private declarations }
  protected

  end;

var
  SqlService: TSql;
  pFIBDatabase1: TpFIBDatabase;
  FQueryOPC: TFIBQuery;
  pFIBTransaction1: TpFIBTransaction;

//  {$DEFINE DEBUG}

  function ConfigFirebirdSetting(InData: bool): bool;


implementation

uses
  settings, logging, main_form;

function ConfigFirebirdSetting(InData: bool): bool;
begin
  if InData then
  begin
      try
        pFIBDatabase1 := TpFIBDatabase.Create(nil);
        FQueryOPC := TpFIBQuery.Create(nil);
        pFIBTransaction1 := TpFIBTransaction.Create(nil);
        pFIBTransaction1.DefaultDatabase := pFIBDatabase1;
        FQueryOPC.Database := pFIBDatabase1;
        FQueryOPC.Transaction := pFIBTransaction1;
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
        FQueryOPC.Free;
        pFIBTransaction1.Free;
  end;
end;

// ��� �������� ��������� ����� ����� �����������
initialization

SqlService := TSql.Create;


// ��� �������� ��������� ������������
finalization

SqlService.Destroy;

end.
