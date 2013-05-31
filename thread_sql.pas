unit thread_sql;


interface

uses
  SysUtils, Classes, Windows, ActiveX, Graphics, Forms;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSql = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadSql: TThreadSql;
    m_sql: bool = false;

    function ThreadSqlInit: bool;
    function ReadHeat: bool;
    function ViewAnalysis: bool;
    function ViewClear: bool;
    procedure WrapperSql;//������� ��� ������������� � ���������� � ������ �������

//    {$DEFINE DEBUG}


implementation

uses
  main, sql_module, thread_chart, chart, logging;





procedure TThreadSql.Execute;
var
  i:integer;
  e:bool;
begin
  CoInitialize(nil);
  while True do
   begin
      Synchronize(WrapperSql);
      sleep(1000);
   end;
   CoUninitialize;
end;


function ThreadSqlInit: bool;
begin
        //������� �����
        ThreadSql:=TThreadSql.Create(False);
        ThreadSql.Priority:=tpNormal;
        ThreadSql.FreeOnTerminate := True;
end;


procedure WrapperSql;
begin
      Application.ProcessMessages;//��������� �������� �� �������� ���������
      ReadHeat;
end;


function ReadHeat: bool;
var
  time: TDateTime;
begin
{  time := Time;

  if m_sql = false then
   begin
    DataModule1.pFIBDatabase1.Connected := false;
    DataModule1.pFIBDatabase1.LibraryName := '.\fbclient.dll';
    DataModule1.pFIBDatabase1.DBName := '10.21.115.4:e:\termo\db\TERMOMS3SPC1.FDB';
    DataModule1.pFIBDatabase1.ConnectParams.UserName := 'sysdba';
    DataModule1.pFIBDatabase1.ConnectParams.Password := 'masterkey';
    DataModule1.pFIBDatabase1.SQLDialect := 3;
    DataModule1.pFIBDatabase1.UseLoginPrompt := false;
    DataModule1.pFIBDatabase1.Timeout := 0;
    DataModule1.pFIBDatabase1.Connected := true;
    DataModule1.pFIBTransaction1.Active := false;
    DataModule1.pFIBTransaction1.Timeout := 0;
    DataModule1.pFIBQuery1.Database := DataModule1.pFIBDatabase1;
    DataModule1.pFIBQuery1.Transaction := DataModule1.pFIBTransaction1;
    m_sql := true;
   end;


   DataModule1.pFIBQuery1.Close;
   DataModule1.pFIBQuery1.SQL.Clear;
   DataModule1.pFIBQuery1.SQL.Add('select *');
   DataModule1.pFIBQuery1.SQL.Add('FROM melts');
   DataModule1.pFIBQuery1.SQL.Add('where begindt=(select max(begindt) FROM melts)');
   DataModule1.pFIBQuery1.ExecQuery;
   DataModule1.pFIBQuery1.Transaction.Commit;

   if LastDate < DataModule1.pFIBQuery1.FieldByName('begindt').AsDateTime then
    begin
      LastDate:=DataModule1.pFIBQuery1.FieldByName('begindt').AsDateTime;
      //Heat:=StringReplace(DataModule1.pFIBQuery1.FieldByName('NOPLAV').AsString,'-','_', [rfReplaceAll]);
      Heat:=DataModule1.pFIBQuery1.FieldByName('NOPLAV').AsString;
    end;

   DataModule1.pFIBQuery1.Close;
   DataModule1.pFIBQuery1.SQL.Clear;
   DataModule1.pFIBQuery1.SQL.Add('select *');
   DataModule1.pFIBQuery1.SQL.Add('FROM P'+FormatDateTime('yymmdd', LastDate)+'N'+StringReplace(Heat,'-','_', [rfReplaceAll]));
   DataModule1.pFIBQuery1.SQL.Add('where recordid=(select max(recordid) FROM P'+FormatDateTime('yymmdd', LastDate)+'N'+StringReplace(Heat,'-','_', [rfReplaceAll])+')');
   DataModule1.pFIBQuery1.ExecQuery;
   DataModule1.pFIBQuery1.Transaction.Commit;

   Form1.Caption := floattostr(DataModule1.pFIBQuery1.FieldByName('recordid').AsFloat);
   Application.Title := floattostr(DataModule1.pFIBQuery1.FieldByName('recordid').AsFloat);
   Temp := DataModule1.pFIBQuery1.FieldByName('TMOUTL').AsString;
 }
   ViewAnalysis;

//   m_chart := false;//��������� ������ ����������

end;


function ViewAnalysis: bool;
begin
    DataModule1.OraQuery1.Close;
    DataModule1.OraQuery1.SQL.Clear;
    DataModule1.OraQuery1.SQL.Add('select * from HIM_STEEL where year=to_char(sysdate, ''YYYY'')');
    DataModule1.OraQuery1.SQL.Add('and npl='''+Heat+''' and NUMBER_TEST=''0'''); //NUMBER_TEST='0' ���������� �����
    DataModule1.OraQuery1.Open;

    if strtoint(Temp) > 250 then
     begin
 {       Ce := StringReplace(FloatToStrF(
              DataModule1.OraQuery1.FieldByName('c').AsFloat+
              (DataModule1.OraQuery1.FieldByName('mn').AsFloat/6)+
              (DataModule1.OraQuery1.FieldByName('cr').AsFloat/5)+
              (DataModule1.OraQuery1.FieldByName('si').AsFloat/10), ffFixed, 8, 4 //8 ������ ����� 4 �������
              ),',','.', [rfReplaceAll]);}

{        Ce := CarbonEquivalent(DataModule1.OraQuery1.FieldByName('c').AsFloat,
                               DataModule1.OraQuery1.FieldByName('mn').AsFloat,
                               DataModule1.OraQuery1.FieldByName('cr').AsFloat,
                               DataModule1.OraQuery1.FieldByName('si').AsFloat);
 }
        Grade := DataModule1.OraQuery1.FieldByName('MST').AsString;
        Section := DataModule1.OraQuery1.FieldByName('PROFILE').AsString;
        Standard := DataModule1.OraQuery1.FieldByName('GOST').AsString;

        //chemical
        form1.l_carbon.Caption := DataModule1.OraQuery1.FieldByName('C').AsString;
        form1.l_manganese.Caption := DataModule1.OraQuery1.FieldByName('MN').AsString;
        form1.l_silicium.Caption := DataModule1.OraQuery1.FieldByName('SI').AsString;
        form1.l_chromium.Caption := DataModule1.OraQuery1.FieldByName('CR').AsString;
        //
        form1.l_heat.Caption := Heat;
        form1.l_grade.Caption := Grade;
        form1.l_c_equivalent.Caption := Ce;
        form1.l_temp.Caption := Temp;
        form1.l_strength_class.Caption := StrengthClass;
        form1.l_section.Caption := Section;
        form1.l_standard.Caption := Standard;
     end
    else
     begin
        ViewClear;
     end;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+DataModule1.OraQuery1.SQL.Text);
  {$ENDIF}
end;


function ViewClear: bool;
begin
    form1.l_carbon.Caption := '';
    form1.l_manganese.Caption := '';
    form1.l_silicium.Caption := '';
    form1.l_chromium.Caption := '';

    //
    form1.l_heat.Caption := '';
    form1.l_grade.Caption := '';
    form1.l_section.Caption := '';
    form1.l_standard.Caption := '';
    form1.l_strength_class.Caption := '';
    form1.l_c_equivalent.Caption := '';
    form1.l_temp.Caption := '';
end;




end.
