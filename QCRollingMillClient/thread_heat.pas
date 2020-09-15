unit thread_heat;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Forms, SyncObjs;

type
  // ����� ���������� ������� ����� TThreadMain:
  TThreadHeat = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadHeat: TThreadHeat;

  // {$DEFINE DEBUG}

procedure WrapperHeat;
// ������� ��� ������������� � ���������� � ������ �������

implementation

uses
  main, settings, logging, chart, sql;

procedure TThreadHeat.Execute;
begin
  CoInitialize(nil);
  while True do
  begin
    Synchronize(WrapperHeat);
    sleep(1000);
    // ��� ���������� ���� ����������� ������� � charts ��� ����������� ��������� ��������
  end;
  CoUninitialize;
end;

procedure WrapperHeat;
begin
  try
    Application.ProcessMessages; // ��������� �������� �� �������� ���������
//    SqlReadCurrentHeat;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;

// ��� �������� ��������� ����� ����� �����������
initialization
// ������� �����
ThreadHeat := TThreadHeat.Create(True);
ThreadHeat.Priority := tpNormal;
ThreadHeat.FreeOnTerminate := True;

// ��� �������� ��������� ������������
finalization
ThreadHeat.Terminate;

end.
