unit chart;

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  TAGraph, TASeries, TAChartUtils, TAChartAxis;

type
   TLimits = record
               min,
               max: integer
   end;
{
  // private
  { Private declarations }
  // protected

   end;}

var
  TimestampLastLeft: TDateTime = 0;
  TimestampLastRight: TDateTime = 0;
  CountSameTemperature: integer = 9;// счетчик одинаковой температуры
  CountLineSeries: integer = 200; //удаляются LineSeries > 200
  ColorCurrentLine: TColor = clBlue;
  ColorWarningLine: TColor = $0000A800;
  ColorAlarmLine: TColor = clRed;

//  {$DEFINE DEBUG}

  function ViewsChartsLeft: boolean;
  function ViewsGreenLimintsLeft: boolean;
  function ViewsRedLimintsLeft: boolean;
  function ViewsChartsRight: boolean;
  function ViewsGreenLimintsRight: boolean;
  function ViewsRedLimintsRight: boolean;
  function LimitMinMax(InTemperature, InSide: integer): TLimits;


implementation

uses
  gui, settings, thread_main, thread_heat;

{ left }
function ViewsChartsLeft: boolean;
var
  LimitLeft: TLimits;
  temperature: integer;
begin
  { счетчик не изменяющейся температуры }
  if (left.temperature = left.OldTemperature) then
    inc(left.count)
  else
    left.count := 0;

  left.OldTemperature := left.temperature;
  temperature := left.temperature;

  if left.count > CountSameTemperature then temperature := 0;

  if now > form1.ChartLeft.BottomAxis.Range.Max then
  begin
    form1.ChartLeft.BottomAxis.Range.Max := now;
    form1.ChartLeft.BottomAxis.Range.Min := now - (1/24/(60/2));{ day/hour/min scale 1 sec | 60/2 10 sec}
  end;

  if form1.ChartLeft.BottomAxis.Marks.AtDataOnly then
     form1.ChartLeft.BottomAxis.Marks.AtDataOnly := false;//включаем шкалу

  // устанавливаем приделы шкалы
  LimitLeft := LimitMinMax(temperature, 0);
  if LimitLeft.max > LimitLeft.min then begin //мин недолжно быть больше мах
    form1.ChartLeft.Extent.YMin := LimitLeft.min;
    form1.ChartLeft.Extent.YMax := LimitLeft.max;
    form1.ChartLeft.Extent.UseYMin := true;
    form1.ChartLeft.Extent.UseYMax := true;
  end;

  ViewsRedLimintsLeft;
  ViewsGreenLimintsLeft;

{{ test }
  form1.label1.Caption:='left count '+inttostr(left.count)+
                        ' series count '+
                        inttostr(form1.ChartLeftLineSeriesCurrent.ListSource.Count);}

  with form1.ChartLeftLineSeriesCurrent do begin
{     if temperature > 0 then}
     AddXY(now, temperature, '', ColorCurrentLine);
{     else
       AddX(0, '', clNone);}
     if Count > CountLineSeries then
       ListSource.Delete(0);
  end;
end;


function ViewsRedLimintsLeft: boolean;
begin
  with form1.ChartLeftLineSeriesRedHight do begin
     if left.HighRed > 0 then
       AddXY(now, left.HighRed, '', ColorAlarmLine)
     else
       AddX(0, '', clNone);
     if Count > CountLineSeries then
       ListSource.Delete(0);
  end;

  with form1.ChartLeftLineSeriesRedLow do begin
     if left.LowRed > 0 then
       AddXY(now, left.LowRed, '', ColorAlarmLine)
     else
       AddX(0, '', clNone);
     if Count > CountLineSeries then
       ListSource.Delete(0);
  end;
end;


function ViewsGreenLimintsLeft: boolean;
begin
  // max
  if (left.HighGreen < left.HighRed) and
     (left.HighGreen > left.LowGreen) then begin
     with form1.ChartLeftLineSeriesGreenHight do begin
        if left.HighGreen > 0 then
          AddXY(now, left.HighGreen, '', ColorWarningLine)
        else
          AddX(0, '', clNone);
        if Count > CountLineSeries then
          ListSource.Delete(0);
     end;
  end;

  // min
  if (left.LowGreen > left.LowRed) and
     (left.LowGreen < left.HighGreen) then begin
     with form1.ChartLeftLineSeriesGreenLow do begin
        if left.LowGreen > 0 then
          AddXY(now, left.LowGreen, '', ColorWarningLine)
        else
          AddX(0, '', clNone);
        if Count > CountLineSeries then
          ListSource.Delete(0);
     end;
  end;

  // min +3 градуса от low красных
  if (left.LowGreen <> 0) and (left.LowRed >= left.LowGreen) and
     (left.HighGreen > left.LowRed) then begin
       with form1.ChartLeftLineSeriesGreenLow do begin
          if left.LowRed > 0 then
            AddXY(now, left.LowRed+3, '', ColorWarningLine)
          else
            AddX(0, '', clNone);
          if Count > CountLineSeries then
            ListSource.Delete(0);
       end;
  end;

  // max -3 градуса от high красных
  if (left.HighGreen >= left.HighRed) then begin
       with form1.ChartLeftLineSeriesGreenHight do begin
           if left.HighRed > 0 then
             AddXY(now, left.HighRed-3, '', ColorWarningLine)
           else
             AddX(0, '', clNone);
           if Count > CountLineSeries then
             ListSource.Delete(0);
       end;
  end;

  if (left.LowGreen > left.HighRed) or (left.HighGreen < left.LowRed) then
  begin
    with form1.ChartLeftLineSeriesGreenLow do begin
        AddX(0, '', clNone);
        if Count > CountLineSeries then
           ListSource.Delete(0);// min в 0
    end;
    with form1.ChartLeftLineSeriesGreenHight do begin
        AddX(0, '', clNone);
        if Count > CountLineSeries then
           ListSource.Delete(0);// max в 0
    end;
  end;
end;


{ right }
function ViewsChartsRight: boolean;
var
  LimitRight: TLimits;
  temperature: integer;
begin
  { счетчик не изменяющейся температуры }
  if (right.temperature = right.OldTemperature) then
    inc(right.count)
  else
    right.count := 0;

  right.OldTemperature := right.temperature;
  temperature := right.temperature;

  if right.count > CountSameTemperature then temperature := 0;

  if now > form1.ChartRight.BottomAxis.Range.Max then
  begin
    form1.ChartRight.BottomAxis.Range.Max := now;
    form1.ChartRight.BottomAxis.Range.Min := now - (1/24/(60/2));{ day/hour/min scale 1 sec | 60/2 10 sec}
  end;

  if form1.ChartRight.BottomAxis.Marks.AtDataOnly then
     form1.ChartRight.BottomAxis.Marks.AtDataOnly := false;//включаем шкалу

  // устанавливаем приделы шкалы
  LimitRight := LimitMinMax(temperature, 1);
  if LimitRight.max > LimitRight.min then begin //мин недолжно быть больше мах
    form1.ChartRight.Extent.YMin := LimitRight.min;
    form1.ChartRight.Extent.YMax := LimitRight.max;
    form1.ChartRight.Extent.UseYMin := true;
    form1.ChartRight.Extent.UseYMax := true;
  end;

  ViewsRedLimintsRight;
  ViewsGreenLimintsRight;

  with form1.ChartRightLineSeriesCurrent do begin
{      if temperature > 0 then}
        AddXY(now, temperature, '', ColorCurrentLine);
{      else
         AddX(0, '', clNone);}
      if Count > CountLineSeries then
        ListSource.Delete(0);
  end;
end;


function ViewsRedLimintsRight: boolean;
begin
  with form1.ChartRightLineSeriesRedHight do begin
      if right.HighRed > 0 then
         AddXY(now, right.HighRed, '', ColorAlarmLine)
      else
         AddX(0, '', clNone);
      if Count > CountLineSeries then
        ListSource.Delete(0);
  end;

  with form1.ChartRightLineSeriesRedLow do begin
      if right.LowRed > 0 then
        AddXY(now, right.LowRed, '', ColorAlarmLine)
      else
         AddX(0, '', clNone);
      if Count > CountLineSeries then
        ListSource.Delete(0);
  end;
end;


function ViewsGreenLimintsRight: boolean;
begin
  // max
  if (right.HighGreen < right.HighRed) and
     (right.HighGreen > right.LowGreen) then begin
     with form1.ChartRightLineSeriesGreenHight do begin
         if right.HighGreen > 0 then
           AddXY(now, right.HighGreen, '', ColorWarningLine)
         else
           AddX(0, '', clNone);
         if Count > CountLineSeries then
           ListSource.Delete(0);
     end;
  end;

  // min
  if (right.LowGreen > right.LowRed) and
     (right.LowGreen < right.HighGreen) then begin
     with form1.ChartRightLineSeriesGreenLow do begin
         if right.LowGreen > 0 then
           AddXY(now, right.LowGreen, '', ColorWarningLine)
         else
           AddX(0, '', clNone);
         if Count > CountLineSeries then
            ListSource.Delete(0);
     end;
  end;

  // min +3 градуса от low красных
  if (right.LowGreen <> 0) and (right.LowRed >= right.LowGreen) and
     (right.HighGreen > right.LowRed) then begin
       with form1.ChartRightLineSeriesGreenLow do begin
           if right.LowRed > 0 then
             AddXY(now, right.LowRed+3, '', ColorWarningLine)
           else
             AddX(0, '', clNone);
           if Count > CountLineSeries then
             ListSource.Delete(0);
       end;
  end;

  // max -3 градуса от high красных
  if (right.HighGreen >= right.HighRed) then begin
       with form1.ChartRightLineSeriesGreenHight do begin
           if right.HighRed > 0 then
             AddXY(now, right.HighRed-3, '', ColorWarningLine)
           else
             AddX(0, '', clNone);
           if Count > CountLineSeries then
             ListSource.Delete(0);
       end;
  end;

  if (right.LowGreen > right.HighRed) or (right.HighGreen < right.LowRed) then
  begin
    with form1.ChartRightLineSeriesGreenLow do begin
        AddX(0, '', clNone);
        if Count > CountLineSeries then
           ListSource.Delete(0);// min в 0
    end;
    with form1.ChartRightLineSeriesGreenHight do begin
        AddX(0, '', clNone);
        if Count > CountLineSeries then
           ListSource.Delete(0);// max в 0
    end;
  end;
end;


function LimitMinMax(InTemperature, InSide: integer): TLimits;
begin
  // side left=0, side right=1
  if (left.LowRed <> 0) and (left.HighRed <> 0) and
     (InSide = 0) then
  begin
    Result.min := left.LowRed-30;
    Result.max := left.HighRed+30;
    exit;
  end;

  if (right.LowRed <> 0) and (right.HighRed <> 0) and
     (InSide = 1) then
  begin
    Result.min := right.LowRed-30;
    Result.max := right.HighRed+30;
    exit;
  end;

  Result.min := 250;
  Result.max := 1250;
end;


end.
