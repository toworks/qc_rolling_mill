unit thread_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

type
  TThreadRM1 = class(TThread)
  private
  protected
    procedure Execute; override;
  public
  end;

type
  TThreadRM3 = class(TThread)
  private
  protected
    procedure Execute; override;
  public
  end;


var
   ThreadRM1: TThreadRM1;
   ThreadRM3: TThreadRM3;
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
    CriticalSection := TCriticalSection.Create;
    if FbSqlSettings[1].enable = 1 then begin
       // создаем поток True - создание остановка, False - создание старт
       ThreadRM1 := TThreadRM1.Create(True);
       ThreadRM1.Priority := tpNormal;
       ThreadRM1.FreeOnTerminate := True;
       ThreadRM1.Start;
    end;
    if FbSqlSettings[3].enable = 1 then begin
       // создаем поток True - создание остановка, False - создание старт
       ThreadRM3 := TThreadRM3.Create(True);
       ThreadRM3.Priority := tpNormal;
       ThreadRM3.FreeOnTerminate := True;
       ThreadRM3.Start;
    end;
  end
  else begin
    if FbSqlSettings[1].enable = 1 then
       ThreadRM1.Terminate;
    if FbSqlSettings[3].enable = 1 then
       ThreadRM3.Terminate;
    CriticalSection.Destroy;
  end;
end;


procedure TThreadRM1.Execute;
var i: integer;
begin
  i := 0;
  SaveLog.Log(etInfo, 'thread rolling mill 1: execute');
  try
    repeat
      { 2 секунды - не нагружать interbase }
      Sleep(2000); //milliseconds
 {$IFDEF DEBUG}
      inc(i);
      SaveLog.Log(etDebug, 'thread loop rolling mill 1 ' + Format('tick :%d', [i]));
 {$ENDIF}
      CriticalSection.Enter;
      try
         if (not FbSqlSettings[1].configured) and (FbSqlSettings[1].enable = 1) then
             ConfigFirebirdSettingToOldIB(true);
         if FbSqlSettings[1].configured then ReadSqlOld;
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: '+UTF8Encode(E.Message));
      end;
      CriticalSection.Leave;
    until Terminated;
    SaveLog.Log(etInfo, 'tread loop rolling mill 1: stopped');
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+UTF8Encode(E.Message));
  end;
end;


procedure TThreadRM3.Execute;
var i: integer;
begin
  i := 0;
  SaveLog.Log(etInfo, 'thread rolling mill 3: execute');
  try
    repeat
      Sleep(1000); //milliseconds
 {$IFDEF DEBUG}
      inc(i);
      SaveLog.Log(etDebug, 'thread loop rolling mill 3 ' + Format('tick :%d', [i]));
 {$ENDIF}
      CriticalSection.Enter;
      try
         if (not FbSqlSettings[3].configured) and (FbSqlSettings[3].enable = 1) then
            ConfigFirebirdSetting(true, 3);
         if FbSqlSettings[3].configured then ReadSql(3);
      except
        on E: Exception do
          SaveLog.Log(etError, E.ClassName + ', с сообщением: '+UTF8Encode(E.Message));
      end;
      CriticalSection.Leave;
    until Terminated;
    SaveLog.Log(etInfo, 'tread loop rolling mill 3: stopped');
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+UTF8Encode(E.Message));
  end;
end;




end.

