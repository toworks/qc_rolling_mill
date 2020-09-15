unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.DBGrids, Data.DB,
  Vcl.StdCtrls, Vcl.DBCtrls, Vcl.Mask;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    e_standard: TEdit;
    l_n_standard: TLabel;
    e_strength_class: TEdit;
    l_n_strength_class: TLabel;
    e_diameter_min: TEdit;
    l_n_diameter_min: TLabel;
    l_n_diameter_max: TLabel;
    e_diameter_max: TEdit;
    l_n_limit_min: TLabel;
    e_limit_min: TEdit;
    e_limit_max: TEdit;
    l_n_limit_max: TLabel;
    rb_yield_point: TRadioButton;
    rb_rupture_strength: TRadioButton;
    l_n_type: TLabel;
    b_action: TButton;
    cb_add_update_delete: TComboBox;
    e_c_max: TEdit;
    l_n_c_max: TLabel;
    e_grade: TEdit;
    l_n_grade: TLabel;
    l_n_c_min: TLabel;
    e_c_min: TEdit;
    e_mn_max: TEdit;
    l_n_mn_max: TLabel;
    l_n_mn_min: TLabel;
    e_mn_min: TEdit;
    e_si_max: TEdit;
    l_n_si_max: TLabel;
    l_n_si_min: TLabel;
    e_si_min: TEdit;

    procedure FormCreate(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure b_actionClick(Sender: TObject);
    procedure e_standardClick(Sender: TObject);
    procedure e_strength_classClick(Sender: TObject);
    procedure e_diameter_minClick(Sender: TObject);
    procedure e_diameter_maxClick(Sender: TObject);
    procedure e_limit_minClick(Sender: TObject);
    procedure e_limit_maxClick(Sender: TObject);
    procedure rb_yield_pointClick(Sender: TObject);
    procedure rb_rupture_strengthClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure e_gradeClick(Sender: TObject);
    procedure e_c_minClick(Sender: TObject);
    procedure e_c_maxClick(Sender: TObject);
    procedure e_mn_minClick(Sender: TObject);
    procedure e_mn_maxClick(Sender: TObject);
    procedure e_si_minClick(Sender: TObject);
    procedure e_si_maxClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
    CurrentDir: string;
    HeadName: string = ' ��� ������� �������� ���������� ��������������� ����';
    Version: string = ' v0.1';
    DBFile: string = 'data.sdb';

    function CheckAppRun: bool;
    function ViewClear(InData: string): bool;
    function DbGridColumnName: bool;
    function EditColor(InData: integer): integer;


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

  DbGridColumnName;
  SqlRead;

end;


procedure TForm1.FormDestroy(Sender: TObject);
begin
  ConfigPostgresSetting(false);
  ConfigSettings(false);
end;


procedure TForm1.DBGrid1CellClick(Column: TColumn);
var
  KeyValues : Variant;
begin
 //��������� ����������
{  form1.DBGrid1.DataSource.DataSet.DisableControls;
  try
      //���������� �� ������� ����� ������������� �����
      KeyValues := VarArrayOf([SQuery.FieldByName('standard').AsString,
                               SQuery.FieldByName('strength_class').AsString,
                               SQuery.FieldByName('diameter_min').AsString]);
      //����� �� �������� �����
      form1.DBGrid1.DataSource.DataSet.Locate('standard;strength_class;diameter_min', KeyValues, []);
  finally
      //�������� ����������
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;

  //����������� �����
  form1.DBGrid1.DataSource.DataSet.MoveBy(-1);
}
  form1.e_grade.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('grade').AsString;
  form1.e_standard.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('standard').AsString;
  form1.e_strength_class.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('strength_class').AsString;
  form1.e_c_min.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('c_min').AsString;
  form1.e_c_max.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('c_max').AsString;
  form1.e_mn_min.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('mn_min').AsString;
  form1.e_mn_max.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('mn_max').AsString;
  form1.e_si_min.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('si_min').AsString;
  form1.e_si_max.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('si_max').AsString;
  form1.e_diameter_min.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('diameter_min').AsString;
  form1.e_diameter_max.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('diameter_max').AsString;
  form1.e_limit_min.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('limit_min').AsString;
  form1.e_limit_max.Text := Form1.DBGrid1.DataSource.DataSet.FieldByName('limit_max').AsString;

  if Form1.DBGrid1.DataSource.DataSet.FieldByName('type').AsString = '������ ���������' then
    form1.rb_yield_point.Checked := true;

  if Form1.DBGrid1.DataSource.DataSet.FieldByName('type').AsString = '��������� �������������' then
    form1.rb_rupture_strength.Checked := true;

  EditColor(2);
end;


function DbGridColumnName: bool;
begin
  form1.DBGrid1.Columns.Items[0].Title.Caption := '�/��';
  form1.DBGrid1.Columns.Items[1].Title.Caption := '����� �����';
  form1.DBGrid1.Columns.Items[2].Title.Caption := '��������';
  form1.DBGrid1.Columns.Items[3].Title.Caption := '����� ���������';
  form1.DBGrid1.Columns.Items[4].Title.Caption := 'C min';
  form1.DBGrid1.Columns.Items[5].Title.Caption := 'C max';
  form1.DBGrid1.Columns.Items[6].Title.Caption := 'Mn min';
  form1.DBGrid1.Columns.Items[7].Title.Caption := 'Mn max';
  form1.DBGrid1.Columns.Items[8].Title.Caption := 'Si min';
  form1.DBGrid1.Columns.Items[9].Title.Caption := 'Si max';
  form1.DBGrid1.Columns.Items[10].Title.Caption := '������� min';
  form1.DBGrid1.Columns.Items[11].Title.Caption := '������� max';
  form1.DBGrid1.Columns.Items[12].Title.Caption := '������ min';
  form1.DBGrid1.Columns.Items[13].Title.Caption := '������ max';
  form1.DBGrid1.Columns.Items[14].Title.Caption := '���';

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

      form1.cb_add_update_delete.Items.Add('��������');
      form1.cb_add_update_delete.Items.Add('��������');
      form1.cb_add_update_delete.Items.Add('�������');
      form1.cb_add_update_delete.ItemIndex := 0;
  end;

  if InData = 'e' then
  begin
    for i:=0 to form1.ComponentCount - 1 do
    begin
     if (form1.Components[i] is TEdit) then
       if copy(form1.Components[i].Name,1,2) = 'e_' then
         Tlabel(Form1.FindComponent(form1.Components[i].Name)).Caption := '';
    end;
    form1.rb_yield_point.Checked := false;
    form1.rb_rupture_strength.Checked := false;
  end;

end;


procedure TForm1.b_actionClick(Sender: TObject);
var
  ID, i, e: integer;
begin

  ID := Form1.DBGrid1.DataSource.DataSet.FieldByName('id').AsInteger;

  e := 0;
  e := EditColor(1);

  if (not form1.rb_yield_point.Checked) and (not form1.rb_rupture_strength.Checked) then
  begin
    b_action.Hint := ' �� ������� �������� - ���';
    b_action.ShowHint := true;
    inc(e);
  end;

  if e > 0 then
    exit;

  if form1.cb_add_update_delete.ItemIndex = 0 then
      if MessageDlg('�������� ����� ������?', mtCustom, mbYesNo, 0) = mrYes then
        SqlInsert;

  if form1.cb_add_update_delete.ItemIndex = 1 then
      if MessageDlg('�������� ������?', mtCustom, mbYesNo, 0) = mrYes then
        SqlUpdate(ID);

  if form1.cb_add_update_delete.ItemIndex = 2 then
      if MessageDlg('������� ������?', mtCustom, mbYesNo, 0) = mrYes then
        SqlDelete(ID);

  ViewClear('e');
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


procedure TForm1.e_si_maxClick(Sender: TObject);
begin
  e_si_max.Color := clWindow;
end;

procedure TForm1.e_si_minClick(Sender: TObject);
begin
  e_si_min.Color := clWindow;
end;

procedure TForm1.e_standardClick(Sender: TObject);
begin
  e_standard.Color := clWindow;
end;

procedure TForm1.e_strength_classClick(Sender: TObject);
begin
  e_strength_class.Color := clWindow;
end;

procedure TForm1.e_diameter_minClick(Sender: TObject);
begin
  e_diameter_min.Color := clWindow;
end;

procedure TForm1.e_gradeClick(Sender: TObject);
begin
  e_grade.Color := clWindow;
end;

procedure TForm1.e_c_maxClick(Sender: TObject);
begin
  e_c_max.Color := clWindow;
end;

procedure TForm1.e_c_minClick(Sender: TObject);
begin
  e_c_min.Color := clWindow;
end;

procedure TForm1.e_diameter_maxClick(Sender: TObject);
begin
  e_diameter_max.Color := clWindow;
end;

procedure TForm1.e_limit_minClick(Sender: TObject);
begin
  e_limit_min.Color := clWindow;
end;

procedure TForm1.e_mn_maxClick(Sender: TObject);
begin
  e_mn_max.Color := clWindow;
end;

procedure TForm1.e_mn_minClick(Sender: TObject);
begin
  e_mn_min.Color := clWindow;
end;

procedure TForm1.e_limit_maxClick(Sender: TObject);
begin
  e_limit_max.Color := clWindow;
end;

procedure TForm1.rb_yield_pointClick(Sender: TObject);
begin
  b_action.ShowHint := false;
end;

procedure TForm1.rb_rupture_strengthClick(Sender: TObject);
begin
  b_action.ShowHint := false;
end;


function CheckAppRun: bool;
var
  hMutex : THandle;
begin
    // �������� 2 ��������� ���������
    hMutex := CreateMutex(0, true , 'AddTechnologicalSample');
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
