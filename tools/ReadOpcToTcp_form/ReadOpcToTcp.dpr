program ReadOpcToTcp;

uses
  Vcl.Forms,
  logging in 'logging.pas',
  settings in 'settings.pas',
  thread_opc in 'thread_opc.pas',
  sql in 'sql.pas',
  main_form in 'main_form.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := false;
  Application.CreateForm(TForm1, Form1);
  Application.ShowMainForm := false;//no show form
  Application.Run;
end.
