unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Math, IdContext,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPServer;

type
  TForm1 = class(TForm)
    Memo1: TMemo;

    procedure IdTCPServerExecute(AContext: TIdContext);
    procedure FormCreate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
var
  IdTCPServer: TIdTCPServer;

  CurrentDir: string;
  HeadName: string = '������ - ���������� ��������� MC 250-5';
  Version: string = ' v0.0beta';
  DBFile: string = 'data.sdb';
  LogFile: string = 'app.log';
  // id ��� ������������� ���������
  IdMsg: string = 'Q0yiEOEf3QHdlmhxQFCFif7ArgmzQsdxqZvLl2r5KL4kebXx1BykPfaGzzVhCNFCYlRiTLtGWhcEFOte7Nl9X5rSfDUBbGeYyseW';

  function SqlWriteTemperature(InTempLeft, InTempRight: integer): bool;

implementation

uses
  settings, sql, logging;

{$R *.dfm}



procedure TForm1.FormCreate(Sender: TObject);
begin

  CurrentDir := GetCurrentDir;
  ConfigSettings(true);
  ConfigFirebirdSetting(true);


   try
      IdTCPServer := TIdTCPServer.Create(nil);
      IdTCPServer.Bindings.Add.IP := '0.0.0.0';
      IdTCPServer.Bindings.Add.Port := strtoint('33333');
      IdTCPServer.DefaultPort := strtoint('33333');
      IdTCPServer.OnExecute := IdTCPServerExecute;
      IdTCPServer.Active := true;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
end;


procedure TForm1.IdTCPServerExecute(AContext: TIdContext);
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
    form1.Memo1.Lines.Add(msg);
//    form1.Memo1.SelStart := 0;
    try
        SqlWriteTemperature(strtoint(msg), strtoint(msg));
        except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end;
end;

function SqlWriteTemperature(InTempLeft, InTempRight: integer): bool;
var
  i, Temperature: integer;
begin

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'InTempLeft -> ' + inttostr(InTempLeft));
  SaveLog('debug' + #9#9 + 'InTempRight -> ' + inttostr(InTempRight));
{$ENDIF}
{
  try
    FQueryOPC.Close;
    FQueryOPC.SQL.Clear;
    FQueryOPC.SQL.Add('select FIRST 1 * from qc_temperature');
    FQueryOPC.ExecQuery;
    FQueryOPC.Transaction.Commit;
  except
    FQueryOPC.Close;
    FQueryOPC.SQL.Clear;
    FQueryOPC.SQL.Add('EXECUTE BLOCK AS BEGIN');
    FQueryOPC.SQL.Add('if (not exists(select 1 from rdb$relations where rdb$relation_name = ''qc_temperature'')) then');
    FQueryOPC.SQL.Add('execute statement ''create table qc_temperature (');
    FQueryOPC.SQL.Add('id NUMERIC(18,0) NOT NULL, DATETIME TIMESTAMP NOT NULL,');
    FQueryOPC.SQL.Add('heat VARCHAR(26) NOT NULL, grade VARCHAR(50),');
    FQueryOPC.SQL.Add('strength_class VARCHAR(50), section VARCHAR(50),');
    FQueryOPC.SQL.Add('standard VARCHAR(50), side integer NOT NULL, temperature integer,');
    FQueryOPC.SQL.Add('PRIMARY KEY (id));'';');
    FQueryOPC.SQL.Add('execute statement ''CREATE SEQUENCE gen_qc_temperature;'';');
    FQueryOPC.SQL.Add('END');
    FQueryOPC.ExecQuery;
    FQueryOPC.Transaction.Commit;
  end;

  try
      // ������ ������� �� ������ ������
      FQueryOPC.Close;
      FQueryOPC.SQL.Clear;
      // ������� ������ ������ 10 ������� (300 ����)
      FQueryOPC.SQL.Add('DELETE FROM qc_temperature where');
      FQueryOPC.SQL.Add('datetime < current_timestamp-300');
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.Commit;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
}
  for i := 0 to 1 do
  begin
    if i=0 then
      Temperature := InTempLeft;
    if i=1 then
      Temperature := InTempRight;

    if Temperature > 250 then
    begin
      try
        FQueryOPC.Close;
        FQueryOPC.SQL.Clear;
        FQueryOPC.SQL.Add('insert INTO qc_temperature');
        FQueryOPC.SQL.Add('(id, datetime, heat, grade, strength_class, section, standard, side, temperature)');
        FQueryOPC.SQL.Add('select GEN_ID(gen_qc_temperature, 1), current_timestamp,');
        FQueryOPC.SQL.Add('NOPLAV, MARKA, KLASS, RAZM1, STANDART, SIDE,');
        FQueryOPC.SQL.Add(''+inttostr(Temperature)+'');
        FQueryOPC.SQL.Add('FROM melts');
        FQueryOPC.SQL.Add('where side='+inttostr(i)+'');
//        FQueryOPC.SQL.Add('order by begindt desc');
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'FQueryOPC side '+inttostr(i)+' -> ' + FQueryOPC.SQL.Text);
{$ENDIF}
        FQueryOPC.ExecQuery;
        FQueryOPC.Transaction.Commit;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      end;
    end;
  end;
end;


end.
