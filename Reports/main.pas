unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.DBGrids, Data.DB,
  Vcl.StdCtrls, Vcl.DBCtrls, Vcl.Mask, DateUtils, Datasnap.DBClient, Types,
  Generics.Collections, MidasLib, CRTL;
  //MidasLib, CRTL - ���������� error midas.dll

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    b_action: TButton;
    rb_calculated_data: TRadioButton;
    rb_temperature: TRadioButton;
    l_n_heat: TLabel;
    e_heat: TEdit;
    cb_export: TCheckBox;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure b_actionClick(Sender: TObject);
    procedure DBGrid1DrawDataCell(Sender: TObject; const Rect: TRect;
      Field: TField; State: TGridDrawState);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure e_heatChange(Sender: TObject);
    procedure rb_calculated_dataClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
    CurrentDir: string;
    HeadName: string = ' ������';
    Version: string = ' v0.0a';
    DBFile: string = 'data.sdb';
    ClientDataSet: TClientDataSet;

//   {$DEFINE DEBUG}

    function CheckAppRun: bool;
    function ViewClear(InData: string): bool;
    function DbGridCalculatedDataColumnName: bool;
    function DbGridTemperatuteColumnName: bool;
    function EditColor(InData: integer): integer;
    function SaveReport(InTimestamp, InType: string; InData: WideString): bool;
    function GetTemperature: bool;
    function GetMedian(aArray: TDoubleDynArray): Double;


implementation

uses
  settings, sql;

{$R *.dfm}



procedure TForm1.FormCreate(Sender: TObject);
begin
 //�������� 1 ���������� ���������
  CheckAppRun;

  Form1.Caption := HeadName+Version;
  //��������� � showmessage
  Application.Title := HeadName+Version;

  // ������� ����������
  CurrentDir := GetCurrentDir;
  // ����� ������ ������� ��� �������������� � ������
  FormatSettings.DecimalSeparator := '.';

  //������ �� ��������� �����
  Form1.BorderStyle := bsToolWindow;
//  Form1.BorderIcons :=  Form1.BorderIcons - [biMaximize];

  ConfigSettings(true);
  ConfigPostgresSetting(true);

  ViewClear('');

end;


procedure TForm1.FormDestroy(Sender: TObject);
begin
  ConfigPostgresSetting(false);
  ConfigSettings(false);
end;

procedure TForm1.rb_calculated_dataClick(Sender: TObject);
begin
    form1.e_heat.Color := clWindow;
end;


procedure TForm1.b_actionClick(Sender: TObject);
const
  Delim = ';';
var
  s, TypeReport, timestamp: string;
  i: integer;
begin
  try
      if not PConnect.Ping then
        PConnect.Reconnect;
  except
    on E: Exception do
//      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  if not form1.rb_calculated_data.Checked and not form1.rb_temperature.Checked then
  begin
      showmessage('�������� ��� ������');
      exit;
  end;

  if form1.rb_calculated_data.Checked then
  begin
      DbGridCalculatedDataColumnName;
      DataSource.DataSet := PQuery;
      SqlCalculatedData;
      TypeReport := 'CalculatedData';
      timestamp := inttostr(DateTimeToUnix(NOW));
  end;

  if form1.rb_temperature.Checked and (trim(form1.e_heat.Text) <> '') then
  begin
      DbGridTemperatuteColumnName;
//--test      DataSource.DataSet := PQuery;
//--tes      SqlTemperature;
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

      Application.ProcessMessages; // ��������� �������� �� �������� ���������
      SaveReport(timestamp, TypeReport, s);

      DBGrid1.DataSource.DataSet.First;//���� ��������� �� ������ ������ ��� �����������

      while not DBGrid1.DataSource.DataSet.Eof do
      begin
        s := '';
        for i := 0 to DBGrid1.Columns.Count - 1 do
            s := s + TColumn(DBGrid1.Columns[I]).Field.aswidestring + Delim;

        Application.ProcessMessages; // ��������� �������� �� �������� ���������
        SaveReport(timestamp, TypeReport, s);
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
      if Column.Field = PQuery.FieldByName('heat_to_work') then
       begin
    //    if not (gdSelected in State) then
          DBGrid1.Canvas.FillRect(Rect);
          DBGrid1.Canvas.TextRect(R, R.Left + 2, R.Top + 2,
                                  PQuery.FieldByName('heat_to_work').AsString);

{            with DBGrid1.Canvas do
            begin
              if Column.FieldName = 'heat_to_work' then
              begin
                Brush.Color := clRed;
                Font.Color := clBlue;
                font.Style:= [fsBold];
                (Sender as TDBGrid).Canvas.TextRect(Rect, Rect.Left + 2,
                                      Rect.Top + 2, Column.Field.AsWideString);
              end
            end}
         end
      else
          Dbgrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
      //      end;


      if PQuery.FieldByName('step').AsString = '�������' then
       begin
          with DBGrid1.Canvas do
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
          with DBGrid1.Canvas do
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
    Dbgrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TForm1.DBGrid1DrawDataCell(Sender: TObject; const Rect: TRect;
  Field: TField; State: TGridDrawState);
begin

  with (Sender as TDBGrid).Canvas do
  begin
    Brush.Color := clRed;
    FillRect(Rect);
    TextOut(Rect.Left, Rect.Top, Field.AsString);
  end;
{

// '���� ��� ���� - "NAME"'
  if Field.FieldName = 'heat_to_work' then
  begin
// '�������� ���� ������ �� ������� '
showmessage('dd');
    (Sender as TDBGrid).Canvas.Font.Color := clRed;
// '������� ����� � ��������� ����� '
//  (Sender as TDBGrid).Canvas.TextRect(Rect, Rect.Left + 2,
//    Rect.Top + 2, Field.AsString);
  end
  else
    DBGrid1.DefaultDrawColumnCell(Rect, Field, State);
//    DBGrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
              }
end;


procedure TForm1.e_heatChange(Sender: TObject);
begin
     form1.e_heat.Color := clWindow;
end;


function DbGridCalculatedDataColumnName: bool;
begin
  // '����������: �������� DefaultDrawing ���������� Grid ������ ����  ����������� � False'
  form1.DBGrid1.DefaultDrawing := false;

  form1.DBGrid1.Columns.Clear;
  form1.DBGrid1.Columns.Add.FieldName := 'timestamp';
  form1.DBGrid1.Columns.Add.FieldName := 'heat';
  form1.DBGrid1.Columns.Add.FieldName := 'section';
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

  form1.DBGrid1.Columns.Items[0].Title.Caption := '�����';
  form1.DBGrid1.Columns.Items[1].Title.Caption := '������';
  form1.DBGrid1.Columns.Items[2].Title.Caption := '�������';
  form1.DBGrid1.Columns.Items[3].Title.Caption := '�������';
  form1.DBGrid1.Columns.Items[4].Title.Caption := '����';
  form1.DBGrid1.Columns.Items[5].Title.Caption := '����. ������ ���.';
  form1.DBGrid1.Columns.Items[6].Title.Caption := '����. ��������� ����.';
  form1.DBGrid1.Columns.Items[7].Title.Caption := '��������� ������';
  form1.DBGrid1.Columns.Items[8].Title.Caption := '����. ������ min';
  form1.DBGrid1.Columns.Items[9].Title.Caption := '����. ������ max';
  form1.DBGrid1.Columns.Items[10].Title.Caption := '��� �������';
  form1.DBGrid1.Columns.Items[11].Title.Caption := '���. �������';
  form1.DBGrid1.Columns.Items[12].Title.Caption := '���. ��.�����.����.';
  form1.DBGrid1.Columns.Items[13].Title.Caption := '���. min';
  form1.DBGrid1.Columns.Items[14].Title.Caption := '���. max';
  form1.DBGrid1.Columns.Items[15].Title.Caption := '���. �������';
  form1.DBGrid1.Columns.Items[16].Title.Caption := '����. min';
  form1.DBGrid1.Columns.Items[17].Title.Caption := '����. max';
  form1.DBGrid1.Columns.Items[18].Title.Caption := '����. �������';
  form1.DBGrid1.Columns.Items[19].Title.Caption := '����. ��.�����.����.';
  form1.DBGrid1.Columns.Items[20].Title.Caption := '����. min';
  form1.DBGrid1.Columns.Items[21].Title.Caption := '����. max';
  form1.DBGrid1.Columns.Items[22].Title.Caption := '����. �������';
  form1.DBGrid1.Columns.Items[23].Title.Caption := 'R';
  form1.DBGrid1.Columns.Items[24].Title.Caption := '�������. min';
  form1.DBGrid1.Columns.Items[25].Title.Caption := '�������. max';
  form1.DBGrid1.Columns.Items[26].Title.Caption := '������ ������';
  form1.DBGrid1.Columns.Items[27].Title.Caption := '������� ������';
  form1.DBGrid1.Columns.Items[28].Title.Caption := 'Ce min ������';
  form1.DBGrid1.Columns.Items[29].Title.Caption := 'Ce min �������';
  form1.DBGrid1.Columns.Items[30].Title.Caption := 'Ce max ������';
  form1.DBGrid1.Columns.Items[31].Title.Caption := 'Ce max �������';
  form1.DBGrid1.Columns.Items[32].Title.Caption := 'Ce cp.';
  form1.DBGrid1.Columns.Items[33].Title.Caption := 'Ce cp. ������';
  form1.DBGrid1.Columns.Items[34].Title.Caption := 'Ce cp. �������';
  form1.DBGrid1.Columns.Items[35].Title.Caption := 'Ce ���������';
  DataSource.Enabled := true;
  form1.DBGrid1.DataSource := DataSource;
end;


function DbGridTemperatuteColumnName: bool;
begin
  // '����������: �������� DefaultDrawing ���������� Grid ������ ����  ����������� � False'
  form1.DBGrid1.DefaultDrawing := false;

  form1.DBGrid1.Columns.Clear;
  form1.DBGrid1.Columns.Add.FieldName := 'timestamp';
  form1.DBGrid1.Columns.Add.FieldName := 'heat';
  form1.DBGrid1.Columns.Add.FieldName := 'section';
  form1.DBGrid1.Columns.Add.FieldName := 'side';
  form1.DBGrid1.Columns.Add.FieldName := 'temperature';

  form1.DBGrid1.Columns.Items[0].Title.Caption := '�����';
  form1.DBGrid1.Columns.Items[1].Title.Caption := '������';
  form1.DBGrid1.Columns.Items[2].Title.Caption := '�������';
  form1.DBGrid1.Columns.Items[3].Title.Caption := '�������';
  form1.DBGrid1.Columns.Items[4].Title.Caption := '�����������';

  DataSource.Enabled := true;
  form1.DBGrid1.DataSource := DataSource;
end;


function ViewClear(InData: string): bool;
var
  i: integer;
begin

  if InData <> 'e' then
  begin
      for i:=0 to form1.ComponentCount - 1 do
      begin
        if (form1.Components[i] is Tlabel) then
          if copy(form1.Components[i].Name,1,4) <> 'l_n_' then
            Tlabel(Form1.FindComponent(form1.Components[i].Name)).Caption := '';
      end;
  end;

  if InData = 'e' then
  begin
    for i:=0 to form1.ComponentCount - 1 do
    begin
     if (form1.Components[i] is TEdit) then
       if copy(form1.Components[i].Name,1,2) = 'e_' then
         Tlabel(Form1.FindComponent(form1.Components[i].Name)).Caption := '';
    end;
  end;

end;


function EditColor(InData: integer): integer;
var
  i, e: integer;
begin
  for i:=0 to form1.ComponentCount - 1 do
   begin
    if (form1.Components[i] is TEdit) then
      begin
          if InData = 1 then
          begin
            if trim(TEdit(Form1.FindComponent(form1.Components[i].Name)).Text) = '' then
            begin
              TEdit(Form1.FindComponent(form1.Components[i].Name)).Color := clRed;
              inc(e);
            end;
          end;
          if InData = 2 then
          begin
              TEdit(Form1.FindComponent(form1.Components[i].Name)).Color := clWindow;
          end;
      end;
  end;
  Result := e;
end;


function SaveReport(InTimestamp, InType: string; InData: WideString): bool;
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


function GetTemperature: bool;
var
  TempArray: Array of Double;
  RawTempArray: TDoubleDynArray;
  a, b, i: integer;
begin
  ClientDataSet := TClientDataSet.Create(nil);
  DataSource.DataSet := ClientDataSet;

  // �������� ����
  ClientDataSet.FieldDefs.Clear;
  ClientDataSet.FieldDefs.Add('timestamp', ftString, 20, False);
  ClientDataSet.FieldDefs.Add('heat', ftString, 20, False);
  ClientDataSet.FieldDefs.Add('section', ftInteger, 0, False);
  ClientDataSet.FieldDefs.Add('side', ftString, 20, False);
  ClientDataSet.FieldDefs.Add('temperature', ftInteger, 0, False);

  // ������� ����� ������
  ClientDataSet.CreateDataSet();

  SqlTemperature;

  a := 0;
  b := a;
  i := a;
  while not PQuery.Eof do
  begin
    if a = length(RawTempArray) then SetLength(RawTempArray, a + 1);
//    SetLength(RawTempArray, 5);
    RawTempArray[a] := PQuery.FieldByName('temperature').AsInteger;
    inc(a);

{$IFDEF DEBUG}
  inc(i);
{$ENDIF}

    if a = 4 then
    begin
      if b = length(TempArray) then SetLength(TempArray, b + 1);
//      TempArray[b] := GetMedian(RawTempArray);
      // ���������
      ClientDataSet.Append; // �������� ����� ������
      ClientDataSet.FieldByName('timestamp').AsString := PQuery.FieldByName('timestamp').AsString;
      ClientDataSet.FieldByName('heat').AsString := PQuery.FieldByName('heat').AsString;
      ClientDataSet.FieldByName('section').AsInteger := PQuery.FieldByName('section').AsInteger;
      ClientDataSet.FieldByName('side').AsString := PQuery.FieldByName('side').AsString;
      ClientDataSet.FieldByName('temperature').AsFloat := GetMedian(RawTempArray);
      ClientDataSet.Post;

      inc(b);
      a := 0;
    end;
    PQuery.Next;
  end;

  ClientDataSet.Active := true;
//  ClientDataSet.Destroy;
{$IFDEF DEBUG}
  showmessage('debug' + #9#9+'all -> '+inttostr(i)+#9+'median -> '+inttostr(b));
{$ENDIF}
end;


function GetMedian(aArray: TDoubleDynArray): Double;
var
  lMiddleIndex: Integer;
begin
  TArray.Sort<Double>(aArray);

  lMiddleIndex := Length(aArray) div 2;
  if Odd(Length(aArray)) then
    Result := aArray[lMiddleIndex]
  else
    Result := (aArray[lMiddleIndex - 1] + aArray[lMiddleIndex]) / 2;
end;


function CheckAppRun: bool;
var
  hMutex : THandle;
begin
    // �������� 2 ��������� ���������
    hMutex := CreateMutex(0, true , 'Reports');
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
