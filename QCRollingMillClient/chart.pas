unit chart;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  VCLTee.TeEngine, VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.chart, VCLTee.DBChart,
  VCLTee.TeeSpline, DateUtils;

type
  TArrayLimit = array [0 .. 1] of integer;

  // private
  { Private declarations }
  // protected

  // end;

var
  TimestampLastLeft: TDateTime = 0;
  TimestampLastRight: TDateTime = 0;
  CountLeft: integer = 1;
  CountRight: integer = 1;

  //{$DEFINE DEBUG}

function ViewsCharts: bool;
function LimitMinMax(InTemperature, InSide: integer): TArrayLimit;

implementation

uses
  main, settings, sql, logging;

function ViewsCharts: bool;
var
  DateTimeLeft, TimeLeft, DateTimeRight, TimeRight: TDateTime;
  i, q: integer;
  LimitLeft, LimitRight: TArrayLimit;
begin

  DateTimeLeft := NOW;
  DateTimeRight := NOW;

  for i := 0 to 4 do
  begin
    // -- left
    Form1.chart_left_side.Series[i].XValues.DateTime := true;
    // -- right
    Form1.chart_right_side.Series[i].XValues.DateTime := true;
  end;

  // -- left
  Form1.chart_left_side.BottomAxis.Automatic := false;
  // -- right
  Form1.chart_right_side.BottomAxis.Automatic := false;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'ViewsCharts -> ' + timetostr(time));
{$ENDIF}
  // -- left
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'TemperatureCurrentLeft -> '+inttostr(left.temperature));
{$ENDIF}

  // LimitLeft[0] - min, LimitLeft[1] - max
  LimitLeft := LimitMinMax(left.temperature, 0);

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'LimitLeft min -> ' + inttostr(LimitLeft[0]));
  SaveLog('debug' + #9#9 + 'LimitLeft max -> ' + inttostr(LimitLeft[1]));
{$ENDIF}
  if NOW > Form1.chart_left_side.BottomAxis.Maximum then
  begin
    Form1.chart_left_side.BottomAxis.Maximum := DateTimeLeft;
    // form1.Chart1.BottomAxis.Minimum := T - 10./(60*60*24);
    Form1.chart_left_side.BottomAxis.Minimum := DateTimeLeft - (1 / 24 / 60);
  end;

  // построение оси с права
  Form1.chart_left_side.Series[2].VertAxis := aRightAxis;
  Form1.chart_left_side.RightAxis.SetMinMax(LimitLeft[0], LimitLeft[1]);
  Form1.chart_left_side.LeftAxis.SetMinMax(LimitLeft[0], LimitLeft[1]);

  // пределы red
  Form1.chart_left_side.Series[4].AddXY(NOW, left.LowRed,
    timetostr(DateTimeLeft), clRed); // min
  Form1.chart_left_side.Series[0].AddXY(NOW, left.HighRed,
    timetostr(DateTimeLeft), clRed); // max

  // пределы green
  if (left.LowGreen > left.LowRed) and (left.LowGreen < left.HighRed) and
     (left.HighGreen > left.LowRed) then
    Form1.chart_left_side.Series[3].AddXY(NOW, left.LowGreen,
      timetostr(DateTimeLeft), clGreen); // min

  if (left.HighGreen < left.HighRed) and (left.HighGreen > left.LowRed) and
     (left.LowGreen < left.HighRed) then
    Form1.chart_left_side.Series[1].AddXY(NOW, left.HighGreen,
      timetostr(DateTimeLeft), clGreen); // max

  if (left.LowGreen <> 0) and (left.LowRed >= left.LowGreen) and
     (left.HighGreen > left.LowRed) then
    Form1.chart_left_side.Series[3].AddXY(NOW, left.LowRed+3,
      timetostr(DateTimeLeft), clGreen); // min +3 градуса от low красных

  if (left.HighGreen <> 0) and (left.HighGreen >= left.HighRed) and
     (left.LowGreen < left.HighRed) then
    Form1.chart_left_side.Series[1].AddXY(NOW, left.HighRed-3,
      timetostr(DateTimeLeft), clGreen); // max -3 градуса от high красных

  if (left.LowGreen > left.HighRed) or (left.HighGreen < left.LowRed) then
  begin
    Form1.chart_left_side.Series[3].AddXY(NOW, 0,
                                   timetostr(DateTimeLeft), clBlack); // min в 0
    Form1.chart_left_side.Series[1].AddXY(NOW, 0,
                                   timetostr(DateTimeLeft), clBlack); // max в 0
  end;

  // график температуры
  Form1.chart_left_side.Series[2].AddXY(NOW, left.temperature,
    timetostr(DateTimeLeft), clBlue);

  try
    // left chart clean old data
    if CountLeft < Form1.chart_left_side.Series[2].Count then
    begin
      for i := Form1.chart_left_side.Series[2].Count - 101 downto 0 do
      begin
        for q := 0 to Form1.chart_left_side.SeriesCount - 1 do
          Form1.chart_left_side.Series[q].Delete(i);
      end;
      CountLeft := Form1.chart_left_side.Series[2].Count + 100;
    end;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;

  // -- right
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'TemperatureCurrentRight -> '+inttostr(right.temperature));
{$ENDIF}

  // LimitRight[0] - min, LimitRight[1] - max
  LimitRight := LimitMinMax(right.temperature, 1);

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'LimitRight min -> ' + inttostr(LimitRight[0]));
  SaveLog('debug' + #9#9 + 'LimitRight max -> ' + inttostr(LimitRight[1]));
{$ENDIF}
  if NOW > Form1.chart_right_side.BottomAxis.Maximum then
  begin
    Form1.chart_right_side.BottomAxis.Maximum := DateTimeRight;
    // form1.Chart1.BottomAxis.Minimum := T - 10./(60*60*24);
    Form1.chart_right_side.BottomAxis.Minimum := DateTimeRight - (1 / 24 / 60);
  end;

  // построение оси с права
  Form1.chart_right_side.Series[2].VertAxis := aRightAxis;
  Form1.chart_right_side.RightAxis.SetMinMax(LimitRight[0], LimitRight[1]);
  Form1.chart_right_side.LeftAxis.SetMinMax(LimitRight[0], LimitRight[1]);

  // пределы red
  Form1.chart_right_side.Series[4].AddXY(NOW, right.LowRed,
    timetostr(DateTimeRight), clRed); // min
  Form1.chart_right_side.Series[0].AddXY(NOW, right.HighRed,
    timetostr(DateTimeRight), clRed); // max

  // пределы green
  if (right.LowGreen > right.LowRed) and (right.LowGreen < right.HighRed) and
     (right.HighGreen > right.LowRed) then
    Form1.chart_right_side.Series[3].AddXY(NOW, right.LowGreen,
      timetostr(DateTimeRight), clGreen); // min

  if (right.HighGreen < right.HighRed) and (right.HighGreen > right.LowRed) and
     (right.LowGreen < right.HighRed) then
    Form1.chart_right_side.Series[1].AddXY(NOW, right.HighGreen,
      timetostr(DateTimeRight), clGreen); // max

  if (right.LowGreen <> 0) and (right.LowRed >= right.LowGreen) and
     (right.HighGreen > right.LowRed) then
    Form1.chart_right_side.Series[3].AddXY(NOW, right.LowRed+3,
      timetostr(DateTimeRight), clGreen); // min +3 градуса от low красных

  if (right.HighGreen <> 0) and (right.HighGreen >= right.HighRed) and
     (right.LowGreen < right.HighRed) then
    Form1.chart_right_side.Series[1].AddXY(NOW, right.HighRed-3,
      timetostr(DateTimeRight), clGreen); // max -3 градуса от high красных

  if (right.LowGreen > right.HighRed) or (right.HighGreen < right.LowRed) then
  begin
    Form1.chart_right_side.Series[3].AddXY(NOW, 0,
                                  timetostr(DateTimeRight), clBlack); // min в 0
    Form1.chart_right_side.Series[1].AddXY(NOW, 0,
                                  timetostr(DateTimeRight), clBlack); // max в 0
  end;

  // график температуры
  Form1.chart_right_side.Series[2].AddXY(NOW, right.temperature,
    timetostr(DateTimeRight), clBlue);

  try
    // right chart clean old data
    if CountRight < Form1.chart_right_side.Series[2].Count then
    begin
      for i := Form1.chart_right_side.Series[2].Count - 101 downto 0 do
      begin
        for q := 0 to Form1.chart_right_side.SeriesCount - 1 do
          Form1.chart_right_side.Series[q].Delete(i);
      end;
      CountRight := Form1.chart_right_side.Series[2].Count + 100;
    end;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;

end;


function LimitMinMax(InTemperature, InSide: integer): TArrayLimit;
begin
  // side left=0, side right=1
  if (left.LowRed <> 0) and (InSide = 0) then
  begin
    Result[0] := left.LowRed-30;
    Result[1] := left.HighRed+30;
    exit;
  end;

  if (right.LowRed <> 0) and (InSide = 1) then
  begin
    Result[0] := right.LowRed-30;
    Result[1] := right.HighRed+30;
    exit;
  end;

  if InTemperature < 450 then
  begin
    Result[0] := 250;
    Result[1] := 550;
  end;

  if (InTemperature < 650) and (InTemperature > 450) then
  begin
    Result[0] := 350;
    Result[1] := 750;
  end;

  if (InTemperature < 850) and (InTemperature > 650) then
  begin
    Result[0] := 550;
    Result[1] := 950;
  end;

  if (InTemperature < 1050) and (InTemperature > 850) then
  begin
    Result[0] := 750;
    Result[1] := 1150;
  end;

  if (InTemperature < 1250) and (InTemperature > 1050) then
  begin
    Result[0] := 950;
    Result[1] := 1250;
  end;
end;

end.
