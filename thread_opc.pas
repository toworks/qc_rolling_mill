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
  SysUtils, Classes, Windows, ActiveX, OPCAutomation_TLB, OleServer, Forms;

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
  OPCTagArray: Array[1..10] of OPCItem;
  OPCGroupName: string = 'QCRollingMill';

//  {$DEFINE DEBUG}

  procedure WrapperOpc;//������� ��� ������������� � ���������� � ������ �������
  function ConfigOPCServer(InData: bool): bool;
  function OPCReadTags: bool;
  function SqlWriteTemperature(InTempLeft, InTempRight: integer): bool;


implementation

uses
  main, logging, settings, sql_module;


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
  Application.ProcessMessages;//��������� �������� �� �������� ���������
  try
    OPCReadTags;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function ConfigOPCServer(InData: bool): bool;
begin

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'OpcConfigServerName -> '+OpcConfigArray[1]);
  {$ENDIF}

    if InData and (OpcConfigArray[1] <> '') then
     begin
      try
          OPCServer := TOPCServer.Create(nil);
          OPCGroup1 :=  TOPCGroup.Create(nil);

          OPCServer.Connect1(OpcConfigArray[1]);
          OPCGroup := OPCServer.OPCGroups.Add(OPCGroupName);
          OPCGroup.UpdateRate := 500;
          OPCGroup.IsActive := true;
          OPCGroup.IsSubscribed := true;

          //������� Tags
          OPCTagArray[1] := OPCGroup.OPCItems.AddItem(OpcConfigArray[2],1);
          OPCTagArray[2] := OPCGroup.OPCItems.AddItem(OpcConfigArray[3],2);
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
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
          on E : Exception do
            SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
        end;
     end;
end;


function OPCReadTags: bool;
var
  Tags: Array[1..4, 1..4] of OleVariant; //read 4 values -> source,value,quality,timestamp
begin

  OPCTagArray[1].Read(Tags[1,1],Tags[1,2],Tags[1,3],Tags[1,4]);
  OPCTagArray[2].Read(Tags[2,1],Tags[2,2],Tags[1,3],Tags[2,4]);
//  OPCTagArray[3].Read(Tags[3,1],Tags[3,2],Tags[3,3],Tags[3,4]);
//  OPCTagArray[4].Read(Tags[4,1],Tags[4,2],Tags[4,3],Tags[4,4]);

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'TempLeft -> '+inttostr(Tags[1,2]));
    SaveLog('debug'+#9#9+'TempRight -> '+inttostr(Tags[2,2]));
  {$ENDIF}

  SqlWriteTemperature(Tags[1,2], Tags[2,2]);

end;


function SqlWriteTemperature(InTempLeft, InTempRight: integer): bool;
begin

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'InTempLeft -> '+inttostr(InTempLeft));
    SaveLog('debug'+#9#9+'InTempRight -> '+inttostr(InTempRight));
  {$ENDIF}

  Settings.SQuery.Close;
  Settings.SQuery.SQL.Clear;
  Settings.SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS temperature (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
  Settings.SQuery.SQL.Add(', timestamp INTEGER(10) NOT NULL, heat VARCHAR(26) NOT NULL, grade VARCHAR(50)');
  Settings.SQuery.SQL.Add(', strength_class VARCHAR(50), section VARCHAR(50)');
  Settings.SQuery.SQL.Add(', standard VARCHAR(50), side integer, temperature integer)');
  Settings.SQuery.ExecSQL;

  //������ ������� �� ������ ������
  Settings.SQuery.Close;
  Settings.SQuery.SQL.Clear;
  //������� ������ ������ 10 ������� 2629743(���� �����)*10
  Settings.SQuery.SQL.Add('DELETE FROM temperature where');
  Settings.SQuery.SQL.Add('timestamp < (strftime(''%s'', ''now'')-(2629743*10))');
  Settings.SQuery.ExecSQL;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'SQuery.SQL.Text -> '+Settings.SQuery.SQL.Text);
  {$ENDIF}

  if InTempLeft > 250 then
   begin
      try
          Module.pFIBQuery1.Close;
          Module.pFIBQuery1.SQL.Clear;
          Module.pFIBQuery1.SQL.Add('select FIRST 1 *');
          Module.pFIBQuery1.SQL.Add('FROM melts');
          Module.pFIBQuery1.SQL.Add('where side=0');
          Module.pFIBQuery1.SQL.Add('order by begindt desc');
          Module.pFIBQuery1.ExecQuery;
          Module.pFIBQuery1.Transaction.Commit;

          Settings.SQuery.Close;
          Settings.SQuery.SQL.Clear;
          Settings.SQuery.SQL.Add('insert INTO temperature');
          Settings.SQuery.SQL.Add('(timestamp, heat, grade, strength_class, section, standard, side, temperature)');
          Settings.SQuery.SQL.Add('values(strftime(''%s'', ''now''), '''+Module.pFIBQuery1.FieldByName('NOPLAV').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('MARKA').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('KLASS').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('RAZM1').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('STANDART').AsString+'''');
          Settings.SQuery.SQL.Add(', 0, '+inttostr(InTempLeft)+')');
          Settings.SQuery.ExecSQL;
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
   end;

  if InTempRight > 250 then
   begin
      try
          Module.pFIBQuery1.Close;
          Module.pFIBQuery1.SQL.Clear;
          Module.pFIBQuery1.SQL.Add('select FIRST 1 *');
          Module.pFIBQuery1.SQL.Add('FROM melts');
          Module.pFIBQuery1.SQL.Add('where side=1');
          Module.pFIBQuery1.SQL.Add('order by begindt desc');
          Module.pFIBQuery1.ExecQuery;
          Module.pFIBQuery1.Transaction.Commit;

          Settings.SQuery.Close;
          Settings.SQuery.SQL.Clear;
          Settings.SQuery.SQL.Add('insert INTO temperature');
          Settings.SQuery.SQL.Add('(timestamp, heat, grade, strength_class, section, standard, side, temperature)');
          Settings.SQuery.SQL.Add('values(strftime(''%s'', ''now''), '''+Module.pFIBQuery1.FieldByName('NOPLAV').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('MARKA').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('KLASS').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('RAZM1').AsString+'''');
          Settings.SQuery.SQL.Add(', '''+Module.pFIBQuery1.FieldByName('STANDART').AsString+'''');
          Settings.SQuery.SQL.Add(', 1, '+inttostr(InTempRight)+')');
          Settings.SQuery.ExecSQL;
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
   end;

end;




// ��� �������� ��������� ����� ����� �����������
initialization
  //������� �����
  ThreadOpc := TThreadOpc.Create(true);
  ThreadOpc.Priority := tpNormal;
  ThreadOpc.FreeOnTerminate := True;

//��� �������� ��������� ������������
finalization
  ThreadOpc.Terminate;

end.

