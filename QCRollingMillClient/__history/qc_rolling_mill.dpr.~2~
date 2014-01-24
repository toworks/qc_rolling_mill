program qc_rolling_mill;

uses
  Vcl.Forms,
  main in 'main.pas' {Form1},
  sql_module in 'sql_module.pas' {DataModule1: TDataModule},
  thread_chart in 'thread_chart.pas',
  Chart in 'Chart.pas',
  thread_sql in 'thread_sql.pas',
  logging in 'logging.pas',
  thread_sql_chemistry in 'thread_sql_chemistry.pas',
  settings in 'settings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.Run;
end.
