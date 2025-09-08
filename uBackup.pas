unit uBackup;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.IOUtils, System.Hash, System.DateUtils, System.Zip, System.JSON, System.Masks;

type
  TLogProc = procedure(const S: string) of object;

  TChangeInfo = record
    Hash: UInt64;
    LastBackup: TDateTime;
  end;

  TBackupManager = class
  private
    FRoots: TArray<string>;
    FBackupRoot: string;
    FExclude: TArray<string>;
    FState: TDictionary<string,TChangeInfo>;
    FOnLog: TLogProc;
    FZip: Boolean;
    FStateFile: string;
    FMaxBackups: Integer;
    FAutoRotation: Boolean;
    function CalcProjectHash(const ProjectPath: string): UInt64;
    function IsExcluded(const Name: string): Boolean;
    procedure DoLog(const S: string);
    function NeedBackup(const ProjectName: string; NewHash: UInt64): Boolean;
    procedure DoZip(const SourceDir, TargetZip: string);
    procedure LoadState;
    procedure SaveState;
    procedure CleanupOldBackups(const ProjectName: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configure(const ARoots: TArray<string>; const ABackupRoot: string; const Ex: TArray<string>; Zip: Boolean);
    procedure SetLogger(const A: TLogProc);
    procedure ScanAndBackup(const EnabledProjects: TArray<string>);
    procedure ForceBackup(const Project: string);
    procedure ResetHashes;
    property MaxBackups: Integer read FMaxBackups write FMaxBackups;
    property AutoRotation: Boolean read FAutoRotation write FAutoRotation;
  end;

function FormatStamp: string;

implementation

function FormatStamp: string;
begin
  Result := FormatDateTime('yyyymmdd_hhnnss', Now);
end;

{ TBackupManager }

constructor TBackupManager.Create;
begin
  FState := TDictionary<string,TChangeInfo>.Create;
  FStateFile := TPath.Combine(TPath.GetDocumentsPath, 'FlutterAutoBackup_state.json');
  FMaxBackups := 4;
  FAutoRotation := True;
  LoadState;
end;

destructor TBackupManager.Destroy;
begin
  SaveState;
  FState.Free;
  inherited;
end;

procedure TBackupManager.Configure(const ARoots: TArray<string>; const ABackupRoot: string; const Ex: TArray<string>; Zip: Boolean);
var
  I: Integer;
  AllExclusions: TArray<string>;
begin
  FRoots := ARoots;
  FBackupRoot := ABackupRoot;
  FZip := Zip;
  
  // Начинаем с переданных исключений
  AllExclusions := Ex;
  
  // Добавляем автоматические исключения для Delphi проектов
  SetLength(AllExclusions, Length(AllExclusions) + 6);
  AllExclusions[Length(AllExclusions) - 6] := '*.dcu';
  AllExclusions[Length(AllExclusions) - 5] := '*.exe';
  AllExclusions[Length(AllExclusions) - 4] := '*.res';
  AllExclusions[Length(AllExclusions) - 3] := '*.rsm';
  AllExclusions[Length(AllExclusions) - 2] := '*.identcache';
  AllExclusions[Length(AllExclusions) - 1] := '*.local';
  
  FExclude := AllExclusions;
  
  // Логируем все исключения для отладки
  DoLog('Настройки исключений:');
  for I := 0 to Length(FExclude) - 1 do
    DoLog('  Исключение: ' + FExclude[I]);
end;

procedure TBackupManager.SetLogger(const A: TLogProc);
begin
  FOnLog := A;
end;

procedure TBackupManager.DoLog(const S: string);
begin
  if Assigned(FOnLog) then
    FOnLog(FormatDateTime('hh:nn:ss', Now)+' '+S);
end;

function TBackupManager.IsExcluded(const Name: string): Boolean;
var
  ExcludeItem: string;
begin
  Result := False;
  for ExcludeItem in FExclude do
  begin
    // Если исключение содержит *, то это маска файла
    if Pos('*', ExcludeItem) > 0 then
    begin
      // Для простых масок вида *.ext делаем проверку через ExtractFileExt
      if (ExcludeItem[1] = '*') and (ExcludeItem[2] = '.') then
      begin
        var Ext := Copy(ExcludeItem, 2, Length(ExcludeItem));
        if SameText(ExtractFileExt(Name), Ext) then
        begin
          // DoLog('Исключен файл по расширению: ' + Name + ' (расширение: ' + Ext + ')');
          Result := True;
          Exit;
        end;
      end
      else if MatchesMask(LowerCase(Name), LowerCase(ExcludeItem)) then
      begin
        // DoLog('Исключен файл по маске: ' + Name + ' (маска: ' + ExcludeItem + ')');
        Result := True;
        Exit;
      end;
    end
    else
    begin
      // Обычное сравнение для папок
      if SameText(Name, ExcludeItem) then
      begin
        // DoLog('Исключена папка: ' + Name);
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function TBackupManager.CalcProjectHash(const ProjectPath: string): UInt64;
var
  Files: TArray<string>;
  F: string;
  Info: TSearchRec;
  I: Integer;
  H: UInt64;
begin
  Files := [];
  var Stack := TStack<string>.Create;
  try
    Stack.Push(ProjectPath);
    while Stack.Count > 0 do
    begin
      var Cur := Stack.Pop;
      if FindFirst(Cur + PathDelim + '*', faAnyFile, Info) = 0 then
      begin
        repeat
          if (Info.Name='.') or (Info.Name='..') then Continue;
          if (Info.Attr and faDirectory)<>0 then
          begin
            if not IsExcluded(Info.Name) then
              Stack.Push(Cur + PathDelim + Info.Name);
          end
          else
          begin
            if not IsExcluded(Info.Name) then
              Files := Files + [Cur + PathDelim + Info.Name];
          end;
        until FindNext(Info)<>0;
        FindClose(Info);
      end;
    end;
  finally
    Stack.Free;
  end;

    H := 1469598103934665603; // FNV offset
    for F in Files do
    begin
      try
        var Size := TFile.GetSize(F);
        var DT := DateTimeToFileDate(TFile.GetLastWriteTime(F));
        
        // Используем более безопасный алгоритм хеширования
        H := H xor UInt64(Size and $FFFFFFFF);
        H := H * 16777619; // FNV prime (32-bit)
        
        H := H xor UInt64(DT and $FFFFFFFF);
        H := H * 16777619;
        
        H := H xor UInt64(Length(F) and $FFFFFFFF);
        H := H * 16777619;
      except
        // Игнорируем ошибки доступа к файлам
        Continue;
      end;
    end;
    Result := H;
end;

function TBackupManager.NeedBackup(const ProjectName: string; NewHash: UInt64): Boolean;
var
  CI: TChangeInfo;
begin
  if not FState.TryGetValue(ProjectName, CI) then
    Exit(True);
  Result := (CI.Hash <> NewHash);
end;

procedure TBackupManager.DoZip(const SourceDir, TargetZip: string);
  procedure AddDir(const Dir, Base: string; Zip: TZipFile);
  var
    Files, Dirs: TArray<string>;
    F: string;
    Rel: string;
    FileName: string;
  begin
    Files := TDirectory.GetFiles(Dir);
    for F in Files do
    begin
      FileName := ExtractFileName(F);
      // Проверяем исключения для файлов
      if not IsExcluded(FileName) then
      begin
        Rel := F.Substring(Length(Base) + 1);
        Zip.Add(F, Rel);
      end;
    end;
    Dirs := TDirectory.GetDirectories(Dir);
    for F in Dirs do
    begin
      var DirName := ExtractFileName(F);
      // Проверяем исключения для папок
      if not IsExcluded(DirName) then
        AddDir(F, Base, Zip);
    end;
  end;
var
  Zip: TZipFile;
begin
  Zip := TZipFile.Create;
  try
    Zip.Open(TargetZip, zmWrite);
    AddDir(SourceDir, SourceDir, Zip);
  finally
    Zip.Close;
    Zip.Free;
  end;
end;

procedure TBackupManager.ForceBackup(const Project: string);
var
  ProjectPath: string;
  Hash: UInt64;
  Dest: string;
  CI: TChangeInfo;
  FinalDest: string;
  IsFlutterProject, IsDelphiProject: Boolean;
  Files: TArray<string>;
  I: Integer;
  RootPath: string;
  Found: Boolean;
begin
  if (Length(FRoots)=0) or (FBackupRoot='') then Exit;
  
  // Ищем проект во всех корневых папках
  Found := False;
  for I := 0 to Length(FRoots)-1 do
  begin
    RootPath := IncludeTrailingPathDelimiter(FRoots[I]);
    ProjectPath := RootPath + Project;
    if TDirectory.Exists(ProjectPath) then
    begin
      Found := True;
      Break;
    end;
  end;
  
  if not Found then
  begin
    DoLog('Пропуск (папка не найдена): '+Project);
    Exit;
  end;
  
  // Определяем тип проекта
  IsFlutterProject := TFile.Exists(ProjectPath+PathDelim+'pubspec.yaml');
  IsDelphiProject := False;
  
  if not IsFlutterProject then
  begin
    Files := TDirectory.GetFiles(ProjectPath, '*.dpr');
    if Length(Files) = 0 then
      Files := TDirectory.GetFiles(ProjectPath, '*.dpk');
    if Length(Files) = 0 then
      Files := TDirectory.GetFiles(ProjectPath, '*.dproj');
    IsDelphiProject := Length(Files) > 0;
  end;
  
  if not (IsFlutterProject or IsDelphiProject) then
  begin
    DoLog('Пропуск (неизвестный тип проекта): '+Project);
    Exit;
  end;
  
  try
    Hash := CalcProjectHash(ProjectPath);
    DoLog(Format('Хеш проекта %s: %u', [Project, Hash]));
  except
    on E: Exception do
    begin
      DoLog('Ошибка вычисления хеша для '+Project+': '+E.Message);
      Exit;
    end;
  end;
  
  if not NeedBackup(Project, Hash) then
  begin
    DoLog('Нет изменений: '+Project);
    Exit;
  end;
  
  DoLog('Требуется бэкап для: '+Project);

  // Очищаем старые резервные копии перед созданием новой
  CleanupOldBackups(Project);

  // Создаем путь с учетом структуры корневых папок
  var RootFolderName := ExtractFileName(ExcludeTrailingPathDelimiter(RootPath));
  var BackupSubDir := IncludeTrailingPathDelimiter(FBackupRoot) + RootFolderName;
  ForceDirectories(BackupSubDir);
  
  Dest := IncludeTrailingPathDelimiter(BackupSubDir) + Project + '_' + FormatStamp;
  ForceDirectories(Dest);

  // Копирование
  var Stack := TStack<string>.Create;
  try
    Stack.Push(ProjectPath);
    while Stack.Count > 0 do
    begin
      var Cur := Stack.Pop;
      var Rel := Copy(Cur, Length(ProjectPath)+2, MaxInt);
      var TargetDir := Dest;
      if Rel<>'' then
        TargetDir := Dest + PathDelim + Rel;
      ForceDirectories(TargetDir);

      var SR: TSearchRec;
      if FindFirst(Cur+PathDelim+'*', faAnyFile, SR)=0 then
      begin
        repeat
          if (SR.Name='.') or (SR.Name='..') then Continue;
          var SourceFull := Cur+PathDelim+SR.Name;
          if (SR.Attr and faDirectory)<>0 then
          begin
            if not IsExcluded(SR.Name) then
              Stack.Push(SourceFull);
          end
          else
          begin
            if not IsExcluded(SR.Name) then
            begin
              // DoLog('Копируем файл: ' + SR.Name);
              TFile.Copy(SourceFull, TargetDir+PathDelim+SR.Name, True);
            end
            else
            begin
              // DoLog('Пропускаем файл: ' + SR.Name);
            end;
          end;
        until FindNext(SR)<>0;
        FindClose(SR);
      end;
    end;
  finally
    Stack.Free;
  end;

  if FZip then
  begin
    FinalDest := Dest + '.zip';
    DoZip(Dest, FinalDest);
    DoLog('ZIP: '+FinalDest);
    // Если нужно удалять незапакованную папку:
    // TDirectory.Delete(Dest, True);
  end
  else
    FinalDest := Dest;

  CI.Hash := Hash;
  CI.LastBackup := Now;
  FState.AddOrSetValue(Project, CI);
  SaveState; // Сохраняем состояние сразу после бэкапа
  DoLog('Бэкап создан: '+FinalDest);
end;

procedure TBackupManager.LoadState;
var
  JsonText: string;
  JsonValue: TJSONValue;
  JsonObj, ProjectObj: TJSONObject;
  JsonArray: TJSONArray;
  I: Integer;
  ProjectName: string;
  CI: TChangeInfo;
begin
  if not TFile.Exists(FStateFile) then Exit;
  
  try
    JsonText := TFile.ReadAllText(FStateFile, TEncoding.UTF8);
    JsonValue := TJSONObject.ParseJSONValue(JsonText);
    try
      if JsonValue is TJSONObject then
      begin
        JsonObj := JsonValue as TJSONObject;
        JsonArray := JsonObj.GetValue<TJSONArray>('projects');
        if Assigned(JsonArray) then
        begin
          for I := 0 to JsonArray.Count - 1 do
          begin
            ProjectObj := JsonArray.Items[I] as TJSONObject;
            ProjectName := ProjectObj.GetValue<string>('name', '');
            CI.Hash := StrToUInt64Def(ProjectObj.GetValue<string>('hash', '0'), 0);
            CI.LastBackup := ISO8601ToDate(ProjectObj.GetValue<string>('lastBackup', ''));
            if ProjectName <> '' then
              FState.AddOrSetValue(ProjectName, CI);
          end;
        end;
      end;
    finally
      JsonValue.Free;
    end;
  except
    // Игнорируем ошибки загрузки состояния
  end;
end;

procedure TBackupManager.SaveState;
var
  JsonObj, ProjectObj: TJSONObject;
  JsonArray: TJSONArray;
  Pair: TPair<string, TChangeInfo>;
begin
  try
    JsonObj := TJSONObject.Create;
    try
      JsonArray := TJSONArray.Create;
      for Pair in FState do
      begin
        ProjectObj := TJSONObject.Create;
        ProjectObj.AddPair('name', Pair.Key);
        ProjectObj.AddPair('hash', UIntToStr(Pair.Value.Hash));
        ProjectObj.AddPair('lastBackup', DateToISO8601(Pair.Value.LastBackup));
        JsonArray.AddElement(ProjectObj);
      end;
      JsonObj.AddPair('projects', JsonArray);
      TFile.WriteAllText(FStateFile, JsonObj.ToJSON, TEncoding.UTF8);
    finally
      JsonObj.Free;
    end;
  except
    // Игнорируем ошибки сохранения состояния
  end;
end;

procedure TBackupManager.ResetHashes;
begin
  FState.Clear;
  SaveState;
  DoLog('Все хеши сброшены');
end;

procedure TBackupManager.ScanAndBackup(const EnabledProjects: TArray<string>);
var
  P: string;
begin
  for P in EnabledProjects do
    ForceBackup(P);
end;

procedure TBackupManager.CleanupOldBackups(const ProjectName: string);
type
  TFileInfo = record
    FileName: string;
    CreationTime: TDateTime;
  end;
var
  BackupFiles: TArray<string>;
  I: Integer;
  BackupPattern: string;
  FileInfo: TFileInfo;
  FileInfos: TArray<TFileInfo>;
  J: Integer;
begin
  if not FAutoRotation then Exit;
  
  // Формируем маску поиска файлов резервных копий для данного проекта
  BackupPattern := TPath.Combine(FBackupRoot, ProjectName + '_*.zip');
  
  try
    // Получаем все файлы резервных копий проекта
    BackupFiles := TDirectory.GetFiles(FBackupRoot, ProjectName + '_*.zip');
    
    DoLog(Format('Найдено резервных копий для %s: %d', [ProjectName, Length(BackupFiles)]));
    
    // Если файлов меньше или равно максимуму, ничего не удаляем
    if Length(BackupFiles) <= FMaxBackups then Exit;
    
    // Создаем массив с информацией о файлах
    SetLength(FileInfos, Length(BackupFiles));
    for I := 0 to Length(BackupFiles) - 1 do
    begin
      FileInfos[I].FileName := BackupFiles[I];
      FileInfos[I].CreationTime := TFile.GetCreationTime(BackupFiles[I]);
    end;
    
    // Сортируем по дате создания (старые первыми)
    for I := 0 to Length(FileInfos) - 2 do
      for J := I + 1 to Length(FileInfos) - 1 do
        if FileInfos[I].CreationTime > FileInfos[J].CreationTime then
        begin
          FileInfo := FileInfos[I];
          FileInfos[I] := FileInfos[J];
          FileInfos[J] := FileInfo;
        end;
    
    // Удаляем старые файлы (оставляем только FMaxBackups-1, так как сейчас создается новый)
    for I := 0 to Length(FileInfos) - FMaxBackups do
    begin
      try
        DoLog('Удаляем старую копию: ' + ExtractFileName(FileInfos[I].FileName));
        TFile.Delete(FileInfos[I].FileName);
      except
        on E: Exception do
          DoLog('Ошибка удаления файла ' + FileInfos[I].FileName + ': ' + E.Message);
      end;
    end;
    
  except
    on E: Exception do
      DoLog('Ошибка очистки старых копий: ' + E.Message);
  end;
end;

end.
