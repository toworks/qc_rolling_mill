unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Math, IdContext,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdException;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Timer1: TTimer;
    Button1: TButton;

    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

type
  EIdException = class(Exception);
  EIdReadTimeout = class(EIdException);

var
  IdTCPClient: TIdTCPClient;

  CurrentDir: string;
  HeadName: string = '������ - ���������� ��������� MC 250-5';
  Version: string = ' v0.0beta';
  DBFile: string = 'data.sdb';
  LogFile: string = 'app.log';
  // id ��� ������������� ���������
  IdMsg: string = 'Q0yiEOEf3QHdlmhxQFCFif7ArgmzQsdxqZvLl2r5KL4kebXx1BykPfaGzzVhCNFCYlRiTLtGWhcEFOte7Nl9X5rSfDUBbGeYyseW';
  Marker: bool = true;

  {$DEFINE DEBUG}

  function ReadServer: bool;
  function SqlWriteTemperature(InTempLeft, InTempRight: integer): bool;

implementation

uses
  settings, sql, logging;

{$R *.dfm}



procedure TForm1.Button1Click(Sender: TObject);
begin
  if not Timer1.Enabled then
  begin
    Timer1.Interval:=1000;
    Timer1.Enabled := true;
    button1.Caption := 'stop';
  end
  else
  begin
        Timer1.Enabled := false;
        button1.Caption := 'start';
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  CurrentDir := GetCurrentDir;
  ConfigSettings(true);
  ConfigFirebirdSetting(true);


   try
      IdTCPClient := TIdTCPClient.Create(nil);
      IdTCPClient.Host := '10.21.69.21';
      IdTCPClient.Port := strtoint('33333');
//      IdTCPClient.Connect;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
end;


function ReadServer: bool;
var
  stream: TStringStream;
  msg: string;
  LSize: longint;
begin
  Marker:=false;
  try
    stream := TStringStream.Create;
    //AContext.Connection.IOHandler.ReadStream(stream);
    //IdTCPClient.Socket.ReadStream(stream);
//    IdTCPClient.IOHandler.ReadStream(stream, stream.Size, true);
    LSize := IdTCPClient.IOHandler.ReadLongInt();
    IdTCPClient.IOHandler.ReadStream(stream, LSize, False);
//    IdTCPClient.IOHandler.ReadStream(stream, stream.Size, False);

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
        Marker:=true;
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

  try
    FQueryOPC.Close;
    FQueryOPC.SQL.Clear;
    FQueryOPC.SQL.Add('select FIRST 1 * from qc_temperature');
    Application.ProcessMessages;
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
    Application.ProcessMessages;
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
      Application.ProcessMessages;
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.Commit;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

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
        FQueryOPC.SQL.Add('select FIRST 1 GEN_ID(gen_qc_temperature, 1), current_timestamp,');
        FQueryOPC.SQL.Add('NOPLAV, MARKA, KLASS, RAZM1, STANDART, SIDE,');
        FQueryOPC.SQL.Add(''+inttostr(Temperature)+'');
        FQueryOPC.SQL.Add('FROM melts');
        FQueryOPC.SQL.Add('where side='+inttostr(i)+'');
        FQueryOPC.SQL.Add('order by begindt desc');
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'FQueryOPC side '+inttostr(i)+' -> ' + FQueryOPC.SQL.Text);
{$ENDIF}
        Application.ProcessMessages;
        FQueryOPC.ExecQuery;
        FQueryOPC.Transaction.Commit;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      end;
    end;
  end;
end;


procedure TForm1.Timer1Timer(Sender: TObject);
var
  stream: TStringStream;
  msg: string;
begin

  if (not IdTCPClient.Connected) and Marker then
  begin
    try
        IdTCPClient.Connect;
        Application.ProcessMessages;
        ReadServer;
    except
      on  E: EIdReadTimeout do//���������� ������ ��������
         SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      else
       IdTCPClient.Disconnect;//���� �� �� ��� �� �������������
    end;
  end;
exit;
  try
    stream := TStringStream.Create;
    //AContext.Connection.IOHandler.ReadStream(stream);
    //IdTCPClient.Socket.ReadStream(stream);
    IdTCPClient.IOHandler.ReadStream(stream);

    // ������ �� ��������� � �����
    stream.Position := 0; // ��������� ������� �� ������ ������
    msg := stream.ReadString(stream.Size);
  finally
    stream.Free;
  end;
end;

end.
