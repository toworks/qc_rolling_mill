program Project7;

uses
  Vcl.Forms,
  main in 'main.pas' {Form8},
  settings in 'settings.pas',
  logging in 'logging.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm8, Form8);
  Application.Run;
end.
