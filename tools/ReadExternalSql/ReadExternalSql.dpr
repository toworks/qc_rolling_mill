program ReadExternalSql;

uses
  Vcl.Forms,
  logging in 'logging.pas',
  settings in 'settings.pas',
  main in 'main.pas' {Form1},
  tcp_send_read in 'tcp_send_read.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := false;
  Application.CreateForm(TForm1, Form1);
  Application.ShowMainForm := false;//no show form
  Application.Run;
end.
