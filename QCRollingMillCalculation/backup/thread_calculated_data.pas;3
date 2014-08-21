{
  в таблице calculated_data (Reports) переписываются данными 2го расчета
  кроме красных пределов
}

unit thread_calculated_data;

interface

uses
  SysUtils, Classes, Variants, Math, ZDataset, Types{, Collections}, sqldb,
  mssqlconn;

type
  TThreadCalculatedData = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  TDoubleArray = array of double;

  TIdHeat = Class
    tid                   : integer;
    Heat                  : string[26]; // плавка
    Grade                 : string[50]; // марка стали
    Section               : string[50]; // профиль
    Standard              : string[50]; // стандарт
    StrengthClass         : string[50]; // клас прочности
    c                     : string[50];
    mn                    : string[50];
    cr                    : string[50];
    si                    : string[50];
    b                     : string[50];
    ce                    : string[50];
    OldStrengthClass      : string[50]; // старый клас прочности
    old_tid               : integer; // стара плавка
    RollingMill           : string[1];
    marker                : integer;
    LowRed                : integer;
    HighRed               : integer;
    LowGreen              : integer;
    HighGreen             : integer;
    step                  : integer;
    technological_sample  : integer;
    constructor Create;
  end;

var
  ThreadCalculatedData: TThreadCalculatedData;
  left, right: TIdHeat;

  {$DEFINE DEBUG}

  function ReadCurrentHeat(InRollingMill: string): boolean;
  function ReadSaveOldData(InData, InRollingMill, InSide: string): boolean;
  function ReadChemicalAnalysis(InHeat: string; InSide: integer): boolean;
  function CalculatingInMechanicalCharacteristics(InHeat: string; InSide: integer): string;
  function CarbonEquivalent(InHeat: string; InSide: integer): boolean;
  function CutChar(InData: string): string;
  function GetDigits(InData: string): string;
{delphi  function GetMedian(aArray: TDoubleDynArray): Double;}
  procedure bubbleSort(var list: TDoubleArray);
  function Median(aArray: TDoubleArray): double;

implementation

uses
  settings, sql;

procedure TThreadCalculatedData.Execute;
var i: integer;
begin
  i := 0;
  SaveLog.Log(etInfo, 'thread execute');
  try
    repeat
      Sleep(1000); //milliseconds
 {$IFDEF DEBUG}
   inc(i);
   SaveLog.Log(etDebug, 'thread loop ' + Format('tick :%d', [i]));
 {$ENDIF}

    try
         //reconnect
         ConfigMsSetting(false);

         if not MsSqlSettings.configured then
            ConfigMsSetting(true);
         if not OraSqlSettings.configured then
            ConfigOracleSetting(true);

         ReadCurrentHeat('1');
//         ReadCurrentHeat('3');
     except
       on E: Exception do
         SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
     end;

    until Terminated;
    SaveLog.Log(etInfo, 'tread loop stopped');
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;
end;


function ReadCurrentHeat(InRollingMill: string): boolean;
var
  i: integer;
  HeatAllLeft, HeatAllRight: string;
begin
  // side left=0, side right=1
  i := 0;
  for i := 0 to 1 do
  begin

    MSDBLibraryLoader.Enabled := true;
    MSConnection.Connected := true;
    MSQuery.Close;
    MSQuery.sql.Clear;
    MSQuery.sql.Add('select top 1 tid, heat, rolling_mill, strength_class,');
    MSQuery.sql.Add('section, grade, standard');
    MSQuery.sql.Add('FROM temperature_current');
    MSQuery.sql.Add('where rolling_mill='+InRollingMill+' and side='+inttostr(i)+'');
    MSQuery.sql.Add('order by timestamp desc');
    MSQuery.Open;

    if i = 0 then
    begin
      left.tid := MSQuery.FieldByName('tid').AsInteger;
      left.Heat := UTF8Decode(MSQuery.FieldByName('heat').AsString);
      left.Grade := UTF8Decode(MSQuery.FieldByName('grade').AsString);
      left.StrengthClass := UTF8Decode(MSQuery.FieldByName('strength_class').AsString);
      left.Section := MSQuery.FieldByName('section').AsString;
      left.Standard := UTF8Decode(MSQuery.FieldByName('standard').AsString);
      left.RollingMill := MSQuery.FieldByName('rolling_mill').AsString;

      // читаем идентификатор старой плавки |номер стана|сторона|
      ReadSaveOldData('read', InRollingMill, inttostr(i));

      // новая плавка устанавливаем маркер
      if (left.old_tid <> left.tid) or (left.OldStrengthClass <> left.StrengthClass) then
      begin
        left.old_tid := left.tid;
        left.OldStrengthClass := left.StrengthClass;
        left.marker := 1;
        left.LowRed := 0;
        left.HighRed := 0;
        left.LowGreen := 0;
        left.HighGreen := 0;
        // химия
        ReadChemicalAnalysis(left.Heat, i);
        // записываем идентификатор старой плавки |номер стана|сторона|
        ReadSaveOldData('save', InRollingMill, inttostr(i));
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'enable left.marker -> '+inttostr(left.marker));
{$ENDIF}
      end else begin
        left.marker := 0;
        ReadSaveOldData('save', InRollingMill, inttostr(i));
      end;

      if left.c = '' then
        // химия при перезапуске сервиса
        ReadChemicalAnalysis(left.Heat, i);

    end
    else
    begin
      right.tid := MSQuery.FieldByName('tid').AsInteger;
      right.Heat := UTF8Decode(MSQuery.FieldByName('heat').AsString);
      right.Grade := UTF8Decode(MSQuery.FieldByName('grade').AsString);
      right.StrengthClass := UTF8Decode(MSQuery.FieldByName('strength_class').AsString);
      right.Section := MSQuery.FieldByName('section').AsString;
      right.Standard := UTF8Decode(MSQuery.FieldByName('standard').AsString);
      right.RollingMill := MSQuery.FieldByName('rolling_mill').AsString;

      // читаем идентификатор старой плавки |номер стана|сторона|
      ReadSaveOldData('read', InRollingMill, inttostr(i));

      // новая плавка устанавливаем маркер
      if (right.old_tid <> right.tid) or (right.OldStrengthClass <> right.StrengthClass) then
      begin
        right.old_tid := right.tid;
        right.OldStrengthClass := right.StrengthClass;
        right.marker := 1;
        right.LowRed := 0;
        right.HighRed := 0;
        right.LowGreen := 0;
        right.HighGreen := 0;
        // химия
        ReadChemicalAnalysis(right.Heat, i);
        // записываем идентификатор старой плавки |номер стана|сторона|
        ReadSaveOldData('save', InRollingMill, inttostr(i));
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'enable right.marker -> '+inttostr(right.marker));
{$ENDIF}
      end else begin
        right.marker := 0;
        ReadSaveOldData('save', InRollingMill, inttostr(i));
      end;


      if right.c = '' then
        // химия при перезапуске сервиса
        ReadChemicalAnalysis(right.Heat, i);

    end;

  end;

  if left.marker = 1 then begin
    SaveLog.Log(etInfo, left.RollingMill+#9+inttostr(left.tid)+#9+left.Heat+#9+left.Grade+#9+
            left.Section+#9+left.Standard+#9+left.StrengthClass+#9+
            left.c+#9+left.mn+#9+left.cr+#9+left.si+#9+left.b+#9+left.ce+#9+
            inttostr(left.old_tid)+#9+inttostr(left.marker)+#9+
            left.OldStrengthClass);
  end;
  if right.marker = 1 then begin
    SaveLog.Log(etInfo, right.RollingMill+#9+inttostr(right.tid)+#9+right.Heat+#9+right.Grade+#9+
            right.Section+#9+right.Standard+#9+right.StrengthClass+#9+
            right.c+#9+right.mn+#9+right.cr+#9+right.si+#9+right.b+#9+right.ce+#9+
            inttostr(right.old_tid)+#9+inttostr(right.marker)+#9+
            right.OldStrengthClass);
  end;

  if left.marker = 1 {and (left.ce <> '')} then
  begin
    try
      // сброс этапа расчета
      left.step := 0;
      // удаляем при перерасчете
      CalculatedData(0, '');
      SaveLog.Log(etInfo, 'start calculation left side, heat -> '+left.Heat);
      // start left step 0
      CalculatedData(0, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
      HeatAllLeft := CalculatingInMechanicalCharacteristics(RolledMelting(0), 0);
      // start left step 1
      if not (HeatAllLeft = '') then
      begin
        CalculatedData(0, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
        CarbonEquivalent(HeatAllLeft, 0);
      end;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'disable left.marker -> '+inttostr(left.marker));
{$ENDIF}
      SaveLog.Log(etInfo, 'end calculation left side, heat -> '+left.Heat);
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
    end;
    HeatAllLeft := '';
  end;

  if right.marker = 1 {and (right.ce <> '')} then
  begin
    try
      // сброс этапа расчета
      right.step := 0;
      // удаляем при перерасчете
      CalculatedData(1, '');
      SaveLog.Log(etInfo, 'start calculation right side, heat -> '+right.Heat);
      // start right step 0
      CalculatedData(1, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
      HeatAllRight := CalculatingInMechanicalCharacteristics(RolledMelting(1), 1);
      // start right step 1
      if not (HeatAllRight = '') then
      begin
        CalculatedData(1, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
        CarbonEquivalent(HeatAllRight, 1);
      end;
      SaveLog.Log(etInfo, 'end calculation right side, heat -> '+right.Heat);
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
    end;
    HeatAllRight := '';
  end;
end;


function ReadSaveOldData(InData, InRollingMill, InSide: string): boolean;
var
  SQueryRSOH: TZQuery;
begin
  SQueryRSOH := TZQuery.Create(nil);
  SQueryRSOH.Connection := SConnect;

  if InData = 'read' then begin
    try
       SQueryRSOH.Close;
       SQueryRSOH.SQL.Clear;
       SQueryRSOH.SQL.Add('SELECT * FROM settings');
       SQueryRSOH.Open;
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', с сообщением: '+E.Message));
    end;

    while not SQueryRSOH.Eof do
    begin
       if SQueryRSOH.FieldByName('name').AsString =
          '::heat::rm'+InRollingMill+'::side'+InSide then begin
            if strtoint(InSide) = 0 then
               left.old_tid := SQueryRSOH.FieldByName('value').AsInteger
            else
               right.old_tid := SQueryRSOH.FieldByName('value').AsInteger;
       end;

       if SQueryRSOH.FieldByName('name').AsString =
          '::StrengthClass::rm'+InRollingMill+'::side'+InSide then begin
            if strtoint(InSide) = 0 then
               left.OldStrengthClass := SQueryRSOH.FieldByName('value').AsString
            else
               right.OldStrengthClass := SQueryRSOH.FieldByName('value').AsString;
       end;

       if SQueryRSOH.FieldByName('name').AsString =
          '::marker::rm'+InRollingMill+'::side'+InSide then begin
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'yes ::marker::');
  SaveLog.Log(etDebug, 'marker -> '+SQueryRSOH.FieldByName('value').AsString);
{$ENDIF}}
            if strtoint(InSide) = 0 then
               left.marker := strtoint(SQueryRSOH.FieldByName('value').AsString)
            else
               right.marker := strtoint(SQueryRSOH.FieldByName('value').AsString);
       end;
{{$IFDEF DEBUG}
  if strtoint(InSide) = 0 then
  SaveLog.Log(etDebug, 'RollingMill '+InRollingMill+' Side '+InSide+' left.marker -> '+inttostr(left.marker))
  else
  SaveLog.Log(etDebug, 'RollingMill '+InRollingMill+' Side '+InSide+' right.marker -> '+inttostr(right.marker));
{$ENDIF}}
       SQueryRSOH.Next;
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'read -> ');
{$ENDIF}}
    end;
  end else begin
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::heat::rm'+InRollingMill+'::side'+InSide+''',');
        if strtoint(InSide) = 0 then
           SQueryRSOH.SQL.Add(''''+inttostr(left.old_tid)+''')')
        else
           SQueryRSOH.SQL.Add(''''+inttostr(right.old_tid)+''')');
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', с сообщением: '+E.Message));
    end;
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::StrengthClass::rm'+InRollingMill+'::side'+InSide+''',');
        if strtoint(InSide) = 0 then
           SQueryRSOH.SQL.Add(''''+left.OldStrengthClass+''')')
        else
           SQueryRSOH.SQL.Add(''''+right.OldStrengthClass+''')');
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', с сообщением: '+E.Message));
    end;
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::marker::rm'+InRollingMill+'::side'+InSide+''',');
        if strtoint(InSide) = 0 then
           SQueryRSOH.SQL.Add(''''+inttostr(left.marker)+''')')
        else
           SQueryRSOH.SQL.Add(''''+inttostr(right.marker)+''')');
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'SQueryRSOH.SQL.Text -> '+SQueryRSOH.SQL.Text);
{$ENDIF}}
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', с сообщением: '+E.Message));
    end;
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'write -> ');
{$ENDIF}}
  end;

  FreeAndNil(SQueryRSOH);

end;


function ReadChemicalAnalysis(InHeat: string; InSide: integer): boolean;
begin
  try
      OraQuery.Close;
      OraQuery.SQL.Clear;
      OraQuery.SQL.Add('select DATE_IN_HIM');
      OraQuery.SQL.Add(', NPL, MST, GOST, C, MN, SI, S, CR, B,');
      OraQuery.SQL.Add('cast(c+(mn/6)+(cr/5)+((si+b)/10) as numeric(6,4)) as ce');
      OraQuery.SQL.Add('from him_steel');
      OraQuery.SQL.Add('where DATE_IN_HIM>=sysdate-300'); //-- 300 = 10 month
      OraQuery.SQL.Add('and NUMBER_TEST=''0''');
      OraQuery.SQL.Add('and NPL in ('''+InHeat+''')');
      OraQuery.SQL.Add('order by DATE_IN_HIM desc');
      OraQuery.Open;
  except
    on E : Exception do
      begin
        SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
        ConfigOracleSetting(false);
        exit;
      end;
  end;

  //если находим
  if not OraQuery.FieldByName('NPL').IsNull then
  begin
    if InSide = 0 then begin
       left.c := OraQuery.FieldByName('c').AsString;
       left.mn := OraQuery.FieldByName('mn').AsString;
       left.cr := OraQuery.FieldByName('cr').AsString;
       left.si := OraQuery.FieldByName('si').AsString;
       left.b := OraQuery.FieldByName('b').AsString;
       left.ce := OraQuery.FieldByName('ce').AsString;
    end else begin
       right.c := OraQuery.FieldByName('c').AsString;
       right.mn := OraQuery.FieldByName('mn').AsString;
       right.cr := OraQuery.FieldByName('cr').AsString;
       right.si := OraQuery.FieldByName('si').AsString;
       right.b := OraQuery.FieldByName('b').AsString;
       right.ce := OraQuery.FieldByName('ce').AsString;
    end;
  end;

  SaveLog.Log(etInfo, 'chemical analysis heat -> '+InHeat+' side '+inttostr(InSide)+' -> '+
          OraQuery.FieldByName('c').AsString+#9+OraQuery.FieldByName('mn').AsString+#9+
          OraQuery.FieldByName('cr').AsString+#9+OraQuery.FieldByName('si').AsString+#9+
          OraQuery.FieldByName('b').AsString+#9+OraQuery.FieldByName('ce').AsString);
end;



function CalculatingInMechanicalCharacteristics(InHeat: string; InSide: integer): string;
var
  { yield point - предел текучести
    rupture strength - временное сопротивление }

  Grade: string; // марка стали
  Section: string; // профиль
  Standard: string; // стандарт
  StrengthClass: string; // клас прочности
  ReturnValue: string;
  side: string;
  RollingScheme: string;

  MSQueryCalculation: TSQLQuery;
  MSQueryData: TSQLQuery;

  i, a, b, CoefficientCount, AdjustmentMin, AdjustmentMax,
  LimitRolledProductsMin, LimitRolledProductsMax, HeatCount: integer;
  m: boolean;
  CoefficientYieldPointValue, CoefficientRuptureStrengthValue, MechanicsAvg,
    MechanicsStdDev, MechanicsMin, MechanicsMax, MechanicsDiff, CoefficientMin,
    CoefficientMax, TempAvg, TempStdDev, TempMin, TempMax, TempDiff, R: real;
  TypeRolledProducts, HeatAll, HeatWorks, HeatTableAll: WideString;
  HeatArray, HeatTableArray: Array of string;
  MechanicsArray, TempArray: Array of Double;
  RawTempArray: TDoubleArray {TDoubleDynArray};
  st, HeatTmp: TStringList;
  c, mn, si, HeatMechanics, RollingMill, technological_sample: string;
begin
  if InSide = 0 then
  begin
    Grade := left.Grade;
    Section := left.Section;
    Standard := left.Standard;
    StrengthClass := left.StrengthClass;
    c := left.c;
    mn := left.mn;
    si := left.si;
    side := 'Левая';
    RollingScheme := right.Section; // схема прокатки 14x16, 16x16, 18x16
    RollingMill := left.RollingMill;
    technological_sample := inttostr(left.technological_sample);
  end
  else
  begin
    Grade := right.Grade;
    Section := right.Section;
    Standard := right.Standard;
    StrengthClass := right.StrengthClass;
    c := right.c;
    mn := right.mn;
    si := right.si;
    side := 'Правая';
    RollingScheme := left.Section; // схема прокатки 14x16, 16x16, 18x16
    RollingMill := right.RollingMill;
    technological_sample := inttostr(right.technological_sample);
  end;

  if InHeat = '' then
  begin
    SaveLog.Log(etWarning, 'сторона -> '+side);
    SaveLog.Log(etWarning, 'недостаточно данных по прокатанным плавкам для расчета по плавке -> '+InHeat);
    exit;
  end;

  MSQueryCalculation := TSQLQuery.Create(nil);
  MSQueryCalculation.DataBase := MSConnection;
  MSQueryCalculation.Transaction := MSTransaction;
  MSQueryCalculation.PacketRecords := -1;  //FetchAll
  MSQueryData := TSQLQuery.Create(nil);
  MSQueryData.DataBase := MSConnection;
  MSQueryData.Transaction := MSTransaction;
  MSQueryData.PacketRecords := -1;  //FetchAll

  a := 0;
  b := a;

  { оставить только  InHeat}
  HeatAll := InHeat;

  try
      OraQuery.Close;
      OraQuery.SQL.Clear;
      OraQuery.SQL.Add('select * from');
      OraQuery.SQL.Add('(select n.nplav heat, n.mst grade, n.GOST standard');
      OraQuery.SQL.Add(',n.razm1 section, n.klass strength_class');
      OraQuery.SQL.Add(',v.limtek yield_point, v.limproch rupture_strength');
      OraQuery.SQL.Add(',ROW_NUMBER() OVER (PARTITION BY n.nplav ORDER BY n.data desc) AS number_row');
      OraQuery.SQL.Add('from czl_v v, czl_n n');
      //-- 305 = 10 month
      OraQuery.SQL.Add('where n.data<=sysdate and n.data>=sysdate-305');
//--      OraQuery.SQL.Add('and n.mst like translate('''+CutChar(Grade)+''','); //переводим Eng буквы похожие на кирилицу
//--      OraQuery.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''ЕТОРАНКХСВМеторанкхсвм'')');
//--      OraQuery.SQL.Add('and n.GOST like translate('''+CutChar(Standard)+''','); //переводим Eng буквы похожие на кирилицу
//--      OraQuery.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''ЕТОРАНКХСВМеторанкхсвм'')');
      OraQuery.SQL.Add('and n.razm1 = '+Section+'');
      OraQuery.SQL.Add('and translate(n.klass,');
      OraQuery.SQL.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
      OraQuery.SQL.Add('like translate('''+CutChar(StrengthClass)+''',');
      OraQuery.SQL.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
      OraQuery.SQL.Add('and n.data=v.data and v.npart=n.npart');
      OraQuery.SQL.Add('and n.npart like '''+RollingMill+'%'''); // номер стана
      if InSide = 0  then
        OraQuery.SQL.Add('and mod(n.npart,2)=1')// проверка на четность | 0 четная - левая | 1 - нечетная правая
      else
        OraQuery.SQL.Add('and mod(n.npart,2)=0');// проверка на четность | 0 четная - левая | 1 - нечетная правая
      if (StrengthClass = 'S400') or (StrengthClass = 'S400W') then // классы при которых берется до 15 проб
        OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=15')
      else
        OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
      OraQuery.SQL.Add('and prizn=''*'' and ROWNUM <= 251');
      OraQuery.SQL.Add('and n.nplav in('+HeatAll+')');
      OraQuery.SQL.Add('order by n.data desc)');
      OraQuery.SQL.Add('where number_row <= 3');
      OraQuery.Open;
      OraQuery.FetchAll;
  except
    on E: Exception do
    begin
      SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
      ConfigOracleSetting(false);
      if InSide = 0 then
         left.marker := 0
      else
         right.marker := 0;
      ReadSaveOldData('save', RollingMill, inttostr(InSide));
      exit;
    end;
  end;

{$IFDEF DEBUG }
  SaveLog.Log(etDebug, 'OraQuery.SQL.Text -> '+UTF8Decode(OraQuery.SQL.Text));
  SaveLog.Log(etDebug, 'OraQuery.RecordCount -> '+inttostr(OraQuery.RecordCount));
{$ENDIF}

  if OraQuery.RecordCount < 5 then
  begin
    SaveLog.Log(etWarning, 'сторона -> '+side);
    SaveLog.Log(etWarning, 'недостаточно данных для расчета по плавкам -> '+HeatAll);
    exit;
  end;

  try
      MSDBLibraryLoader.Enabled := true;
      MSConnection.Connected := true;
      MSQueryData.Close;
      MSQueryData.sql.Clear;
      MSQueryData.sql.Add('SELECT top 1 n, k_yield_point, k_rupture_strength');
      MSQueryData.sql.Add('FROM coefficient');
      MSQueryData.sql.Add('where n<='+inttostr(OraQuery.RecordCount)+'');
      MSQueryData.sql.Add('order by n desc');
{$IFDEF DEBUG }
  SaveLog.Log(etDebug, 'MSQueryData.SQL.Text -> '+MSQueryData.SQL.Text);
{$ENDIF}
      MSQueryData.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;

  CoefficientCount := MSQueryData.FieldByName('n').AsInteger;
  CoefficientYieldPointValue := MSQueryData.FieldByName('k_yield_point').AsFloat;
  { CoefficientRuptureStrengthValue - одинаковый с CoefficientYieldPointValue
    k_rupture_strength используеться для другого расчета }
  CoefficientRuptureStrengthValue := MSQueryData.FieldByName('k_yield_point').AsFloat;//PQueryData.FieldByName('k_rupture_strength').AsFloat;

  // -- report
  CalculatedData(InSide, 'coefficient_count=''' + inttostr(CoefficientCount) + '''');
  CalculatedData(InSide, 'coefficient_yield_point_value=''' + floattostr(CoefficientYieldPointValue) + '''');
  CalculatedData(InSide, 'coefficient_rupture_strength_value=''' + floattostr(CoefficientRuptureStrengthValue) + '''');
  // -- report
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CoefficientCount -> ' + inttostr(CoefficientCount));
  SaveLog.Log(etDebug, 'CoefficientYieldPointValue -> ' + floattostr(CoefficientYieldPointValue));
  SaveLog.Log(etDebug, 'CoefficientRuptureStrengthValue -> ' + floattostr(CoefficientRuptureStrengthValue));
{$ENDIF}

  SQuery.Close;
  SQuery.sql.Clear;
  SQuery.sql.Add('CREATE TABLE IF NOT EXISTS mechanics');
  SQuery.sql.Add('(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
  SQuery.sql.Add(', heat VARCHAR(26),timestamp INTEGER(10), grade VARCHAR(16)');
  SQuery.sql.Add(', standard VARCHAR(16), section VARCHAR(16)');
  SQuery.sql.Add(', strength_class VARCHAR(16), yield_point NUMERIC(10,6)');
  SQuery.sql.Add(', rupture_strength NUMERIC(10,6), side NUMERIC(1,1) NOT NULL)');
  SQuery.ExecSQL;

  // -- clean table mechanics
  try
      SQuery.Close;
      SQuery.sql.Clear;
      SQuery.sql.Add('delete from mechanics where side='+inttostr(InSide)+'');
      SQuery.ExecSQL;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;

  i := 1;
  while not OraQuery.Eof do
  begin
    if i <= CoefficientCount then
    begin
        if (OraQuery.FieldByName('heat').AsString <> HeatMechanics) or
           (HeatCount <= 3) then
        begin
          if HeatCount = 4 then
            HeatCount := 0;

          HeatMechanics := OraQuery.FieldByName('heat').AsString;
          inc(HeatCount);

          try
              SQuery.Close;
              SQuery.sql.Clear;
              SQuery.sql.Add('insert into mechanics (heat, timestamp, grade, standard');
              SQuery.sql.Add(', section , strength_class, yield_point, rupture_strength, side)');
              SQuery.sql.Add('values (''' + OraQuery.FieldByName('heat').AsString+'''');
              SQuery.sql.Add(', strftime(''%s'', ''now'')');
              SQuery.sql.Add(', ''NULL''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('standard').AsString+'''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('section').AsString+'''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('strength_class').AsString+'''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('yield_point').AsString+'''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('rupture_strength').AsString+'''');
              SQuery.sql.Add(', '''+inttostr(InSide)+''')');
              SQuery.ExecSQL;
          except
            on E: Exception do
              SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
          end;
        end;
    end;
    inc(i);
    OraQuery.Next;
  end;

  // -- heat to works
  try
      SQuery.Close;
      SQuery.sql.Clear;
      SQuery.sql.Add('select distinct heat from mechanics');
      SQuery.sql.Add('where side=' + inttostr(InSide) + '');
      SQuery.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;

  i := 0;
  while not SQuery.Eof do
  begin
    if i = 0 then
      HeatAll := '''' + SQuery.FieldByName('heat').AsString + ''''
    else
      HeatAll := HeatAll+','+''''+SQuery.FieldByName('heat').AsString+'''';
    inc(i);
    SQuery.Next;
  end;

  // -- report
  CalculatedData(InSide, 'heat_to_work='''+StringReplace(HeatAll, '''', '', [rfReplaceAll])+'''');
  // -- report

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'HeatAll to works -> ' + HeatAll);
{$ENDIF}
  // -- heat to works
  // выбор пределов из таблицы technological_sample
  try
      MSDBLibraryLoader.Enabled := true;
      MSConnection.Connected := true;
      MSQueryData.Close;
      MSQueryData.sql.Clear;
      MSQueryData.sql.Add('SELECT limit_min, limit_max, [type]');
      MSQueryData.sql.Add('FROM technological_sample');
      MSQueryData.sql.Add('where id = '+technological_sample+'');
{$IFDEF DEBUG }
  SaveLog.Log(etDebug, UTF8Decode('MSQueryData.SQL.Text -> '+MSQueryData.SQL.Text));
{$ENDIF}
      MSQueryData.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;

{$IFDEF DEBUG }
  SaveLog.Log(etDebug, 'MSQueryData.RecordCount -> '+inttostr(MSQueryData.RecordCount));
{$ENDIF}

  if MSQueryData.FieldByName('limit_min').IsNull then
  begin
    SaveLog.Log(etWarning, 'сторона -> '+side);
    SaveLog.Log(etWarning, 'недостаточно данных по технологической инструкции для -> '+InHeat);
    exit;
  end;

  LimitRolledProductsMin := MSQueryData.FieldByName('limit_min').AsInteger;
  LimitRolledProductsMax := MSQueryData.FieldByName('limit_max').AsInteger;
  TypeRolledProducts := MSQueryData.FieldByName('type').AsString;

  // -- report
  CalculatedData(InSide, 'limit_rolled_products_min='''+inttostr(LimitRolledProductsMin)+'''');
  CalculatedData(InSide, 'limit_rolled_products_max='''+floattostr(LimitRolledProductsMax)+'''');
  CalculatedData(InSide, 'type_rolled_products='''+TypeRolledProducts+'''');
  // -- report

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'LimitRolledProductsMin -> '+inttostr(LimitRolledProductsMin));
  SaveLog.Log(etDebug, 'LimitRolledProductsMax -> '+inttostr(LimitRolledProductsMax));
  SaveLog.Log(etDebug, 'TypeRolledProducts -> ' + TypeRolledProducts);
  SaveLog.Log(etDebug, 'RolledProducts RecordCount -> '+inttostr(SQuery.RecordCount));
{$ENDIF}

  try
      SQuery.Close;
      SQuery.sql.Clear;
      SQuery.sql.Add('SELECT * FROM mechanics');
      SQuery.sql.Add('where side=' + inttostr(InSide) + '');
      SQuery.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;

  if SQuery.RecordCount < 1 then
  begin
    SaveLog.Log(etWarning, 'сторона -> '+side);
    SaveLog.Log(etWarning, 'недостаточно данных по мех. испытаниям для расчета по плавкам -> '+HeatAll);
    exit;
  end;

  i := 0;
  while not SQuery.Eof do
  begin
    if i = length(MechanicsArray) then
      SetLength(MechanicsArray, i + 1);
    MechanicsArray[i] := SQuery.FieldByName(TypeRolledProducts).AsInteger;
    inc(i);
    SQuery.Next;
  end;

  MechanicsAvg := Mean(MechanicsArray);
  MechanicsStdDev := StdDev(MechanicsArray);
  if TypeRolledProducts = 'yield_point' then
  begin
    MechanicsMin := MechanicsAvg - MechanicsStdDev * CoefficientYieldPointValue;
    MechanicsMax := MechanicsAvg + MechanicsStdDev * CoefficientYieldPointValue;
  end;
  if TypeRolledProducts = 'rupture_strength' then
  begin
    MechanicsMin := MechanicsAvg - MechanicsStdDev *
      CoefficientRuptureStrengthValue;
    MechanicsMax := MechanicsAvg + MechanicsStdDev *
      CoefficientRuptureStrengthValue;
  end;

  MechanicsDiff := MechanicsMax - MechanicsMin;
  CoefficientMin := MechanicsMin - LimitRolledProductsMin;
  CoefficientMax := MechanicsMax - LimitRolledProductsMax;

  // -- report
  CalculatedData(InSide, 'mechanics_avg=''' + floattostr(MechanicsAvg) + '''');
  CalculatedData(InSide, 'mechanics_std_dev=''' + floattostr(MechanicsStdDev) + '''');
  CalculatedData(InSide, 'mechanics_min=''' + floattostr(MechanicsMin) + '''');
  CalculatedData(InSide, 'mechanics_max=''' + floattostr(MechanicsMax) + '''');
  CalculatedData(InSide, 'mechanics_diff=''' + floattostr(MechanicsDiff) + '''');
  CalculatedData(InSide, 'coefficient_min=''' + floattostr(CoefficientMin) + '''');
  CalculatedData(InSide, 'coefficient_max=''' + floattostr(CoefficientMax) + '''');
  // -- report

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MechanicsAvg -> ' + floattostr(MechanicsAvg));
  SaveLog.Log(etDebug, 'MechanicsStdDev -> ' + floattostr(MechanicsStdDev));
  SaveLog.Log(etDebug, 'MechanicsMin -> ' + floattostr(MechanicsMin));
  SaveLog.Log(etDebug, 'MechanicsMax -> ' + floattostr(MechanicsMax));
  SaveLog.Log(etDebug, 'MechanicsDiff -> ' + floattostr(MechanicsDiff));
  SaveLog.Log(etDebug, 'CoefficientMin -> ' + floattostr(CoefficientMin));
  SaveLog.Log(etDebug, 'CoefficientMax -> ' + floattostr(CoefficientMax));
  SaveLog.Log(etDebug, 'Section -> ' + Section);
  SaveLog.Log(etDebug, 'RollingScheme -> ' + RollingScheme);
{$ENDIF}

  try
      MSDBLibraryLoader.Enabled := true;
      MSConnection.Connected := true;
      MSQueryCalculation.Close;
      MSQueryCalculation.sql.Clear;
      MSQueryCalculation.sql.Add('select t1.tid, t1.heat, t2.temperature from temperature_current t1');
      MSQueryCalculation.sql.Add('inner join');
      MSQueryCalculation.sql.Add('temperature_historical t2');
      MSQueryCalculation.sql.Add('on t1.tid=t2.tid');
      MSQueryCalculation.sql.Add('where t1.timestamp<=datediff(s, ''01/01/1970'', getdate())');
      MSQueryCalculation.sql.Add('and t1.timestamp>=datediff(s, ''01/01/1970'', getdate())-(2629743*10)');// timestamp 2629743 month * 10
      MSQueryCalculation.sql.Add('and t1.heat in ('+HeatAll+')');
      MSQueryCalculation.sql.Add('and t1.section <= '+Section+'');
      MSQueryCalculation.sql.Add('and dbo.translate(t1.strength_class,');
      MSQueryCalculation.sql.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
      MSQueryCalculation.sql.Add('= dbo.translate('''+StrengthClass+''',');
      MSQueryCalculation.sql.Add('''ЕТОРАНКХСВМеторанкхсвм'',''ETOPAHKXCBMetopahkxcbm'')');
      MSQueryCalculation.sql.Add('and t1.side='+inttostr(InSide)+'');
{      if (strtofloat(Section) = 14) or (strtofloat(Section) = 16) or (strtofloat(Section) = 18) then
          MSQueryCalculation.sql.Add('and t2.rolling_scheme = '''+RollingScheme+''''); для 5го стана}
      MSQueryCalculation.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: ' + E.Message);
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'MSQueryCalculation.SQL.Text -> '+UTF8Decode(MSQueryCalculation.sql.Text));
  SaveLog.Log(etDebug, 'MSQueryCalculation.RecordCount -> '+inttostr(MSQueryCalculation.RecordCount));
{$ENDIF}

  if MSQueryCalculation.RecordCount < 1 then
  begin
    SaveLog.Log(etWarning, 'сторона -> '+side);
    SaveLog.Log(etWarning, 'недостаточно данных по температуре для расчета по плавкам -> '+HeatAll);
    exit;
  end;

  {// температура без медианы
  a := 0;
  while not MSQueryCalculation.Eof do
  begin
    if a = length(TempArray) then
      SetLength(TempArray, a + 1);
    TempArray[a] := MSQueryCalculation.FieldByName('temperature').AsInteger;
    inc(a);
    MSQueryCalculation.Next;
  end;}

  a := 0;
  b := a;
  i := a;
  while not MSQueryCalculation.Eof do
  begin
    if a = length(RawTempArray) then SetLength(RawTempArray, a + 1);
    RawTempArray[a] := MSQueryCalculation.FieldByName('temperature').AsInteger;
    inc(a);

{$IFDEF DEBUG}
  inc(i);
{$ENDIF}

    if a = 4 then
    begin
      if b = length(TempArray) then SetLength(TempArray, b + 1);
      TempArray[b] := Median(RawTempArray);
      inc(b);
      a := 0;
    end;
    MSQueryCalculation.Next;
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'count temperature all -> ' + inttostr(i));
  SaveLog.Log(etDebug, 'count temperature median -> ' + inttostr(b));
{$ENDIF}

  FreeAndNil(MSQueryCalculation);
  FreeAndNil(MSQueryData);

  TempAvg := Mean(TempArray);
  TempStdDev := StdDev(TempArray);
  SetLength(TempArray, 0); // обнуляем массив c температурой
  TempMin := TempAvg - TempStdDev;
  TempMax := TempAvg + TempStdDev;
  TempDiff := TempMax - TempMin;
  R := TempDiff / MechanicsDiff;
  AdjustmentMin := Round(CoefficientMin * R);
  AdjustmentMax := Round(CoefficientMax * R);

  // -- report
  CalculatedData(InSide, 'temp_avg=''' + floattostr(TempAvg) + '''');
  CalculatedData(InSide, 'temp_std_dev=''' + floattostr(TempStdDev) + '''');
  CalculatedData(InSide, 'temp_min=''' + floattostr(TempMin) + '''');
  CalculatedData(InSide, 'temp_max=''' + floattostr(TempMax) + '''');
  CalculatedData(InSide, 'temp_diff=''' + floattostr(TempDiff) + '''');
  CalculatedData(InSide, 'r=''' + floattostr(R) + '''');
  CalculatedData(InSide, 'adjustment_min=''' + inttostr(AdjustmentMin) + '''');
  CalculatedData(InSide, 'adjustment_max=''' + inttostr(AdjustmentMax) + '''');
  // -- report

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'TempAvg -> ' + floattostr(TempAvg));
  SaveLog.Log(etDebug, 'TempStdDev -> ' + floattostr(TempStdDev));
  SaveLog.Log(etDebug, 'TempMin -> ' + floattostr(TempMin));
  SaveLog.Log(etDebug, 'TempMax -> ' + floattostr(TempMax));
  SaveLog.Log(etDebug, 'TempDiff -> ' + floattostr(TempDiff));
  SaveLog.Log(etDebug, 'R -> ' + floattostr(R));
  SaveLog.Log(etDebug, 'AdjustmentMin -> ' + inttostr(AdjustmentMin));
  SaveLog.Log(etDebug, 'AdjustmentMax -> ' + inttostr(AdjustmentMax));
{$ENDIF}

    if ((InSide = 0) and (left.step = 0)) then
    begin
      // увеличиваем диапозон на 10 градусов
      left.LowRed := Round(TempMin + AdjustmentMax) - 10;
      left.HighRed := Round(TempMax + AdjustmentMin) + 10;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(left.LowRed) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(left.HighRed) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog.Log(etDebug, 'LowRedLeft -> ' + inttostr(left.LowRed));
      SaveLog.Log(etDebug, 'HighRedLeft -> ' + inttostr(left.HighRed));
      SaveLog.Log(etDebug, 'left.step first -> ' + inttostr(left.step));
{$ENDIF}
      inc(left.step); // маркер 2го прохода
      // возвращаем плавки по которым произволдился расчет
      Result := HeatAll;
      exit;
    end;
    if ((InSide = 0) and (left.step = 1)) then
    begin
      // увеличиваем диапозон на 5 градусов
      left.LowGreen := Round(TempMin + AdjustmentMax) - 5; //вместо 2.5 ибо округляется
      left.HighGreen := Round(TempMax + AdjustmentMin) + 5;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(left.LowGreen) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(left.HighGreen) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog.Log(etDebug, 'LowGreenLeft -> ' + inttostr(left.LowGreen));
      SaveLog.Log(etDebug, 'HighGreenLeft -> ' + inttostr(left.HighGreen));
      SaveLog.Log(etDebug, 'left.step last -> ' + inttostr(left.step));
{$ENDIF}
//      left.step := 0; // сброс этапа перенесен в начало
      // возвращаем плавки по которым произволдился расчет
      Result := HeatAll;
      exit;
    end;

    if ((InSide = 1) and (right.step = 0)) then
    begin
      // увеличиваем диапозон на 10 градусов
      right.LowRed := Round(TempMin + AdjustmentMax) - 10;
      right.HighRed := Round(TempMax + AdjustmentMin) + 10;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(right.LowRed) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(right.HighRed) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog.Log(etDebug, 'LowRedRight -> ' + inttostr(right.LowRed));
      SaveLog.Log(etDebug, 'HighRedRight -> ' + inttostr(right.HighRed));
      SaveLog.Log(etDebug, 'right.step first -> ' + inttostr(right.step));
{$ENDIF}
      inc(right.step); // маркер 2го прохода
      // возвращаем плавки по которым произволдился расчет
      Result := HeatAll;
      exit;
    end;
    if ((InSide = 1) and (right.step = 1)) then
    begin
      // увеличиваем диапозон на 5 градусов
      right.LowGreen := Round(TempMin + AdjustmentMax) - 5;
      right.HighGreen := Round(TempMax + AdjustmentMin) + 5;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(right.LowGreen) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(right.HighGreen) + '''');
      // -- report
{$IFDEF DEBUG}
    SaveLog.Log(etDebug, 'LowGreenRight -> ' + inttostr(right.LowGreen));
    SaveLog.Log(etDebug, 'HighGreenRight -> ' + inttostr(right.HighGreen));
    SaveLog.Log(etDebug, 'right.step last -> ' + inttostr(right.step));
{$ENDIF}
//      right.step := 0; // сброс этапа перенесен в начало
      // возвращаем плавки по которым произволдился расчет
      Result := HeatAll;
      exit;
    end;
end;


function CarbonEquivalent(InHeat: string; InSide: integer): boolean;
var
  CeMin, CeMax, CeAvg, CeMinP, CeMaxM, CeAvgP, CeAvgM, rangeMin: real;
  i, a, b, c, rangeM: integer;
  CeArray: TArrayArrayVariant; // array of array of variant;
  CeMinHeat, CeHeatStringMin, CeHeatStringMax, CeHeatStringAvg: string;
  range: array of variant;
begin

  i := 0;
  a := 0;
  b := a;
  c := a;

  CeArray := SqlCarbonEquivalent(InHeat);

  CeMin := CeArray[0, 1]; // Берем первое значение из матрицы
  CeMax := CeMin;
  For i := Low(CeArray) To High(CeArray) Do
  Begin
    If CeArray[i, 1] < CeMin Then
      CeMin := CeArray[i, 1];
    If CeArray[i, 1] > CeMax Then
      CeMax := CeArray[i, 1];
  End;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeMin -> ' + floattostr(CeMin));
  SaveLog.Log(etDebug, 'CeMax -> ' + floattostr(CeMax));
{$ENDIF}
  CeAvg := (CeMin + CeMax) / 2;
  CeMinP := CeMin + 0.02; //было 0.03
  CeMaxM := CeMax - 0.02;
  CeAvgP := CeAvg + 0.01; //0.015
  CeAvgM := CeAvg - 0.01;

  For i := Low(CeArray) To High(CeArray) Do
  Begin
    If InRange(CeArray[i, 1], CeMin, CeMinP) then
    begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeMinRangeHeat -> ' + CeArray[i, 0]);
  SaveLog.Log(etDebug, 'CeMinRangeValue -> ' +floattostr(CeArray[i, 1]));
{$ENDIF}
      if a = 0 then
        CeHeatStringMin := ''''+CeArray[i, 0]+''''
      else
        CeHeatStringMin := CeHeatStringMin + ',' + ''''+CeArray[i, 0]+'''';
      inc(a);
    end;

    if InRange(CeArray[i, 1], CeMaxM, CeMax) then
    begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeMaxRangeHeat -> ' + CeArray[i, 0]);
  SaveLog.Log(etDebug, 'CeMaxRangeValue -> ' + floattostr(CeArray[i, 1]));
{$ENDIF}
      if b = 0 then
        CeHeatStringMax := ''''+CeArray[i, 0]+''''
      else
        CeHeatStringMax := CeHeatStringMax + ',' + ''''+CeArray[i, 0]+'''';
      inc(b);
    end;

    if InRange(CeArray[i, 1], CeAvgM, CeAvgP) then
    begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeAvgRangeHeat -> ' + CeArray[i, 0]);
  SaveLog.Log(etDebug, 'CeAvgRangeValue -> ' + floattostr(CeArray[i, 1]));
{$ENDIF}
      if c = 0 then
        CeHeatStringAvg := ''''+CeArray[i, 0]+''''
      else
        CeHeatStringAvg := CeHeatStringAvg + ',' + ''''+CeArray[i, 0]+'''';
      inc(c);
    end;
  end;

  // -- report
  CalculatedData(InSide, 'ce_min_down=''' + FloatToStrF(CeMin, ffGeneral,6,0) + '''');
  CalculatedData(InSide, 'ce_min_up=''' + floattostr(CeMinP) + '''');
  CalculatedData(InSide, 'ce_max_down=''' + floattostr(CeMaxM) + '''');
  CalculatedData(InSide, 'ce_max_up=''' + floattostr(CeMax) + '''');
  CalculatedData(InSide, 'ce_avg=''' + floattostr(CeAvg) + '''');
  CalculatedData(InSide, 'ce_avg_down=''' + floattostr(CeAvgM) + '''');
  CalculatedData(InSide, 'ce_avg_up=''' + floattostr(CeAvgP) + '''');
  // -- report

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeInHeat -> ' + InHeat);
  SaveLog.Log(etDebug, 'CeMin -> ' + floattostr(CeMin));
  SaveLog.Log(etDebug, 'CeMax -> ' + floattostr(CeMax));
  SaveLog.Log(etDebug, 'CeAvg -> ' + floattostr(CeAvg));
  SaveLog.Log(etDebug, 'CeMinP -> ' + floattostr(CeMinP));
  SaveLog.Log(etDebug, 'CeMaxM -> ' + floattostr(CeMaxM));
  SaveLog.Log(etDebug, 'CeAvgP -> ' + floattostr(CeAvgP));
  SaveLog.Log(etDebug, 'CeAvgM -> ' + floattostr(CeAvgM));
{$ENDIF}

  SetLength(CeArray, 0); // обнуляем массив
  SetLength(CeArray, 1, 2);

  if InSide = 0 then
  begin
    // -- Се по текущей плавке
    CeArray[0, 0] := left.Heat;
    CeArray[0, 1] := left.ce;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'Currentleft.Heat -> ' + CeArray[0, 0]);
  SaveLog.Log(etDebug, 'CurrentCeLeft -> ' + floattostr(CeArray[0, 1]));
{$ENDIF}
  end
  else
  begin
    // -- Се по текущей плавке
    CeArray[0, 0] := right.Heat;
    CeArray[0, 1] := right.ce;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'Currentright.Heat -> ' + CeArray[0, 0]);
  SaveLog.Log(etDebug, 'CurrentCeRight -> ' + floattostr(CeArray[0, 1]));
{$ENDIF}
  end;

  // -- текущая плавка к какому из диапозонов относится min,max,avg
  if InRange(CeArray[0, 1], CeMin, CeMinP) and (CeHeatStringMin <> '') then
  begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CurrentCeMinRange -> ' + CeArray[0, 0]);
  SaveLog.Log(etDebug, 'CurrentCeMinRangeValue -> '+floattostr(CeArray[0, 1]));
{$ENDIF}
//-- расчет осуществляется на ближаешем значение от min
{    // -- report
    CalculatedData(InSide, 'ce_category=''min''');
    // -- report
    if InSide = 0 then
    begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMinRangeleft.Heat -> ' + CeHeatStringMin);
{$ENDIF}
        CalculatingInMechanicalCharacteristics(CeHeatStringMin, 0);
    end
    else
    begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMinRangeright.Heat -> ' + CeHeatStringMin);
{$ENDIF}
        CalculatingInMechanicalCharacteristics(CeHeatStringMin, 1);
    end;}
//-- расчет осуществляется на ближаешем значение от min
  end;

  if InRange(CeArray[0, 1], CeMaxM, CeMax) and (CeHeatStringMax <> '') then
  begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CurrentCeMaxRange -> ' + CeArray[0, 0]);
  SaveLog.Log(etDebug, 'CurrentCeMaxRangeValue -> '+floattostr(CeArray[0, 1]));
{$ENDIF}
//-- расчет осуществляется на ближаешем значение от max
{    // -- report
    CalculatedData(InSide, 'ce_category=''max''');
    // -- report
    if InSide = 0 then
    begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMaxRangeleft.Heat -> ' + CeHeatStringMax);
{$ENDIF}
        CalculatingInMechanicalCharacteristics(CeHeatStringMax, 0);
    end
    else
    begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMaxRangeright.Heat -> ' + CeHeatStringMax);
{$ENDIF}
        CalculatingInMechanicalCharacteristics(CeHeatStringMax, 1);
    end;}
//-- расчет осуществляется на ближаешем значение от max
  end;

  if InRange(CeArray[0, 1], CeAvgM, CeAvgP) and (CeHeatStringAvg <> '') then
  begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CurrentCeAvgRange -> ' + CeArray[0, 0]);
  SaveLog.Log(etDebug, 'CurrentCeAvgRangeValue -> '+floattostr(CeArray[0, 1]));
{$ENDIF}
//-- расчет осуществляется на ближаешем значение от avg
{    // -- report
    CalculatedData(InSide, 'ce_category=''avg''');
    // -- report
    if InSide = 0 then
    begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeAvgRangeleft.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
        CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 0);
    end
    else
    begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeAvgRangeright.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
        CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 1);
    end;}
//-- расчет осуществляется на ближаешем значение от avg
  end;

  SetLength(range, 3);
  //получаем минимальную разницу
  range[0] := ABS(CeMin - CeArray[0, 1]);
  range[1] := ABS(CeMax - CeArray[0, 1]);
  range[2] := ABS(CeAvg - CeArray[0, 1]);

  rangeMin := range[0];

  for i := low(range) To high(range) Do
    if range[i] < rangeMin then
      rangeMin := range[i];  // к какому из пределов ближе

  for i := low(range) To high(range) Do
  begin
    If range[i] = rangeMin Then
    begin
      if (i = 0) and (CeHeatStringMin <> '') then
      begin
        if InSide = 0 then
        begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeMinRangeleft.Heat -> ' + CeHeatStringMin);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''min''');
          // -- report
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'do CalculatingInMechanicalCharacteristics');
{$ENDIF}
         try
          CalculatingInMechanicalCharacteristics(CeHeatStringMin, 0);
          except
           on E: Exception do
             SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
          end;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'after CalculatingInMechanicalCharacteristics');
{$ENDIF}
        end
        else
        begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeMinRangeright.Heat -> ' + CeHeatStringMin);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''min''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringMin, 1);
        end;
      end;
      if (i = 1) and (CeHeatStringMax <> '') then
      begin
        if InSide = 0 then
        begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeMaxRangeleft.Heat -> ' + CeHeatStringMax);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''max''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringMax, 0);
        end
        else
        begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeMaxRangeright.Heat -> ' + CeHeatStringMax);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''max''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringMax, 1);
        end;
      end;
      if (i = 2) and (CeHeatStringAvg <> '') then
      begin
        if InSide = 0 then
        begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeAvgRangeleft.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''avg''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 0);
        end
        else
        begin
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeAvgRangeright.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''avg''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 1);
        end;
      end;
    end;
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'CeRangeMinValue -> ' + floattostr(rangeMin));
  SaveLog.Log(etDebug, 'min range[0] -> ' + floattostr(range[0]));
  SaveLog.Log(etDebug, 'max range[1] -> ' + floattostr(range[1]));
  SaveLog.Log(etDebug, 'avg range[2] -> ' + floattostr(range[2]));
  SaveLog.Log(etDebug, 'rangeM -> ' + floattostr(rangeM));
{$ENDIF}
end;


function CutChar(InData: string): string;
var
  i: integer;
  BadChars: string;
begin
  BadChars := ' ()/\:-;';
  for i := 0 to Length(BadChars) do
    InData := StringReplace(InData, BadChars[i], '%', [rfReplaceAll]);

  Result := InData;
end;


function GetDigits(InData: string): string;
var
  digits: string;
  i: integer;
begin
  for i := 1 to length(InData) do
  begin
    if not(InData[i] in ['0' .. '9']) then
      digits := digits + '%'
    else
      digits := digits + InData[i];
  end;
  Result := digits;
end;

{ delphi median
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
end;}


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


constructor TIdHeat.Create;
begin
    tid                   := 0;
    Heat                  := ''; // плавка
    Grade                 := ''; // марка стали
    Section               := ''; // профиль
    Standard              := ''; // стандарт
    StrengthClass         := ''; // клас прочности
    c                     := '';
    mn                    := '';
    cr                    := '';
    si                    := '';
    b                     := '';
    ce                    := '';
    OldStrengthClass      := ''; // старый клас прочности
    old_tid               := 0; // стара плавка
    RollingMill           := '';
    marker                := 0;
    LowRed                := 0;
    HighRed               := 0;
    LowGreen              := 0;
    HighGreen             := 0;
    step                  := 0;
    technological_sample  := -1;
end;


// При загрузке программы класс будет создаваться
initialization
left := TIdHeat.Create;
right := TIdHeat.Create;

// При закрытии программы уничтожаться
finalization
FreeAndNil(left);
FreeAndNil(right);

end.
