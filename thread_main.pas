unit thread_main;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Forms, SyncObjs;

type
  //����� ���������� ������� ����� TThreadMain:
  TThreadMain = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadMain: TThreadMain;

  {$DEFINE DEBUG}

  procedure WrapperMain;//������� ��� ������������� � ���������� � ������ �������


implementation

uses
  main, settings, logging, sql_module, chart, sql;




procedure TThreadMain.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      Synchronize(WrapperMain);
      sleep(250);
   end;
   CoUninitialize;
end;


procedure WrapperMain;
begin
  try
      Application.ProcessMessages;//��������� �������� �� �������� ���������
      SqlReadCurrentHeat;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
  try
      Application.ProcessMessages;//��������� �������� �� �������� ���������
      ViewsCharts;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;




// ��� �������� ��������� ����� ����� �����������
initialization
  //������� �����
  ThreadMain := TThreadMain.Create(true);
  ThreadMain.Priority := tpNormal;
  ThreadMain.FreeOnTerminate := True;

//��� �������� ��������� ������������
finalization
  ThreadMain.Terminate;

end.