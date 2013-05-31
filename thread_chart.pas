unit thread_chart;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Forms, SyncObjs;

type
  //����� ���������� ������� ����� TViewThread:
  TThreadChart = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadChart: TThreadChart;

  function ThreadChartInit: bool;
  procedure WrapperChart;//������� ��� ������������� � ���������� � ������ �������



implementation

uses
  main, sql_module, chart, thread_sql;




procedure TThreadChart.Execute;
var
  i:integer;
  e:bool;
begin
  CoInitialize(nil);
  while True do
   begin
      Synchronize(WrapperChart);
      sleep(100);
   end;
   CoUninitialize;
end;


function ThreadChartInit: bool;
begin
        //������� �����
        ThreadChart:=TThreadChart.Create(False);
        ThreadChart.Priority:=tpNormal;
        ThreadChart.FreeOnTerminate := True;
end;


procedure WrapperChart;
begin
      Application.ProcessMessages;//��������� �������� �� �������� ���������
      ViewsCharts;
end;






end.