unit Unit9;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Types, Generics.Collections;

type
  TForm9 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
//    Edit1: TEdit;
  //  Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form9: TForm9;

  function Mediana(aArray: TDoubleDynArray): Double;

implementation

{$R *.dfm}

procedure TForm9.Button1Click(Sender: TObject);
var
aaa: TDoubleDynArray;
i: integer;
begin
SetLength(aaa, 7);
aaa[0] := 417;
aaa[1] := 428;
aaa[2] := 435;
aaa[3] := 333;
aaa[4] := 427;
aaa[5] := 423;
aaa[6] := 421;

{ aaa[0] := 425;
 aaa[1] := 423;
 aaa[2] := 431;
 aaa[3] := 426;
 aaa[4] := 425;
 }
 for I := 0 to High(aaa) do
 begin
    edit1.Text := inttostr(i)+' - '+FloatToStr(aaa[i]);
//    sleep(1000);
 end;
//exit;
edit1.Text := FloatToStr(Mediana(aaa))+' == ';
//  edit1.Text := FloatToStr(Mediana(TDoubleDynArray.Create(425,423,431,426,425)));
//  Writeln(Median(TDoubleDynArray.Create(4.1, 5.6, 7.2, 1.7, 9.3, 4.4, 3.2)));
//  Writeln(Median(TDoubleDynArray.Create(4.1, 7.2, 1.7, 9.3, 4.4, 3.2)));
end;

function Mediana(aArray: TDoubleDynArray): Double;
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

end.
