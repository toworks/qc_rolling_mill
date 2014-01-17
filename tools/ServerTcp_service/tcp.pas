unit tcp;

interface

uses
  Windows, SysUtils, Classes, IdContext, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPServer, FIB, FIBQuery, pFIBQuery, FIBDatabase, pFIBDatabase, pFIBErrorHandler,
  Data.DB, FIBDataSet, pFIBDataSet;

type
  TTcpWorks = class
    procedure IdTCPServerExecute(AContext: TIdContext);

  private
    { Private declarations }
  protected

  end;

var
  TcpWorks: TTcpWorks;
  IdTCPServer: TIdTCPServer;
  // id ��� ������������� ���������
  IdMsg: string = '70xZv3jlnS9KrrCHxXO44I10NKaFfvjXlVhYYugdprEIT8QgVG';

//  {$DEFINE DEBUG}

  function ConfigTcpSetting(InData: bool): bool;
  function SqlWriteTemperature(InData: string): bool;

implementation

uses
  settings, sql, logging;


function ConfigTcpSetting(InData: bool): bool;
begin
  if InData then
  begin
      try
        IdTCPServer := TIdTCPServer.Create(nil);
        IdTCPServer.Bindings.Add.IP := '0.0.0.0';
        IdTCPServer.Bindings.Add.Port := strtoint(TcpConfigArray[2]);
        IdTCPServer.DefaultPort := strtoint(TcpConfigArray[2]);
        IdTCPServer.OnExecute := TcpWorks.IdTCPServerExecute;
        IdTCPServer.Active := true;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      end;
  end
  else
      IdTCPServer.Free;
end;


procedure TTcpWorks.IdTCPServerExecute(AContext: TIdContext);
var
  stream: TStringStream;
  msg: string;
begin
  try
    stream := TStringStream.Create;
    AContext.Connection.IOHandler.ReadStream(stream);
    // ������ �� ��������� � �����
    stream.Position := 0; // ��������� ������� �� ������ ������
    msg := stream.ReadString(stream.Size);
  finally
    stream.Free;
  end;
  if AnsiPos(IdMsg, msg) <> 0 then
  begin
    msg := StringReplace(msg, IdMsg, '', [rfReplaceAll]);
//    SaveLog('tcp'+#9#9+' data -> '+msg);
    try
        SqlWriteTemperature(msg);
        except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end;
end;


function SqlWriteTemperature(InData: string): bool;
var
  str: TStringList;
  FDatabase: TpFIBDatabase;
  FTransaction: TpFIBTransaction;
  FQueryWrite: TFIBQuery;
begin
  try
      FDatabase := TpFIBDatabase.Create(nil);
      FTransaction := TpFIBTransaction.Create(nil);
      FTransaction.DefaultDatabase := pFIBDatabase1;
      FQueryWrite := TpFIBQuery.Create(nil);
      FQueryWrite.Database := FDatabase;
      FQueryWrite.Transaction := FTransaction;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  try
    FQueryWrite.Close;
    FQueryWrite.SQL.Clear;
    FQueryWrite.SQL.Add('select FIRST 1 * from qc_temperature');
    FQueryWrite.ExecQuery;
    FQueryWrite.Transaction.Commit;
  except
    FQueryWrite.Close;
    FQueryWrite.SQL.Clear;
    FQueryWrite.SQL.Add('EXECUTE BLOCK AS BEGIN');
    FQueryWrite.SQL.Add('if (not exists(select 1 from rdb$relations where rdb$relation_name = ''qc_temperature'')) then');
    FQueryWrite.SQL.Add('execute statement ''create table qc_temperature (');
    FQueryWrite.SQL.Add('id NUMERIC(18,0) NOT NULL, DATETIME TIMESTAMP NOT NULL,');
    FQueryWrite.SQL.Add('heat VARCHAR(26) NOT NULL, grade VARCHAR(50),');
    FQueryWrite.SQL.Add('strength_class VARCHAR(50), section VARCHAR(50),');
    FQueryWrite.SQL.Add('standard VARCHAR(50), side integer NOT NULL, temperature integer,');
    FQueryWrite.SQL.Add('PRIMARY KEY (id));'';');
    FQueryWrite.SQL.Add('execute statement ''CREATE SEQUENCE gen_qc_temperature;'';');
    FQueryWrite.SQL.Add('END');
    FQueryWrite.ExecQuery;
    FQueryWrite.Transaction.Commit;
  end;

  try
      // ������ ������� �� ������ ������
      FQueryWrite.Close;
      FQueryWrite.SQL.Clear;
      // ������� ������ ������ 10 ������� (300 ����)
      FQueryWrite.SQL.Add('DELETE FROM qc_temperature where');
      FQueryWrite.SQL.Add('datetime < current_timestamp-300');
      FQueryWrite.ExecQuery;
      FQueryWrite.Transaction.Commit;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  str := TStringList.Create;
  str.Text := StringReplace(InData, '|', #13#10, [rfReplaceAll]);

{$IFDEF DEBUG}
  for i := 0 to str.Count - 1 do
  begin
  SaveLog('debug'+#9#9+inttostr(i)+' -> ' + str.Strings[i]);
  end;
{$ENDIF}

  try
      FQueryWrite.Close;
      FQueryWrite.SQL.Clear;
      FQueryWrite.SQL.Add('insert INTO qc_temperature');
      FQueryWrite.SQL.Add('(id, datetime, heat, grade, strength_class, section, standard, side, temperature)');
      FQueryWrite.SQL.Add('values(GEN_ID(gen_qc_temperature, 1), current_timestamp,');
      FQueryWrite.SQL.Add(''''+str.Strings[0]+''', '''+str.Strings[1]+''', '''+str.Strings[2]+''',');
      FQueryWrite.SQL.Add(''+str.Strings[3]+', '''+str.Strings[4]+''', '+str.Strings[5]+',');
      FQueryWrite.SQL.Add(''+str.Strings[6]+')');
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'FQueryWrite side -> ' + FQueryWrite.SQL.Text);
{$ENDIF}
      FQueryWrite.ExecQuery;
      FQueryWrite.Transaction.Commit;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;

  FQueryWrite.Free;
  FTransaction.Free;
  FDatabase.Free;
  str.Free;
end;



// ��� �������� ��������� ����� ����� �����������
initialization
  TcpWorks := TTcpWorks.Create;

//��� �������� ��������� ������������
finalization
  TcpWorks.Destroy;

end.
