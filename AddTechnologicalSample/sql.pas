unit sql;

interface

uses
  SysUtils, Classes, Windows, ActiveX, Dialogs, Forms, Data.DB, ZAbstractDataset,
  ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset, ZStoredProcedure;

var
  PConnect: TZConnection;
  PQuery: TZQuery;
  DataSource: TDataSource;
  function ConfigPostgresSetting(InData: bool): bool;
  function SqlRead: bool;
  function SqlInsert: bool;
  function SqlUpdate(InId: integer): bool;
  function SqlDelete(InId: integer): bool;

implementation

uses
  main, settings;




function ConfigPostgresSetting(InData: bool): bool;
begin
  if InData then
  begin
    PConnect := TZConnection.Create(nil);
    PQuery := TZQuery.Create(nil);

    try
        PConnect.LibraryLocation := CurrentDir + '\'+ PgSqlConfigArray[3];
        PConnect.Protocol := 'postgresql-9';
        PConnect.HostName := PgSqlConfigArray[1];
        PConnect.Port := strtoint(PgSqlConfigArray[6]);
        PConnect.User := PgSqlConfigArray[4];
        PConnect.Password := PgSqlConfigArray[5];
        PConnect.Database := PgSqlConfigArray[2];
        PConnect.Connect;
        PQuery.Connection := PConnect;
        DataSource := TDataSource.Create(nil);
        DataSource.DataSet := PQuery;
    except
      on E: Exception do
        Showmessage('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
  end
  else
  begin
      FreeAndNil(DataSource);
      FreeAndNil(PQuery);
      FreeAndNil(PConnect);
  end;
end;


function SqlRead: bool;
begin
  try
    PQuery.Close;
    PQuery.SQL.Clear;
    PQuery.SQL.Add('SELECT id, grade, standard, strength_class, c_min, c_max, mn_min');
    PQuery.SQL.Add(',mn_max, si_min, si_max, diameter_min, diameter_max, limit_min, limit_max');
    PQuery.SQL.Add(', cast(case t1.type');
    PQuery.SQL.Add('when ''yield_point'' then ''������ ���������''');
    PQuery.SQL.Add('when ''rupture_strength'' then ''��������� �������������'' end as varchar(50)) as type');
    PQuery.SQL.Add(',(SELECT COUNT(*) FROM technological_sample AS t2');
    PQuery.SQL.Add('WHERE t2.id <= t1.id) AS numeric FROM technological_sample AS t1');
    PQuery.SQL.Add('order by id desc');
    PQuery.Open;
  except
    on E: Exception do
      Showmessage('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
end;


function SqlInsert: bool;
begin
  PQuery.Close;
  PQuery.SQL.Clear;
  PQuery.SQL.Add('INSERT INTO technological_sample');
  PQuery.SQL.Add('(grade, standard, strength_class, c_min, c_max, mn_min');
  PQuery.SQL.Add(',mn_max, si_min, si_max, diameter_min, diameter_max, limit_min');
  PQuery.SQL.Add(', limit_max, type)');
  PQuery.SQL.Add('VALUES('''+trim(form1.e_grade.Text)+'''');
  PQuery.SQL.Add(', '''+trim(form1.e_standard.Text)+'''');
  PQuery.SQL.Add(', '''+trim(form1.e_strength_class.Text)+'''');
  PQuery.SQL.Add(', '+trim(form1.e_c_min.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_c_max.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_mn_min.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_mn_max.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_si_min.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_si_max.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_diameter_min.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_diameter_max.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_limit_min.Text)+'');
  PQuery.SQL.Add(', '+trim(form1.e_limit_max.Text)+'');
  if form1.rb_yield_point.Checked then
    PQuery.SQL.Add(', ''yield_point'')');
  if form1.rb_rupture_strength.Checked then
    PQuery.SQL.Add(', ''rupture_strength'')');
  PQuery.ExecSQL;

  SqlRead;
end;


function SqlUpdate(InId: integer): bool;
begin
  PQuery.Close;
  PQuery.SQL.Clear;
  PQuery.SQL.Add('UPDATE technological_sample SET');
  PQuery.SQL.Add('grade='''+trim(form1.e_grade.Text)+'''');
  PQuery.SQL.Add(', standard='''+trim(form1.e_standard.Text)+'''');
  PQuery.SQL.Add(', strength_class='''+trim(form1.e_strength_class.Text)+'''');
  PQuery.SQL.Add(', c_min='+trim(form1.e_c_min.Text)+'');
  PQuery.SQL.Add(', c_max='+trim(form1.e_c_max.Text)+'');
  PQuery.SQL.Add(', mn_min='+trim(form1.e_mn_min.Text)+'');
  PQuery.SQL.Add(', mn_max='+trim(form1.e_mn_max.Text)+'');
  PQuery.SQL.Add(', si_min='+trim(form1.e_si_min.Text)+'');
  PQuery.SQL.Add(', si_max='+trim(form1.e_si_max.Text)+'');
  PQuery.SQL.Add(', diameter_min='+trim(form1.e_diameter_min.Text)+'');
  PQuery.SQL.Add(', diameter_max='+trim(form1.e_diameter_max.Text)+'');
  PQuery.SQL.Add(', limit_min='+trim(form1.e_limit_min.Text)+'');
  PQuery.SQL.Add(', limit_max='+trim(form1.e_limit_max.Text)+'');
  if form1.rb_yield_point.Checked then
    PQuery.SQL.Add(', type=''yield_point''');
  if form1.rb_rupture_strength.Checked then
    PQuery.SQL.Add(', type=''rupture_strength''');
  PQuery.SQL.Add('where id='+inttostr(InId)+'');
  PQuery.ExecSQL;

  SqlRead;
end;


function SqlDelete(InId: integer): bool;
begin
  PQuery.Close;
  PQuery.SQL.Clear;
  PQuery.SQL.Add('DELETE FROM technological_sample');
  PQuery.SQL.Add('where id='+inttostr(InId)+'');
  PQuery.ExecSQL;

  SqlRead;  
end;




end.

