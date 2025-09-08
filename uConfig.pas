unit uConfig;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,System.IOUtils, Winapi.Windows, Winapi.ShLwApi, win.Registry, uLanguageSimple;

type
  TProjectItem = record
    Name: string;
    Enabled: Boolean;
  end;

  TConfig = class
  private
    FRoots: TArray<string>;
    FBackupRoot: string;
    FProjects: TList<TProjectItem>;
    FExclude: TArray<string>;
    FAutoStart: Boolean;
    FScanIntervalSec: Integer;
    FZip: Boolean;
    FConfigPath: string;
    FMaxBackups: Integer;
    FAutoRotation: Boolean;
    FBackupInterval: Integer; // в миллисекундах
    FLanguage: TLanguage;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    function FindProject(const Name: string): Integer;
    property Roots: TArray<string> read FRoots write FRoots;
    property BackupRoot: string read FBackupRoot write FBackupRoot;
    property Projects: TList<TProjectItem> read FProjects;
    property Exclude: TArray<string> read FExclude write FExclude;
    property AutoStart: Boolean read FAutoStart write FAutoStart;
    property ScanIntervalSec: Integer read FScanIntervalSec write FScanIntervalSec;
    property Zip: Boolean read FZip write FZip;
    property MaxBackups: Integer read FMaxBackups write FMaxBackups;
    property AutoRotation: Boolean read FAutoRotation write FAutoRotation;
    property BackupInterval: Integer read FBackupInterval write FBackupInterval;
    property Language: TLanguage read FLanguage write FLanguage;
  end;

procedure SetAutoStart(const Enable: Boolean);

implementation



const
  CAppName = 'FlutterAutoBackup';

procedure SetAutoStart(const Enable: Boolean);
var
  R: TRegistry;
  Exe: string;
begin
  R := TRegistry.Create(KEY_WRITE);
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True) then
    begin
      if Enable then
      begin
        Exe := ParamStr(0);
        R.WriteString(CAppName, '"'+Exe+'" --minimized');
      end
      else
        R.DeleteValue(CAppName);
    end;
  finally
    R.Free;
  end;
end;

constructor TConfig.Create;
begin
  FProjects := TList<TProjectItem>.Create;
  FExclude := ['build','.dart_tool','.idea','.git','__history','Win32','Win64','Debug','Release',
    '*.exe','*.dcu','*.res','*.map','*.rsm','*.local','*.identcache','*.stat',
    '*.deployproj','*.groupproj.local','*.dll','*.bpl','*.dcp','*.lib','*.obj',
    '*.pdb','*.tds','*.~*','*.cbk','*.backup','*.#*'];
  FAutoStart := False;
  FScanIntervalSec := 20;
  FZip := False;
  FConfigPath := TPath.Combine(TPath.GetDocumentsPath, CAppName + '.json');
  FMaxBackups := 4;
  FAutoRotation := True;
  FBackupInterval := 60000; // 1 минута по умолчанию
  FLanguage := lgRussian;
end;

destructor TConfig.Destroy;
begin
  FProjects.Free;
  inherited;
end;

function TConfig.FindProject(const Name: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FProjects.Count - 1 do
    if SameText(FProjects[I].Name, Name) then
      Exit(I);
end;

procedure TConfig.Load;
var
  S: string;
  J, JProj: TJSONValue;
  Arr: TJSONArray;
  I: Integer;
  Item: TProjectItem;
begin
  if not FileExists(FConfigPath) then
    Exit;
  S := TFile.ReadAllText(FConfigPath, TEncoding.UTF8);
  J := TJSONObject.ParseJSONValue(S);
  try
    if not (J is TJSONObject) then Exit;
    
    // Загружаем корневые папки
    Arr := (J as TJSONObject).GetValue('roots') as TJSONArray;
    if Assigned(Arr) then
    begin
      SetLength(FRoots, Arr.Count);
      for I := 0 to Arr.Count-1 do
        FRoots[I] := Arr.Items[I].Value;
    end
    else
    begin
      // Совместимость со старым форматом
      var OldRootValue := (J as TJSONObject).GetValue('root');
      if Assigned(OldRootValue) then
      begin
        var OldRoot := OldRootValue.Value;
        if OldRoot <> '' then
        begin
          SetLength(FRoots, 1);
          FRoots[0] := OldRoot;
        end;
      end;
    end;
    
    var BackupRootValue := (J as TJSONObject).GetValue('backupRoot');
    if Assigned(BackupRootValue) then
      FBackupRoot := BackupRootValue.Value;
      
    var ScanIntervalValue := (J as TJSONObject).GetValue('scanInterval');
    if Assigned(ScanIntervalValue) then
      FScanIntervalSec := StrToIntDef(ScanIntervalValue.Value, FScanIntervalSec);
      
    var AutoStartValue := (J as TJSONObject).GetValue('autoStart');
    if Assigned(AutoStartValue) then
      FAutoStart := SameText(AutoStartValue.Value, 'true');
      
    var ZipValue := (J as TJSONObject).GetValue('zip');
    if Assigned(ZipValue) then
      FZip := SameText(ZipValue.Value, 'true');

    Arr := (J as TJSONObject).GetValue('exclude') as TJSONArray;
    if Assigned(Arr) then
    begin
      SetLength(FExclude, Arr.Count);
      for I := 0 to Arr.Count-1 do
        FExclude[I] := Arr.Items[I].Value;
    end;

    Arr := (J as TJSONObject).GetValue('projects') as TJSONArray;
    if Assigned(Arr) then
    begin
      FProjects.Clear;
      for I := 0 to Arr.Count-1 do
      begin
        JProj := Arr.Items[I];
        if JProj is TJSONObject then
        begin
          var NameValue := (JProj as TJSONObject).GetValue('name');
          var EnabledValue := (JProj as TJSONObject).GetValue('enabled');
          
          if Assigned(NameValue) then
            Item.Name := NameValue.Value
          else
            Item.Name := '';
            
          if Assigned(EnabledValue) then
            Item.Enabled := SameText(EnabledValue.Value, 'true')
          else
            Item.Enabled := True;
            
          if Item.Name <> '' then
            FProjects.Add(Item);
        end;
      end;
    end;
    
    // Загружаем новые поля
    var MaxBackupsValue := (J as TJSONObject).GetValue('maxBackups');
    if Assigned(MaxBackupsValue) then
      FMaxBackups := StrToIntDef(MaxBackupsValue.Value, FMaxBackups);
      
    var AutoRotationValue := (J as TJSONObject).GetValue('autoRotation');
    if Assigned(AutoRotationValue) then
      FAutoRotation := SameText(AutoRotationValue.Value, 'true');
      
    var BackupIntervalValue := (J as TJSONObject).GetValue('backupInterval');
    if Assigned(BackupIntervalValue) then
      FBackupInterval := StrToIntDef(BackupIntervalValue.Value, FBackupInterval);
      
    var LanguageValue := (J as TJSONObject).GetValue('language');
    if Assigned(LanguageValue) then
    begin
      var LangIndex := StrToIntDef(LanguageValue.Value, Ord(lgRussian));
      if LangIndex in [Ord(lgRussian), Ord(lgEnglish)] then
        FLanguage := TLanguage(LangIndex);
    end;
    
  finally
    J.Free;
  end;
end;

procedure TConfig.Save;
var
  Obj, PObj: TJSONObject;
  Arr, ArrP: TJSONArray;
  Item: TProjectItem;
  I: Integer;
begin
  Obj := TJSONObject.Create;
  try
    // Сохраняем корневые папки
    Arr := TJSONArray.Create;
    for I := 0 to Length(FRoots)-1 do
      Arr.Add(FRoots[I]);
    Obj.AddPair('roots', Arr);
    
    Obj.AddPair('backupRoot', FBackupRoot);
    Obj.AddPair('scanInterval', TJSONNumber.Create(FScanIntervalSec));
    Obj.AddPair('autoStart', TJSONBool.Create(FAutoStart));
    Obj.AddPair('zip', TJSONBool.Create(FZip));
    Obj.AddPair('maxBackups', TJSONNumber.Create(FMaxBackups));
    Obj.AddPair('autoRotation', TJSONBool.Create(FAutoRotation));
    Obj.AddPair('backupInterval', TJSONNumber.Create(FBackupInterval));
    Obj.AddPair('language', TJSONNumber.Create(Ord(FLanguage)));

    Arr := TJSONArray.Create;
    for I := 0 to Length(FExclude)-1 do
      Arr.Add(FExclude[I]);
    Obj.AddPair('exclude', Arr);

    ArrP := TJSONArray.Create;
    for Item in FProjects do
    begin
      PObj := TJSONObject.Create;
      PObj.AddPair('name', Item.Name);
      PObj.AddPair('enabled', TJSONBool.Create(Item.Enabled));
      ArrP.AddElement(PObj);
    end;
    Obj.AddPair('projects', ArrP);

    TFile.WriteAllText(FConfigPath, Obj.ToJSON, TEncoding.UTF8);
  finally
    Obj.Free;
  end;
end;

end.