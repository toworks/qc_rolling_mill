unit tcp_send_read;

interface

uses
  SysUtils, Classes, Windows, ActiveX, IdContext, IdCustomTCPServer,
  IdTCPServer, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient;

type
  TTcpWorks = class
  procedure IdTCPServerExecute(AContext: TIdContext);

  private
    { Private declarations }
  protected

  end;

var
   TcpWorks: TTcpWorks;
   IdTCPServer: TIdTCPServer;
   IdTCPClient: TIdTCPClient;

   //id ��� ������������� ���������
   IdMsg: string = 'Q0yiEOEf3QHdlmhxQFCFif7ArgmzQsdxqZvLl2r5KL4kebXx1BykPfaGzzVhCNFCYlRiTLtGWhcEFOte7Nl9X5rSfDUBbGeYyseW';

   {$DEFINE DEBUG}

   function TcpConfig(InData: bool): bool;
   function GetChemicalAnalysis(InHeat: string): bool;
   function ReplaceComa(InData: string): string;
   function SendChemicalAnalysis(InData: string): bool;



implementation

uses
  main, settings, logging;



function TcpConfig(InData: bool): bool;
begin
  if InData then
   begin
    try
        IdTCPServer := TIdTCPServer.Create(nil);
        IdTCPServer.Bindings.Add.IP := '0.0.0.0';
        IdTCPServer.Bindings.Add.Port := strtoint(TcpConfigArray[2]);
        IdTCPServer.DefaultPort := strtoint(TcpConfigArray[2]);
        IdTCPServer.OnExecute := TcpWorks.IdTCPServerExecute;
        IdTCPServer.Active := true;

        IdTCPClient := TIdTCPClient.Create(nil);
        IdTCPClient.Host := TcpConfigArray[1];
        IdTCPClient.Port := strtoint(TcpConfigArray[2]);

        SaveLog('tcp'+#9#9+'start');

    except
      on E : Exception do
        SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
    end;
   end
  else
   begin
    try
        IdTCPServer.Active := false;
        IdTCPClient.Free;
        SaveLog('tcp'+#9#9+'stop');
    except
      on E : Exception do
        SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
    end;
   end;
end;


procedure TTcpWorks.IdTCPServerExecute(AContext: TIdContext);
var
  stream: TStringStream;
  msg: string;
begin
  try
      stream := TStringStream.Create;
      AContext.Connection.IOHandler.ReadStream(stream); //������ �� ��������� � �����
      stream.Position := 0;  //��������� ������� �� ������ ������
      msg := stream.ReadString(stream.Size);
  finally
    	stream.Free;
  end;


  if  AnsiPos(IdMsg, msg) <> 0 then
  begin
      msg := StringReplace(msg, IdMsg, '', [rfReplaceAll]);
      SaveLog('tcp'+#9#9+'receive'+#9+'heat -> '+msg);
      GetChemicalAnalysis(msg);
  end;
end;


function GetChemicalAnalysis(InHeat: string): bool;
var
  msg: string;
begin
  try
      form1.OraQuery1.FetchAll := true;
      form1.OraQuery1.Close;
      form1.OraQuery1.SQL.Clear;
      form1.OraQuery1.SQL.Add('select TO_CHAR(DATE_IN_HIM, ''YYYY-MM-DD'') as DATE_IN_HIM');
      form1.OraQuery1.SQL.Add(', NPL, MST, GOST, C, MN, SI, S, CR, B from him_steel');
      form1.OraQuery1.SQL.Add('where DATE_IN_HIM>=sysdate-305'); //-- 305 = 10 month
      form1.OraQuery1.SQL.Add('and NUMBER_TEST=''0''');
      form1.OraQuery1.SQL.Add('and NPL in ('''+InHeat+''')');
      form1.OraQuery1.SQL.Add('order by DATE_IN_HIM desc');
      form1.OraQuery1.Open;

      //���� �� ������� ���� �e��
      if form1.OraQuery1.FieldByName('NPL').AsString <> '' then
       begin
          msg := form1.OraQuery1.FieldByName('DATE_IN_HIM').AsString+'|'+
                 form1.OraQuery1.FieldByName('NPL').AsString+'|'+
                 form1.OraQuery1.FieldByName('MST').AsString+'|'+
                 form1.OraQuery1.FieldByName('GOST').AsString+'|'+
                 ReplaceComa(form1.OraQuery1.FieldByName('C').AsString)+'|'+
                 ReplaceComa(form1.OraQuery1.FieldByName('MN').AsString)+'|'+
                 ReplaceComa(form1.OraQuery1.FieldByName('SI').AsString)+'|'+
                 ReplaceComa(form1.OraQuery1.FieldByName('S').AsString)+'|'+
                 ReplaceComa(form1.OraQuery1.FieldByName('CR').AsString)+'|'+
                 ReplaceComa(form1.OraQuery1.FieldByName('B').AsString);
       end
      else
       begin
          msg := '0000-00-00'+'|'+
                 InHeat+'|'+
                 '0'+'|'+
                 '0'+'|'+
                 '0'+'|'+
                 '0'+'|'+
                 '0'+'|'+
                 '0'+'|'+
                 '0'+'|'+
                 '0';
       end;

      SendChemicalAnalysis(msg);
      SaveLog('tcp'+#9#9+'sent'+#9+'chemical analysis -> '+msg);
      ShowTrayMessage('Chemical Analysis', '������� �� ������'+#9+InHeat, 1);
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function SendChemicalAnalysis(InData: string): bool;
var
  msg: TStringStream;
begin
  try
      IdTCPClient.Connect;
      try
          //����� ����� �������� �������� � ����������
          msg := TStringStream.Create;
          msg.WriteString(InData+IdMsg);  //������ ��������� � �����
          msg.Position := 0; //��������� ������� �� ������ ������
          IdTCPClient.IOHandler.Write(msg, msg.Size, true);
      finally
       		msg.Free;
      end;
      IdTCPClient.Disconnect;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function ReplaceComa(InData: string): string;
begin
  result := Trim(StringReplace(InData,',','.',[rfReplaceAll]));
end;



// ��� �������� ��������� ����� ����� �����������
initialization
  TcpWorks := TTcpWorks.Create;

//��� �������� ��������� ������������
finalization
  TcpWorks.Destroy;

end.