unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FIB, FIBQuery, pFIBQuery, FIBDatabase,
  pFIBDatabase, pFIBErrorHandler, Data.DB, FIBDataSet, pFIBDataSet, Vcl.StdCtrls,
  Ora;

type
  TForm8 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
  CurrentDir: string;
  DBFile: string = 'data.sdb';
  LogFile: string = 'app.log';
  OraSession1: TOraSession;
  OraQuery1: TOraQuery;

implementation

uses
  settings, logging;

{$R *.dfm}

procedure TForm8.Button1Click(Sender: TObject);
begin

showmessage('1 -> '+FbSqlConfigArray[1]+#9+'2 -> '+FbSqlConfigArray[2]+#9+
'3 -> '+FbSqlConfigArray[3]+#9+'4 -> '+FbSqlConfigArray[4]);

  try
    pFIBDatabase1 := TpFIBDatabase.Create(nil);
    FQueryOPC := TpFIBQuery.Create(nil);
    pFIBTransaction1 := TpFIBTransaction.Create(nil);
    pFIBDatabase1.DefaultTransaction := pFIBTransaction1;
    pFIBDatabase1.DefaultUpdateTransaction := pFIBTransaction1;
    pFIBTransaction1.DefaultDatabase := pFIBDatabase1;
    FQueryOPC.Database := pFIBDatabase1;
    FQueryOPC.Transaction := pFIBTransaction1;
    pFIBDatabase1.Connected := false;
    pFIBDatabase1.LibraryName := '.\' + FbSqlConfigArray[3];
    pFIBDatabase1.DBName := FbSqlConfigArray[1] + ':' + FbSqlConfigArray[2];
    pFIBDatabase1.ConnectParams.UserName := FbSqlConfigArray[5];
    pFIBDatabase1.ConnectParams.Password := FbSqlConfigArray[6];
    pFIBDatabase1.ConnectParams.CharSet := 'NONE';// 'UNICODE_FSS';//'UTF8';//'ASCII';//'WIN1251';
    pFIBDatabase1.SQLDialect := strtoint(FbSqlConfigArray[4]);
    pFIBDatabase1.UseLoginPrompt := false;
    pFIBDatabase1.Timeout := 0;
    pFIBDatabase1.Connected := true;
    pFIBTransaction1.Active := false;
    pFIBTransaction1.Timeout := 0;
  except
    on E: Exception do
      SaveLog('error' + #9#9 + E.ClassName + ', � ����������: ' + E.Message);
  end;



  FQueryOPC.Close;
  FQueryOPC.SQL.Clear;
  FQueryOPC.SQL.Add('EXECUTE BLOCK AS BEGIN');
  FQueryOPC.SQL.Add('if (not exists(select 1 from rdb$relations where rdb$relation_name = ''qc_temperature'')) then');
  FQueryOPC.SQL.Add('execute statement ''create table qc_temperature (');
  FQueryOPC.SQL.Add('id NUMERIC(18,0) NOT NULL, datetime TIMESTAMP NOT NULL,');
  FQueryOPC.SQL.Add('heat VARCHAR(26) NOT NULL, grade VARCHAR(50),');
  FQueryOPC.SQL.Add('strength_class VARCHAR(50), section VARCHAR(50),');
  FQueryOPC.SQL.Add('standard VARCHAR(50), side integer NOT NULL, temperature integer,');
  FQueryOPC.SQL.Add('PRIMARY KEY (id));'';');
  FQueryOPC.SQL.Add('execute statement ''CREATE SEQUENCE gen_qc_temperature;'';');
  FQueryOPC.SQL.Add('END');

//  showmessage(FQueryOPC.SQL.text);
      FQueryOPC.Transaction.Active := True;
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.commit;

      FQueryOPC.Close;
      FQueryOPC.SQL.Clear;
      FQueryOPC.SQL.Add('insert INTO qc_temperature');
      FQueryOPC.SQL.Add('(id, datetime, heat, grade, strength_class, section, standard, side, temperature)');
      FQueryOPC.SQL.Add('select FIRST 1 GEN_ID(gen_qc_temperature, 1), current_timestamp,');
      FQueryOPC.SQL.Add('NOPLAV, MARKA, KLASS, RAZM1, STANDART, SIDE,');
      FQueryOPC.SQL.Add('20200');
      FQueryOPC.SQL.Add('FROM melts');
      FQueryOPC.SQL.Add('where side=0');
      FQueryOPC.SQL.Add('order by begindt desc');
{$IFDEF DEBUG}
  SaveLog('debug' + #9#9 + 'FQueryOPC.SQL.Text -> ' + FQueryOPC.SQL.Text);
{$ENDIF}
      FQueryOPC.Transaction.Active := True;
      FQueryOPC.ExecQuery;
      FQueryOPC.Transaction.commit;

    pFIBDatabase1.Free;
    FQueryOPC.Free;
    pFIBTransaction1.Free;
end;

procedure TForm8.Button2Click(Sender: TObject);
var msg: string;
begin
  OraSession1 := TOraSession.Create(nil);
  OraQuery1 := TOraQuery.Create(nil);
  OraSession1.Username := OraSqlConfigArray[4];
  OraSession1.Password := OraSqlConfigArray[5];
  OraSession1.Server := OraSqlConfigArray[1]+':'+OraSqlConfigArray[2]+
                                    ':'+OraSqlConfigArray[3];//'krr-sql13:1521:ovp68';
  OraSession1.Options.Direct := true;
  OraSession1.Options.DateFormat := 'DD.MM.RR';//������ ���� ��.��.��
  OraSession1.Options.Charset := 'CL8MSWIN1251';// 'AL32UTF8';//CL8MSWIN1251
//  OraSession1.Options.UseUnicode := true;

 OraQuery1.FetchAll := true;
 OraQuery1.Close;
 OraQuery1.SQL.Clear;
 OraQuery1.SQL.Add('select TO_CHAR(DATE_IN_HIM, ''YYYY-MM-DD'') as DATE_IN_HIM');
 OraQuery1.SQL.Add(', NPL, MST, GOST, C, MN, SI, S, CR, B from him_steel');
 OraQuery1.SQL.Add('where DATE_IN_HIM>=sysdate-305'); //-- 305 = 10 month
 OraQuery1.SQL.Add('and NUMBER_TEST=''0''');
// OraQuery1.SQL.Add('and NPL in ('''+InHeat+''')');
 OraQuery1.SQL.Add('order by DATE_IN_HIM desc');
 OraQuery1.Open;

           msg := OraQuery1.FieldByName('DATE_IN_HIM').AsString+'|'+
                 OraQuery1.FieldByName('NPL').AsString+'|'+
                 OraQuery1.FieldByName('MST').AsString+'|'+
                 OraQuery1.FieldByName('GOST').AsString+'|'+
                 OraQuery1.FieldByName('C').AsString+'|'+
                 OraQuery1.FieldByName('MN').AsString+'|'+
                 OraQuery1.FieldByName('SI').AsString;

showmessage(msg);

  OraSession1.Free;
  OraQuery1.Free;
end;

procedure TForm8.FormCreate(Sender: TObject);
begin

  CurrentDir :=getCurrentDir;

end;

end.
