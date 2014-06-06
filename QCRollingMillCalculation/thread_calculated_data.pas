{
  � ������� calculated_data (Reports) �������������� ������� 2�� �������
  ����� ������� ��������
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

  TIdHeat = Class
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
    RollingMill      : string[1];
    marker           : boolean;
    LowRed           : integer;
    HighRed          : integer;
    LowGreen         : integer;
    HighGreen        : integer;
    step             : integer;
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
{  function CarbonEquivalent(InHeat: string; InSide: integer): boolean;}
  function HeatToIn(InHeat: string): string;
  function CutChar(InData: string): string;
{  function GetDigits(InData: string): string;
  function GetMedian(aArray: TDoubleDynArray): Double;}

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
         if not MsSqlSettings.configured then
            ConfigMsSetting(true);
         if not OraSqlSettings.configured then
            ConfigOracleSetting(true);

         ReadCurrentHeat('1');
         ReadCurrentHeat('3');
     except
       on E: Exception do
         SaveLog.Log(etError, E.ClassName+', � ����������: '+E.Message);
     end;

    until Terminated;
    SaveLog.Log(etInfo, 'tread loop stopped');
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', � ����������: '+E.Message);
  end;
end;


function ReadCurrentHeat(InRollingMill: string): boolean;
var
  i: integer;
  HeatAllLeft, HeatAllRight: string;
begin
  // side left=0, side right=1
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
      left.Section := UTF8Decode(MSQuery.FieldByName('section').AsString);
      left.Standard := UTF8Decode(MSQuery.FieldByName('standard').AsString);
      left.RollingMill := UTF8Decode(MSQuery.FieldByName('rolling_mill').AsString);

      // ������ ������������� ������ ������ |����� �����|�������|
      ReadSaveOldData('read', InRollingMill, inttostr(i));

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
        // �����
        ReadChemicalAnalysis(left.Heat, i);
        // ���������� ������������� ������ ������ |����� �����|�������|
        ReadSaveOldData('save', InRollingMill, inttostr(i));
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, UTF8Encode('enable left.marker -> '+booltostr(left.marker)));
{$ENDIF}
      end;

      if left.c = '' then
        // ����� ��� ����������� �������
        ReadChemicalAnalysis(left.Heat, i);

    end
    else
    begin
      right.tid := MSQuery.FieldByName('tid').AsInteger;
      right.Heat := UTF8Decode(MSQuery.FieldByName('heat').AsString);
      right.Grade := UTF8Decode(MSQuery.FieldByName('grade').AsString);
      right.StrengthClass := UTF8Decode(MSQuery.FieldByName('strength_class').AsString);
      right.Section := UTF8Decode(MSQuery.FieldByName('section').AsString);
      right.Standard := UTF8Decode(MSQuery.FieldByName('standard').AsString);
      right.RollingMill := UTF8Decode(MSQuery.FieldByName('rolling_mill').AsString);

      // ������ ������������� ������ ������ |����� �����|�������|
      ReadSaveOldData('read', InRollingMill, inttostr(i));

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
        // �����
        ReadChemicalAnalysis(right.Heat, i);
        // ���������� ������������� ������ ������ |����� �����|�������|
        ReadSaveOldData('save', InRollingMill, inttostr(i));
      end;

      if right.c = '' then
        // ����� ��� ����������� �������
        ReadChemicalAnalysis(left.Heat, i);

    end;

  end;

  if left.marker then begin
    SaveLog.Log(etInfo, left.RollingMill+#9+inttostr(left.tid)+#9+left.Heat+#9+left.Grade+#9+
            left.Section+#9+left.Standard+#9+left.StrengthClass+#9+
            left.c+#9+left.mn+#9+left.cr+#9+left.si+#9+left.b+#9+left.ce+#9+
            inttostr(left.old_tid)+#9+booltostr(left.marker)+#9+
            left.OldStrengthClass);
  end;
  if right.marker then begin
    SaveLog.Log(etInfo, right.RollingMill+#9+inttostr(right.tid)+#9+right.Heat+#9+right.Grade+#9+
            right.Section+#9+right.Standard+#9+right.StrengthClass+#9+
            right.c+#9+right.mn+#9+right.cr+#9+right.si+#9+right.b+#9+right.ce+#9+
            inttostr(right.old_tid)+#9+booltostr(right.marker)+#9+
            right.OldStrengthClass);
  end;

  if left.marker {and (left.ce <> '')} then
  begin
    try
      left.marker := false;
{      // ���������� ������������� ������ ������ |����� �����|�������|
      ReadSaveOldData('save', left.RollingMill, '0');}
      // ����� ����� �������
      left.step := 0;
      // ������� ��� �����������
      CalculatedData(0, '');
      SaveLog.Log(etInfo, 'start calculation left side, heat -> '+left.Heat);
      // start left step 0
      CalculatedData(0, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
      HeatAllLeft := CalculatingInMechanicalCharacteristics(RolledMelting(0), 0);
{{      // start left step 1
      if not HeatAllLeft.IsEmpty then
      begin
        CalculatedData(0, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
        CarbonEquivalent(HeatAllLeft, 0);
      end;}}
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'disable left.marker -> '+booltostr(left.marker));
{$ENDIF}
      SaveLog.Log(etInfo, 'end calculation left side, heat -> '+left.Heat);
    except
      on E: Exception do
        SaveLog.Log(etError, E.ClassName + ', � ����������: ' + E.Message);
    end;
    HeatAllLeft := '';
  end;

  if right.marker {and (right.ce <> '')} then
  begin
    try
      right.marker := false;
{      // ���������� ������������� ������ ������ |����� �����|�������|
      ReadSaveOldData('save', right.RollingMill, '0');}
      // ����� ����� �������
      right.step := 0;
      // ������� ��� �����������
      CalculatedData(1, '');
      SaveLog.Log(etInfo, UTF8Encode('start calculation right side, heat -> '+right.Heat));
      // start right step 0
      CalculatedData(1, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
{{      HeatAllRight := CalculatingInMechanicalCharacteristics(RolledMelting(1), 1);
      // start right step 1
      if not HeatAllRight.IsEmpty then
      begin
        CalculatedData(1, 'timestamp=DATEDIFF(s, ''1970/01/01'', GETDATE())');
        CarbonEquivalent(HeatAllRight, 1);
      end;}}
      SaveLog.Log(etInfo, UTF8Encode('end calculation right side, heat -> '+right.Heat));
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: ' + E.Message));
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
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
    end;

    while not SQueryRSOH.Eof do
    begin
       if SQueryRSOH.FieldByName('name').AsString =
          '::heat::rm'+InRollingMill+'::side'+InSide then begin
            if InSide = '0' then
               left.old_tid := SQueryRSOH.FieldByName('value').AsInteger
            else
               right.old_tid := SQueryRSOH.FieldByName('value').AsInteger;
       end;

       if SQueryRSOH.FieldByName('name').AsString =
          '::StrengthClass::rm'+InRollingMill+'::side'+InSide then begin
            if InSide = '0' then
               left.OldStrengthClass := SQueryRSOH.FieldByName('value').AsString
            else
               right.OldStrengthClass := SQueryRSOH.FieldByName('value').AsString;
       end;

       if SQueryRSOH.FieldByName('name').AsString =
          '::marker::rm'+InRollingMill+'::side'+InSide then begin
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, UTF8Encode('yes ::marker::'));
  SaveLog.Log(etDebug, UTF8Encode('marker -> '+SQueryRSOH.FieldByName('value').AsString));
{$ENDIF}}
            if InSide = '0' then
               left.marker := strtobool(SQueryRSOH.FieldByName('value').AsString);
            if InSide = '1' then
               right.marker := strtobool(SQueryRSOH.FieldByName('value').AsString);
       end;
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, UTF8Encode('RollingMill '+InRollingMill+' Side '+InSide+' left.marker -> '+booltostr(left.marker)));
  SaveLog.Log(etDebug, UTF8Encode('RollingMill '+InRollingMill+' Side '+InSide+' right.marker -> '+booltostr(right.marker)));
{$ENDIF}}
       SQueryRSOH.Next;
{{$IFDEF DEBUG}
  SaveLog.Log(etDebug, UTF8Encode('read -> '));
{$ENDIF}}
    end;
  end else begin
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::heat::rm'+InRollingMill+'::side'+InSide+''',');
        if InSide = '0' then
           SQueryRSOH.SQL.Add(''''+inttostr(left.old_tid)+''')')
        else
           SQueryRSOH.SQL.Add(''''+inttostr(right.old_tid)+''')');
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
    end;
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::StrengthClass::rm'+InRollingMill+'::side'+InSide+''',');
        if InSide = '0' then
           SQueryRSOH.SQL.Add(''''+left.OldStrengthClass+''')')
        else
           SQueryRSOH.SQL.Add(''''+right.OldStrengthClass+''')');
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
    end;
    try
        SQueryRSOH.Close;
        SQueryRSOH.SQL.Clear;
        SQueryRSOH.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
        SQueryRSOH.SQL.Add('VALUES (''::marker::rm'+InRollingMill+'::side'+InSide+''',');
        if InSide = '0' then
           SQueryRSOH.SQL.Add(''''+booltostr(left.marker)+''')')
        else
           SQueryRSOH.SQL.Add(''''+booltostr(right.marker)+''')');
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, UTF8Encode('SQueryRSOH.SQL.Text -> '+SQueryRSOH.SQL.Text));
{$ENDIF}
        SQueryRSOH.ExecSQL;
    except
      on E: Exception do
        SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
    end;
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, UTF8Encode('write -> '));
{$ENDIF}
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
        SaveLog.Log(etError, UTF8Encode(E.ClassName+', � ����������: '+E.Message));
        exit;
      end;
  end;

  //���� �������
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
  { yield point - ������ ���������
    rupture strength - ��������� ������������� }

  Grade: string; // ����� �����
  Section: string; // �������
  Standard: string; // ��������
  StrengthClass: string; // ���� ���������
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
  RawTempArray: TDoubleDynArray;
  st, HeatTmp: TStringList;
  c, mn, si, HeatMechanics, RollingMill: string;
  zx: ansistring;
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
    RollingMill := left.RollingMill;
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
    RollingMill := right.RollingMill;
  end;

  if InHeat = '' then
  begin
    SaveLog.Log(etWarning, '������� -> '+side);
    SaveLog.Log(etWarning, '������������ ������ �� ����������� ������� ��� ������� �� ������ -> '+InHeat);
    exit;
  end;

  MSQueryCalculation := TSQLQuery.Create(nil);
  MSQueryCalculation.DataBase := MSConnection;
  MSQueryCalculation.Transaction := MSTransaction;
  MSQueryData := TSQLQuery.Create(nil);
  MSQueryData.DataBase := MSConnection;
  MSQueryData.Transaction := MSTransaction;

  a := 0;
  b := a;

  HeatAll := HeatToIn(InHeat);

  try
      OraQuery.Close;
      OraQuery.SQL.Clear;
      zx:='select * from'+
'(select n.nplav heat, n.mst grade, n.GOST standard'+
',n.razm1 section, n.klass strength_class'+
',v.limtek yield_point, v.limproch rupture_strength'+
',ROW_NUMBER() OVER (PARTITION BY n.nplav ORDER BY n.data desc) AS number_row'+
' from czl_v v, czl_n n'+
' where n.data<=sysdate and n.data>=sysdate-305'+
' and n.razm1 = 8'+
' and translate(n.klass,'+
' ''����������������������'',''ETOPAHKXCBMetopahkxcbm'')'+
' like translate(''A500C'','+
' ''����������������������'',''ETOPAHKXCBMetopahkxcbm'')'+
' and n.data=v.data and v.npart=n.npart'+
' and n.npart like ''1%'''+
' and mod(n.npart,2)=1'+
' and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3'+
' and prizn=''*'' and ROWNUM <= 251'+
' and n.nplav in(''262457'',''222410'',''232158'',''222395'',''262440'',''262440'',''262441'',''252683'',''252684'',''231676'',''212130'',''212148'',''262427'',''222388'',''222394'',''262432'',''262437'',''222394'',''212149'',''262432'',''222388'',''232129'',''212148'',''212150'',''212149'',''212150'',''212147'',''222389'',''222384'',''212147'',''211803'',''232131'',''262422'',''212133'',''262425'',''262422'',''262425'',''212121'',''262320'',''212060'',''242593'',''231851'',''211932'',''212049'',''222245'',''231975'',''222237'',''222248'',''222125'',''262020'',''242210'',''211740'',''242209'',''211896'',''211876'',''211835'',''222006'',''222022'',''222122'',''242423'',''242424'',''222025'',''222036'',''222042'',''231803'',''222021'',''231803'',''262164'',''222010'',''222107'',''222107'',''222004'',''211884'',''211816'',''262164'',''262050'',''222100'',''252296'',''262139'',''211894'',''222097'',''231795'',''231795'',''222093'',''231799'',''262138'',''211894'',''231799'',''222011'',''262138'',''211890'',''211822'',''211890'',''231789'',''262139'',''231787'',''231780'',''222088'',''231742'',''211824'',''231775'',''222088'',''231772'',''222007'',''222081'',''231769'',''222009'',''231764'',''242293'',''231764'',''242355'',''231748'',''262049'',''242355'',''252327'',''242352'',''242353'',''242352'',''262017'',''252326'',''222063'',''252321'',''252320'',''222057'',''222059'')'+
' order by n.data desc)'+
' where number_row <= 3';
{      OraQuery.SQL.Add('select * from');
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
      OraQuery.SQL.Add('and n.npart like '''+RollingMill+'%'''); // ����� �����
      if InSide = 0  then
        OraQuery.SQL.Add('and mod(n.npart,2)=1')// �������� �� �������� | 0 ������ - ����� | 1 - �������� ������
      else
        OraQuery.SQL.Add('and mod(n.npart,2)=0');// �������� �� �������� | 0 ������ - ����� | 1 - �������� ������
      if (StrengthClass = 'S400') or (StrengthClass = 'S400W') then // ������ ��� ������� ������� �� 15 ����
        OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=15')
      else
        OraQuery.SQL.Add('and nvl(n.npach,0)=nvl(v.npach,0) and NI<=3');
      OraQuery.SQL.Add('and prizn=''*'' and ROWNUM <= 251');
      OraQuery.SQL.Add('and n.nplav in('+HeatAll+')');
      OraQuery.SQL.Add('order by n.data desc)');
      OraQuery.SQL.Add('where number_row <= 3');}
      OraQuery.SQL.Text := zx;
      OraQuery.Open;
      OraQuery.FetchAll;
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', � ����������: '+E.Message);
  end;

{$IFDEF DEBUG }
  SaveLog.Log(etDebug, 'OraQuery.SQL.Text -> '+OraQuery.SQL.Text);
  SaveLog.Log(etDebug, 'OraQuery.RecordCount -> '+inttostr(OraQuery.RecordCount));
{$ENDIF}

while not OraQuery.Eof do
begin
       SaveLog.Log(etDebug, 'STANDARD  '+OraQuery.FieldByName('STANDARD').AsString);
  OraQuery.Next;
end;
exit;
{
  if OraQuery.RecordCount < 5 then
  begin
    SaveLog.Log(etWarning, UTF8Encode('������� -> '+side));
    SaveLog.Log(etWarning, UTF8Encode('������������ ������ ��� ������� �� ������� -> '+HeatAll));
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
      SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
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
  SaveLog.Log(etDebug, UTF8Encode('CoefficientCount -> ' + inttostr(CoefficientCount)));
  SaveLog.Log(etDebug, UTF8Encode('CoefficientYieldPointValue -> ' + floattostr(CoefficientYieldPointValue)));
  SaveLog.Log(etDebug, UTF8Encode('CoefficientRuptureStrengthValue -> ' + floattostr(CoefficientRuptureStrengthValue)));
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
      SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
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
              SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
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
      SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
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
  SaveLog.Log(etDebug, UTF8Encode('HeatAll to works -> ' + HeatAll));
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
      SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
  end;

  if PQueryData.FieldByName('limit_min').IsNull then
  begin
    SaveLog.Log(etWarning, UTF8Encode('������� -> '+side));
    SaveLog.Log(etWarning, UTF8Encode('������������ ������ �� ��������������� ���������� ��� -> '+InHeat));
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
  SaveLog.Log(etDebug, UTF8Encode('LimitRolledProductsMin -> '+inttostr(LimitRolledProductsMin)));
  SaveLog.Log(etDebug, UTF8Encode('LimitRolledProductsMax -> '+inttostr(LimitRolledProductsMax)));
  SaveLog.Log(etDebug, UTF8Encode('TypeRolledProducts -> ' + TypeRolledProducts));
  SaveLog.Log(etDebug, UTF8Encode('RolledProducts RecordCount -> '+inttostr(SQuery.RecordCount)));
{$ENDIF}

  try
      SQuery.Close;
      SQuery.sql.Clear;
      SQuery.sql.Add('SELECT * FROM mechanics');
      SQuery.sql.Add('where side=' + inttostr(InSide) + '');
      SQuery.Open;
  except
    on E: Exception do
      SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: '+E.Message));
  end;

  if SQuery.RecordCount < 1 then
  begin
    SaveLog.Log(etWarning, UTF8Encode('������� -> '+side));
    SaveLog.Log(etWarning, UTF8Encode('������������ ������ �� ���. ���������� ��� ������� �� ������� -> '+HeatAll));
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
  SaveLog.Log(etDebug, UTF8Encode('MechanicsAvg -> ' + floattostr(MechanicsAvg)));
  SaveLog.Log(etDebug, UTF8Encode('MechanicsStdDev -> ' + floattostr(MechanicsStdDev)));
  SaveLog.Log(etDebug, UTF8Encode('MechanicsMin -> ' + floattostr(MechanicsMin)));
  SaveLog.Log(etDebug, UTF8Encode('MechanicsMax -> ' + floattostr(MechanicsMax)));
  SaveLog.Log(etDebug, UTF8Encode('MechanicsDiff -> ' + floattostr(MechanicsDiff)));
  SaveLog.Log(etDebug, UTF8Encode('CoefficientMin -> ' + floattostr(CoefficientMin)));
  SaveLog.Log(etDebug, UTF8Encode('CoefficientMax -> ' + floattostr(CoefficientMax)));
  SaveLog.Log(etDebug, UTF8Encode('Section -> ' + Section));
  SaveLog.Log(etDebug, UTF8Encode('RollingScheme -> ' + RollingScheme));
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
      PQueryCalculation.sql.Add('inner JOIN');
      PQueryCalculation.sql.Add('temperature_historical t4');
      PQueryCalculation.sql.Add('on t1.tid=t4.tid');
      PQueryCalculation.sql.Add('where t1.timestamp<=EXTRACT(EPOCH FROM now())');
      PQueryCalculation.sql.Add('and t1.timestamp>=EXTRACT(EPOCH FROM now())-(2629743*10)');
      PQueryCalculation.sql.Add('and t2.heat in ('+HeatAll+')');
      PQueryCalculation.sql.Add('and translate(t3.strength_class,');
      PQueryCalculation.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
      PQueryCalculation.sql.Add('like translate('''+StrengthClass+''',');
      PQueryCalculation.sql.Add('''����������������������'',''ETOPAHKXCBMetopahkxcbm'')');
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
      SaveLog.Log(etError, UTF8Encode(E.ClassName + ', � ����������: ' + E.Message));
  end;

{$IFDEF DEBUG}
  SaveLog.Log(etDebug, UTF8Encode('PQueryCalculation.SQL.Text -> ' + PQueryCalculation.sql.Text));
{$ENDIF}

  if PQueryCalculation.RecordCount < 1 then
  begin
    SaveLog.Log(etWarning, UTF8Encode('������� -> '+side));
    SaveLog.Log(etWarning, UTF8Encode('������������ ������ �� ����������� ��� ������� �� ������� -> '+HeatAll));
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
  SaveLog.Log(etDebug, UTF8Encode('count temperature all -> ' + inttostr(i)));
  SaveLog.Log(etDebug, UTF8Encode('count temperature median -> ' + inttostr(b)));
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
  SaveLog.Log(etDebug, UTF8Encode('TempAvg -> ' + floattostr(TempAvg)));
  SaveLog.Log(etDebug, UTF8Encode('TempStdDev -> ' + floattostr(TempStdDev)));
  SaveLog.Log(etDebug, UTF8Encode('TempMin -> ' + floattostr(TempMin)));
  SaveLog.Log(etDebug, UTF8Encode('TempMax -> ' + floattostr(TempMax)));
  SaveLog.Log(etDebug, UTF8Encode('TempDiff -> ' + floattostr(TempDiff)));
  SaveLog.Log(etDebug, UTF8Encode('R -> ' + floattostr(R)));
  SaveLog.Log(etDebug, UTF8Encode('AdjustmentMin -> ' + inttostr(AdjustmentMin)));
  SaveLog.Log(etDebug, UTF8Encode('AdjustmentMax -> ' + inttostr(AdjustmentMax)));
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
      SaveLog.Log(etDebug, UTF8Encode('LowRedLeft -> ' + inttostr(left.LowRed)));
      SaveLog.Log(etDebug, UTF8Encode('HighRedLeft -> ' + inttostr(left.HighRed)));
      SaveLog.Log(etDebug, UTF8Encode('left.step first -> ' + inttostr(left.step)));
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
      SaveLog.Log(etDebug, UTF8Encode('LowGreenLeft -> ' + inttostr(left.LowGreen)));
      SaveLog.Log(etDebug, UTF8Encode('HighGreenLeft -> ' + inttostr(left.HighGreen)));
      SaveLog.Log(etDebug, UTF8Encode('left.step last -> ' + inttostr(left.step)));
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
      SaveLog.Log(etDebug, UTF8Encode('LowRedRight -> ' + inttostr(right.LowRed)));
      SaveLog.Log(etDebug, UTF8Encode('HighRedRight -> ' + inttostr(right.HighRed)));
      SaveLog.Log(etDebug, UTF8Encode('right.step first -> ' + inttostr(right.step)));
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
    SaveLog.Log(etDebug, UTF8Encode('LowGreenRight -> ' + inttostr(right.LowGreen)));
    SaveLog.Log(etDebug, UTF8Encode('HighGreenRight -> ' + inttostr(right.HighGreen)));
    SaveLog.Log(etDebug, UTF8Encode('right.step last -> ' + inttostr(right.step)));
{$ENDIF}
//      right.step := 0; // ����� ����� ��������� � ������
      // ���������� ������ �� ������� ������������� ������
      Result := HeatAll;
      exit;
    end;}
end;

{{
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
}}

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

{{
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
}}

constructor TIdHeat.Create;
begin
    tid              := 0;
    Heat             := ''; // ������
    Grade            := ''; // ����� �����
    Section          := ''; // �������
    Standard         := ''; // ��������
    StrengthClass    := ''; // ���� ���������
    c                := '';
    mn               := '';
    cr               := '';
    si               := '';
    b                := '';
    ce               := '';
    OldStrengthClass := ''; // ������ ���� ���������
    old_tid          := 0; // ����� ������
    RollingMill      := '';
//    marker           := false;
    LowRed           := 0;
    HighRed          := 0;
    LowGreen         := 0;
    HighGreen        := 0;
    step             := 0;
end;


// ��� �������� ��������� ����� ����� �����������
initialization
left := TIdHeat.Create;
right := TIdHeat.Create;

// ��� �������� ��������� ������������
finalization
FreeAndNil(left);
FreeAndNil(right);

end.
