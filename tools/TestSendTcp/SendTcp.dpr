program SendTcp;

uses
  Vcl.Forms,
  main in 'main.pas' {Form1},
  logging in 'logging.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
