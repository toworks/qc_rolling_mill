unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Math, IdContext,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPServer;

type
  TForm1 = class(TForm)
    Memo1: TMemo;

    procedure IdTCPServerConnect(AContext: TIdContext);
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
  msg_send: string = '';

  function Send(AContext: TIdContext): bool;

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
      IdTCPServer.OnConnect := IdTCPServerConnect;
      IdTCPServer.Active := true;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
end;


procedure TForm1.IdTCPServerConnect(AContext: TIdContext);
begin
  if AContext.Connection.Socket.Binding.PeerIP = '10.21.69.21' then
  begin
    //form1.Memo1.Lines.Add('tcp'+#9+'connect -> '+clients[1].clIP);
    Send(AContext);
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
    msg_send := msg;
  end
  else
  begin
      msg_send := '';
  end;
end;


function Send(AContext: TIdContext): bool;
var
  stream: TStringStream;
  i: integer;
begin
  try
      // ����� ����� �������� �������� � ����������
      stream := TStringStream.Create;
      stream.WriteString(msg_send+IdMsg); // ������ ��������� � �����
      stream.Position := 0; // ��������� ������� �� ������ ������
      try
//        form1.Memo1.Lines.Add('send ip -> '+AContext.Connection.Socket.Binding.PeerIP);
        AContext.Connection.IOHandler.Write(stream, stream.Size, true);
        finally
          AContext.Connection.Disconnect;
        end;
      finally
         stream.Free;
      end;
end;


end.
