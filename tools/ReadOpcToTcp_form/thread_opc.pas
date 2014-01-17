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
  SysUtils, Classes, Windows, ActiveX, OPCAutomation_TLB, OleServer, IdContext,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, DateUtils, Forms;

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
   // id для идентификации сообщения
  IdMsg: string = '70xZv3jlnS9KrrCHxXO44I10NKaFfvjXlVhYYugdprEIT8QgVG';

//  {$DEFINE DEBUG}

procedure WrapperOpc; // обертка для синхронизации и выполнения с другим потоком
function ConfigOPCServer(InData: bool): bool;
function OPCReadTags: bool;
function SqlReadMelts(InTempLeft, InTempRight: integer): bool;
function TcpSend(InData: string): bool;

implementation

uses
  logging, settings, sql;

procedure TThreadOpc.Execute;
begin
  CoInitialize(nil);
  while True do
  begin
    Synchronize(WrapperOpc);
    sleep(1000);
  end;
  CoUninitialize;
end;

procedure WrapperOpc;
begin
  try
      OPCReadTags;
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
  SqlReadMelts(Tags[1, 2], Tags[2, 2]);
end;

function SqlReadMelts(InTempLeft, InTempRight: integer): bool;
var
  i, Temperature: integer;
  msg: string;
begin

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'InTempLeft -> ' + inttostr(InTempLeft));
  SaveLog('debug' + #9#9 + 'InTempRight -> ' + inttostr(InTempRight));
{$ENDIF}

  for i := 0 to 1 do
  begin
    if i=0 then
      Temperature := InTempLeft;
    if i=1 then
      Temperature := InTempRight;

    if Temperature > 250 then
    begin
      try
        FQueryOPC.Close;
        FQueryOPC.SQL.Clear;
        //id, datetime, heat, grade, strength_class, section, standard, side, temperature
        FQueryOPC.SQL.Add('select FIRST 1');
        FQueryOPC.SQL.Add('NOPLAV, MARKA, KLASS, RAZM1, STANDART, SIDE');
        FQueryOPC.SQL.Add('FROM melts');
        FQueryOPC.SQL.Add('where side='+inttostr(i)+'');
        FQueryOPC.SQL.Add('order by begindt desc');
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'FQueryOPC side '+inttostr(i)+' -> ' + FQueryOPC.SQL.Text);
{$ENDIF}
        Application.ProcessMessages; // следующая операция не тормозит интерфейс
        FQueryOPC.ExecQuery;
      except
        on E: Exception do
          SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
      end;

      msg := INTTOSTR(DateTimeToUnix(NOW))+'|'+
             FQueryOPC.FieldByName('NOPLAV').AsString+'|'+
             FQueryOPC.FieldByName('MARKA').AsString+'|'+
             FQueryOPC.FieldByName('KLASS').AsString+'|'+
             FQueryOPC.FieldByName('RAZM1').AsString+'|'+
             FQueryOPC.FieldByName('STANDART').AsString+'|'+
             FQueryOPC.FieldByName('SIDE').AsString+'|'+
             inttostr(Temperature)+'|';
      TcpSend(msg);
    end;
  end;
end;

function TcpSend(InData: string): bool;
var
  IdTCPClient: TIdTCPClient;
  msg: TStringStream;
begin
  try
      IdTCPClient := TIdTCPClient.Create(nil);
      IdTCPClient.Host := TcpConfigArray[1];
      IdTCPClient.Port := strtoint(TcpConfigArray[2]);
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;
  try
      IdTCPClient.Connect;
      try
        // поток чтобы избежать проблемы с кодировкой
        msg := TStringStream.Create;
        msg.WriteString(InData+IdMsg); // запись сообщения в поток
        msg.Position := 0; // установка позиция на начало потока
        IdTCPClient.IOHandler.Write(msg, msg.Size, true);
      finally
        msg.Free;
      end;
      IdTCPClient.Disconnect;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;
end;


// При загрузке программы класс будет создаваться
initialization
// создаем поток True - создание остановка, False - создание старт
ThreadOpc := TThreadOpc.Create(True);
ThreadOpc.Priority := tpNormal;
ThreadOpc.FreeOnTerminate := True;

// При закрытии программы уничтожаться
finalization
ThreadOpc.Terminate;

end.

