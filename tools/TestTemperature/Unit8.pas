unit Unit8;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FIB, FIBQuery, pFIBQuery, FIBDatabase,
  pFIBDatabase, pFIBErrorHandler, Data.DB, FIBDataSet, pFIBDataSet, Vcl.StdCtrls,
  Vcl.ExtCtrls, Math;

type
  TForm8 = class(TForm)
    Button1: TButton;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form8: TForm8;
  pFIBDatabase1: TpFIBDatabase;
  FQueryOPC: TFIBQuery;
  pFIBTransaction1: TpFIBTransaction;
  start: bool = false;

implementation

{$R *.dfm}

procedure TForm8.Button1Click(Sender: TObject);
begin
    if start = false then
    begin
       try
        pFIBDatabase1 := TpFIBDatabase.Create(nil);
        FQueryOPC := TpFIBQuery.Create(nil);
        pFIBTransaction1 := TpFIBTransaction.Create(nil);
        pFIBTransaction1.DefaultDatabase := pFIBDatabase1;
        FQueryOPC.Database := pFIBDatabase1;
        FQueryOPC.Transaction := pFIBTransaction1;
        pFIBDatabase1.Connected := false;
        pFIBDatabase1.LibraryName := 'C:\tmp\qc_rolling_mill.git\install\fbclient.dll';
        pFIBDatabase1.DBName := 'localhost:C:\tmp\mc_250-5\MS5DB6.FDB';
        pFIBDatabase1.ConnectParams.UserName := 'sysdba';
        pFIBDatabase1.ConnectParams.Password := 'masterkey';
        pFIBDatabase1.ConnectParams.CharSet := 'NONE';// 'UNICODE_FSS';//'UTF8';//'ASCII';//'WIN1251';
        pFIBDatabase1.SQLDialect := 3;
        pFIBDatabase1.UseLoginPrompt := false;
        pFIBDatabase1.Timeout := 0;
        pFIBDatabase1.Connected := true;
        pFIBDatabase1.AutoReconnect := true;
        pFIBTransaction1.Active := false;
        pFIBTransaction1.Timeout := 0;
      except
        on E: Exception do
            showmessage('error: '+E.ClassName+', с сообщением:' + E.Message);
      end;
      timer1.Enabled := true;
      Button1.Caption := 'start';
      start := true;
    end
    else
      begin
        pFIBDatabase1.Free;
        FQueryOPC.Free;
        pFIBTransaction1.Free;
        timer1.Enabled := false;
        Button1.Caption := 'stop';
        start := false;
      end;
end;




procedure TForm8.FormCreate(Sender: TObject);
begin
  Button1.Caption := 'stop';
end;

procedure TForm8.Timer1Timer(Sender: TObject);
var
  i, Temperature, InTempLeft, InTempRight: integer;
begin
  try
      // чистим таблицу от старых данных
      FQueryOPC.Close;
      FQueryOPC.SQL.Clear;
      // удаляем записи старше 10 месяцев (300 дней)
      FQueryOPC.SQL.Add('DELETE FROM qc_temperature where');
      FQueryOPC.SQL.Add('datetime < current_timestamp-300');
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.Commit;
  except
    on E: Exception do
            showmessage('error: '+E.ClassName+', с сообщением:' + E.Message);
  end;

  InTempLeft := RandomRange(251, 1300);
  InTempRight := RandomRange(251, 1300);

  for i := 0 to 1 do
  begin
    if i=0 then
      Temperature := InTempLeft;
    if i=1 then
      Temperature := InTempRight;

    if Temperature > 250 then
    begin
      try
        FQueryOPC.Close;
        FQueryOPC.SQL.Clear;
        FQueryOPC.SQL.Add('insert INTO qc_temperature');
        FQueryOPC.SQL.Add('(id, datetime, heat, grade, strength_class, section, standard, side, temperature)');
        FQueryOPC.SQL.Add('select FIRST 1 GEN_ID(gen_qc_temperature, 1), current_timestamp,');
        FQueryOPC.SQL.Add('NOPLAV, MARKA, KLASS, RAZM1, STANDART, SIDE,');
        FQueryOPC.SQL.Add(''+inttostr(Temperature)+'');
        FQueryOPC.SQL.Add('FROM melts');
        FQueryOPC.SQL.Add('where side='+inttostr(i)+'');
        FQueryOPC.SQL.Add('order by begindt desc');
        FQueryOPC.ExecQuery;
        FQueryOPC.Transaction.Commit;
      except
        on E: Exception do
            showmessage('error: '+E.ClassName+', с сообщением:' + E.Message);
      end;
    end;
  end;
end;

end.
