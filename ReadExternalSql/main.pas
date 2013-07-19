unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, DBAccess, Ora, Vcl.ExtCtrls,
  MemDS, Vcl.Menus, Vcl.ActnPopup, ActiveX;

type
  TForm1 = class(TForm)
    OraQuery1: TOraQuery;
    TrayIcon: TTrayIcon;
    OraSession1: TOraSession;
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
    function ShowTrayMessage(InTitle, InMessage: string; InFlag: integer): bool;
    function TrayAppRun: bool;
    function CheckAppRun: bool;
    function OraDbInit: bool;

implementation

uses
  settings, logging, tcp_send_read;

{$R *.dfm}




function OraDbInit: bool;
begin
  Form1.OraSession1.Username := OraSqlConfigArray[4];
  Form1.OraSession1.Password := OraSqlConfigArray[5];
  Form1.OraSession1.Server := OraSqlConfigArray[1]+':'+OraSqlConfigArray[2]+
                                    ':'+OraSqlConfigArray[3];//'krr-sql13:1521:ovp68';
  Form1.OraSession1.Options.Direct := true;
  Form1.OraSession1.Options.DateFormat := 'DD.MM.RR';//������ ���� ��.��.��
  Form1.OraSession1.Options.Charset := 'CL8MSWIN1251';// 'AL32UTF8';//CL8MSWIN1251
//  Form1.OraSession1.Options.UseUnicode := true;
end;


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

  OraDbInit;

  TcpConfig(true);
end;


function ShowTrayMessage(InTitle, InMessage: string; InFlag: integer): bool;
begin
{
bfNone = 0
bfInfo = 1
bfWarning = 2
bfError = 3
}
  form1.TrayIcon.BalloonTitle := InTitle;
  form1.TrayIcon.BalloonHint := TimeToStr(NOW)+#9+InMessage;
  form1.TrayIcon.BalloonFlags := TBalloonFlags(InFlag);
  form1.TrayIcon.BalloonTimeout := 10;
  form1.TrayIcon.ShowBalloonHint;
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
  TcpConfig(false);
  SaveLog('app'+#9#9+'close');
  Form1.Trayicon.Visible := false;
  //��������� ����������
  TerminateProcess(GetCurrentProcess, 0);
end;


function CheckAppRun: bool;
var
  hMutex : THandle;
begin
    // �������� 2 ��������� ���������
    hMutex := CreateMutex(0, true , 'ReadExternalSql');
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
