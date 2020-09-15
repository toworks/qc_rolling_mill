unit gui;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BufDataset, FileUtil, Forms, Controls, Graphics,
  Dialogs, DBGrids, StdCtrls, Grids, dateutils, db;

type

  { TForm1 }

  TForm1 = class(TForm)
    b_action: TButton;
    cb_export: TCheckBox;
    cb_n_rolling_mill: TComboBox;
    cb_n_side: TComboBox;
    DBGrid1: TDBGrid;
    e_heat: TEdit;
    l_n_heat: TLabel;
    rb_calculated_data: TRadioButton;
    rb_temperature: TRadioButton;
    procedure cb_n_rolling_millChange(Sender: TObject);
    procedure cb_n_sideChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure b_actionClick(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DBGrid1PrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure ChangeHeatColor(Sender: TObject);
    procedure DBGridClear(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  TDoubleArray = array of double;

var
  Form1: TForm1;
  _BufDataSet: TBufDataSet;
  _resize: boolean;
  rolling_mill: string;
  side: string;

//   {$DEFINE DEBUG}

  function AppFormTitle(InData: string): boolean;
  function DbGridCalculatedDataColumnName: boolean;
  function DbGridTemperatuteColumnName: boolean;

  function SaveReport(InTimestamp, InType: string; InData: WideString): boolean;
  function GetRolingMill(InData: string): string;
  function GetTemperature: boolean;
  function ChangeSide: boolean;
  {delphi  function GetMedian(aArray: TDoubleDynArray): Double;}
  procedure bubbleSort(var list: TDoubleArray);
  function Median(aArray: TDoubleArray): double;

implementation

uses
    settings, sql;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Form1.BorderStyle := bsSingle;
  Form1.BorderIcons := Form1.BorderIcons - [biMaximize];
  Form1.DBGrid1.TitleStyle := tsNative;

//  SaveLog.Log(etInfo, 'app  start');

  if not MsSqlSettings.configured then
     ConfigMsSetting(true);

  for i := 1 to 6 do
       Form1.cb_n_rolling_mill.Items.Add('МС 250-'+inttostr(i));
  Form1.cb_n_rolling_mill.ReadOnly := true;
  Form1.cb_n_rolling_mill.ItemIndex := 0;
  rolling_mill := GetRolingMill(Form1.cb_n_rolling_mill.Text);

  ChangeSide; //activation/deactivation side

  AppFormTitle(rolling_mill);
end;


procedure TForm1.cb_n_rolling_millChange(Sender: TObject);
begin
  rolling_mill := GetRolingMill(Form1.cb_n_rolling_mill.Text);
  AppFormTitle(rolling_mill);
end;

procedure TForm1.cb_n_sideChange(Sender: TObject);
begin
  side := inttostr(Form1.cb_n_side.ItemIndex);
end;


procedure TForm1.ChangeHeatColor(Sender: TObject);
begin
  form1.e_heat.Color := clWindow;

  ChangeSide; //activation/deactivation side
end;


procedure TForm1.DBGridClear(Sender: TObject);
begin
  DBGrid1.DataSource := nil;
  DBGrid1.Columns.Clear;

  ChangeSide; //activation/deactivation side
end;


procedure TForm1.b_actionClick(Sender: TObject);
const
  Delim = ';';
var
  s, TypeReport, timestamp: string;
  i: integer;
begin
  _resize := false; //нужно для перерисовки dbgrid

  if not form1.rb_calculated_data.Checked and not form1.rb_temperature.Checked then
    begin
        showmessage('выберите вид отчета');
        exit;
    end;

    if form1.rb_calculated_data.Checked then
    begin
        DbGridCalculatedDataColumnName;
        DataSource.DataSet := MSQuery;
        SqlCalculatedData;
        TypeReport := 'CalculatedData';
        timestamp := inttostr(DateTimeToUnix(NOW));
    end;

    if form1.rb_temperature.Checked and (trim(form1.e_heat.Text) <> '') then
    begin
        DbGridTemperatuteColumnName;
        GetTemperature;
        TypeReport := 'temperature';
        timestamp := inttostr(DateTimeToUnix(NOW));
    end;

    if form1.rb_temperature.Checked and (trim(form1.e_heat.Text) = '') then
      form1.e_heat.Color := clRed;

  if form1.cb_export.Checked and ((form1.rb_calculated_data.Checked)
                                    or (form1.rb_temperature.Checked and (trim(form1.e_heat.Text) <> ''))) then
    begin
        form1.DBGrid1.DataSource.DataSet.DisableControls;
        form1.b_action.Enabled := false;
        form1.DBGrid1.Enabled := false;

        for i := 0 to DBGrid1.Columns.Count-1 do
          s := s + TColumn(DBGrid1.Columns[i]).Title.Caption + Delim;

        Application.ProcessMessages; // следующая операция не тормозит интерфейс
        SaveReport(timestamp, TypeReport, UTF8Decode(s));

        DBGrid1.DataSource.DataSet.First;//надо выставить на начало данных при температуре

        while not DBGrid1.DataSource.DataSet.Eof do
        begin
          s := '';
          for i := 0 to DBGrid1.Columns.Count - 1 do
              s := s + TColumn(DBGrid1.Columns[I]).Field.aswidestring + Delim;

          Application.ProcessMessages; // следующая операция не тормозит интерфейс
          SaveReport(timestamp, TypeReport, UTF8Decode(s));
          DBGrid1.DataSource.DataSet.Next;
        end;

        DBGrid1.Enabled := true;
        b_action.Enabled := true;
  //      DBGrid1.DataSource.DataSet.First;
        DBGrid1.DataSource.DataSet.EnableControls;
    end;
end;


procedure TForm1.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  R: TRect;
begin

  if form1.rb_calculated_data.Checked then
  begin
      R := Rect;
      Dec(R.Bottom, 2);
      if Column.Field = MSQuery.FieldByName('heat_to_work') then
       begin
          (Sender As TDBGrid).Canvas.FillRect(Rect); //не смазывает при прокрутке
          (Sender As TDBGrid).Canvas.TextRect(R, R.Left + 2, R.Top + 2,
                                  MSQuery.FieldByName('heat_to_work').AsString);
       end
      else begin
          TDBGrid(Sender).Canvas.FillRect(Rect); //не смазывает при прокрутке
          TDBGrid(Sender).DefaultDrawColumnCell(Rect, DataCol, Column, State);
      end;

      if MSQuery.FieldByName('step').AsString = 'Красный' then
       begin
          (Sender As TDBGrid).Canvas.FillRect(Rect); //не смазывает при прокрутке
          with (Sender As TDBGrid).Canvas do
          begin
            Font.Color := clRed;
            if (Column.FieldName = 'low') or (Column.FieldName = 'high') then
              font.Style:= [fsBold];
            (Sender as TDBGrid).Canvas.TextRect(Rect, Rect.Left + 2,
                                  Rect.Top + 2, Column.Field.AsWideString);
          end
       end
      else
       begin
          (Sender As TDBGrid).Canvas.FillRect(Rect); //не смазывает при прокрутке
          with (Sender As TDBGrid).Canvas do
          begin
            Font.Color := clGreen;
            if (Column.FieldName = 'low') or (Column.FieldName = 'high') then
              font.Style:= [fsBold];
            (Sender as TDBGrid).Canvas.TextRect(Rect, Rect.Left + 2,
                                 Rect.Top + 2, Column.Field.AsWideString);
          end
      end;
  end
  else
    (Sender As TDBGrid).DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;


procedure TForm1.DBGrid1PrepareCanvas(sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
var
  i: integer;
  TitleWidth: integer;
  TextWidth: integer;
begin
  with (Sender As TDBGrid) do begin
    for i:=0 to Columns.Count-1 do begin
        TitleWidth := Canvas.TextWidth(Columns.Items[i].Title.Caption);
        TextWidth := Canvas.TextWidth(Columns.Items[i].Field.ToString);
{        if (TitleWidth < Columns.Items[i].Width) and not _resize then begin
           Columns.Items[i].Width := TextWidth;
           Columns.Items[i].Alignment := taCenter;
           Columns.Items[i].Alignment := taLeftJustify;
        end;}
        if (TextWidth < Columns.Items[i].Width) and not _resize then begin
           Columns.Items[i].Width := TextWidth;
           Columns.Items[i].Alignment := taLeftJustify;
           Columns.Items[i].Title.Alignment := taLeftJustify;
        end;
    end;
  end;

{  if  MSQuery.FieldByName('step').AsString = 'Красный' then
    begin
      with (Sender As TDBGrid) do
      begin
        if (Column.FieldName = 'low') then begin
              Canvas.Brush.Color := $006868FD; //Red
              Canvas.Font.Color := clBlack;
              Canvas.font.Style := [fsBold];
        end;
        if (Column.FieldName = 'high') then begin
              Canvas.Brush.Color := $0002E813; //Green;
              Canvas.Font.Color := clBlack;
              Canvas.font.Style := [fsBold];
        end;
      end;
    end;}
    _resize := true;
end;


function AppFormTitle(InData: string): boolean;
begin
 Form1.Caption := AppName+' | отчеты | '+HeadName+InData+''+'    '+Version;
 //заголовки к showmessage
 Application.Title := Form1.Caption;
end;


function DbGridCalculatedDataColumnName: boolean;
var
  i: integer;
begin
  // 'ПРИМЕЧАНИЕ: Свойство DefaultDrawing компонента Grid должно быть  установлено в False'
  //{for delphi}  form1.DBGrid1.DefaultDrawing := false;

  form1.DBGrid1.Columns.Clear;
  form1.DBGrid1.Columns.Add.FieldName := 'timestamp';
  form1.DBGrid1.Columns.Add.FieldName := 'heat';
  form1.DBGrid1.Columns.Add.FieldName := 'section';
  form1.DBGrid1.Columns.Add.FieldName := 'rolling_mill';
  form1.DBGrid1.Columns.Add.FieldName := 'side';
  form1.DBGrid1.Columns.Add.FieldName := 'step';
  form1.DBGrid1.Columns.Add.FieldName := 'coefficient_yield_point_value';
  form1.DBGrid1.Columns.Add.FieldName := 'coefficient_rupture_strength_value';
  form1.DBGrid1.Columns.Add.FieldName := 'heat_to_work';
  form1.DBGrid1.Columns.Add.FieldName := 'limit_rolled_products_min';
  form1.DBGrid1.Columns.Add.FieldName := 'limit_rolled_products_max';
  form1.DBGrid1.Columns.Add.FieldName := 'type_rolled_products';
  form1.DBGrid1.Columns.Add.FieldName := 'mechanics_avg';
  form1.DBGrid1.Columns.Add.FieldName := 'mechanics_std_dev';
  form1.DBGrid1.Columns.Add.FieldName := 'mechanics_min';
  form1.DBGrid1.Columns.Add.FieldName := 'mechanics_max';
  form1.DBGrid1.Columns.Add.FieldName := 'mechanics_diff';
  form1.DBGrid1.Columns.Add.FieldName := 'coefficient_min';
  form1.DBGrid1.Columns.Add.FieldName := 'coefficient_max';
  form1.DBGrid1.Columns.Add.FieldName := 'temp_avg';
  form1.DBGrid1.Columns.Add.FieldName := 'temp_std_dev';
  form1.DBGrid1.Columns.Add.FieldName := 'temp_min';
  form1.DBGrid1.Columns.Add.FieldName := 'temp_max';
  form1.DBGrid1.Columns.Add.FieldName := 'temp_diff';
  form1.DBGrid1.Columns.Add.FieldName := 'r';
  form1.DBGrid1.Columns.Add.FieldName := 'adjustment_min';
  form1.DBGrid1.Columns.Add.FieldName := 'adjustment_max';
  form1.DBGrid1.Columns.Add.FieldName := 'low';
  form1.DBGrid1.Columns.Add.FieldName := 'high';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_min_down';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_min_up';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_max_down';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_max_up';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_avg';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_avg_down';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_avg_up';
  form1.DBGrid1.Columns.Add.FieldName := 'ce_category';

  form1.DBGrid1.Columns.Items[0].Title.Caption := 'Время';
  form1.DBGrid1.Columns.Items[1].Title.Caption := 'Плавка';
  form1.DBGrid1.Columns.Items[2].Title.Caption := 'Профиль';
  form1.DBGrid1.Columns.Items[3].Title.Caption := 'Стан';
  form1.DBGrid1.Columns.Items[4].Title.Caption := 'Сторона';
  form1.DBGrid1.Columns.Items[5].Title.Caption := 'Этап';
  form1.DBGrid1.Columns.Items[6].Title.Caption := 'Коэф. предел тек.';
  form1.DBGrid1.Columns.Items[7].Title.Caption := 'Коэф. временное сопр.';
  form1.DBGrid1.Columns.Items[8].Title.Caption := 'Расчетные плавки';
  form1.DBGrid1.Columns.Items[9].Title.Caption := 'Табл. предел min';
  form1.DBGrid1.Columns.Items[10].Title.Caption := 'Табл. предел max';
  form1.DBGrid1.Columns.Items[11].Title.Caption := 'Тип расчета';
  form1.DBGrid1.Columns.Items[12].Title.Caption := 'Мех. среднее';
  form1.DBGrid1.Columns.Items[13].Title.Caption := 'Мех. ср.квадр.откл.';
  form1.DBGrid1.Columns.Items[14].Title.Caption := 'Мех. min';
  form1.DBGrid1.Columns.Items[15].Title.Caption := 'Мех. max';
  form1.DBGrid1.Columns.Items[16].Title.Caption := 'Мех. разница';
  form1.DBGrid1.Columns.Items[17].Title.Caption := 'Коэф. min';
  form1.DBGrid1.Columns.Items[18].Title.Caption := 'Коэф. max';
  form1.DBGrid1.Columns.Items[19].Title.Caption := 'Темп. среднея';
  form1.DBGrid1.Columns.Items[20].Title.Caption := 'Темп. ср.квадр.откл.';
  form1.DBGrid1.Columns.Items[21].Title.Caption := 'Темп. min';
  form1.DBGrid1.Columns.Items[22].Title.Caption := 'Темп. max';
  form1.DBGrid1.Columns.Items[23].Title.Caption := 'Темп. разница';
  form1.DBGrid1.Columns.Items[24].Title.Caption := 'R';
  form1.DBGrid1.Columns.Items[25].Title.Caption := 'Коррект. min';
  form1.DBGrid1.Columns.Items[26].Title.Caption := 'Коррект. max';
  form1.DBGrid1.Columns.Items[27].Title.Caption := 'Нижний предел';
  form1.DBGrid1.Columns.Items[28].Title.Caption := 'Верхний предел';
  form1.DBGrid1.Columns.Items[29].Title.Caption := 'Ce min нижний';
  form1.DBGrid1.Columns.Items[30].Title.Caption := 'Ce min верхний';
  form1.DBGrid1.Columns.Items[31].Title.Caption := 'Ce max нижний';
  form1.DBGrid1.Columns.Items[32].Title.Caption := 'Ce max верхний';
  form1.DBGrid1.Columns.Items[33].Title.Caption := 'Ce cp.';
  form1.DBGrid1.Columns.Items[34].Title.Caption := 'Ce cp. нижний';
  form1.DBGrid1.Columns.Items[35].Title.Caption := 'Ce cp. верхний';
  form1.DBGrid1.Columns.Items[36].Title.Caption := 'Ce категория';

  DataSource.Enabled := true;
  form1.DBGrid1.DataSource := DataSource;
end;


function DbGridTemperatuteColumnName: boolean;
begin
  // 'ПРИМЕЧАНИЕ: Свойство DefaultDrawing компонента Grid должно быть  установлено в False'
  //{for delphi}  form1.DBGrid1.DefaultDrawing := false;

  form1.DBGrid1.Columns.Clear;
  form1.DBGrid1.Columns.Add.FieldName := 'timestamp';
  form1.DBGrid1.Columns.Add.FieldName := 'heat';
  form1.DBGrid1.Columns.Add.FieldName := 'section';
  form1.DBGrid1.Columns.Add.FieldName := 'rolling_mill';
  form1.DBGrid1.Columns.Add.FieldName := 'side';
  form1.DBGrid1.Columns.Add.FieldName := 'temperature';

  form1.DBGrid1.Columns.Items[0].Title.Caption := 'Время';
  form1.DBGrid1.Columns.Items[1].Title.Caption := 'Плавка';
  form1.DBGrid1.Columns.Items[2].Title.Caption := 'Профиль';
  form1.DBGrid1.Columns.Items[3].Title.Caption := 'Стан';
  form1.DBGrid1.Columns.Items[4].Title.Caption := 'Сторона';
  form1.DBGrid1.Columns.Items[5].Title.Caption := 'Температура';

  DataSource.Enabled := true;
  form1.DBGrid1.DataSource := DataSource;
end;


function SaveReport(InTimestamp, InType: string; InData: WideString): boolean;
var
  f: TextFile;
begin
  AssignFile(f, CurrentDir+'\'+InTimestamp+'_report_'+InType+'.csv');
  if not FileExists(CurrentDir+'\'+InTimestamp+'_report_'+InType+'.csv') then
  begin
      Rewrite(f);
      CloseFile(f);
  end;
  Append(f);
  Writeln(f, InData);
  Flush(f);
  CloseFile(f);
end;


function GetTemperature: boolean;
var
  RawTempArray: TDoubleArray;
  a, b, i: integer;
begin
  _BufDataSet := TBufDataSet.Create(nil);
  DataSource.DataSet := _BufDataSet;

  // Добавили поля
  _BufDataSet.FieldDefs.Clear;
  _BufDataSet.FieldDefs.Add('timestamp', ftString, 20, False);
  _BufDataSet.FieldDefs.Add('heat', ftString, 20, False);
  _BufDataSet.FieldDefs.Add('section', ftString, 20, False);
  _BufDataSet.FieldDefs.Add('rolling_mill', ftString, 20, False);
  _BufDataSet.FieldDefs.Add('side', ftString, 20, False);
  _BufDataSet.FieldDefs.Add('temperature', ftInteger, 0, False);

  // Создали набор данных
  _BufDataSet.CreateDataSet();

  SqlTemperature;

  a := 0;
  b := a;
  i := a;
  while not MSQuery.Eof do
  begin
    if a = length(RawTempArray) then SetLength(RawTempArray, a + 1);
    RawTempArray[a] := MSQuery.FieldByName('temperature').AsInteger;
    inc(a);

{$IFDEF DEBUG}
  inc(i);
{$ENDIF}

    if a = 4 then
    begin
      // Заполнили
      _BufDataSet.Append; // Добавить новую запись
      _BufDataSet.FieldByName('timestamp').AsString := MSQuery.FieldByName('timestamp').AsString;
      _BufDataSet.FieldByName('heat').AsString := MSQuery.FieldByName('heat').AsString;
      _BufDataSet.FieldByName('section').AsInteger := MSQuery.FieldByName('section').AsInteger;
      _BufDataSet.FieldByName('rolling_mill').AsString := MSQuery.FieldByName('rolling_mill').AsString;
      _BufDataSet.FieldByName('side').AsString := MSQuery.FieldByName('side').AsString;
      _BufDataSet.FieldByName('temperature').AsFloat := Median(RawTempArray);
      _BufDataSet.Post;

{$IFDEF DEBUG}
      inc(b);
{$ENDIF}

      SetLength(RawTempArray, 0); //обнуляем массив
      a := 0;
    end;
    MSQuery.Next;
  end;

  _BufDataSet.Active := true;
//  ClientDataSet.Destroy;
{$IFDEF DEBUG}
  showmessage('debug  '+'all -> '+inttostr(i)+'  median -> '+inttostr(b));
{$ENDIF}
end;


procedure bubbleSort(var list: TDoubleArray);
var
  i, j, n: integer;
  t: double;
begin
  n := length(list);
  for i := n downto 2 do
    for j := 0 to i - 1 do
      if list[j] > list[j + 1] then
      begin
        t := list[j];
        list[j] := list[j + 1];
        list[j + 1] := t;
      end;
end;


function Median(aArray: TDoubleArray): double;
var
  lMiddleIndex: integer;
begin
  bubbleSort(aArray);
  lMiddleIndex := (high(aArray) - low(aArray)) div 2;
  if Odd(Length(aArray)) then
    Result := aArray[lMiddleIndex + 1]
  else
    Result := (aArray[lMiddleIndex + 1] + aArray[lMiddleIndex]) / 2;
end;


function GetRolingMill(InData: string): string;
begin
  result := copy(InData, length(InData), 1);
end;


function ChangeSide: boolean;
begin
  if form1.rb_temperature.Checked then begin
    Form1.cb_n_side.Clear;
    Form1.cb_n_side.Enabled := true;
    Form1.cb_n_side.Items.Add('Левая сторона');
    Form1.cb_n_side.Items.Add('Правая сторона');
    Form1.cb_n_side.ReadOnly := true;
    Form1.cb_n_side.ItemIndex := 0;
    side := inttostr(Form1.cb_n_side.ItemIndex);
  end else begin
    Form1.cb_n_side.Enabled := false;
    Form1.cb_n_side.ItemIndex := -1;
  end;
end;


end.
