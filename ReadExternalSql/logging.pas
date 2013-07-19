unit Logging;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, OoMisc;


  function SaveLog(InData: string): bool;


implementation

uses
  main;



//--| start |--
function SaveLog(InData: string): bool;
var
   f: TextFile;
begin
  try
      AssignFile(f, CurrentDir+'\'+LogFile);
      if not FileExists(CurrentDir+'\'+LogFile) then
       begin
          Rewrite(f);
          CloseFile(f);
       end;

      Append(f);

      Writeln(f,DateTimeToStr(NOW)+#9+InData);

      Flush(f);
      CloseFile(f);
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;




end.
