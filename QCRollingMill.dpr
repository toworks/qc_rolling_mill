program QCRollingMill;

uses
  Vcl.Forms,
  main in 'main.pas' {Form1},
  sql_module in 'sql_module.pas' {Module: TDataModule},
  chart in 'chart.pas',
  sql in 'sql.pas',
  logging in 'logging.pas',
  settings in 'settings.pas',
  thread_opc in 'thread_opc.pas',
  tcp_send_read in 'tcp_send_read.pas',
  thread_main in 'thread_main.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TModule, Module);
  Application.Run;
end.
