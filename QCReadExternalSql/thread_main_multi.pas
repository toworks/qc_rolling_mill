unit thread_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, sql;

type
  TThreadMain = class(TThread)
  private
  protected
    procedure Execute; override;
  public
  end;


{type
  TThreadRM3 = class(TThread)
  private
  protected
    procedure Execute; override;
  public
  end;}


var
   ThreadRM: array [1..5] of TThreadMain;
//   ThreadRM3: TThreadRM3;
   CriticalSection: TCriticalSection;

   {$DEFINE DEBUG}

   function ThreadMainCreateAndDestroy(InData: boolean): boolean;


implementation

uses
    daemonmapper, daemon, settings{, sql};



function ThreadMainCreateAndDestroy(InData: boolean): boolean;
var
   i: integer;
begin
  for i:=1 to 5 do begin
   if InData then begin
     if FbSqlSettings[i].enable = 1 then begin
        // создаем поток True - создание остановка, False - создание старт
        ThreadRM[i] := TThreadMain.Create(True);
        ThreadRM[i].Priority := tpNormal;
        ThreadRM[i].FreeOnTerminate := True;
        ThreadRM[i].Start;
     end;
   end else begin
     if FbSqlSettings[i].enable = 1 then
        ThreadRM[i].Terminate;
   end;
  end;

  if InData then
     CriticalSection := TCriticalSection.Create
  else
     CriticalSection.Destroy;
end;


procedure TThreadMain.Execute;
var i: integer;
begin
  i := 0;
  SaveLog.Log(etInfo, 'thread execute');
  try
    repeat
      Sleep(500); //milliseconds
 {$IFDEF DEBUG}
      inc(i);
      SaveLog.Log(etDebug, 'thread loop ' + Format('tick :%d', [i]));
 {$ENDIF}
//      CriticalSection.Enter;
      try
      CriticalSection.Enter;
         if (not FbSqlSettings[1].configured) and (FbSqlSettings[1].enable = 1) then
            ConfigFirebirdSettingToOldIB(true);
         if FbSqlSettings[1].configured then ReadSqlOld;
 {$IFDEF DEBUG}
   SaveLog.Log(etDebug, 'thread CriticalSection rm 1');
 {$ENDIF}
      CriticalSection.Leave;
      CriticalSection.Enter;
         if (not FbSqlSettings[3].configured) and (FbSqlSettings[3].enable = 1) then
            ConfigFirebirdSetting(true, 3);
         if FbSqlSettings[3].configured then ReadSql(3);
 {$IFDEF DEBUG}
   SaveLog.Log(etDebug, 'thread CriticalSection rm 3');
 {$ENDIF}
      CriticalSection.Leave;
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
end;




end.

