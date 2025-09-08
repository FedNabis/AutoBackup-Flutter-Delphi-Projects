unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Forms, Vcl.StdCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.CheckLst, Vcl.ComCtrls,
  uConfig, uBackup, uLanguageSimple, Vcl.Menus, Vcl.Dialogs;

type
  TfrmMain = class(TForm)
    PanelTop: TPanel;
    lblRoot: TLabel;
    listRoots: TListBox;
    btnAddRoot: TButton;
    btnRemoveRoot: TButton;
    lblBackup: TLabel;
    edtBackup: TEdit;
    btnBrowseBackup: TButton;
    btnScan: TButton;
    chkAutoStart: TCheckBox;
    chkZip: TCheckBox;
    lblInterval: TLabel;
    trackInterval: TTrackBar;
    lblIntervalValue: TLabel;
    lblZipInterval: TLabel;
    trackZipInterval: TTrackBar;
    lblZipIntervalValue: TLabel;
    lblLanguage: TLabel;
    cmbLanguage: TComboBox;
    btnSave: TButton;
    btnBackupNow: TButton;
    chklistProjects: TCheckListBox;
    MemoLog: TMemo;
    TimerScan: TTimer;
    btnSelectAll: TButton;
    btnSelectNone: TButton;
    btnRefreshProjects: TButton;
    chkMinimizeToTray: TCheckBox;
    TrayIcon: TTrayIcon;
    PopupTray: TPopupMenu;
    miRestore: TMenuItem;
    miExit: TMenuItem;
    btnForceAll: TButton;
    btnResetHashes: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAddRootClick(Sender: TObject);
    procedure btnRemoveRootClick(Sender: TObject);
    procedure btnBrowseBackupClick(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure TimerScanTimer(Sender: TObject);
    procedure btnBackupNowClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnSelectNoneClick(Sender: TObject);
    procedure btnRefreshProjectsClick(Sender: TObject);
    procedure chkAutoStartClick(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure miRestoreClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure chkMinimizeToTrayClick(Sender: TObject);
    procedure btnForceAllClick(Sender: TObject);
    procedure btnResetHashesClick(Sender: TObject);
    procedure trackIntervalChange(Sender: TObject);
    procedure trackZipIntervalChange(Sender: TObject);
    procedure cmbLanguageChange(Sender: TObject);
  private
    FConfig: TConfig;
    FManager: TBackupManager;
    FSilentStart: Boolean;
    FZipIntervalMin: Integer;
    procedure Log(const S: string);
    procedure LoadConfigGUI;
    procedure SaveConfigFromGUI;
    procedure PopulateProjects;
    function EnabledProjects: TArray<string>;
    procedure ApplyInterval;
    procedure MinimizeToTray;
    procedure UpdateInterfaceLanguage;
  public
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  System.IOUtils, Vcl.FileCtrl;

procedure TfrmMain.ApplyInterval;
var
  Sec: Integer;
begin
  Sec := trackInterval.Position;
  if Sec < 5 then Sec := 5;
  TimerScan.Interval := Sec * 1000;
  FConfig.ScanIntervalSec := Sec;
  FZipIntervalMin := trackZipInterval.Position;
end;

procedure TfrmMain.btnBackupNowClick(Sender: TObject);
begin
  FManager.ScanAndBackup(EnabledProjects);
end;

procedure TfrmMain.btnBrowseBackupClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtBackup.Text;
  if SelectDirectory('Backup folder', '', Dir) then
    edtBackup.Text := Dir;
end;

procedure TfrmMain.btnAddRootClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := '';
  if SelectDirectory('Выберите корневую папку для проектов', '', Dir) then
  begin
    if listRoots.Items.IndexOf(Dir) = -1 then
    begin
      listRoots.Items.Add(Dir);
      PopulateProjects;
    end;
  end;
end;

procedure TfrmMain.btnRemoveRootClick(Sender: TObject);
begin
  if listRoots.ItemIndex >= 0 then
  begin
    listRoots.Items.Delete(listRoots.ItemIndex);
    PopulateProjects;
  end;
end;

procedure TfrmMain.btnForceAllClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to chklistProjects.Count - 1 do
    if chklistProjects.Checked[I] then
      FManager.ForceBackup(chklistProjects.Items[I]);
end;

procedure TfrmMain.btnResetHashesClick(Sender: TObject);
begin
  if Application.MessageBox('Вы уверены, что хотите сбросить все хеши? Это приведет к полному резервному копированию всех проектов при следующем сканировании.', 
    'Подтверждение сброса хешей', MB_YESNO + MB_ICONQUESTION) = IDYES then
  begin
    FManager.ResetHashes;
    Log('Все хеши сброшены. При следующем сканировании будет выполнено полное резервное копирование всех проектов.');
  end;
end;

procedure TfrmMain.btnRefreshProjectsClick(Sender: TObject);
begin
  PopulateProjects;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  SaveConfigFromGUI;
  FConfig.Save;
  FManager.Configure(FConfig.Roots, FConfig.BackupRoot, FConfig.Exclude, FConfig.Zip);
  ApplyInterval;
  Log('Настройки сохранены.');
end;

procedure TfrmMain.btnScanClick(Sender: TObject);
begin
  PopulateProjects;
end;

procedure TfrmMain.btnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to chklistProjects.Count - 1 do
    chklistProjects.Checked[I] := True;
end;

procedure TfrmMain.btnSelectNoneClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to chklistProjects.Count - 1 do
    chklistProjects.Checked[I] := False;
end;

procedure TfrmMain.chkAutoStartClick(Sender: TObject);
begin
  SetAutoStart(chkAutoStart.Checked);
  FConfig.AutoStart := chkAutoStart.Checked;
  FConfig.Save;
end;

procedure TfrmMain.chkMinimizeToTrayClick(Sender: TObject);
begin
  if chkMinimizeToTray.Checked then
    Log('Будет сворачиваться в трей.');
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if chkMinimizeToTray.Checked and (Application.MessageBox('Закрыть (OK) или свернуть в трей (Cancel)?','Выход',MB_OKCANCEL)=IDCANCEL) then
  begin
    CanClose := False;
    MinimizeToTray;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FSilentStart := (ParamCount>0) and SameText(ParamStr(1), '--minimized');
  FConfig := TConfig.Create;
  FConfig.Load;
  FManager := TBackupManager.Create;
  FManager.SetLogger(Log);

  LoadConfigGUI;
  FManager.Configure(FConfig.Roots, FConfig.BackupRoot, FConfig.Exclude, FConfig.Zip);
  ApplyInterval;
  PopulateProjects;
  if FSilentStart then
    MinimizeToTray;
end;

destructor TfrmMain.Destroy;
begin
  FManager.Free;
  FConfig.Free;
  inherited;
end;

procedure TfrmMain.LoadConfigGUI;
var
  I: Integer;
begin
  if not Assigned(FConfig) then Exit;
  
  // Загружаем корневые папки
  listRoots.Items.Clear;
  for I := 0 to Length(FConfig.Roots) - 1 do
    listRoots.Items.Add(FConfig.Roots[I]);
    
  edtBackup.Text := FConfig.BackupRoot;
  chkAutoStart.Checked := FConfig.AutoStart;
  chkZip.Checked := FConfig.Zip;
  
  if Assigned(trackInterval) then
  begin
    trackInterval.Position := FConfig.ScanIntervalSec;
    if Assigned(lblIntervalValue) then
      lblIntervalValue.Caption := IntToStr(FConfig.ScanIntervalSec);
  end;
  
  if Assigned(trackZipInterval) then
  begin
    trackZipInterval.Position := 5; // значение по умолчанию
    if Assigned(lblZipIntervalValue) then
      lblZipIntervalValue.Caption := '5';
  end;
  
  FZipIntervalMin := 5;
  
  // Устанавливаем язык из конфигурации
  CurrentLanguage := FConfig.Language;
  
  // Обновляем интерфейс в соответствии с языком
  UpdateInterfaceLanguage;
end;

procedure TfrmMain.Log(const S: string);
begin
  MemoLog.Lines.Add(S);
  while MemoLog.Lines.Count > 5000 do
    MemoLog.Lines.Delete(0);
end;

procedure TfrmMain.miExitClick(Sender: TObject);
begin
  chkMinimizeToTray.Checked := False;
  Close;
end;

procedure TfrmMain.miRestoreClick(Sender: TObject);
begin
  TrayIcon.Visible := False;
  Show;
  Application.Restore;
end;

procedure TfrmMain.MinimizeToTray;
begin
  TrayIcon.Hint := 'Flutter Auto Backup';
  TrayIcon.Visible := True;
  Hide;
end;

procedure TfrmMain.UpdateInterfaceLanguage;
begin
  // Обновляем заголовки
  Caption := _('AppTitle');
  lblRoot.Caption := _('RootFolders');
  lblBackup.Caption := _('BackupFolder');
  lblLanguage.Caption := _('Language');
  
  // Обновляем кнопки (исключаем кнопки с символами +, -, ...)
  // btnAddRoot и btnRemoveRoot оставляем как есть (+ и -)
  // btnBrowseBackup оставляем как есть (...)
  btnScan.Caption := _('Start');
  btnBackupNow.Caption := _('ForceBackup');
  btnResetHashes.Caption := _('ResetHashes');
  btnRefreshProjects.Caption := _('RefreshProjects');
  
  // Обновляем чекбоксы
  chkAutoStart.Caption := _('AutoStart');
  chkZip.Caption := _('ZipBackups');
  
  // Обновляем ComboBox языков
  cmbLanguage.Items.Clear;
  cmbLanguage.Items.Add(_('Russian'));
  cmbLanguage.Items.Add(_('English'));
  
  // Устанавливаем правильный выбор языка
  if CurrentLanguage = lgRussian then
    cmbLanguage.ItemIndex := 0
  else
    cmbLanguage.ItemIndex := 1;
end;

procedure TfrmMain.PopulateProjects;
var
  Dirs: TArray<string>;
  D: string;
  Name: string;
  I, R: Integer;
  IsProject: Boolean;
  Files: TArray<string>;
  RootPath: string;
begin
  chklistProjects.Items.BeginUpdate;
  try
    chklistProjects.Items.Clear;
    
    // Проходим по всем корневым папкам
    for R := 0 to listRoots.Items.Count - 1 do
    begin
      RootPath := listRoots.Items[R];
      if not TDirectory.Exists(RootPath) then Continue;
      
      Dirs := TDirectory.GetDirectories(RootPath);
      for D in Dirs do
      begin
        IsProject := False;
        
        // Проверяем Flutter проект
        if TFile.Exists(D + PathDelim + 'pubspec.yaml') then
          IsProject := True
        else
        begin
          // Проверяем Delphi проект
          Files := TDirectory.GetFiles(D, '*.dpr');
          if Length(Files) > 0 then
            IsProject := True
          else
          begin
            Files := TDirectory.GetFiles(D, '*.dpk');
            if Length(Files) > 0 then
              IsProject := True
            else
            begin
              Files := TDirectory.GetFiles(D, '*.dproj');
              if Length(Files) > 0 then
                IsProject := True;
            end;
          end;
        end;
        
        if IsProject then
        begin
          Name := ExtractFileName(D);
          // Добавляем только если еще нет такого проекта
          if chklistProjects.Items.IndexOf(Name) = -1 then
            chklistProjects.Items.Add(Name);
        end;
      end;
    end;
    
    // восстановить флаги из конфига
    for I := 0 to chklistProjects.Count - 1 do
    begin
      Name := chklistProjects.Items[I];
      var Idx := FConfig.FindProject(Name);
      if Idx >= 0 then
        chklistProjects.Checked[I] := FConfig.Projects[Idx].Enabled
      else
        chklistProjects.Checked[I] := True;
    end;
  finally
    chklistProjects.Items.EndUpdate;
  end;
  Log('Проекты обновлены.');
end;

procedure TfrmMain.SaveConfigFromGUI;
var
  I: Integer;
  Item: TProjectItem;
  Roots: TArray<string>;
begin
  // Сохраняем корневые папки
  SetLength(Roots, listRoots.Items.Count);
  for I := 0 to listRoots.Items.Count - 1 do
    Roots[I] := listRoots.Items[I];
  FConfig.Roots := Roots;
  
  FConfig.BackupRoot := edtBackup.Text;
  FConfig.Zip := chkZip.Checked;
  FConfig.Projects.Clear;
  for I := 0 to chklistProjects.Count - 1 do
  begin
    Item.Name := chklistProjects.Items[I];
    Item.Enabled := chklistProjects.Checked[I];
    FConfig.Projects.Add(Item);
  end;
end;

function TfrmMain.EnabledProjects: TArray<string>;
var
  I: Integer;
begin
  for I := 0 to chklistProjects.Count - 1 do
    if chklistProjects.Checked[I] then
      Result := Result + [chklistProjects.Items[I]];
end;

procedure TfrmMain.TimerScanTimer(Sender: TObject);
var
  Roots: TArray<string>;
  I: Integer;
begin
  // Собираем корневые папки из списка
  SetLength(Roots, listRoots.Items.Count);
  for I := 0 to listRoots.Items.Count - 1 do
    Roots[I] := listRoots.Items[I];
    
  FManager.Configure(Roots, edtBackup.Text, FConfig.Exclude, chkZip.Checked);
  FManager.ScanAndBackup(EnabledProjects);
end;

procedure TfrmMain.TrayIconDblClick(Sender: TObject);
begin
  miRestoreClick(Sender);
end;

procedure TfrmMain.trackIntervalChange(Sender: TObject);
begin
  lblIntervalValue.Caption := IntToStr(trackInterval.Position);
  ApplyInterval;
end;

procedure TfrmMain.trackZipIntervalChange(Sender: TObject);
begin
  lblZipIntervalValue.Caption := IntToStr(trackZipInterval.Position);
  FZipIntervalMin := trackZipInterval.Position;
end;

procedure TfrmMain.cmbLanguageChange(Sender: TObject);
begin
  // Сохраняем выбранный язык в конфигурацию
  if cmbLanguage.ItemIndex = 0 then
    FConfig.Language := lgRussian
  else
    FConfig.Language := lgEnglish;
    
  // Устанавливаем текущий язык
  CurrentLanguage := FConfig.Language;
  
  // Обновляем интерфейс
  UpdateInterfaceLanguage;
  
  // Сохраняем настройки
  FConfig.Save;
end;

end.