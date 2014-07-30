unit thread_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs{, Variants, ActiveX};

type
  TThreadMain = class(TThread)
  private
//    function ConfigFirebirdSettingToOldIB(InData: boolean): boolean;
//    procedure ReadSqlOld;
  protected
    procedure Execute; override;
  public
  end;

var
   ThreadMain: TThreadMain;
   CriticalSection: TCriticalSection;

//   {$DEFINE DEBUG}

   function ThreadMainCreateAndDestroy(InData: boolean): boolean;


implementation

uses
    daemonmapper, daemon, settings, sql;



function ThreadMainCreateAndDestroy(InData: boolean): boolean;
begin
  if InData then
  begin
    // создаем поток True - создание остановка, False - создание старт
    ThreadMain := TThreadMain.Create(True);
    ThreadMain.Priority := tpNormal;
    ThreadMain.FreeOnTerminate := True;
    ThreadMain.Start;
    CriticalSection := TCriticalSection.Create;
  end
  else begin
    CriticalSection.Destroy;
    ThreadMain.Terminate;
  end;
end;


procedure TThreadMain.Execute;
var i: integer;
begin
//  CoInitialize(nil);
  i := 0;
  SaveLog.Log(etInfo, 'thread execute');
  try
    repeat
      Sleep(1000); //milliseconds
 {$IFDEF DEBUG}
      inc(i);
      SaveLog.Log(etDebug, 'thread loop ' + Format('tick :%d', [i]));
 {$ENDIF}
//      CriticalSection.Enter;
      try
{         if (not FbSqlSettings[1].configured) and (FbSqlSettings[1].enable = 1) then
            ConfigFirebirdSettingToOldIB(true);
         if FbSqlSettings[1].configured then ReadSqlOld;}
         if (not FbSqlSettings[3].configured) and (FbSqlSettings[3].enable = 1) then
            ConfigFirebirdSetting(true, 3);
         if FbSqlSettings[3].configured then ReadSql(3);
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: '+UTF8Encode(E.Message));
      end;
//      CriticalSection.Leave;

    until Terminated;
    SaveLog.Log(etInfo, 'tread loop stopped');
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+UTF8Encode(E.Message));
  end;
//  CoUninitialize;
end;




end.

