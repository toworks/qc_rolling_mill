unit gui;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, UniqueInstance, dateutils, TAGraph, TAIntervalSources, TASeries,
  TAChartUtils, TAChartAxis, TAChartAxisUtils, Menus;

type

  { TForm1 }

  TForm1 = class(TForm)
    UniqueInstanceApp: TUniqueInstance;
    ChartLeft: TChart;
    ChartLeftAxisRight: TChartAxis;
    ChartLeftLineSeriesGreenHight: TLineSeries;
    ChartLeftLineSeriesGreenLow: TLineSeries;
    ChartLeftLineSeriesRedHight: TLineSeries;
    ChartLeftLineSeriesRedLow: TLineSeries;
    ChartLeftLineSeriesCurrent: TLineSeries;
    DateTimeIntervalChartSourceLeft: TDateTimeIntervalChartSource;
    ChartRight: TChart;
    ChartRightAxisRight: TChartAxis;
    ChartRightLineSeriesGreenHight: TLineSeries;
    ChartRightLineSeriesGreenLow: TLineSeries;
    ChartRightLineSeriesRedHight: TLineSeries;
    ChartRightLineSeriesRedLow: TLineSeries;
    ChartRightLineSeriesCurrent: TLineSeries;
    DateTimeIntervalChartSourceRight: TDateTimeIntervalChartSource;
    cb_n_rolling_mill: TComboBox;
    gb_left: TGroupBox;
    gb_right: TGroupBox;
    l_chemical_left: TLabel;
    l_chemical_right: TLabel;
    l_heat_left: TLabel;
    l_heat_right: TLabel;
    function OneInstance: boolean;
    procedure UniqueInstanceAppOtherInstance(Sender: TObject;
      ParamCount: Integer; Parameters: array of String);
    procedure cb_n_rolling_millChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ChartLeftCreate(Sender: TObject);
    procedure ChartRightCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure MenuItemCloseClick(Sender: TObject);
    procedure ShowForm(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  Form1: TForm1;
  SysTrayIcon: TTrayIcon;
  MenuItemClose: TMenuItem;
  PopUpMenu: TPopupMenu;
  rolling_mill: string;
  side: string;

//   {$DEFINE DEBUG}

  function AppFormTitle(InData: string): boolean;
  function GetRolingMill(InData: string): string;
  function ViewCurrentDataLeft: boolean;
  function ViewCurrentDataRight: boolean;
  function SysTrayIconCreate: boolean;
  function PopUpMenuCreate: boolean;
  function ShowTrayMessage(InTitle, InMessage: AnsiString; InFlag: integer): boolean;
  function ViewClear: boolean;


implementation

{$ifdef unix}
uses
  BaseUnix,
{$endif}

{$ifdef windows}
uses
  Windows,
{$endif}
  settings, chart, thread_heat, thread_main;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Form1.BorderStyle := bsSingle;
  Form1.BorderIcons := Form1.BorderIcons - [biMaximize];

  //проверка 1 экземпляр программы
  OneInstance;

  ViewClear;

//  SaveLog.Log(etInfo, 'app  start');

  for i := 1 to 6 do
      Form1.cb_n_rolling_mill.Items.Add(HeadName+inttostr(i));
  Form1.cb_n_rolling_mill.ReadOnly := true;

  Form1.cb_n_rolling_mill.ItemIndex := 0;
  rolling_mill := GetRolingMill(Form1.cb_n_rolling_mill.Text);

  AppFormTitle(rolling_mill);
  PopUpMenuCreate;
  SysTrayIconCreate;
  ChartLeftCreate(Form1);
  ChartRightCreate(Form1);
end;


function TForm1.OneInstance: boolean;
begin
  //проверка 1 экземпляр программы
  UniqueInstanceApp := TUniqueInstance.Create(Self);
  with UniqueInstanceApp do
    begin
      Identifier := '47tu4C6a1yKP6NNWsvEEmzEvbD14L7OhzabAG21kqwVOo3FH2y';//ID program
      UpdateInterval := 800;
      OnOtherInstance := @UniqueInstanceAppOtherInstance;
      Enabled := True;
      Loaded;
    end;
end;


procedure TForm1.UniqueInstanceAppOtherInstance(Sender: TObject;
  ParamCount: Integer; Parameters: array of String);
begin
  //hack to force app bring to front
{  FormStyle := fsSystemStayOnTop;
  FormStyle := fsNormal;}
  ShowForm(Self);
end;


procedure TForm1.cb_n_rolling_millChange(Sender: TObject);
begin
  rolling_mill := GetRolingMill(Form1.cb_n_rolling_mill.Text);
  AppFormTitle(rolling_mill);
  SysTrayIcon.Hint := Form1.Caption;
end;


procedure TForm1.ChartLeftCreate(Sender: TObject);
begin
  DateTimeIntervalChartSourceLeft := TDateTimeIntervalChartSource.Create(ChartLeft);
  DateTimeIntervalChartSourceLeft.DateTimeFormat := 'hh:mm:ss';
  ChartLeftLineSeriesGreenHight := TLineSeries.Create(ChartLeft);
  ChartLeftLineSeriesGreenLow := TLineSeries.Create(ChartLeft);
  ChartLeftLineSeriesRedHight := TLineSeries.Create(ChartLeft);
  ChartLeftLineSeriesRedLow := TLineSeries.Create(ChartLeft);
  ChartLeftLineSeriesCurrent := TLineSeries.Create(ChartLeft);
  //шкала с права
  ChartLeftAxisRight := TChartAxis.Create(ChartLeft.AxisList);
  ChartLeft.AddSeries(ChartLeftLineSeriesGreenHight);
  ChartLeft.AddSeries(ChartLeftLineSeriesGreenLow);
  ChartLeft.AddSeries(ChartLeftLineSeriesRedHight);
  ChartLeft.AddSeries(ChartLeftLineSeriesRedLow);
  ChartLeft.AddSeries(ChartLeftLineSeriesCurrent);

  with ChartLeft.BottomAxis do begin
    Marks.Source := DateTimeIntervalChartSourceLeft;
    Marks.Style := smsLabel;
    Marks.AtDataOnly := true; //при старте убераеи шкалу
    Range.UseMin := true;
    Range.UseMax := true;
  end;

  with ChartLeftLineSeriesGreenHight do begin
    SeriesColor := ColorWarningLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartLeftLineSeriesGreenLow do begin
    SeriesColor := ColorWarningLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartLeftLineSeriesRedHight do begin
    SeriesColor := ColorAlarmLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartLeftLineSeriesRedLow do begin
    SeriesColor := ColorAlarmLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartLeftLineSeriesCurrent do begin
    SeriesColor := ColorCurrentLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  //шкала с права
  ChartLeftAxisRight.Alignment := calRight;
end;


procedure TForm1.ChartRightCreate(Sender: TObject);
begin
  DateTimeIntervalChartSourceRight := TDateTimeIntervalChartSource.Create(ChartRight);
  DateTimeIntervalChartSourceRight.DateTimeFormat := 'hh:mm:ss';
  ChartRightLineSeriesGreenHight := TLineSeries.Create(ChartRight);
  ChartRightLineSeriesGreenLow := TLineSeries.Create(ChartRight);
  ChartRightLineSeriesRedHight := TLineSeries.Create(ChartRight);
  ChartRightLineSeriesRedLow := TLineSeries.Create(ChartRight);
  ChartRightLineSeriesCurrent := TLineSeries.Create(ChartRight);
  //шкала с права
  ChartRightAxisRight := TChartAxis.Create(ChartRight.AxisList);
  ChartRight.AddSeries(ChartRightLineSeriesGreenHight);
  ChartRight.AddSeries(ChartRightLineSeriesGreenLow);
  ChartRight.AddSeries(ChartRightLineSeriesRedHight);
  ChartRight.AddSeries(ChartRightLineSeriesRedLow);
  ChartRight.AddSeries(ChartRightLineSeriesCurrent);

  with ChartRight.BottomAxis do begin
    Marks.Source := DateTimeIntervalChartSourceRight;
    Marks.Style := smsLabel;
    Marks.AtDataOnly := true; //при старте убераеи шкалу
    Range.UseMin := true;
    Range.UseMax := true;
  end;

  with ChartRightLineSeriesGreenHight do begin
    SeriesColor := ColorWarningLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartRightLineSeriesGreenLow do begin
    SeriesColor := ColorWarningLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartRightLineSeriesRedHight do begin
    SeriesColor := ColorAlarmLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartRightLineSeriesRedLow do begin
    SeriesColor := ColorAlarmLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  with ChartRightLineSeriesCurrent do begin
    SeriesColor := ColorCurrentLine;
    linePen.Width := 2;
    AxisIndexX := 1;//привязываем данные к оси X - график с лева уходит за границы не останавливаясь
  end;

  //шкала с права
  ChartRightAxisRight.Alignment := calRight;
end;


function AppFormTitle(InData: string): boolean;
begin
 Form1.Caption := AppName+' | '+HeadName+InData+''+'    '+Version;
 //заголовки к showmessage
 Application.Title := Form1.Caption;
end;


function GetRolingMill(InData: string): string;
begin
  result := copy(InData, length(InData), 1);
end;


function ViewCurrentDataLeft: boolean;
begin
  form1.l_heat_left.Caption := 'плавка: ' + left.Heat + ' | ' + 'марка: ' +
    left.Grade + ' | ' + 'класс прочности: ' + left.StrengthClass + ' | ' +
    'профиль: ' + left.Section + ' | ' + 'стандарт: ' + left.Standard;

  form1.l_chemical_left.Caption := 'химический анализ' + #9 + 'C: ' + left.c +
    ' | ' + 'Mn: ' + left.mn + ' | ' + 'Si: ' + left.si + ' | ' +
    'Cr: ' + left.cr + ' | ' + 'B: ' + left.b + ' | ' + 'Ce: ' + left.ce +
    ' ' + left.ce_category;
end;


function ViewCurrentDataRight: boolean;
begin
  form1.l_heat_right.Caption := 'плавка: ' + right.Heat + ' | ' + 'марка: ' +
    right.Grade + ' | ' + 'класс прочности: ' + right.StrengthClass + ' | ' +
    'профиль: ' + right.Section + ' | ' + 'стандарт: ' + right.Standard;

  form1.l_chemical_right.Caption := 'химический анализ' + #9 + 'C: ' + right.c +
    ' | ' + 'Mn: ' + right.mn + ' | ' + 'Si: ' + right.si + ' | ' +
    'Cr: ' + right.cr + ' | ' + 'B: ' + right.b + ' | ' + 'Ce: ' + right.ce +
    ' ' + right.ce_category;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := false;
  Form1.Hide;
end;


function SysTrayIconCreate: boolean;
begin
  SysTrayIcon := TTrayIcon.Create(nil);
  SysTrayIcon.Hint := Form1.Caption;
  SysTrayIcon.Icon.LoadFromFile(AppName+'.ico');
  SystrayIcon.OnClick := @Form1.ShowForm;
  SysTrayIcon.PopUpMenu := PopUpMenu;
  SysTrayIcon.Show;
end;


function PopUpMenuCreate: boolean;
begin
  PopUpMenu := TPopupMenu.Create(nil);
  MenuItemClose := TMenuItem.Create(nil);

  MenuItemClose.Caption:= 'выход';
  MenuItemClose.OnClick := @Form1.MenuItemCloseClick;
  PopUpMenu.Items.Add(MenuItemClose);
end;


function ShowTrayMessage(InTitle, InMessage: AnsiString; InFlag: integer): boolean;
begin
  {
    bfNone = 0
    bfInfo = 1
    bfWarning = 2
    bfError = 3
  }

  SysTrayIcon.BalloonTitle := InTitle;
  SysTrayIcon.BalloonHint := TimeToStr(NOW)+#9+InMessage;
  SysTrayIcon.BalloonFlags := TBalloonFlags(InFlag);
  SysTrayIcon.BalloonTimeout := 10;
  SysTrayIcon.ShowBalloonHint;
end;


procedure TForm1.ShowForm(Sender: TObject);
begin
  //hack to force app bring to front
  FormStyle := fsSystemStayOnTop;
  FormStyle := fsNormal;
  Show;
end;


procedure TForm1.MenuItemCloseClick(Sender: TObject);
begin
//  SaveLog.Log(etInfo, 'app  close');

  SystrayIcon.Destroy;

  // закрываем приложение
  {$ifdef unix}
    FpKill(FpGetpid, 9);
  {$endif}
  {$ifdef windows}
    TerminateProcess(GetCurrentProcess, 0);
  {$endif}
end;


function ViewClear: boolean;
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

end;


end.
