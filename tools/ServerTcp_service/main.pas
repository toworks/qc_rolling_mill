unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, Registry, SyncObjs;

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
  HeadName: string = '���������� ��������� MC 250-5';
  ServiceName: string = 'ServerTcp';
  Version: string = ' v0.0';
  DBFile: string = 'data.sdb';
  LogFile: string = 'service.log';

 {$DEFINE DEBUG}

implementation

uses
  settings, logging, sql, thread_main, tcp;

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
    // ����������� ���� ��������
    if Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\' + Name {ServiceName}, false) then
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
  // ������� ����������
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
  // ������� ����������
  CurrentDir := ExtractFileDir(ParamStr(0));
  SaveLog('service' + #9#9 + 'start');
  ConfigSettings(true);
  ConfigFirebirdSetting(true);
  ConfigOracleSetting(true);
  ConfigTcpSetting(true);

  // ������� ����� False - ������� ���������, True - ������� ����������
  ThreadMain := TThreadMain.Create(True);
  ThreadMain.Priority := tpNormal;
  ThreadMain.FreeOnTerminate := True;
  Started := True;
end;


procedure TService1.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try
      ThreadMain.Terminate;
      Stopped := True;
      ConfigTcpSetting(false);
      ConfigFirebirdSetting(false);
      ConfigOracleSetting(false);
      ConfigSettings(false);
  finally
      SaveLog('service' + #9#9 + 'stop');
  end;
end;




end.
