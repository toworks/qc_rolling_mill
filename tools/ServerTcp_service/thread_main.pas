unit thread_main;

interface

uses
  SysUtils, Classes, Windows, ActiveX;

type
  TThreadMain = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadMain: TThreadMain;

//  {$DEFINE DEBUG}

procedure WrapperMain; // обертка для синхронизации и выполнения с другим потоком
function GetHeat: bool;
function GetChemicalAnalysis(InHeat: string): bool;

implementation

uses
  logging, settings, main, sql;

procedure TThreadMain.Execute;
begin
  CoInitialize(nil);
  while not Terminated do
  begin
    Synchronize(WrapperMain);
    sleep(1000);
  end;
  CoUninitialize;
end;

procedure WrapperMain;
begin
  try
      GetHeat;
  except
    on E: Exception do
      SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
  end;
end;


function GetHeat: bool;
begin
  try
    FQueryChemical.Close;
    FQueryChemical.SQL.Clear;
    FQueryChemical.SQL.Add('select FIRST 1 * from qc_chemical_analysis');
    FQueryChemical.ExecQuery;
    FQueryChemical.Transaction.Commit;
  except
    FQueryChemical.Close;
    FQueryChemical.SQL.Clear;
    FQueryChemical.SQL.Add('EXECUTE BLOCK AS BEGIN');
    FQueryChemical.SQL.Add('if (not exists(select 1 from rdb$relations where rdb$relation_name = ''qc_chemical_analysis'')) then');
    FQueryChemical.SQL.Add('execute statement ''create table qc_chemical_analysis (');
    FQueryChemical.SQL.Add('id NUMERIC(18,0) NOT NULL, datetime TIMESTAMP NOT NULL,');
    FQueryChemical.SQL.Add('heat VARCHAR(26) NOT NULL, date_external DATE NOT NULL,');
    FQueryChemical.SQL.Add('grade VARCHAR(50), standard VARCHAR(50), c NUMERIC(6,6),');
    FQueryChemical.SQL.Add('mn NUMERIC(6,6), si NUMERIC(6,6), s NUMERIC(6,6),');
    FQueryChemical.SQL.Add('cr NUMERIC(6,6), b NUMERIC(6,6),');
    FQueryChemical.SQL.Add('PRIMARY KEY (id));'';');
    FQueryChemical.SQL.Add('execute statement ''CREATE SEQUENCE gen_qc_chemical_analysis;'';');
    FQueryChemical.SQL.Add('END');
    FQueryChemical.ExecQuery;
    FQueryChemical.Transaction.Commit;
  end;

  try
      // чистим таблицу от старых данных
      FQueryChemical.Close;
      FQueryChemical.SQL.Clear;
      // удаляем записи старше 10 месяцев (300 дней)
      FQueryChemical.SQL.Add('DELETE FROM qc_chemical_analysis where');
      FQueryChemical.SQL.Add('datetime < current_timestamp-300');
      FQueryChemical.ExecQuery;
      FQueryChemical.Transaction.Commit;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;

  try
    FQueryChemical.Close;
    FQueryChemical.SQL.Clear;
    FQueryChemical.SQL.Add('select distinct t1.heat, t2.heat as heat_test FROM qc_temperature t1');
    FQueryChemical.SQL.Add('LEFT OUTER JOIN');
    FQueryChemical.SQL.Add('qc_chemical_analysis t2');
    FQueryChemical.SQL.Add('on t1.heat=t2.heat');
    FQueryChemical.SQL.Add('where t2.heat is null');
    FQueryChemical.SQL.Add('group by t1.heat, t2.heat, t1.id');
    FQueryChemical.SQL.Add('order by t1.id desc');
    FQueryChemical.ExecQuery;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;

  while not FQueryChemical.Eof do
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'heat -> '+FQueryChemical.FieldByName('heat').AsString);
    SaveLog('debug' + #9#9 + 'heat_test -> '+FQueryChemical.FieldByName('heat_test').AsString);
{$ENDIF}
      if FQueryChemical.FieldByName('heat_test').IsNull then
          GetChemicalAnalysis(FQueryChemical.FieldByName('heat').AsString);
      FQueryChemical.Next;
  end;
end;


function GetChemicalAnalysis(InHeat: string): bool;
var
  ChemicalAnalysisArray: array [0 .. 9] of string;
begin
  try
      OraQuery1.FetchAll := true;
      OraQuery1.Close;
      OraQuery1.SQL.Clear;
      OraQuery1.SQL.Add('select DATE_IN_HIM');
      OraQuery1.SQL.Add(', NPL, MST, GOST, C, MN, SI, S, CR, B from him_steel');
      OraQuery1.SQL.Add('where DATE_IN_HIM>=sysdate-300'); //-- 300 = 10 month
      OraQuery1.SQL.Add('and NUMBER_TEST=''0''');
      OraQuery1.SQL.Add('and NPL in ('''+InHeat+''')');
      OraQuery1.SQL.Add('order by DATE_IN_HIM desc');
      OraQuery1.Open;
  except
    on E : Exception do
      begin
        SaveLog('error'+#9#9+E.ClassName+', с сообщением: '+E.Message);
        exit;
      end;
  end;
  //если не находим записываем фeйк
  if not OraQuery1.FieldByName('NPL').IsNull then
  begin
    ChemicalAnalysisArray[0] := OraQuery1.FieldByName('DATE_IN_HIM').AsString;
    ChemicalAnalysisArray[1] := OraQuery1.FieldByName('NPL').AsString;
    ChemicalAnalysisArray[2] := OraQuery1.FieldByName('MST').AsString;
    ChemicalAnalysisArray[3] := OraQuery1.FieldByName('GOST').AsString;
    ChemicalAnalysisArray[4] := StringReplace(OraQuery1.FieldByName('C').AsString,',','.',[rfReplaceAll]);
    ChemicalAnalysisArray[5] := StringReplace(OraQuery1.FieldByName('MN').AsString,',','.',[rfReplaceAll]);
    ChemicalAnalysisArray[6] := StringReplace(OraQuery1.FieldByName('SI').AsString,',','.',[rfReplaceAll]);
    ChemicalAnalysisArray[7] := StringReplace(OraQuery1.FieldByName('S').AsString,',','.',[rfReplaceAll]);
    ChemicalAnalysisArray[8] := StringReplace(OraQuery1.FieldByName('CR').AsString,',','.',[rfReplaceAll]);
    ChemicalAnalysisArray[9] := StringReplace(OraQuery1.FieldByName('B').AsString,',','.',[rfReplaceAll]);
  end
  else
  begin
    ChemicalAnalysisArray[0] := '01.01.0001';
    ChemicalAnalysisArray[1] := InHeat;
    ChemicalAnalysisArray[2] := '0';
    ChemicalAnalysisArray[3] := '0';
    ChemicalAnalysisArray[4] := '0';
    ChemicalAnalysisArray[5] := '0';
    ChemicalAnalysisArray[6] := '0';
    ChemicalAnalysisArray[7] := '0';
    ChemicalAnalysisArray[8] := '0';
    ChemicalAnalysisArray[9] := '0';
  end;

  SaveLog('service'+#9#9+'save'+#9+'chemical analysis -> '+
                       ChemicalAnalysisArray[0]+#9+ChemicalAnalysisArray[1]+#9+
                       ChemicalAnalysisArray[2]+#9+ChemicalAnalysisArray[3]+#9+
                       ChemicalAnalysisArray[4]+#9+ChemicalAnalysisArray[5]+#9+
                       ChemicalAnalysisArray[6]+#9+ChemicalAnalysisArray[7]+#9+
                       ChemicalAnalysisArray[8]+#9+ChemicalAnalysisArray[9]);

  try
    FQueryChemical.Close;
    FQueryChemical.SQL.Clear;
    FQueryChemical.SQL.Add('insert INTO qc_chemical_analysis');
    FQueryChemical.SQL.Add('(id, datetime, heat, date_external, grade, standard, c, mn, si, s, cr, b)');
    FQueryChemical.SQL.Add('values(GEN_ID(gen_qc_chemical_analysis, 1), current_timestamp,');
    FQueryChemical.SQL.Add(''''+ChemicalAnalysisArray[1]+''', '''+ChemicalAnalysisArray[0]+''',');
    FQueryChemical.SQL.Add(''''+ChemicalAnalysisArray[2]+''', '''+ChemicalAnalysisArray[3]+''',');
    FQueryChemical.SQL.Add(''+ChemicalAnalysisArray[4]+', '+ChemicalAnalysisArray[5]+',');
    FQueryChemical.SQL.Add(''+ChemicalAnalysisArray[6]+', '+ChemicalAnalysisArray[7]+',');
    FQueryChemical.SQL.Add(''+ChemicalAnalysisArray[8]+', '+ChemicalAnalysisArray[9]+')');
    FQueryChemical.ExecQuery;
    FQueryChemical.Transaction.Commit;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
  end;
end;




end.
