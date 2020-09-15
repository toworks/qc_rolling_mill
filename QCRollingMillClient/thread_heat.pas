unit thread_heat;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Forms, SyncObjs;

type
  // Здесь необходимо описать класс TThreadMain:
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
// обертка для синхронизации и выполнения с другим потоком

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
    // при уменьшении надо увеличивать счетчик в charts для правильного затирания графиков
  end;
  CoUninitialize;
end;

procedure WrapperHeat;
begin
  try
    Application.ProcessMessages; // следующая операция не тормозит интерфейс
//    SqlReadCurrentHeat;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;
end;

// При загрузке программы класс будет создаваться
initialization
// создаем поток
ThreadHeat := TThreadHeat.Create(True);
ThreadHeat.Priority := tpNormal;
ThreadHeat.FreeOnTerminate := True;

// При закрытии программы уничтожаться
finalization
ThreadHeat.Terminate;

end.
