unit main_form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ActnPopup, Vcl.ExtCtrls, SyncObjs,
  ZAbstractConnection, ZConnection;

type
  TForm1 = class(TForm)
    TrayIcon: TTrayIcon;
    procedure FormCreate(Sender: TObject);

  private
    { Private declarations }
    procedure TrayPopUpCloseClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
    CurrentDir: string;
    HeadName: string = '���������� ��������� MC 250-5';
    Version: string = ' v0.0alpha';
    DBFile: string = 'data.sdb';
    LogFile: string = 'app.log';
    PopupTray: TPopupMenu;

//    {$DEFINE DEBUG}

//    procedure TrayPopUpCloseClick(Sender: TObject);
    function TrayAppRun: bool;
    function CheckAppRun: bool;

implementation

uses
  settings, logging, thread_opc, sql;

{$R *.dfm}


procedure TForm1.FormCreate(Sender: TObject);
begin

  //�������� 1 ���������� ���������
  CheckAppRun;

  Form1.Caption := HeadName+Version;
  //��������� � showmessage
  Application.Title := HeadName+Version;

  //������� ����������
  CurrentDir := GetCurrentDir;

  SaveLog('app'+#9#9+'start');

  ConfigSettings(true);

  //������������� ����
  TrayAppRun;

  ConfigFirebirdSetting(true);
  ConfigPostgresSetting(true);
  ConfigOPCServer(true);
  ThreadOpc.Start;
end;


function TrayAppRun: bool;
begin
    PopupTray := TPopupMenu.Create(nil);
    Form1.Trayicon.Hint := HeadName;
    Form1.Trayicon.PopupMenu := PopupTray;
    PopupTray.Items.Add(NewItem('�����', 0, False, True, Form1.TrayPopUpCloseClick, 0, 'close'));
    Form1.Trayicon.Visible := True;
end;


procedure TForm1.TrayPopUpCloseClick(Sender: TObject);
begin
try
  Form1.Trayicon.Visible := false;
  ConfigFirebirdSetting(false);
  ConfigPostgresSetting(false);
  ThreadOpc.Terminate;
  ConfigOPCServer(false);
  ConfigSettings(false);
finally
  SaveLog('app'+#9#9+'close');
  //��������� ����������
  TerminateProcess(GetCurrentProcess, 0);
end;
end;


function CheckAppRun: bool;
var
  hMutex : THandle;
begin
    // �������� 2 ��������� ���������
    hMutex := CreateMutex(0, true , 'ReadOpcToSql');
    if GetLastError = ERROR_ALREADY_EXISTS then
     begin
        Application.Title := HeadName+Version;
        //������ ����� � ������� ���������
        Application.ShowMainForm:=false;
        showmessage('��������� ��������� ��� �������');

        CloseHandle(hMutex);
        TerminateProcess(GetCurrentProcess, 0);
     end;
end;




end.
