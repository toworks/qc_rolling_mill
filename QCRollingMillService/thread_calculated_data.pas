{
  � ������� calculated_data (Reports) �������������� ������� 2�� �������
  ����� ������� ��������
}

unit thread_calculated_data;

interface

uses
  SysUtils, Classes, Windows, ActiveX, System.Variants, Math,
  ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection, ZAbstractRODataset,
  Types, Generics.Collections;

type
  TThreadCalculatedData = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  TIdHeat = Record
    tid              : integer;
    Heat             : string[26]; // ������
    Grade            : string[50]; // ����� �����
    Section          : string[50]; // �������
    Standard         : string[50]; // ��������
    StrengthClass    : string[50]; // ���� ���������
    c                : string[50];
    mn               : string[50];
    cr               : string[50];
    si               : string[50];
    b                : string[50];
    ce               : string[50];
    OldStrengthClass : string[50]; // ������ ���� ���������
    old_tid          : integer; // ����� ������
    marker           : bool;
    LowRed           : integer;
    HighRed          : integer;
    LowGreen         : integer;
    HighGreen        : integer;
    step             : integer;
    constructor Create(_tid: integer; _Heat, _Grade, _Section, _Standard, _StrengthClass,
                      _c, _mn, _cr, _si, _b, _ce, _OldStrengthClass: string;
                      _old_tid: integer; _marker: bool; _LowRed, _HighRed,
                      _LowGreen, _HighGreen, _step: integer);
  end;

var
  ThreadCalculatedData: TThreadCalculatedData;
  left, right: TIdHeat;

  {$DEFINE DEBUG}

  procedure WrapperCalculatedData; // ������� ��� ������������� � ���������� � ������ �������
  function ReadCurrentHeat: bool;
  function CalculatingInMechanicalCharacteristics(InHeat: string; InSide: integer): string;
  function CarbonEquivalent(InHeat: string; InSide: integer): bool;
  function HeatToIn(InHeat: string): string;
  function CutChar(InData: string): string;
  function GetDigits(InData: string): string;
  function GetMedian(aArray: TDoubleDynArray): Double;

implementation

uses
  logging, settings, main, sql;

procedure TThreadCalculatedData.Execute;
begin
  CoInitialize(nil);
  while not Terminated do
  begin
    Synchronize(WrapperCalculatedData);
    sleep(1000);
  end;
  CoUninitialize;
end;

procedure WrapperCalculatedData;
begin
  try
      if not PConnect.Ping then
        PConnect.Reconnect;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;
  try
      // ����� ������ ������� ��� �������������� � ������
      FormatSettings.DecimalSeparator := '.';
      ReadCurrentHeat;
  except
    on E: Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function ReadCurrentHeat: bool;
var
  i: integer;
  HeatAllLeft, HeatAllRight: string;
begin

  for i := 0 to 1 do
  begin
    // side left=0, side right=1
    PQuery.Close;
    PQuery.sql.Clear;
    PQuery.sql.Add('select t1.tid, t1.heat, t1.strength_class, t1.section,');
    PQuery.sql.Add('t2.grade, t2.standard, t2.c, t2.mn, t2.cr, t2.si, t2.b,');
    PQuery.sql.Add('cast(t2.c+(mn/6)+(cr/5)+((si+b)/10) as numeric(6,4)) as ce');
    PQuery.sql.Add('FROM temperature_current t1');
    PQuery.sql.Add('LEFT OUTER JOIN');
    PQuery.sql.Add('chemical_analysis t2');
    PQuery.sql.Add('on t1.heat=t2.heat');
    PQuery.sql.Add('where t1.side='+inttostr(i)+'');
    PQuery.sql.Add('order by t1.timestamp desc LIMIT 1');
    PQuery.Open;

    if i = 0 then
    begin
      left.tid := PQuery.FieldByName('tid').AsInteger;
      left.Heat := PQuery.FieldByName('heat').AsString;
      left.Grade := PQuery.FieldByName('grade').AsString;
      left.StrengthClass := PQuery.FieldByName('strength_class').AsString;
      left.Section := PQuery.FieldByName('section').AsString;
      left.Standard := PQuery.FieldByName('standard').AsString;

      left.c := PQuery.FieldByName('c').AsString;
      left.mn := PQuery.FieldByName('mn').AsString;
      left.cr := PQuery.FieldByName('cr').AsString;
      left.si := PQuery.FieldByName('si').AsString;
      left.b := PQuery.FieldByName('b').AsString;
      left.ce := PQuery.FieldByName('ce').AsString;

      // ����� ������ ������������� ������
      if (left.old_tid <> left.tid) or (left.OldStrengthClass <> left.StrengthClass) then
      begin
        left.old_tid := left.tid;
        left.OldStrengthClass := left.StrengthClass;
        left.marker := true;
        left.LowRed := 0;
        left.HighRed := 0;
        left.LowGreen := 0;
        left.HighGreen := 0;
      end;

    end
    else
    begin
      right.tid := PQuery.FieldByName('tid').AsInteger;
      right.Heat := PQuery.FieldByName('heat').AsString;
      right.Grade := PQuery.FieldByName('grade').AsString;
      right.StrengthClass := PQuery.FieldByName('strength_class').AsString;
      right.Section := PQuery.FieldByName('section').AsString;
      right.Standard := PQuery.FieldByName('standard').AsString;

      right.c := PQuery.FieldByName('c').AsString;
      right.mn := PQuery.FieldByName('mn').AsString;
      right.cr := PQuery.FieldByName('cr').AsString;
      right.si := PQuery.FieldByName('si').AsString;
      right.b := PQuery.FieldByName('b').AsString;
      right.ce := PQuery.FieldByName('ce').AsString;

      // ����� ������ ������������� ������
      if (right.old_tid <> right.tid) or (right.OldStrengthClass <> right.StrengthClass) then
      begin
        right.old_tid := right.tid;
        right.OldStrengthClass := right.StrengthClass;
        right.marker := true;
        right.LowRed := 0;
        right.HighRed := 0;
        right.LowGreen := 0;
        right.HighGreen := 0;
      end;

    end;

  end;

  if left.marker or right.marker then
  begin
    SaveLog('info'+#9#9+inttostr(left.tid)+#9+left.Heat+#9+left.Grade+#9+
            left.Section+#9+left.Standard+#9+left.StrengthClass+#9+
            left.c+#9+left.mn+#9+left.cr+#9+left.si+#9+left.b+#9+left.ce+#9+
            inttostr(left.old_tid)+#9+booltostr(left.marker)+#9+
            left.OldStrengthClass);
    SaveLog('info'+#9#9+inttostr(right.tid)+#9+right.Heat+#9+right.Grade+#9+
            right.Section+#9+right.Standard+#9+right.StrengthClass+#9+
            right.c+#9+right.mn+#9+right.cr+#9+right.si+#9+right.b+#9+right.ce+#9+
            inttostr(right.old_tid)+#9+booltostr(right.marker)+#9+
            right.OldStrengthClass);
  end;

  if left.marker and (left.ce <> '') then
  begin
    try
      left.marker := false;
      // ����� ����� �������
      left.step := 0;
      // ������� ��� �����������
      CalculatedData(0, '');
      SaveLog('info'+#9#9+'start calculation left side, heat -> '+left.Heat);
      // start left step 0
      CalculatedData(0, 'timestamp=EXTRACT(EPOCH FROM now())');
      HeatAllLeft := CalculatingInMechanicalCharacteristics(RolledMelting(0), 0);
      // start left step 1
      if not HeatAllLeft.IsEmpty then
      begin
        CalculatedData(0, 'timestamp=EXTRACT(EPOCH FROM now())');
        CarbonEquivalent(HeatAllLeft, 0);
      end;
      SaveLog('info'+#9#9+'end calculation left side, heat -> '+left.Heat);
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
    HeatAllLeft := '';
  end;

  if right.marker and (right.ce <> '') then
  begin
    try
      right.marker := false;
      // ����� ����� �������
      right.step := 0;
      // ������� ��� �����������
      CalculatedData(1, '');
      SaveLog('info'+#9#9+'start calculation right side, heat -> '+right.Heat);
      // start right step 0
      CalculatedData(1, 'timestamp=EXTRACT(EPOCH FROM now())');
      HeatAllRight := CalculatingInMechanicalCharacteristics(RolledMelting(1), 1);
      // start right step 1
      if not HeatAllRight.IsEmpty then
      begin
        CalculatedData(1, 'timestamp=EXTRACT(EPOCH FROM now())');
        CarbonEquivalent(HeatAllRight, 1);
      end;
      SaveLog('info' + #9#9 + 'end calculation right side, heat -> '+right.Heat);
    except
      on E: Exception do
        SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
    end;
    HeatAllRight := '';
  end;
end;


function CalculatingInMechanicalCharacteristics(InHeat: string; InSide: integer): string;
var
  { yield point - ������ ���������
    rupture strength - ��������� ������������� }

  Grade: string; // ����� �����
  Section: string; // �������
  Standard: string; // ��������
  StrengthClass: string; // ���� ���������
  ReturnValue: string;
  side: string;
  RollingScheme: string;

  PQueryCalculation: TZQuery;
  PQueryData: TZQuery;

  i, a, b, CoefficientCount, AdjustmentMin, AdjustmentMax,
  LimitRolledProductsMin, LimitRolledProductsMax, HeatCount: integer;
  m: bool;
  CoefficientYieldPointValue, CoefficientRuptureStrengthValue, MechanicsAvg,
    MechanicsStdDev, MechanicsMin, MechanicsMax, MechanicsDiff, CoefficientMin,
    CoefficientMax, TempAvg, TempStdDev, TempMin, TempMax, TempDiff, R: real;
  TypeRolledProducts, HeatAll, HeatWorks, HeatTableAll: WideString;
  HeatArray, HeatTableArray: Array of string;
  MechanicsArray, TempArray: Array of Double;
  RawTempArray: TDoubleDynArray;
  st, HeatTmp: TStringList;
  c, mn, si, HeatMechanics: string;
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
    side := '�����';
    RollingScheme := right.Section; // ����� �������� 14x16, 16x16, 18x16
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
    side := '������';
    RollingScheme := left.Section; // ����� �������� 14x16, 16x16, 18x16
  end;

  if InHeat.IsEmpty then
  begin
    SaveLog('warning'+#9#9+'������� -> '+side);
    SaveLog('warning'+#9#9 +'������������ ������ �� ����������� ������� ��� ������� �� ������ -> '+InHeat);
    exit;
  end;

  PQueryCalculation := TZQuery.Create(nil);
  PQueryCalculation.Connection := PConnect;
  PQueryData := TZQuery.Create(nil);
  PQueryData.Connection := PConnect;

  a := 0;
  b := a;

  HeatAll := HeatToIn(InHeat);

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
//--      OraQuery.SQL.Add('and n.mst like translate('''+CutChar(Grade)+''','); //��������� Eng ����� ������� �� ��������
//--      OraQuery.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
//--      OraQuery.SQL.Add('and n.GOST like translate('''+CutChar(Standard)+''','); //��������� Eng ����� ������� �� ��������
//--      OraQuery.SQL.Add('''ETOPAHKXCBMetopahkxcbm'',''����������������������'')');
      OraQuery.SQL.Add('and n.razm1 = '+Section+'');
      OraQuery.SQL.Add('and translate(n.klass,');
      OraQuery.SQL.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      OraQuery.SQL.Add('like translate('''+CutChar(StrengthClass)+''',');
      OraQuery.SQL.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      OraQuery.SQL.Add('and n.data=v.data and v.npart=n.npart');
      OraQuery.SQL.Add('and n.npart like '''+RollingMillConfigArray[1]+'%'''); // ����� �����
      if InSide = 0  then
        OraQuery.SQL.Add('and mod(n.npart,2)=1')// �������� �� �������� | 0 ������ - ����� | 1 - �������� ������
      else
        OraQuery.SQL.Add('and mod(n.npart,2)=0');// �������� �� �������� | 0 ������ - ����� | 1 - �������� ������
{      if (StrengthClass = 'S400') or (StrengthClass = 'S400W') then // ������ ��� ������� ������� �� 15 ����
        OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=15')
      else
        OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');}
      OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0)');
      OraQuery.SQL.Add('and prizn=''*'' and ROWNUM <= 251');
      OraQuery.SQL.Add('and n.nplav in('+HeatAll+')');
      OraQuery.SQL.Add('order by n.data desc)');
      if (StrengthClass = 'S400') or (StrengthClass = 'S400W') then // ������ ��� ������� ������� �� 15 ����
        OraQuery.SQL.Add('where number_row <= 15')
      else
        OraQuery.SQL.Add('where number_row <= 3');
      OraQuery.Open;
      OraQuery.FetchAll;
  except
    on E: Exception do
    begin
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
      ConfigOracleSetting(false);
      exit;
    end;
  end;

{$IFDEF DEBUG }
  SaveLog('debug'+#9#9+'OraQuery.SQL.Text -> '+OraQuery.SQL.Text);
  SaveLog('debug' + #9#9 + 'OraQuery.RecordCount -> '+inttostr(OraQuery.RecordCount));
{$ENDIF}

  if OraQuery.RecordCount < 5 then
  begin
    SaveLog('warning' + #9#9 + '������� -> '+side);
    SaveLog('warning' + #9#9 + '������������ ������ ��� ������� �� ������� -> '+HeatAll);
    exit;
  end;

  try
      PQueryData.sql.Clear;
      PQueryData.sql.Add('SELECT n, k_yield_point, k_rupture_strength FROM coefficient');
      PQueryData.sql.Add('where n<='+inttostr(OraQuery.RecordCount)+'');
      PQueryData.sql.Add('order by n desc limit 1');
      PQueryData.Open;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  CoefficientCount := PQueryData.FieldByName('n').AsInteger;
  CoefficientYieldPointValue := PQueryData.FieldByName('k_yield_point').AsFloat;
  { CoefficientRuptureStrengthValue - ���������� � CoefficientYieldPointValue
    k_rupture_strength ������������� ��� ������� ������� }
  CoefficientRuptureStrengthValue := PQueryData.FieldByName('k_yield_point').AsFloat;//PQueryData.FieldByName('k_rupture_strength').AsFloat;

  // -- report
  CalculatedData(InSide, 'coefficient_count=''' + inttostr(CoefficientCount) + '''');
  CalculatedData(InSide, 'coefficient_yield_point_value=''' + floattostr(CoefficientYieldPointValue) + '''');
  CalculatedData(InSide, 'coefficient_rupture_strength_value=''' + floattostr(CoefficientRuptureStrengthValue) + '''');
  // -- report
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CoefficientCount -> ' + inttostr(CoefficientCount));
  SaveLog('debug' + #9#9 + 'CoefficientYieldPointValue -> ' + floattostr(CoefficientYieldPointValue));
  SaveLog('debug' + #9#9 + 'CoefficientRuptureStrengthValue -> ' + floattostr(CoefficientRuptureStrengthValue));
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
      SQuery.sql.Add('delete from mechanics where side=' + inttostr(InSide) + '');
      SQuery.ExecSQL;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  i := 1;
  while not OraQuery.Eof do
  begin
    if i <= CoefficientCount then
    begin
        if (UTF8Decode(OraQuery.FieldByName('heat').AsString) <> HeatMechanics) or
           (HeatCount <= 3) then
        begin
          if HeatCount = 4 then
            HeatCount := 0;

          HeatMechanics := UTF8Decode(OraQuery.FieldByName('heat').AsString);
          inc(HeatCount);

          try
              SQuery.Close;
              SQuery.sql.Clear;
              SQuery.sql.Add('insert into mechanics (heat, timestamp, grade, standard');
              SQuery.sql.Add(', section , strength_class, yield_point, rupture_strength, side)');
              SQuery.sql.Add('values (''' + UTF8Decode(OraQuery.FieldByName('heat').AsString)+'''');
              SQuery.sql.Add(', strftime(''%s'', ''now'')');
              SQuery.sql.Add(', ''NULL''');
              SQuery.sql.Add(', '''+UTF8Decode(OraQuery.FieldByName('standard').AsString)+'''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('section').AsString+'''');
              SQuery.sql.Add(', '''+UTF8Decode(OraQuery.FieldByName('strength_class').AsString)+'''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('yield_point').AsString+'''');
              SQuery.sql.Add(', '''+OraQuery.FieldByName('rupture_strength').AsString+'''');
              SQuery.sql.Add(', '''+inttostr(InSide)+''')');
              SQuery.ExecSQL;
          except
            on E: Exception do
              SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
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
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
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
  SaveLog('debug' + #9#9 + 'HeatAll to works -> ' + HeatAll);
{$ENDIF}
  // -- heat to works
  // ����� �������� �� ������� technological_sample
  try
      PQueryData.Close;
      PQueryData.sql.Clear;
      PQueryData.sql.Add('SELECT limit_min, limit_max, type FROM technological_sample');
      PQueryData.sql.Add('where translate(strength_class,');
      PQueryData.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      PQueryData.sql.Add('like translate('''+StrengthClass+''',');
      PQueryData.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      PQueryData.sql.Add('and diameter_min <= '+Section+' and diameter_max >= '+Section+'');
      PQueryData.sql.Add('and c_min <= '+c+' and c_max >= '+c+'');
      PQueryData.sql.Add('and mn_min <= '+mn+' and mn_max >= '+mn+'');
      PQueryData.sql.Add('and si_min <= '+si+' and si_max >= '+si+'');
      PQueryData.sql.Add('limit 1');
      PQueryData.Open;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  if PQueryData.FieldByName('limit_min').IsNull then
  begin
    SaveLog('warning' + #9#9 + '������� -> '+side);
    SaveLog('warning' + #9#9 + '������������ ������ �� ��������������� ���������� ��� -> '+InHeat);
    exit;
  end;

  LimitRolledProductsMin := PQueryData.FieldByName('limit_min').AsInteger;
  LimitRolledProductsMax := PQueryData.FieldByName('limit_max').AsInteger;
  TypeRolledProducts := PQueryData.FieldByName('type').AsString;

  // -- report
  CalculatedData(InSide, 'limit_rolled_products_min='''+inttostr(LimitRolledProductsMin)+'''');
  CalculatedData(InSide, 'limit_rolled_products_max='''+floattostr(LimitRolledProductsMax)+'''');
  CalculatedData(InSide, 'type_rolled_products='''+TypeRolledProducts+'''');
  // -- report

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'LimitRolledProductsMin -> '+inttostr(LimitRolledProductsMin));
  SaveLog('debug' + #9#9 + 'LimitRolledProductsMax -> '+inttostr(LimitRolledProductsMax));
  SaveLog('debug' + #9#9 + 'TypeRolledProducts -> ' + TypeRolledProducts);
  SaveLog('debug' + #9#9 + 'RolledProducts RecordCount -> '+inttostr(SQuery.RecordCount));
{$ENDIF}

  try
      SQuery.Close;
      SQuery.sql.Clear;
      SQuery.sql.Add('SELECT * FROM mechanics');
      SQuery.sql.Add('where side=' + inttostr(InSide) + '');
      SQuery.Open;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

  if SQuery.RecordCount < 1 then
  begin
    SaveLog('warning'+#9#9+'������� -> '+side);
    SaveLog('warning'+#9#9+'������������ ������ �� ���. ���������� ��� ������� �� ������� -> '+HeatAll);
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
  SaveLog('debug' + #9#9 + 'MechanicsAvg -> ' + floattostr(MechanicsAvg));
  SaveLog('debug' + #9#9 + 'MechanicsStdDev -> ' + floattostr(MechanicsStdDev));
  SaveLog('debug' + #9#9 + 'MechanicsMin -> ' + floattostr(MechanicsMin));
  SaveLog('debug' + #9#9 + 'MechanicsMax -> ' + floattostr(MechanicsMax));
  SaveLog('debug' + #9#9 + 'MechanicsDiff -> ' + floattostr(MechanicsDiff));
  SaveLog('debug' + #9#9 + 'CoefficientMin -> ' + floattostr(CoefficientMin));
  SaveLog('debug' + #9#9 + 'CoefficientMax -> ' + floattostr(CoefficientMax));
  SaveLog('debug' + #9#9 + 'Section -> ' + Section);
  SaveLog('debug' + #9#9 + 'RollingScheme -> ' + RollingScheme);
{$ENDIF}

  try
      PQueryCalculation.Close;
      PQueryCalculation.sql.Clear;
      PQueryCalculation.sql.Add('select t1.tid, t1.heat, t4.temperature from temperature_current t1');
      PQueryCalculation.sql.Add('inner join');
      PQueryCalculation.sql.Add('chemical_analysis t2');
      PQueryCalculation.sql.Add('on t1.heat = t2.heat');
      PQueryCalculation.sql.Add('inner join');
      PQueryCalculation.sql.Add('technological_sample t3');
      PQueryCalculation.sql.Add('on t3.diameter_min <= '+Section+' and t3.diameter_max >= '+Section+'');
      PQueryCalculation.sql.Add('and t3.c_min <= '+c+' and t3.c_max >= '+c+'');
      PQueryCalculation.sql.Add('and t3.mn_min <= '+mn+' and t3.mn_max >= '+mn+'');
      PQueryCalculation.sql.Add('and t3.si_min <= '+si+' and t3.si_max >= '+si+'');
      PQueryCalculation.sql.Add('and translate(t3.strength_class,');
      PQueryCalculation.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      PQueryCalculation.sql.Add('like translate('''+StrengthClass+''',');
      PQueryCalculation.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      PQueryCalculation.sql.Add('inner JOIN');
      PQueryCalculation.sql.Add('temperature_historical t4');
      PQueryCalculation.sql.Add('on t1.tid=t4.tid');
      PQueryCalculation.sql.Add('where t1.timestamp<=EXTRACT(EPOCH FROM now())');
      PQueryCalculation.sql.Add('and t1.timestamp>=EXTRACT(EPOCH FROM now())-(2629743*10)');
      PQueryCalculation.sql.Add('and t2.heat in ('+HeatAll+')');
      PQueryCalculation.sql.Add('and translate(t3.strength_class,');
      PQueryCalculation.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      PQueryCalculation.sql.Add('like translate(t1.strength_class,');
      PQueryCalculation.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      PQueryCalculation.sql.Add('and t3.c_min <= t2.c and t3.c_max >= t2.c');// �������� � ������������� ������
      PQueryCalculation.sql.Add('and t3.mn_min <= t2.mn and t3.mn_max >= t2.mn');
      PQueryCalculation.sql.Add('and t3.si_min <= t2.si and t3.si_max >= t2.si');
      PQueryCalculation.sql.Add('and t1.side='+inttostr(InSide)+'');
      if (strtofloat(Section) = 14) or (strtofloat(Section) = 16) or (strtofloat(Section) = 18) then
          PQueryCalculation.sql.Add('and t4.rolling_scheme = '''+RollingScheme+'''');

//      PQueryCalculation.sql.Add('and t3.type like ''yield_point'');

{      PQueryCalculation.sql.Add('select t1.tid, t1.heat, t2.temperature from temperature_current t1');
      PQueryCalculation.sql.Add('LEFT OUTER JOIN');
      PQueryCalculation.sql.Add('temperature_historical t2');
      PQueryCalculation.sql.Add('on t1.tid=t2.tid');
      PQueryCalculation.sql.Add('where t1.heat in ('+HeatAll+')');
      PQueryCalculation.sql.Add('and t1.strength_class like '''+CutChar(StrengthClass)+'''');
      PQueryCalculation.SQL.Add('and t1.grade like '''+CutChar(Grade)+'''');
      PQueryCalculation.sql.Add('and t1.section = '+CutChar(Section)+'');
      PQueryCalculation.sql.Add('and t1.standard like '''+GetDigits(Standard)+'%''');
      PQueryCalculation.sql.Add('and t1.side='+inttostr(InSide)+'');}
      PQueryCalculation.Open;
      PQueryCalculation.FetchAll;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'PQueryCalculation.SQL.Text -> ' + PQueryCalculation.sql.Text);
{$ENDIF}

  if PQueryCalculation.RecordCount < 1 then
  begin
    SaveLog('warning'+#9#9+'������� -> '+side);
    SaveLog('warning'+#9#9+'������������ ������ �� ����������� ��� ������� �� ������� -> '+HeatAll);
    exit;
  end;

{  a := 0;
  while not PQueryCalculation.Eof do
  begin
    if a = length(TempArray) then
      SetLength(TempArray, a + 1);
    TempArray[a] := PQueryCalculation.FieldByName('temperature').AsInteger;
    inc(a);
    PQueryCalculation.Next;
  end;}

  a := 0;
  b := a;
  i := a;
  while not PQueryCalculation.Eof do
  begin
    if a = length(RawTempArray) then SetLength(RawTempArray, a + 1);
//    SetLength(RawTempArray, 5);
    RawTempArray[a] := PQueryCalculation.FieldByName('temperature').AsInteger;
    inc(a);

{$IFDEF DEBUG}
  inc(i);
{$ENDIF}

    if a = 4 then
    begin
      if b = length(TempArray) then SetLength(TempArray, b + 1);
      TempArray[b] := GetMedian(RawTempArray);
      inc(b);
      a := 0;
    end;
    PQueryCalculation.Next;
  end;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'count temperature all -> ' + inttostr(i));
  SaveLog('debug' + #9#9 + 'count temperature median -> ' + inttostr(b));
{$ENDIF}

  FreeAndNil(PQueryCalculation);
  FreeAndNil(PQueryData);

  TempAvg := Mean(TempArray);
  TempStdDev := StdDev(TempArray);
  SetLength(TempArray, 0); // �������� ������ c ������������
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
  SaveLog('debug' + #9#9 + 'TempAvg -> ' + floattostr(TempAvg));
  SaveLog('debug' + #9#9 + 'TempStdDev -> ' + floattostr(TempStdDev));
  SaveLog('debug' + #9#9 + 'TempMin -> ' + floattostr(TempMin));
  SaveLog('debug' + #9#9 + 'TempMax -> ' + floattostr(TempMax));
  SaveLog('debug' + #9#9 + 'TempDiff -> ' + floattostr(TempDiff));
  SaveLog('debug' + #9#9 + 'R -> ' + floattostr(R));
  SaveLog('debug' + #9#9 + 'AdjustmentMin -> ' + inttostr(AdjustmentMin));
  SaveLog('debug' + #9#9 + 'AdjustmentMax -> ' + inttostr(AdjustmentMax));
{$ENDIF}

    if ((InSide = 0) and (left.step = 0)) then
    begin
      // ����������� �������� �� 10 ��������
      left.LowRed := Round(TempMin + AdjustmentMax) - 10;
      left.HighRed := Round(TempMax + AdjustmentMin) + 10;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(left.LowRed) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(left.HighRed) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'LowRedLeft -> ' + inttostr(left.LowRed));
      SaveLog('debug' + #9#9 + 'HighRedLeft -> ' + inttostr(left.HighRed));
      SaveLog('debug' + #9#9 + 'left.step first -> ' + inttostr(left.step));
{$ENDIF}
      inc(left.step); // ������ 2�� �������
      // ���������� ������ �� ������� ������������� ������
      Result := HeatAll;
      exit;
    end;
    if ((InSide = 0) and (left.step = 1)) then
    begin
      // ����������� �������� �� 5 ��������
      left.LowGreen := Round(TempMin + AdjustmentMax) - 5; //������ 2.5 ��� �����������
      left.HighGreen := Round(TempMax + AdjustmentMin) + 5;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(left.LowGreen) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(left.HighGreen) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'LowGreenLeft -> ' + inttostr(left.LowGreen));
      SaveLog('debug' + #9#9 + 'HighGreenLeft -> ' + inttostr(left.HighGreen));
      SaveLog('debug' + #9#9 + 'left.step last -> ' + inttostr(left.step));
{$ENDIF}
//      left.step := 0; // ����� ����� ��������� � ������
      // ���������� ������ �� ������� ������������� ������
      Result := HeatAll;
      exit;
    end;

    if ((InSide = 1) and (right.step = 0)) then
    begin
      // ����������� �������� �� 10 ��������
      right.LowRed := Round(TempMin + AdjustmentMax) - 10;
      right.HighRed := Round(TempMax + AdjustmentMin) + 10;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(right.LowRed) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(right.HighRed) + '''');
      // -- report
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'LowRedRight -> ' + inttostr(right.LowRed));
      SaveLog('debug' + #9#9 + 'HighRedRight -> ' + inttostr(right.HighRed));
      SaveLog('debug' + #9#9 + 'right.step first -> ' + inttostr(right.step));
{$ENDIF}
      inc(right.step); // ������ 2�� �������
      // ���������� ������ �� ������� ������������� ������
      Result := HeatAll;
      exit;
    end;
    if ((InSide = 1) and (right.step = 1)) then
    begin
      // ����������� �������� �� 5 ��������
      right.LowGreen := Round(TempMin + AdjustmentMax) - 5;
      right.HighGreen := Round(TempMax + AdjustmentMin) + 5;
      // -- report
      CalculatedData(InSide, 'low=''' + inttostr(right.LowGreen) + '''');
      CalculatedData(InSide, 'high=''' + inttostr(right.HighGreen) + '''');
      // -- report
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'LowGreenRight -> ' + inttostr(right.LowGreen));
    SaveLog('debug' + #9#9 + 'HighGreenRight -> ' + inttostr(right.HighGreen));
    SaveLog('debug' + #9#9 + 'right.step last -> ' + inttostr(right.step));
{$ENDIF}
//      right.step := 0; // ����� ����� ��������� � ������
      // ���������� ������ �� ������� ������������� ������
      Result := HeatAll;
      exit;
    end;
end;


function CarbonEquivalent(InHeat: string; InSide: integer): bool;
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

  CeMin := CeArray[0, 1]; // ����� ������ �������� �� �������
  CeMax := CeMin;
  For i := Low(CeArray) To High(CeArray) Do
  Begin
    If CeArray[i, 1] < CeMin Then
      CeMin := CeArray[i, 1];
    If CeArray[i, 1] > CeMax Then
      CeMax := CeArray[i, 1];
  End;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMin -> ' + floattostr(CeMin));
  SaveLog('debug' + #9#9 + 'CeMax -> ' + floattostr(CeMax));
{$ENDIF}
  CeAvg := (CeMin + CeMax) / 2;
  CeMinP := CeMin + 0.02; //���� 0.03
  CeMaxM := CeMax - 0.02;
  CeAvgP := CeAvg + 0.01; //0.015
  CeAvgM := CeAvg - 0.01;

  For i := Low(CeArray) To High(CeArray) Do
  Begin
    If InRange(CeArray[i, 1], CeMin, CeMinP) then
    begin
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'CeMinRangeHeat -> ' + CeArray[i, 0]);
      SaveLog('debug' + #9#9 + 'CeMinRangeValue -> ' +floattostr(CeArray[i, 1]));
{$ENDIF}
      if a = 0 then
        CeHeatStringMin := CeArray[i, 0]
      else
        CeHeatStringMin := CeHeatStringMin + '|' + CeArray[i, 0];
      inc(a);
    end;

    if InRange(CeArray[i, 1], CeMaxM, CeMax) then
    begin
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'CeMaxRangeHeat -> ' + CeArray[i, 0]);
      SaveLog('debug' + #9#9 + 'CeMaxRangeValue -> ' + floattostr(CeArray[i, 1]));
{$ENDIF}
      if b = 0 then
        CeHeatStringMax := CeArray[i, 0]
      else
        CeHeatStringMax := CeHeatStringMax + '|' + CeArray[i, 0];
      inc(b);
    end;

    if InRange(CeArray[i, 1], CeAvgM, CeAvgP) then
    begin
{$IFDEF DEBUG}
      SaveLog('debug' + #9#9 + 'CeAvgRangeHeat -> ' + CeArray[i, 0]);
      SaveLog('debug' + #9#9 + 'CeAvgRangeValue -> ' + floattostr(CeArray[i, 1]));
{$ENDIF}
      if c = 0 then
        CeHeatStringAvg := CeArray[i, 0]
      else
        CeHeatStringAvg := CeHeatStringAvg + '|' + CeArray[i, 0];
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
  SaveLog('debug' + #9#9 + 'CeInHeat -> ' + InHeat);
  SaveLog('debug' + #9#9 + 'CeMin -> ' + floattostr(CeMin));
  SaveLog('debug' + #9#9 + 'CeMax -> ' + floattostr(CeMax));
  SaveLog('debug' + #9#9 + 'CeAvg -> ' + floattostr(CeAvg));
  SaveLog('debug' + #9#9 + 'CeMinP -> ' + floattostr(CeMinP));
  SaveLog('debug' + #9#9 + 'CeMaxM -> ' + floattostr(CeMaxM));
  SaveLog('debug' + #9#9 + 'CeAvgP -> ' + floattostr(CeAvgP));
  SaveLog('debug' + #9#9 + 'CeAvgM -> ' + floattostr(CeAvgM));
{$ENDIF}
  if InSide = 0 then
  begin
    // -- �� �� ������� ������
    CeArray := SqlCarbonEquivalent('''' + left.Heat + '''');
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'Currentleft.Heat -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeLeft -> ' + floattostr(CeArray[0, 1]));
{$ENDIF}
  end
  else
  begin
    // -- �� �� ������� ������
    CeArray := SqlCarbonEquivalent('''' + right.Heat + '''');
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'Currentright.Heat -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeRight -> ' + floattostr(CeArray[0, 1]));
{$ENDIF}
  end;

  // -- ������� ������ � ������ �� ���������� ��������� min,max,avg
  if InRange(CeArray[0, 1], CeMin, CeMinP) and (CeHeatStringMin <> '') then
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'CurrentCeMinRange -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeMinRangeValue -> '+floattostr(CeArray[0, 1]));
{$ENDIF}
//-- ������ �������������� �� ��������� �������� �� min
{    // -- report
    CalculatedData(InSide, 'ce_category=''min''');
    // -- report
    if InSide = 0 then
    begin
//{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'CeMinRangeleft.Heat -> ' + CeHeatStringMin);
//{$ENDIF}
{        CalculatingInMechanicalCharacteristics(CeHeatStringMin, 0);
    end
    else
    begin
//{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'CeMinRangeright.Heat -> ' + CeHeatStringMin);
//{$ENDIF}
{        CalculatingInMechanicalCharacteristics(CeHeatStringMin, 1);
    end;}
//-- ������ �������������� �� ��������� �������� �� min
  end;

  if InRange(CeArray[0, 1], CeMaxM, CeMax) and (CeHeatStringMax <> '') then
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'CurrentCeMaxRange -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeMaxRangeValue -> '+floattostr(CeArray[0, 1]));
{$ENDIF}
//-- ������ �������������� �� ��������� �������� �� max
{    // -- report
    CalculatedData(InSide, 'ce_category=''max''');
    // -- report
    if InSide = 0 then
    begin
//{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'CeMaxRangeleft.Heat -> ' + CeHeatStringMax);
//{$ENDIF}
{        CalculatingInMechanicalCharacteristics(CeHeatStringMax, 0);
    end
    else
    begin
//{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'CeMaxRangeright.Heat -> ' + CeHeatStringMax);
//{$ENDIF}
{        CalculatingInMechanicalCharacteristics(CeHeatStringMax, 1);
    end;}
//-- ������ �������������� �� ��������� �������� �� max
  end;

  if InRange(CeArray[0, 1], CeAvgM, CeAvgP) and (CeHeatStringAvg <> '') then
  begin
{$IFDEF DEBUG}
    SaveLog('debug' + #9#9 + 'CurrentCeAvgRange -> ' + CeArray[0, 0]);
    SaveLog('debug' + #9#9 + 'CurrentCeAvgRangeValue -> '+floattostr(CeArray[0, 1]));
{$ENDIF}
//-- ������ �������������� �� ��������� �������� �� avg
{    // -- report
    CalculatedData(InSide, 'ce_category=''avg''');
    // -- report
    if InSide = 0 then
    begin
//{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'CeAvgRangeleft.Heat -> ' + CeHeatStringAvg);
//{$ENDIF}
{        CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 0);
    end
    else
    begin
//{$IFDEF DEBUG}
//  SaveLog('debug' + #9#9 + 'CeAvgRangeright.Heat -> ' + CeHeatStringAvg);
//{$ENDIF}
{        CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 1);
    end;}
//-- ������ �������������� �� ��������� �������� �� avg
  end;

  SetLength(range, 3);
  //�������� ����������� �������
  range[0] := ABS(CeMin - CeArray[0, 1]);
  range[1] := ABS(CeMax - CeArray[0, 1]);
  range[2] := ABS(CeAvg - CeArray[0, 1]);

  rangeMin := range[0];

  for i := low(range) To high(range) Do
    if range[i] < rangeMin then
      rangeMin := range[i];  // � ������ �� �������� �����

  for i := low(range) To high(range) Do
  begin
    If range[i] = rangeMin Then
    begin
      if (i = 0) and (CeHeatStringMin <> '') then
      begin
        if InSide = 0 then
        begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMinRangeleft.Heat -> ' + CeHeatStringMin);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''���''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringMin, 0);
        end
        else
        begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMinRangeright.Heat -> ' + CeHeatStringMin);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''���''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringMin, 1);
        end;
      end;
      if (i = 1) and (CeHeatStringMax <> '') then
      begin
        if InSide = 0 then
        begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMaxRangeleft.Heat -> ' + CeHeatStringMax);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''����''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringMax, 0);
        end
        else
        begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeMaxRangeright.Heat -> ' + CeHeatStringMax);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''����''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringMax, 1);
        end;
      end;
      if (i = 2) and (CeHeatStringAvg <> '') then
      begin
        if InSide = 0 then
        begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeAvgRangeleft.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''����''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 0);
        end
        else
        begin
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeAvgRangeright.Heat -> ' + CeHeatStringAvg);
{$ENDIF}
          // -- report
          CalculatedData(InSide, 'ce_category=''����''');
          // -- report
          CalculatingInMechanicalCharacteristics(CeHeatStringAvg, 1);
        end;
      end;
    end;
  end;

{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'CeRangeMinValue -> ' + floattostr(rangeMin));
  SaveLog('debug' + #9#9 + 'min range[0] -> ' + floattostr(range[0]));
  SaveLog('debug' + #9#9 + 'max range[1] -> ' + floattostr(range[1]));
  SaveLog('debug' + #9#9 + 'avg range[2] -> ' + floattostr(range[2]));
  SaveLog('debug' + #9#9 + 'rangeM -> ' + floattostr(rangeM));
{$ENDIF}
end;


function HeatToIn(InHeat: string): string;
var
  i: integer;
  AllHeat: string;
  st: TStringList;
begin
  st := TStringList.Create;
  st.Text := StringReplace(InHeat, '|', #13#10, [rfReplaceAll]);

  for i := 0 to st.Count - 1 do
  begin
    if i <> st.Count - 1 then
      st.Strings[i] := '''' + st.Strings[i] + '''' + ','
    else
      st.Strings[i] := '''' + st.Strings[i] + '''';

    AllHeat := AllHeat + '' + st.Strings[i] + '';
  end;
  st.Free;
  Result := AllHeat;
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


constructor TIdHeat.Create(_tid: integer; _Heat, _Grade, _Section, _Standard, _StrengthClass,
                      _c, _mn, _cr, _si, _b, _ce, _OldStrengthClass: string;
                      _old_tid: integer; _marker: bool; _LowRed, _HighRed,
                      _LowGreen, _HighGreen, _step: integer);
begin
    tid              := _tid;
    Heat             := _Heat; // ������
    Grade            := _Grade; // ����� �����
    Section          := _Section; // �������
    Standard         := _Standard; // ��������
    StrengthClass    := _StrengthClass; // ���� ���������
    c                := _c;
    mn               := _mn;
    cr               := _cr;
    si               := _si;
    b                := _b;
    ce               := _ce;
    OldStrengthClass := _OldStrengthClass; // ������ ���� ���������
    old_tid          := _old_tid; // ����� ������
    marker           := _marker;
    LowRed           := _LowRed;
    HighRed          := _HighRed;
    LowGreen         := _LowGreen;
    HighGreen        := _HighGreen;
    step             := _step;
end;


// ��� �������� ��������� ����� ����� �����������
initialization
left := TIdHeat.Create(0,'','','','','','','','','','','','',0,false,0,0,0,0,0);
right := TIdHeat.Create(0,'','','','','','','','','','','','',0,false,0,0,0,0,0);

// ��� �������� ��������� ������������
finalization
FreeAndNil(left);
FreeAndNil(right);

end.
