unit daemonmapper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DaemonApp;

type

  { TDaemonMapper1 }

  TDaemonMapper1 = class(TDaemonMapper)
  private
    { private declarations }
  public
    { public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure ToDoOnInstall(Sender: TObject);
    procedure ToDoOnRun(Sender: TObject);
    procedure ToDoOnUninstall(Sender: TObject);
    procedure ToDoOnDestroy(Sender: TObject);
  end;

var
  DaemonMapper1: TDaemonMapper1;

implementation

uses
  settings{, logging};

{$R *.lfm}


constructor TDaemonMapper1.Create(AOwner: TComponent);
begin
  SaveLog.Log(etInfo, 'DaemonMapper.Create');
  inherited Create(AOwner);
  with DaemonDefs.Add as TDaemonDef do
  begin
    DaemonClassName := 'TDaemon1';
    Name := DaemonName;
    Description := DaemonDescription;
    DisplayName := Name;
    RunArguments := '--run';
    Options := [doAllowStop,doAllowPause];
    Enabled := true;
    with WinBindings do
    begin
      StartType := stBoot;
      WaitHint := 0;
      IDTag := 0;
      ServiceType := stWin32;
      ErrorSeverity := esNormal;//esIgnore;
    end;
//    OnCreateInstance := ?;
    LogStatusReport := false;
  end;
  OnInstall := @Self.ToDoOnInstall;
  OnRun := @Self.ToDoOnRun;
  OnUnInstall := @Self.ToDoOnUninstall;
  OnDestroy := @Self.ToDoOnDestroy;
  SaveLog.Log(etInfo, 'DaemonMapper.Createted');
end;

procedure TDaemonMapper1.ToDoOnInstall(Sender: TObject);
begin
  SaveLog.Log(etInfo, 'DaemonMapper.Install');
end;

procedure TDaemonMapper1.ToDoOnRun(Sender: TObject);
begin
  SaveLog.Log(etInfo, 'DaemonMapper.Run');
end;

procedure TDaemonMapper1.ToDoOnUnInstall(Sender: TObject);
begin
  SaveLog.Log(etInfo, 'DaemonMapper.Uninstall');
end;

procedure TDaemonMapper1.ToDoOnDestroy(Sender: TObject);
begin
  //doesn't comes here
  SaveLog.Log(etInfo, 'DaemonMapper.Destroy');
end;


initialization
  RegisterDaemonMapper(TDaemonMapper1)
end.

