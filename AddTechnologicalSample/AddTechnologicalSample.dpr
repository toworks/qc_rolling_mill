program AddTechnologicalSample;

uses
  Vcl.Forms,
  main in 'main.pas' {Form1},
  sql in 'sql.pas',
  settings in 'settings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
