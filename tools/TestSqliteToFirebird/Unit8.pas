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
    procedure Button1Click(Sender: TObject);
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

  function SqliteToFirebird: bool;

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
        pFIBDatabase1.LibraryName := '.\fbclient.dll';
        pFIBDatabase1.DBName := '10.21.69.21:c:\tmp\mc_250-5\Ms5db6.fdb';
        pFIBDatabase1.ConnectParams.UserName := 'sysdba';
        pFIBDatabase1.ConnectParams.Password := 'testing';
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
      Button1.Caption := 'start';
      SqliteToFirebird;
      start := true;
    end
    else
      begin
        pFIBDatabase1.Free;
        FQueryOPC.Free;
        pFIBTransaction1.Free;
        Button1.Caption := 'stop';
        start := false;
      end;
end;




procedure TForm8.FormCreate(Sender: TObject);
begin
  Button1.Caption := 'stop';
end;

function SqliteToFirebird: bool;
var
  i: integer;
  f:textfile; s: string;
  l:textfile;
  str: TStrings;
begin

 AssignFile(f, 'Export.csv');
  reset(f);
 // AssignFile(l, 'log.txt');
//  Append(l);
  try
    while not eof(f) do
    begin
    readln(f, s);
      if not s.IsEmpty then
      begin
        try
          str := TStringList.Create;
          str.Text := StringReplace(s,';',#13#10,[rfReplaceAll]);

//            for i:=0 to str.Count-1 do
//              showmessage(str.strings[i]+' count = '+inttostr(i) );

      try
        FQueryOPC.Close;
        FQueryOPC.SQL.Clear;
        FQueryOPC.SQL.Add('insert INTO qc_temperature');
        FQueryOPC.SQL.Add('(id, datetime, heat, grade, strength_class, section, standard, side, temperature)');
        FQueryOPC.SQL.Add('values( GEN_ID(gen_qc_temperature, 1), current_timestamp,');
        FQueryOPC.SQL.Add(''''+str.strings[2]+''',');
        FQueryOPC.SQL.Add(''''+str.strings[3]+''', '''+str.strings[4]+''',');
        FQueryOPC.SQL.Add(''+str.strings[5]+', '''+str.strings[6]+''',');
        FQueryOPC.SQL.Add(''+str.strings[7]+',');
        FQueryOPC.SQL.Add(''+str.strings[8]+')');
//      showmessage(FQueryOPC.SQL.Text);
        FQueryOPC.ExecQuery;
        FQueryOPC.Transaction.Commit;
      except
        on E: Exception do
            showmessage('error: '+E.ClassName+', с сообщением:' + E.Message);
      end;

          str.Destroy;

        except
            on E: Exception do
        //      writeln(l,'debug'+#9#9+'error -> '+s);
        end;
      //  writeln(l,'debug'+#9#9+'sql -> '+s);
      end;
//    exit;
    end;
  except
    on E: Exception do
 //     writeln(l,'debug'+#9#9+'error -> '+s);
  end;

  closefile(f);
 // closefile(l);


  showmessage('end');

end;

end.
