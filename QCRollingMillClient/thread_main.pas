unit thread_main;

interface

uses
  SysUtils, Classes, SyncObjs;

type
  TThreadMain = class(TThread)

  private
    procedure ChartsLeft;
    procedure ChartsRight;
  protected
    procedure Execute; override;
  public
    Constructor Create; overload;
    Destructor Destroy; override;
  end;


var
  ThreadMain: TThreadMain;
  CriticalSectionMain: TCriticalSection;

//  {$DEFINE DEBUG}

implementation

uses
  settings, gui, chart, thread_heat;


constructor TThreadMain.Create;
begin
  inherited;
  CriticalSectionMain := TCriticalSection.Create;
  // создаем поток True - создание остановка, False - создание старт
  ThreadMain := TThreadMain.Create(True);
  ThreadMain.Priority := tpNormal;
  ThreadMain.FreeOnTerminate := True;
  ThreadMain.Start;
end;


destructor TThreadMain.Destroy;
begin
  if ThreadMain <> nil then begin
    ThreadMain.Terminate;
    CriticalSectionMain.Destroy;
  end;
  inherited Destroy;
end;


procedure TThreadMain.Execute;
var i: integer;
begin
  i := 0;
  SaveLog.Log(etInfo, 'thread main execute');
  try
    repeat
      Sleep(1000); //milliseconds
 {$IFDEF DEBUG}
   inc(i);
   SaveLog.Log(etDebug, 'thread main loop ' + Format('tick :%d', [i]));
 {$ENDIF}
      CriticalSectionMain.Enter;
      try
         if left <> nil then begin
            ViewCurrentDataLeft;
            Synchronize(@ChartsLeft);
         end;
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
      end;

      try
         if right <> nil then begin
            ViewCurrentDataRight;
            Synchronize(@ChartsRight);
         end;
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
      end;
      CriticalSectionMain.Leave;

    until Terminated;
    SaveLog.Log(etInfo, 'tread main loop stopped');
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;
end;


procedure TThreadMain.ChartsLeft;
begin
  ViewsChartsLeft;
end;


procedure TThreadMain.ChartsRight;
begin
  ViewsChartsRight;
end;



// При загрузке программы класс будет создаваться
initialization
ThreadMain := TThreadMain.Create;


// При закрытии программы уничтожаться
finalization
ThreadMain.Destroy;


end.
