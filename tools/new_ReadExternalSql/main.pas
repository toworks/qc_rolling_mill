unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  Registry;

type
  TService1 = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceShutdown(Sender: TService);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  Service1: TService1;
  CurrentDir: string;
  HeadName: string = 'управление качеством MC 250-5';
  ServiceName: string = 'ReadExternalSql';
  Version: string = ' v0.0';
  DBFile: string = 'data.sdb';
  LogFile: string = 'app.log';

implementation
uses
  settings, logging, sql, thread_opc;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  Service1.Controller(CtrlCode);
end;

function TService1.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;


procedure TService1.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    // Прописываем себе описание
    if Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\' + Name, false) then
    begin
      Reg.WriteString('Description', HeadName);
      Reg.CloseKey;
    end;
  finally
    FreeAndNil(Reg);
  end;
end;


procedure TService1.ServiceCreate(Sender: TObject);
begin
  // текущая дириктория
  CurrentDir := ExtractFileDir(ParamStr(0));
  Name := DisplayName;
  DisplayName := ServiceName;
end;


procedure TService1.ServiceShutdown(Sender: TService);
var
  Stopped : boolean;
begin
  // is called when windows shuts down
  ServiceStop(Self, Stopped);
end;


procedure TService1.ServiceStart(Sender: TService; var Started: Boolean);
begin
  // текущая дириктория
//  CurrentDir := ExtractFileDir(ParamStr(0));

  ConfigSettings(true);
  FbInit(true);

  if ThreadOpc <> nil then
    ThreadOpc.Start
  else
  begin
    ThreadOpc := TThreadOpc.Create(false);
    ThreadOpc.Priority := tpNormal;
    ThreadOpc.FreeOnTerminate := True;
  end;
end;


procedure TService1.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  ThreadOpc.Terminate;
  FbInit(false);
  ConfigSettings(false);
end;




end.
