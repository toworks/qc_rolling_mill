{
  для работы с OPC используется  OPCDAAuto.dll  из комплекта "OPC DA Auto 2.02 Source Code 5.30.msi"
  установка:
  import component -> import a type library -> OPC DA Automation Wrapper 2.02 version 1.0 ->
  pallete page ActiveX -> install new package
  compile -> install
  unhide button ActiveX (TOPCGroups,TOPCGroup,TOPCActivator,TOPCServer)
  в uses добавить (OPCAutomation_TLB,OleServer)
}

unit thread_opc;

interface

uses
  SysUtils, Classes, Windows, ActiveX, OPCAutomation_TLB, OleServer, Forms,
  ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection,
  ZAbstractRODataset,
  ZStoredProcedure;

type
  TThreadOpc = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadOpc: TThreadOpc;
  OPCServer: TOPCServer;
  OPCGroup1: TOPCGroup;
  OPCGroup: IOPCGroup;
  OPCTagArray: Array [1 .. 10] of OPCItem;
  OPCGroupName: string = 'QCRollingMill';

  // {$DEFINE DEBUG}

procedure WrapperOpc; // обертка для синхронизации и выполнения с другим потоком
function ConfigOPCServer(InData: bool): bool;
function OPCReadTags: bool;
function SqlWriteTemperature(InTempLeft, InTempRight: integer): bool;

implementation

uses
  logging, settings, main, sql;

procedure TThreadOpc.Execute;
begin
  CoInitialize(nil);
  while True do
  begin
    Synchronize(WrapperOpc);
    sleep(500);
  end;
  CoUninitialize;
end;

procedure WrapperOpc;
begin
  Application.ProcessMessages; // следующая операция не тормозит интерфейс
  try
//    OPCReadTags;
      SaveLog('test'+#9#9+'opc work');
  except
    on E: Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;
end;

function ConfigOPCServer(InData: bool): bool;
begin

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'OpcConfigServerName -> ' + OpcConfigArray[1]);
{$ENDIF}
  if InData and (OpcConfigArray[1] <> '') then
  begin
    try
      OPCServer := TOPCServer.Create(nil);
      OPCGroup1 := TOPCGroup.Create(nil);

      OPCServer.Connect1(OpcConfigArray[1]);
      OPCGroup := OPCServer.OPCGroups.Add(OPCGroupName);
      OPCGroup.UpdateRate := 500;
      OPCGroup.IsActive := True;
      OPCGroup.IsSubscribed := True;

      // создаем Tags
      OPCTagArray[1] := OPCGroup.OPCItems.AddItem(OpcConfigArray[2], 1);
      OPCTagArray[2] := OPCGroup.OPCItems.AddItem(OpcConfigArray[3], 2);
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end;

  if (InData = false) and (OpcConfigArray[1] <> '') then
  begin
    try
      OPCGroup.IsActive := false;
      OPCGroup.IsSubscribed := false;
      OPCServer.OPCGroups.Remove(OPCGroupName);
      OPCServer.Disconnect;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end;
end;

function OPCReadTags: bool;
var
  Tags: Array [1 .. 4, 1 .. 4] of OleVariant;
  // read 4 values -> source,value,quality,timestamp
begin

  OPCTagArray[1].Read(Tags[1, 1], Tags[1, 2], Tags[1, 3], Tags[1, 4]);
  OPCTagArray[2].Read(Tags[2, 1], Tags[2, 2], Tags[1, 3], Tags[2, 4]);
  // OPCTagArray[3].Read(Tags[3,1],Tags[3,2],Tags[3,3],Tags[3,4]);
  // OPCTagArray[4].Read(Tags[4,1],Tags[4,2],Tags[4,3],Tags[4,4]);

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'TempLeft -> ' + inttostr(Tags[1, 2]));
  SaveLog('debug' + #9#9 + 'TempRight -> ' + inttostr(Tags[2, 2]));
{$ENDIF}
  SqlWriteTemperature(Tags[1, 2], Tags[2, 2]);

end;

function SqlWriteTemperature(InTempLeft, InTempRight: integer): bool;
begin

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'InTempLeft -> ' + inttostr(InTempLeft));
  SaveLog('debug' + #9#9 + 'InTempRight -> ' + inttostr(InTempRight));
{$ENDIF}

  try
    FQueryOPC.Close;
    FQueryOPC.SQL.Clear;
    FQueryOPC.SQL.Add('select FIRST 1 * from qc_temperature');
    FQueryOPC.ExecQuery;
    FQueryOPC.Transaction.Commit;
  except
    FQueryOPC.Close;
    FQueryOPC.SQL.Clear;
    FQueryOPC.SQL.Add('EXECUTE BLOCK AS BEGIN');
    FQueryOPC.SQL.Add('if (not exists(select 1 from rdb$relations where rdb$relation_name = ''qc_temperature'')) then');
    FQueryOPC.SQL.Add('execute statement ''create table qc_temperature (');
    FQueryOPC.SQL.Add('id NUMERIC(18,0) NOT NULL, datetime TIMESTAMP NOT NULL,');
    FQueryOPC.SQL.Add('heat VARCHAR(26) NOT NULL, grade VARCHAR(50),');
    FQueryOPC.SQL.Add('strength_class VARCHAR(50), section VARCHAR(50),');
    FQueryOPC.SQL.Add('standard VARCHAR(50), side integer NOT NULL, temperature integer,');
    FQueryOPC.SQL.Add('PRIMARY KEY (id));''');
    FQueryOPC.SQL.Add('execute statement ''CREATE SEQUENCE qc_temperature;''');
    FQueryOPC.SQL.Add('END');
    FQueryOPC.ExecQuery;
    FQueryOPC.Transaction.Commit;
  end;

  try
      // чистим таблицу от старых данных
      FQueryOPC.Close;
      FQueryOPC.SQL.Clear;
      // удаляем записи старше 10 месяцев (300 дней)
      FQueryOPC.SQL.Add('DELETE FROM qc_temperature where');
      FQueryOPC.SQL.Add('datetime < current_timestamp-300');
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.Commit;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;

 { if InTempLeft > 250 then
  begin
    try
      FQueryOPC.Close;
      FQueryOPC.SQL.Clear;
      FQueryOPC.SQL.Add('select FIRST 1 * FROM melts');
      FQueryOPC.SQL.Add('where side=0');
      FQueryOPC.SQL.Add('order by begindt desc');
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.Commit;

      SQueryOPC.Close;
      SQueryOPC.SQL.Clear;
      SQueryOPC.SQL.Add('insert INTO temperature');
      SQueryOPC.SQL.Add
        ('(timestamp, heat, grade, strength_class, section, standard, side, temperature)');
      SQueryOPC.SQL.Add('values(strftime(''%s'', ''now''), ''' +
        FQueryOPC.FieldByName('NOPLAV').AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('MARKA')
        .AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('KLASS')
        .AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('RAZM1')
        .AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('STANDART')
        .AsString + '''');
      SQueryOPC.SQL.Add(', 0, ' + inttostr(InTempLeft) + ')');
      SQueryOPC.ExecSQL;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end;

  if InTempRight > 250 then
  begin
    try
      FQueryOPC.Close;
      FQueryOPC.SQL.Clear;
      FQueryOPC.SQL.Add('select FIRST 1 * FROM melts');
      FQueryOPC.SQL.Add('where side=1');
      FQueryOPC.SQL.Add('order by begindt desc');
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.Commit;

      SQueryOPC.Close;
      SQueryOPC.SQL.Clear;
      SQueryOPC.SQL.Add('insert INTO temperature');
      SQueryOPC.SQL.Add
        ('(timestamp, heat, grade, strength_class, section, standard, side, temperature)');
      SQueryOPC.SQL.Add('values(strftime(''%s'', ''now''), ''' +
        FQueryOPC.FieldByName('NOPLAV').AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('MARKA')
        .AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('KLASS')
        .AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('RAZM1')
        .AsString + '''');
      SQueryOPC.SQL.Add(', ''' + FQueryOPC.FieldByName('STANDART')
        .AsString + '''');
      SQueryOPC.SQL.Add(', 1, ' + inttostr(InTempRight) + ')');
      SQueryOPC.ExecSQL;
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
    end;
  end;
 }
end;

// При загрузке программы класс будет создаваться
initialization

// создаем поток
ThreadOpc := TThreadOpc.Create(True);
ThreadOpc.Priority := tpNormal;
ThreadOpc.FreeOnTerminate := True;

// При закрытии программы уничтожаться
finalization

ThreadOpc.Terminate;

end.
