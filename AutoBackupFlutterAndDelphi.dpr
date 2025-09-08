program AutoBackupFlutter;

uses
  Vcl.Forms,
  uBackup in 'uBackup.pas',
  uConfig in 'uConfig.pas',
  uMain in 'uMain.pas' {frmMain},
  uLanguageSimple in 'uLanguageSimple.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Carbon');
  Application.Title := 'Flutter Auto Backup';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
