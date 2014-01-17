unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Math, IdContext,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Timer1: TTimer;
    e_ip: TEdit;
    e_port: TEdit;

    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  // id ��� ������������� ���������
  IdMsg: string = 'Q0yiEOEf3QHdlmhxQFCFif7ArgmzQsdxqZvLl2r5KL4kebXx1BykPfaGzzVhCNFCYlRiTLtGWhcEFOte7Nl9X5rSfDUBbGeYyseW';
var
  IdTCPClient: TIdTCPClient;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
//    if (e_ip.Text = '') or (e_port.Text = '') then
//        exit;


    try
      IdTCPClient := TIdTCPClient.Create(nil);
      IdTCPClient.Host := 'krr-ws03485';
      IdTCPClient.Port := strtoint('33333');
    except
      on E: Exception do
        showmessage('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;

      if timer1.Enabled then
          timer1.Enabled := false
      else
          timer1.Enabled := true;
end;




procedure TForm1.Timer1Timer(Sender: TObject);
var
  msg: TStringStream;
  InData: string;
begin

  InData := inttostr(RandomRange(250, 1300));

  try
      IdTCPClient.Connect;
      try
        // ����� ����� �������� �������� � ����������
        msg := TStringStream.Create;
//        msg.WriteString(InData+#9+datetimetostr(now)+IdMsg); // ������ ��������� � �����
        msg.WriteString(InData+IdMsg); // ������ ��������� � �����
        msg.Position := 0; // ��������� ������� �� ������ ������
        IdTCPClient.IOHandler.Write(msg, msg.Size, true);
      finally
        msg.Free;
      end;
      IdTCPClient.Disconnect;
  except
    on E: Exception do
      showmessage('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;

end.
