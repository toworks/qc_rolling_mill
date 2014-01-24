program QCRollingMillService;

uses
  Vcl.SvcMgr,
  main in 'main.pas' {Service1: TService},
  logging in 'logging.pas',
  settings in 'settings.pas',
  thread_main in 'thread_main.pas',
  sql in 'sql.pas',
  thread_calculated_data in 'thread_calculated_data.pas';

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
      Application.Initialize;
  Application.CreateForm(TService1, Service1);
  Application.Run;
end.
