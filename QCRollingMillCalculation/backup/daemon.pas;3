unit daemon;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DaemonApp;

type
  TDaemon1 = class(TDaemon)
  private
    { private declarations }
    procedure ThreadStopped(Sender: TObject);
  public
    { public declarations }
    function Install: boolean; override;
    function UnInstall: boolean; override;
    function Start: boolean; override;
    function Stop: boolean; override;
    function Pause: boolean; override;
    function Continue: boolean; override;
    function Execute: boolean; override;
    function ShutDown: boolean; override;
  end;

var
  Daemon1: TDaemon1;

implementation

uses
  settings, daemonmapper, thread_calculated_data;

{$R *.lfm}


procedure TDaemon1.ThreadStopped(Sender: TObject);
begin
//  if ThreadMain <> nil then
//    FreeAndNil(ThreadMain);
  SaveLog.Log(etInfo, 'Daemon.ThreadStopped');
end;

function TDaemon1.Install: boolean;
begin
  result := inherited Install;
  SaveLog.Log(etInfo, 'Daemon.installed: ' + BoolToStr(result));
end;

function TDaemon1.UnInstall: boolean;
begin
  result := inherited UnInstall;
  SaveLog.Log(etInfo, 'Daemon.Uninstall: ' + BoolToStr(result));
end;

function TDaemon1.Start: boolean;
begin
  result := inherited Start;
  SaveLog.Log(etInfo, 'Daemon.Start: ' + BoolToStr(result));
  // создаем поток True - создание остановка, False - создание старт
  ThreadCalculatedData := TThreadCalculatedData.Create(True);
  ThreadCalculatedData.Priority := tpNormal;
  ThreadCalculatedData.FreeOnTerminate := True;
  ThreadCalculatedData.Start;
end;

function TDaemon1.Stop: boolean;
begin
  result := inherited Stop;
  SaveLog.Log(etInfo, 'Daemon.Stop: ' + BoolToStr(result));
  ThreadCalculatedData.Terminate;
end;

function TDaemon1.Pause: boolean;
begin
  result := inherited Pause;
  SaveLog.Log(etInfo, 'Daemon.Pause: ' + BoolToStr(result));
//  ThreadMain.Suspend;
  Stop;
end;

function TDaemon1.Continue: boolean;
begin
  result := inherited Continue;
  SaveLog.Log(etInfo, 'Daemon.Continue: ' + BoolToStr(result));
//  ThreadMain.Start;
  Start;
end;

function TDaemon1.Execute: boolean;
begin
  result := inherited Execute;
  SaveLog.Log(etInfo, 'Daemon.Execute: ' + BoolToStr(result));
end;

function TDaemon1.ShutDown: boolean;
begin
  result := inherited ShutDown;
  SaveLog.Log(etInfo, 'Daemon.ShutDown: ' + BoolToStr(result));
end;


initialization
  RegisterDaemonClass(TDaemon1)
end.

