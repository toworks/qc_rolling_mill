Program QCReadExternalSql;

Uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
  CThreads,
{$ENDIF}{$ENDIF}
  DaemonApp, lazdaemonapp, daemon, daemonmapper, settings,
  versioninfo, sql, thread_calculated_data, zcore;

{$R *.res}

begin
  Application.Title:='daemon application';
  Application.Initialize;
  Application.Run;
end.
