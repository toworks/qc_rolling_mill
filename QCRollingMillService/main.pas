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
  ServiceName: string = 'QCRollingMillService';
  Version: string = ' v0.0';
  DBFile: string = 'data.sdb';
  LogFile: string = 'service.log';

// {$DEFINE DEBUG}

implementation

uses
  settings, logging, sql, thread_main, thread_calculated_data;

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
  try
      CurrentDir := ExtractFileDir(ParamStr(0));
      // ����� ������ ������� ��� �������������� � ������
      FormatSettings.DecimalSeparator := '.';
      ConfigSettings(true);
      ConfigPostgresSetting(true);
      ConfigOracleSetting(true);
      SaveLog('service' + #9#9 + 'start');
  except
      on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  try
      // ������� ����� False - ������� ���������, True - ������� ����������
      ThreadMain := TThreadMain.Create(True);
      ThreadMain.Priority := tpNormal;
      ThreadMain.FreeOnTerminate := True;
      ThreadMain.Start;
  except
      on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  try
      // ������� ����� False - ������� ���������, True - ������� ����������
      ThreadCalculatedData := TThreadCalculatedData.Create(True);
      ThreadCalculatedData.Priority := tpNormal;
      ThreadCalculatedData.FreeOnTerminate := True;
      ThreadCalculatedData.Start;
  except
      on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  Started := True;
end;


procedure TService1.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try
      ThreadMain.Terminate;
      ThreadCalculatedData.Terminate;
      Stopped := True;
      ConfigPostgresSetting(false);
      ConfigOracleSetting(false);
      ConfigSettings(false);
      SaveLog('service' + #9#9 + 'stop');
  except
      on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;




end.
