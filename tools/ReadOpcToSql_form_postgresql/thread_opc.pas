{
  ��� ������ � OPC ������������  OPCDAAuto.dll  �� ��������� "OPC DA Auto 2.02 Source Code 5.30.msi"
  ���������:
  import component -> import a type library -> OPC DA Automation Wrapper 2.02 version 1.0 ->
  pallete page ActiveX -> install new package
  compile -> install
  unhide button ActiveX (TOPCGroups,TOPCGroup,TOPCActivator,TOPCServer)
  � uses �������� (OPCAutomation_TLB,OleServer)
}

unit thread_opc;

interface

uses
  SysUtils, Classes, Windows, ActiveX, OPCAutomation_TLB, OleServer, Forms,
  DateUtils;

type
  TThreadOpc = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  TIdHeat = Record
    Heat          : string[26]; // ������
    Grade         : string[50]; // ����� �����
    Section       : string[50]; // �������
    Standard      : string[50]; // ��������
    StrengthClass : string[50]; // ���� ���������
    constructor Create(_Heat, _Grade, _Section, _Standard, _StrengthClass: string);
  end;

var
  ThreadOpc: TThreadOpc;
  OPCServer: TOPCServer;
  OPCGroup1: TOPCGroup;
  OPCGroup: IOPCGroup;
  OPCTagArray: Array [1 .. 10] of OPCItem;
  OPCGroupName: string = 'QCRollingMill';
  left, right: TIdHeat;

//  {$DEFINE DEBUG}

procedure WrapperOpc; // ������� ��� ������������� � ���������� � ������ �������
function ConfigOPCServer(InData: bool): bool;
function OPCReadTags: bool;
function SqlWriteTemperature(InTemperature, InSide: integer; InCogging: bool): bool;

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
      if not PConnect.Ping then
        PConnect.Reconnect;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
  try
      OPCReadTags;
  except
    on E: Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
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
      OPCGroup.UpdateRate := 1000;
      OPCGroup.IsActive := True;
      OPCGroup.IsSubscribed := True;

      // ������� Tags
      OPCTagArray[1] := OPCGroup.OPCItems.AddItem(OpcConfigArray[2], 1);
      OPCTagArray[2] := OPCGroup.OPCItems.AddItem(OpcConfigArray[3], 2);
      OPCTagArray[3] := OPCGroup.OPCItems.AddItem(OpcConfigArray[4], 3);
      OPCTagArray[4] := OPCGroup.OPCItems.AddItem(OpcConfigArray[5], 4);
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
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
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end;
end;

function OPCReadTags: bool;
var
  Tags: Array [1 .. 4, 1 .. 4] of OleVariant;
  // read 4 values -> source,value,quality,timestamp
begin
  try
      OPCTagArray[1].Read(Tags[1, 1], Tags[1, 2], Tags[1, 3], Tags[1, 4]);
      OPCTagArray[2].Read(Tags[2, 1], Tags[2, 2], Tags[1, 3], Tags[2, 4]);
      OPCTagArray[3].Read(Tags[3, 1], Tags[3, 2], Tags[3, 3], Tags[3, 4]);
      OPCTagArray[4].Read(Tags[4, 1], Tags[4, 2], Tags[4, 3], Tags[4, 4]);
  except
    on E: Exception do
    begin
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      ConfigOPCServer(false);
      ConfigOPCServer(true);
    end;
  end;
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'TempLeft -> ' + inttostr(Tags[1, 2]));
  SaveLog('debug' + #9#9 + 'TempRight -> ' + inttostr(Tags[2, 2]));
  SaveLog('debug' + #9#9 + 'CoggingLeft -> ' + booltostr(Tags[3, 2]));
  SaveLog('debug' + #9#9 + 'CoggingRight -> ' + booltostr(Tags[4, 2]));
{$ENDIF}
  //left -> 0
  try
      SqlWriteTemperature(Tags[1, 2], 0, Tags[3, 2]);
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  //right -> 1
  try
      SqlWriteTemperature(Tags[2, 2], 1, Tags[4, 2]);
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;

function SqlWriteTemperature(InTemperature, InSide: integer; InCogging: bool): bool;
var
  heat, tid: string;
  main: TIdHeat;
begin

  main.Create('','','','','');

  if InSide = 0 then
  begin
      main.Heat := left.Heat;
      main.Grade := left.Grade;
      main.Section := left.Section;
      main.Standard := left.Standard;
      main.StrengthClass := left.StrengthClass;
  end
  else
  begin
      main.Heat := right.Heat;
      main.Grade := right.Grade;
      main.Section := right.Section;
      main.Standard := right.Standard;
      main.StrengthClass := right.StrengthClass;
  end;

  if not InCogging or (main.Heat = '') then
  begin
   try
      FQueryOPC.Close;
      FQueryOPC.SQL.Clear;
      FQueryOPC.SQL.Add('select first 1');
      FQueryOPC.SQL.Add('NOPLAV as heat, MARKA as grade, KLASS as strength_class, RAZM1 as section, STANDART as standard, SIDE');
      FQueryOPC.SQL.Add('FROM melts');
      FQueryOPC.SQL.Add('where side='+inttostr(InSide)+'');
      FQueryOPC.SQL.Add('order by begindt desc');
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'FQueryOPC side '+inttostr(InSide)+' -> ' + FQueryOPC.SQL.Text);
{$ENDIF}
      Application.ProcessMessages; // ��������� �������� �� �������� ���������
      FQueryOPC.ExecQuery;
   except
     on E: Exception do
       SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
   end;
      main.Heat := FQueryOPC.FieldByName('heat').AsString;
      main.Grade := FQueryOPC.FieldByName('grade').AsString;
      main.Section := FQueryOPC.FieldByName('section').AsString;
      main.Standard := FQueryOPC.FieldByName('standard').AsString;
      main.StrengthClass := FQueryOPC.FieldByName('strength_class').AsString;

    if InSide = 0 then
    begin
        left.Heat := main.Heat;
        left.Grade := main.Grade;
        left.Section := main.Section;
        left.Standard := main.Standard;
        left.StrengthClass := main.StrengthClass;
    end
    else
    begin
        right.Heat := main.Heat;
        right.Grade := main.Grade;
        right.Section := main.Section;
        right.Standard := main.Standard;
        right.StrengthClass := main.StrengthClass;
    end;
  end;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'main.Heat -> ' + main.Heat);
  SaveLog('debug' + #9#9 + 'main.Grade -> ' + main.Grade);
  SaveLog('debug' + #9#9 + 'main.Section -> ' + main.Section);
  SaveLog('debug' + #9#9 + 'main.Standard -> ' + main.Standard);
  SaveLog('debug' + #9#9 + 'main.StrengthClass -> ' + main.StrengthClass);
  SaveLog('debug' + #9#9 + 'InSide -> ' + inttostr(Inside));
  SaveLog('debug' + #9#9 + 'InCoggingRight -> ' + booltostr(InCogging));
{$ENDIF}

   try
       SQuery.Close;
       SQuery.SQL.Clear;
       SQuery.SQL.Add('SELECT * FROM settings');
       SQuery.Open;
   except
     on E: Exception do
       SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
   end;

   while not SQuery.Eof do
   begin
     if SQuery.FieldByName('name').AsString = '::heat::side'+inttostr(InSide) then
       heat := SQuery.FieldByName('value').AsString;
     if SQuery.FieldByName('name').AsString = '::tid::side'+inttostr(InSide) then
       tid := SQuery.FieldByName('value').AsString;
     SQuery.Next;
   end;

   if heat <> main.Heat then
   begin
       tid := inttostr(DateTimeToUnix(NOW));
       try
           SQuery.Close;
           SQuery.SQL.Clear;
           SQuery.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
           SQuery.SQL.Add('VALUES (''::heat::side'+inttostr(InSide)+''',');
           SQuery.SQL.Add(''''+main.Heat+''')');
           SQuery.ExecSQL;
       except
         on E: Exception do
           SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
       end;
       try
           SQuery.Close;
           SQuery.SQL.Clear;
           SQuery.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
           SQuery.SQL.Add('VALUES (''::tid::side'+inttostr(InSide)+''',');
           SQuery.SQL.Add(''''+tid+''')');
           SQuery.ExecSQL;
       except
         on E: Exception do
           SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
       end;
   end;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'heat side '+inttostr(InSide)+' -> ' + heat);
  SaveLog('debug' + #9#9 + 'tid side '+inttostr(InSide)+' -> ' + tid);
{$ENDIF}

   try
     PQuery.Close;
     PQuery.SQL.Clear;
     PQuery.SQL.Add('WITH upsert AS (UPDATE temperature_current SET timestamp=EXTRACT(EPOCH FROM now()),');
     PQuery.SQL.Add('heat='''+main.Heat+''',');
     PQuery.SQL.Add('grade='''+main.Grade+''',');
     PQuery.SQL.Add('strength_class='''+main.StrengthClass+''',');
     PQuery.SQL.Add('section='+main.Section+',');
     PQuery.SQL.Add('standard='''+main.Standard+''',');
     PQuery.SQL.Add('temperature='+inttostr(InTemperature)+'');
     PQuery.SQL.Add('WHERE tid='+tid+' and side='+inttostr(InSide)+' RETURNING *)');
     PQuery.SQL.Add('INSERT INTO temperature_current (tid,timestamp,heat,grade,');
     PQuery.SQL.Add('strength_class,section,standard,side,temperature)');
     PQuery.SQL.Add('SELECT '+tid+', EXTRACT(EPOCH FROM now()),');
     PQuery.SQL.Add(''''+main.Heat+''',');
     PQuery.SQL.Add(''''+main.Grade+''',');
     PQuery.SQL.Add(''''+main.StrengthClass+''',');
     PQuery.SQL.Add(''+main.Section+',');
     PQuery.SQL.Add(''''+main.Standard+''',');
     PQuery.SQL.Add(''+inttostr(InSide)+',');
     PQuery.SQL.Add(''+inttostr(InTemperature)+'');
     PQuery.SQL.Add('WHERE NOT EXISTS (SELECT * FROM upsert)');
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'PQuery side '+inttostr(InSide)+' -> ' + PQuery.SQL.Text);
{$ENDIF}
     PQuery.ExecSQL;
   except
     on E: Exception do
       SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
   end;

end;

constructor TIdHeat.Create(_Heat, _Grade, _Section, _Standard, _StrengthClass: string);
begin
    Heat          := _Heat; // ������
    Grade         := _Grade; // ����� �����
    Section       := _Section; // �������
    Standard      := _Standard; // ��������
    StrengthClass := _StrengthClass; // ���� ���������
end;


// ��� �������� ��������� ����� ����� �����������
initialization
// ������� ����� True - �������� ���������, False - �������� �����
ThreadOpc := TThreadOpc.Create(True);
ThreadOpc.Priority := tpNormal;
ThreadOpc.FreeOnTerminate := True;
left.Create('','','','','');
right.Create('','','','','');

// ��� �������� ��������� ������������
finalization
ThreadOpc.Terminate;
FreeAndNil(left);
FreeAndNil(right);

end.

