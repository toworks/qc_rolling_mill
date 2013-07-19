{
  1 правая - не четная, 2 левая - четная, сторона | мс5 0 лева 1 правая
}
unit sql;


interface

uses
  SysUtils, Classes, Windows, ActiveX, Graphics, Forms;


type
  TArray = array of array of variant;
//  THeatArray = array of array of variant;

var
  //global
//  Side: integer = 0; //1 правая - не четная, 2 левая - четная, сторона | мс5 0 лева 1 правая
  Side: integer;
  Heat: string = ''; //плавка
  Grade: string = ''; //марка стали
  Section: string = ''; //профиль
  Standard: string = ''; //стандарт
  StrengthClass: string = ''; //клас прочности

  HeatLeft: string = ''; //плавка
  GradeLeft: string = ''; //марка стали
  SectionLeft: string = ''; //профиль
  StandardLeft: string = ''; //стандарт
  StrengthClassLeft: string = ''; //клас прочности
  c_left: string = '';
  mn_left: string = '';
  cr_left: string = '';
  si_left: string = '';
  b_left: string = '';


  HeatRight: string = ''; //плавка
  GradeRight: string = ''; //марка стали
  SectionRight: string = ''; //профиль
  StandardRight: string = ''; //стандарт
  StrengthClassRight: string = ''; //клас прочности
  c_right: string = '';
  mn_right: string = '';
  cr_right: string = '';
  si_right: string = '';
  b_right: string = '';



  function SqlReadCurrentHeat: bool;
  function ViewCurrentData: bool;
  function ReadCemicalAnalysis(InHeat: string; InSide: integer): bool;
//  function SqlWriteHeatToCemicalAnalysis(InHeat: string): bool;
  function SqlWriteHeatToCemicalAnalysis: bool;
  function SqlWriteCemicalAnalysis(InData: string): bool;
  function SqlCarbonEquivalent(InHeat: string): TArray;//array of array of variant;


//  {$DEFINE DEBUG}


implementation

uses
  main, logging, settings, sql_module, chart, tcp_send_read;






function SqlReadCurrentHeat: bool;
var
  i: integer;
  OldHeatLeft, OldHeatRight, HeatAll: string;
begin

  OldHeatLeft := HeatLeft;
  OldHeatRight := HeatRight;

  try
      SqlWriteHeatToCemicalAnalysis;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;

  for i := 0 to 1 do
  begin
      //side left=0, side right=1
      Module.pFIBQuery1.Close;
      Module.pFIBQuery1.SQL.Clear;
      Module.pFIBQuery1.SQL.Add('select FIRST 1 *');
      Module.pFIBQuery1.SQL.Add('FROM melts');
      Module.pFIBQuery1.SQL.Add('where side='+inttostr(i)+'');
      Module.pFIBQuery1.SQL.Add('order by begindt desc');
      Module.pFIBQuery1.ExecQuery;
      Module.pFIBQuery1.Transaction.Commit;

      if i = 0 then
      begin
          HeatLeft := Module.pFIBQuery1.FieldByName('NOPLAV').AsString;
          GradeLeft := Module.pFIBQuery1.FieldByName('MARKA').AsString;
          StrengthClassLeft := Module.pFIBQuery1.FieldByName('KLASS').AsString;
          SectionLeft := Module.pFIBQuery1.FieldByName('RAZM1').AsString;
          StandardLeft := Module.pFIBQuery1.FieldByName('STANDART').AsString;
      end
      else
      begin
          HeatRight := Module.pFIBQuery1.FieldByName('NOPLAV').AsString;
          GradeRight := Module.pFIBQuery1.FieldByName('MARKA').AsString;
          StrengthClassRight := Module.pFIBQuery1.FieldByName('KLASS').AsString;
          SectionRight := Module.pFIBQuery1.FieldByName('RAZM1').AsString;
          StandardRight := Module.pFIBQuery1.FieldByName('STANDART').AsString;
      end;

      ReadCemicalAnalysis(HeatLeft, i);
  end;

  ViewCurrentData;

  GetHeatChemicalAnalysis;

  if OldHeatLeft <> HeatLeft then
  begin
      try
        SaveLog('info'+#9#9+'start calculation left side');
        HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(0),0);
        CarbonEquivalent(HeatAll,0);
        SaveLog('info'+#9#9+'end calculation left side');
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
      end;
  end;

  if OldHeatRight <> HeatRight then
  begin
      try
        SaveLog('info'+#9#9+'start calculation right side');
        HeatAll := CalculatingInMechanicalCharacteristics(RolledMelting(1),1);
        CarbonEquivalent(HeatAll,1);
        SaveLog('info'+#9#9+'end calculation right side');
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
      end;
  end;
end;


function ViewCurrentData: bool;
begin

  //side left
  form1.l_global_left.Caption := 'плавка: '+HeatLeft+' | '+'марка: '+GradeLeft+' | '+
                                 'класс прочности: '+StrengthClassLeft+' | '+
                                 'профиль: '+SectionLeft+' | '+'стандарт: '+StandardLeft;
  form1.l_chemical_left.Caption := 'Химический анализ'+#9+'C: '+c_left+' | '+
                                   'Mn: '+mn_left+' | '+'Cr: '+cr_left+' | '+
                                   'Si: '+si_left+' | '+'B: '+b_left;


  //side right
  form1.l_global_right.Caption := 'плавка: '+HeatRight+' | '+'марка: '+GradeRight+' | '+
                                 'класс прочности: '+StrengthClassRight+' | '+
                                 'профиль: '+SectionRight+' | '+'стандарт: '+StandardRight;
  form1.l_chemical_right.Caption := 'Химический анализ'+#9+'C: '+c_right+' | '+
                                    'Mn: '+mn_right+' | '+'Cr: '+cr_right+' | '+
                                    'Si: '+si_right+' | '+'B: '+b_right;

end;


function ReadCemicalAnalysis(InHeat: string; InSide: integer): bool;
begin
  try
      Settings.SQuery.Close;
      Settings.SQuery.SQL.Clear;
      Settings.SQuery.SQL.Add('SELECT c, mn, cr, si, b FROM chemical_analysis');
      Settings.SQuery.SQL.Add('where heat='''+InHeat+'''');
      Settings.SQuery.Open;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;

  if InSide = 0 then
   begin
    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'Settings.SQuery.SQL.Text  left -> '+Settings.SQuery.SQL.Text);
    {$ENDIF}

    c_left := Settings.SQuery.FieldByName('c').AsString;
    mn_left :=  Settings.SQuery.FieldByName('mn').AsString;
    cr_left := Settings.SQuery.FieldByName('cr').AsString;
    si_left := Settings.SQuery.FieldByName('si').AsString;
    b_left := Settings.SQuery.FieldByName('b').AsString;

    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'C left -> '+floattostr(Settings.SQuery.FieldByName('c').AsFloat));
    {$ENDIF}
   end;

  if InSide = 1 then
   begin
    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'Settings.SQuery.SQL.Text right -> '+Settings.SQuery.SQL.Text);
    {$ENDIF}

    c_right := Settings.SQuery.FieldByName('c').AsString;
    mn_right :=  Settings.SQuery.FieldByName('mn').AsString;
    cr_right := Settings.SQuery.FieldByName('cr').AsString;
    si_right := Settings.SQuery.FieldByName('si').AsString;
    b_right := Settings.SQuery.FieldByName('b').AsString;

    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'C right -> '+Settings.SQuery.FieldByName('c').AsString);
    {$ENDIF}
   end;

end;


function SqlWriteHeatToCemicalAnalysis: bool;
begin

  try
      Settings.SQuery.Close;
      Settings.SQuery.SQL.Clear;
      Settings.SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS chemical_analysis (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
      Settings.SQuery.SQL.Add(', timestamp INTEGER(10), heat VARCHAR(26) NOT NULL');
      Settings.SQuery.SQL.Add(', datetime DATETIME, grade VARCHAR(50), standard VARCHAR(50)');
      Settings.SQuery.SQL.Add(', c REAL, mn REAL, si REAL, s REAL, cr REAL, b REAL)');
      Settings.SQuery.ExecSQL;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;

  try
      //удаляем записи старше 10 месяцев 2629743(один месяц)*10
      Settings.SQuery.Close;
      Settings.SQuery.SQL.Clear;
      Settings.SQuery.SQL.Add('DELETE FROM chemical_analysis');
      Settings.SQuery.SQL.Add('where strftime(''%s'', datetime)<(strftime(''%s'',''now'')-(2629743*10))');
      Settings.SQuery.SQL.Add('and datetime not null');
      Settings.SQuery.ExecSQL;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;

  try
{      Settings.SQuery.Close;
      Settings.SQuery.SQL.Clear;
      Settings.SQuery.SQL.Add('INSERT INTO chemical_analysis (heat)');
      Settings.SQuery.SQL.Add('Select '''+InHeat+'''');
      Settings.SQuery.SQL.Add('Where not exists(select * from chemical_analysis where heat='''+InHeat+''')');
      Settings.SQuery.ExecSQL;}

      Settings.SQuery.Close;
      Settings.SQuery.SQL.Clear;
      Settings.SQuery.SQL.Add('INSERT INTO chemical_analysis (heat)');
      Settings.SQuery.SQL.Add('select distinct heat from temperature');
      Settings.SQuery.SQL.Add('where not EXISTS (select heat from chemical_analysis where heat=temperature.heat)');
      Settings.SQuery.SQL.Add('order by temperature.id desc');
      Settings.SQuery.ExecSQL;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'SQuery.SQL.Text insert heat -> '+Settings.SQuery.SQL.Text);
  {$ENDIF}
   except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;
end;


function SqlWriteCemicalAnalysis(InData: string): bool;
var
  str: TStringList;
begin
{ DATE_IN_HIM, NPL, MST, GOST, C, MN, SI, S, CR, B' }

  str := TstringList.Create;
  str.text := StringReplace(InData, '|', #13#10, [rfReplaceAll]);

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'DATE_IN_HIM -> '+str[0]);
    SaveLog('debug'+#9#9+'NPL -> '+str[1]);
    SaveLog('debug'+#9#9+'MST -> '+str[2]);
    SaveLog('debug'+#9#9+'GOST -> '+str[3]);
    SaveLog('debug'+#9#9+'C -> '+str[4]);
    SaveLog('debug'+#9#9+'MN -> '+str[5]);
    SaveLog('debug'+#9#9+'SI -> '+str[6]);
    SaveLog('debug'+#9#9+'S -> '+str[7]);
    SaveLog('debug'+#9#9+'CR -> '+str[8]);
    SaveLog('debug'+#9#9+'B -> '+str[9]);
  {$ENDIF}

  try
      Settings.SQuery.Close;
      Settings.SQuery.SQL.Clear;
      Settings.SQuery.SQL.Add('UPDATE chemical_analysis SET timestamp=strftime(''%s'',''now'')');
      Settings.SQuery.SQL.Add(', datetime='''+str[0]+''', grade='''+str[2]+'''');
      Settings.SQuery.SQL.Add(', standard='''+str[3]+''', c='+str[4]+', mn='+str[5]+'');
      Settings.SQuery.SQL.Add(', si='+str[6]+', s='+str[7]+', cr='+str[8]+', b='+str[9]+'');
      Settings.SQuery.SQL.Add('where heat='''+str[1]+'''');
      Settings.SQuery.ExecSQL;

      ShowTrayMessage('Chemical Analysis', 'получен на плавку'+#9+str[1], 1);

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'SQuery.SQL.Text update -> '+Settings.SQuery.SQL.Text);
  {$ENDIF}
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;

end;


function SqlCarbonEquivalent(InHeat: string): TArray;
var
  i: integer;
  HeatCeArray: TArray;
begin
{ для 3го проката
    Module.OraQuery1.FetchAll := true;
    Module.OraQuery1.Close;
    Module.OraQuery1.SQL.Clear;
    Module.OraQuery1.SQL.Add('select NPL, C+(MN/6)+(CR/5)+((SI+B)/10) as Ce');
    Module.OraQuery1.SQL.Add('from him_steel');
    Module.OraQuery1.SQL.Add('where DATE_IN_HIM<=sysdate');
    Module.OraQuery1.SQL.Add('and DATE_IN_HIM>=sysdate-305'); //-- 305 = 10 month
    Module.OraQuery1.SQL.Add('and NUMBER_TEST=''0''');
    Module.OraQuery1.SQL.Add('and NPL in ('+InHeat+')');
    Module.OraQuery1.SQL.Add('order by DATE_IN_HIM desc');
    Module.OraQuery1.Open;

    i:=0;
    while not Module.OraQuery1.Eof do
     begin
        if i = Length(HeatCeArray) then SetLength(HeatCeArray, i+1, 2);
          HeatCeArray[i,0] := Module.OraQuery1.FieldByName('NPL').AsString;
          HeatCeArray[i,1] := Module.OraQuery1.FieldByName('Ce').AsFloat;
          inc(i);
          Module.OraQuery1.Next;
    end;
}

  Settings.SQuery.Close;
  Settings.SQuery.SQL.Clear;
  Settings.SQuery.SQL.Add('select heat, c+(mn/6)+(cr/5)+((si+b)/10) as ce');
  Settings.SQuery.SQL.Add('from chemical_analysis');
  Settings.SQuery.SQL.Add('where heat in ('+InHeat+')');
  Settings.SQuery.SQL.Add('order by datetime desc');
  Settings.SQuery.Open;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'ce -> SQuery.SQL.Text -> '+Settings.SQuery.SQL.Text);
  {$ENDIF}

  i:=0;
  while not Settings.SQuery.Eof do
  begin
    if i = Length(HeatCeArray) then SetLength(HeatCeArray, i+1, 2);
    HeatCeArray[i,0] := Settings.SQuery.FieldByName('heat').AsString;
    HeatCeArray[i,1] := Settings.SQuery.FieldByName('ce').AsFloat;
    inc(i);
    Settings.SQuery.Next;
  end;

  for I := Low(HeatCeArray) to High(HeatCeArray) do
  begin
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'heat for ce -> '+floattostr(HeatCeArray[i,0]));
    SaveLog('debug'+#9#9+'ce -> '+floattostr(HeatCeArray[i,1]));
  {$ENDIF}
  end;

  Result := HeatCeArray;
end;




end.

