Program QCReadExternalSql;

Uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
  CThreads,
{$ENDIF}{$ENDIF}
  DaemonApp, lazdaemonapp, daemon, daemonmapper, settings, thread_main,
  versioninfo, sql, zcore;

{$R *.res}

begin
  Application.Title:='QCReadExternalSql daemon application';
  Application.Initialize;
  Application.Run;
end.
