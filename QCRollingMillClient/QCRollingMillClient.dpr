program QCRollingMillClient;

uses
  Vcl.Forms,
  main in 'main.pas' {Form1},
  chart in 'chart.pas',
  sql in 'sql.pas',
  logging in 'logging.pas',
  settings in 'settings.pas',
  thread_main in 'thread_main.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
