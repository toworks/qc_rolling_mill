unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.DBChart,
  VCLTee.TeeSpline, SyncObjs, Math, Vcl.Menus, Vcl.ActnPopup;

type
  TForm1 = class(TForm)
    chart_right_side: TChart;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Series3: TLineSeries;
    Series4: TLineSeries;
    Series5: TLineSeries;
    l_chemical_right: TLabel;
    gb_right_side: TGroupBox;
    l_global_right: TLabel;
    TrayIcon: TTrayIcon;
    gb_left_side: TGroupBox;
    l_global_left: TLabel;
    l_chemical_left: TLabel;
    chart_left_side: TChart;
    series_max_red: TLineSeries;
    series_max_green: TLineSeries;
    series_current: TLineSeries;
    series_min_green: TLineSeries;
    series_min_red: TLineSeries;
    procedure FormCreate(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure TrayPopUpCloseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

  private
    { Private declarations }
    // procedure TrayPopUpCloseClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  LastDate: TDateTime = 0;
  CurrentDir: string;
  HeadName: string = ' ���������� ��������� MC 250-5';
  Version: string = ' v0.0beta';
  DBFile: string = 'data.sdb';
  LogFile: string = 'app.log';
  PopupTray: TPopupMenu;
  TrayMark: bool = false;
  LeftM: bool = false;
  RightM: bool = false;
  LimitsM: integer = 0;


{$DEFINE DEBUG}

function TrayAppRun: bool;
function CheckAppRun: bool;
function ViewClear: bool;
function ShowTrayMessage(InTitle, InMessage: AnsiString; InFlag: integer): bool;

implementation

uses
  settings, logging, sql, chart, thread_main;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  // �������� 1 ���������� ���������
  CheckAppRun;

  Form1.Caption := HeadName + Version;
  // ��������� � showmessage
  Application.Title := HeadName + Version;

  // ������� ����������
  CurrentDir := GetCurrentDir;
  // ����� ������ ������� ��� �������������� � ������
  FormatSettings.DecimalSeparator := '.';

  // ������ �� ��������� �����
  Form1.BorderStyle := bsToolWindow;
  Form1.BorderIcons := Form1.BorderIcons - [biMaximize];

  SaveLog('app' + #9#9 + 'start');

  // ������������� ����
  TrayAppRun;

  ViewClear;

  ConfigSettings(true);
  ConfigPostgresSetting(true);
  ThreadMain.Start;
end;


function ShowTrayMessage(InTitle, InMessage: AnsiString; InFlag: integer): bool;
begin
  {
    bfNone = 0
    bfInfo = 1
    bfWarning = 2
    bfError = 3
  }

  Form1.TrayIcon.BalloonTitle := InTitle;
  Form1.TrayIcon.BalloonHint := TimeToStr(NOW) + #9 + InMessage;
  Form1.TrayIcon.BalloonFlags := TBalloonFlags(InFlag);
  Form1.TrayIcon.BalloonTimeout := 10;
  Form1.TrayIcon.ShowBalloonHint;
  Form1.TrayIcon.OnBalloonClick := Form1.TrayIconClick;
end;


function TrayAppRun: bool;
begin
  PopupTray := TPopupMenu.Create(nil);
  Form1.TrayIcon.Hint := HeadName;
  Form1.TrayIcon.PopupMenu := PopupTray;
  PopupTray.Items.Add(NewItem('�����', 0, false, true, Form1.TrayPopUpCloseClick, 0, 'close'));
  Form1.TrayIcon.Visible := true;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := false;
  Form1.Hide;
end;


procedure TForm1.TrayPopUpCloseClick(Sender: TObject);
var
  buttonSelected: integer;
begin
  SaveLog('app' + #9#9 + 'close');

  ConfigPostgresSetting(false);

  TrayIcon.Visible := false;
  // ��������� ����������
  TerminateProcess(GetCurrentProcess, 0);
end;


procedure TForm1.TrayIconClick(Sender: TObject);
begin
  if TrayMark then
  begin
    // ShowWindow(Wind, SW_SHOWNOACTIVATE);
    // SetForegroundWindow(Application.MainForm.Handle);
    Form1.show;
    TrayMark := false;
  end
  else
  begin
    // ShowWindow(Application.MainForm.Handle, SW_HIDE);
    // SetForegroundWindow(Application.MainForm.Handle);
    Form1.Hide;
    TrayMark := true;
  end

  // Trayicon1.Visible := False;
  // PopupTray.Items.Delete(0);
end;


function CheckAppRun: bool;
var
  hMutex: THandle;
begin
  // �������� 2 ��������� ���������
  hMutex := CreateMutex(0, true, 'QCRollingMillClient');
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    Application.Title := HeadName + Version;
    // ������ ����� � ������� ���������
    Application.ShowMainForm := false;
    showmessage('��������� ��������� ��� �������');

    CloseHandle(hMutex);
    TerminateProcess(GetCurrentProcess, 0);
  end;

end;


function ViewClear: bool;
var
  i: integer;
begin

  for i := 0 to Form1.ComponentCount - 1 do
  begin
    if (Form1.Components[i] is TLabel) then
    begin
      if copy(Form1.Components[i].Name, 1, 4) <> 'l_n_' then
        TLabel(Form1.FindComponent(Form1.Components[i].Name)).Caption := '';
    end;
  end;

  left.LowRed := 0;
  left.HighRed := 0;
  left.LowGreen := 0;
  left.HighGreen := 0;

  right.LowRed := 0;
  right.HighRed := 0;
  right.LowGreen := 0;
  right.HighGreen := 0;

end;

end.
