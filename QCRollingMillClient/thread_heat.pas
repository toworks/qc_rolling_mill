unit thread_heat;

interface

uses
  SysUtils, Classes, SyncObjs;

type
  TThreadHeat = class(TThread)

  private
{    procedure ReadSql;
    procedure ReadSqlOld;
    procedure ViewTemp;}
  protected
    procedure Execute; override;
  public
    Constructor Create; overload;
    Destructor Destroy; override;
  end;


  TIdHeat = Class
    tid                      : integer;
    Heat                     : string[26]; // плавка
    Grade                    : string[50]; // марка стали
    Section                  : string[50]; // профиль
    Standard                 : string[50]; // стандарт
    StrengthClass            : string[50]; // клас прочности
    c                        : string[50];
    mn                       : string[50];
    cr                       : string[50];
    si                       : string[50];
    b                        : string[50];
    ce                       : string[50];
    ce_category              : string[10];
    OldStrengthClass         : string[50]; // старый клас прочности
    old_tid                  : integer; // стара плавка
    RollingMill              : string[1];
    marker                   : integer;
    temperature              : integer;
    LowRed                   : integer;
    HighRed                  : integer;
    LowGreen                 : integer;
    HighGreen                : integer;
    step                     : smallint;
    technological_sample     : integer;
    count                    : smallint;
    OldTemperature           : smallint;
    constructor Create;
  end;

var
  ThreadHeat: TThreadHeat;
  CriticalSectionHeat: TCriticalSection;
  left: TIdHeat;
  right: TIdHeat;

//  {$DEFINE DEBUG}

  function GetCurrentDataLeft: boolean;
  function GetCurrentDataRight: boolean;
  function ClearData(InSide: TIdHeat): boolean;


implementation

uses
  settings, gui, sql, thread_main;


constructor TThreadHeat.Create;
begin
  inherited;
  CriticalSectionHeat := TCriticalSection.Create;
  // создаем поток True - создание остановка, False - создание старт
  ThreadHeat := TThreadHeat.Create(True);
  ThreadHeat.Priority := tpNormal;
  ThreadHeat.FreeOnTerminate := True;
  ThreadHeat.Start;
end;


destructor TThreadHeat.Destroy;
begin
  if ThreadHeat <> nil then begin
    ThreadHeat.Terminate;
    CriticalSectionHeat.Destroy;
  end;
  inherited Destroy;
end;


procedure TThreadHeat.Execute;
var i: integer;
begin
  i := 0;
  SaveLog.Log(etInfo, 'thread heat execute');
  try
    repeat
      Sleep(1000); //milliseconds
 {$IFDEF DEBUG}
   inc(i);
   SaveLog.Log(etDebug, 'thread heat loop ' + Format('tick :%d', [i]));
 {$ENDIF}
    CriticalSectionHeat.Enter;
    try
         //reconnect
         ConfigMsSetting(false);

         if not MsSqlSettings.configured then
           ConfigMsSetting(true);
         if not OraSqlSettings.configured then
           ConfigOracleSetting(true);

         if MsSqlSettings.configured and OraSqlSettings.configured then begin
            SqlGetCurrentHeat;
            GetCurrentDataLeft;
            GetCurrentDataRight;
         end;
     except
       on E: Exception do
         SaveLog.Log(etError, E.ClassName+', с сообщением: '+E.Message);
     end;
     CriticalSectionHeat.Leave;

    until Terminated;
    SaveLog.Log(etInfo, 'tread heat loop stopped');
  except
    on E: Exception do
      SaveLog.Log(etError, E.ClassName + ', с сообщением: '+E.Message);
  end;
end;


function GetCurrentDataLeft: boolean;
const
  side: integer = 0;
begin
  SqlCurrentData(side);

  // читаем идентификатор старой плавки |номер стана|сторона|
  ReadSaveOldData('read', rolling_mill, inttostr(side));

  // новая плавка устанавливаем маркер
  if left.old_tid <> left.tid  then
  begin
     left.old_tid := left.tid;
     left.marker := 1;
     ClearData(left);
     // химия
     GetChemicalAnalysis(left.Heat, side);
     // записываем идентификатор старой плавки |номер стана|сторона|
     ReadSaveOldData('save', rolling_mill, inttostr(side));

     ShowTrayMessage('информация','новая плавка: '+left.Heat,1);
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'enable left.marker -> '+inttostr(left.marker));
{$ENDIF}
  end else begin
     left.marker := 0;
     ReadSaveOldData('save', rolling_mill, inttostr(side));
  end;

  if left.c = '' then
    // химия при перезапуске сервиса
    GetChemicalAnalysis(left.Heat, side);
end;


function GetCurrentDataRight: boolean;
const
  side: integer = 1;
begin
  SqlCurrentData(side);

  // читаем идентификатор старой плавки |номер стана|сторона|
  ReadSaveOldData('read', rolling_mill, inttostr(side));

  // новая плавка устанавливаем маркер
  if right.old_tid <> right.tid  then
  begin
     right.old_tid := right.tid;
     right.marker := 1;
     ClearData(right);
     // химия
     GetChemicalAnalysis(right.Heat, side);
     // записываем идентификатор старой плавки |номер стана|сторона|
     ReadSaveOldData('save', rolling_mill, inttostr(side));

     ShowTrayMessage('информация','новая плавка: '+right.Heat,1);
{$IFDEF DEBUG}
  SaveLog.Log(etDebug, 'enable right.marker -> '+inttostr(right.marker));
{$ENDIF}
  end else begin
     right.marker := 0;
     ReadSaveOldData('save', rolling_mill, inttostr(side));
  end;

  if right.c = '' then
    // химия при перезапуске сервиса
    GetChemicalAnalysis(right.Heat, side);
end;


function ClearData(InSide: TIdHeat): boolean;
begin
     InSide.LowRed := 0;
     InSide.HighRed := 0;
     InSide.LowGreen := 0;
     InSide.HighGreen := 0;

     InSide.Heat := '';
     InSide.Grade := '';
     InSide.StrengthClass := '';
     InSide.Section := '';
     InSide.Standard := '';

     InSide.c := '';
     InSide.mn := '';
     InSide.si := '';
     InSide.cr := '';
     InSide.b := '';
     InSide.ce := '';
     InSide.ce_category := '';
end;


constructor TIdHeat.Create;
begin
    tid                      := 0;
    Heat                     := ''; // плавка
    Grade                    := ''; // марка стали
    Section                  := ''; // профиль
    Standard                 := ''; // стандарт
    StrengthClass            := ''; // клас прочности
    c                        := '';
    mn                       := '';
    cr                       := '';
    si                       := '';
    b                        := '';
    ce                       := '';
    ce_category              := '';
    OldStrengthClass         := ''; // старый клас прочности
    old_tid                  := 0; // стара плавка
    RollingMill              := '';
    marker                   := 0;
    temperature              := 0;
    LowRed                   := 0;
    HighRed                  := 0;
    LowGreen                 := 0;
    HighGreen                := 0;
    step                     := 0;
    technological_sample     := -1;
    count                    := 0;
    OldTemperature           := 0;
end;


// При загрузке программы класс будет создаватьс¤
initialization
ThreadHeat := TThreadHeat.Create;
left := TIdHeat.Create;
right := TIdHeat.Create;


// При закрытии программы уничтожатьс¤
finalization
ThreadHeat.Destroy;
FreeAndNil(left);
FreeAndNil(right);


end.
