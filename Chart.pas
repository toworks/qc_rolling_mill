unit Chart;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.DBChart,
  VCLTee.TeeSpline;

{type
  //����� ���������� ������� ����� TViewThread:
  //TViewThread = class(TThread)

  private
    { Private declarations }
 { protected

  end;

var}

//  {$DEFINE DEBUG}

//  ViewThread: TViewThread;
  function ViewsCharts: bool;



implementation

uses
  main, sql_module, thread_chart, thread_sql, logging;



function ViewsCharts: bool;
var T: TDateTime;
begin

    T := Time;
    Form1.Chart1.Series[2].XValues.DateTime := true;
    Form1.Chart1.BottomAxis.Automatic := false;

  DataModule1.pFIBQuery1.Close;
  DataModule1.pFIBQuery1.SQL.Clear;
  DataModule1.pFIBQuery1.SQL.Add('select *');
  DataModule1.pFIBQuery1.SQL.Add('FROM melts');
  DataModule1.pFIBQuery1.SQL.Add('where begindt=(select max(begindt) FROM melts)');
  DataModule1.pFIBQuery1.ExecQuery;
  DataModule1.pFIBQuery1.Transaction.Commit;

  Heat:= DataModule1.pFIBQuery1.FieldByName('NOPLAV').AsString; //������
  Grade:= '%'+DataModule1.pFIBQuery1.FieldByName('MARKA').AsString; //'%��3����'; //����� �����
  Section:= '%10%'; //�������
  Standard:= '����%3760%2006'; //��������
  StrengthClass:= '%�500�%'; //���� ���������

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'CurrentHeat='+Heat);
    SaveLog('debug'+#9#9+'CurrentGrade='+Grade);
    SaveLog('debug'+#9#9+'CurrentSection='+Section);
    SaveLog('debug'+#9#9+'CurrentStandard='+Standard);
    SaveLog('debug'+#9#9+'CurrentStrengthClass='+StrengthClass);
  {$ENDIF}

   if LastDate < DataModule1.pFIBQuery1.FieldByName('begindt').AsDateTime then
    begin
      LastDate := DataModule1.pFIBQuery1.FieldByName('begindt').AsDateTime;
//      Heat := StringReplace(DataModule1.pFIBQuery1.FieldByName('NOPLAV').AsString,'-','_', [rfReplaceAll]);
      Heat := DataModule1.pFIBQuery1.FieldByName('NOPLAV').AsString;
      StrengthClass := DataModule1.pFIBQuery1.FieldByName('KLASS').AsString;
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

   Temp := inttostr(DataModule1.pFIBQuery1.FieldByName('TMOUTL').AsInteger);

   if(time > form1.Chart1.BottomAxis.Maximum) then
    begin
      form1.Chart1.BottomAxis.Maximum := T;
      //form1.Chart1.BottomAxis.Minimum := T - 10./(60*60*24);
      form1.Chart1.BottomAxis.Minimum := T - strtotime('00:01:00');
    end;

    //���������� ��� � �����
    form1.Series3.VertAxis := aRightAxis;
    form1.Chart1.RightAxis.SetMinMax(450,650);

    //������� red
    form1.series1.AddXY(Time, HighRed, timetostr(T), clRed); //max
    form1.series5.AddXY(Time, LowRed, timetostr(T), clRed); //min

    //������� green
    form1.series2.AddXY(Time, HighGreen, timetostr(T), clGreen); //max
    form1.series4.AddXY(Time, LowGreen, timetostr(T), clGreen); //min

    form1.Chart1.LeftAxis.SetMinMax(450,650);
    form1.series3.AddXY(Time, DataModule1.pFIBQuery1.FieldByName('TMOUTL').AsInteger, timetostr(T), clBlue);

{    DataModule1.pFIBQuery1.Close;
    DataModule1.pFIBQuery1.SQL.Clear;
    DataModule1.pFIBQuery1.SQL.Add('select * from melts as m,');
    DataModule1.pFIBQuery1.SQL.Add('(select * from chemical) as c');
    DataModule1.pFIBQuery1.SQL.Add('where m.begindt=(select max(begindt) FROM melts)');
    DataModule1.pFIBQuery1.SQL.Add('and m.noplav = c.noplav');
    DataModule1.pFIBQuery1.ExecQuery;
    DataModule1.pFIBQuery1.Transaction.Commit;
}

end;





end.
