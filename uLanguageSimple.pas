unit uLanguageSimple;

interface

uses
  System.SysUtils;

type
  TLanguage = (lgRussian, lgEnglish);

var
  CurrentLanguage: TLanguage = lgRussian;

// Функции для получения переведенных строк
function _(const Key: string): string;
procedure SetLanguage(Lang: TLanguage);

implementation

function _(const Key: string): string;
begin
  // Основные элементы интерфейса
  if Key = 'AppTitle' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Автоматический бэкап проектов'
    else
      Result := 'Automatic Project Backup';
  end
  else if Key = 'RootFolders' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Корневые папки:'
    else
      Result := 'Root Folders:';
  end
  else if Key = 'BackupFolder' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Папка резервных копий:'
    else
      Result := 'Backup Folder:';
  end
  else if Key = 'Projects' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Проекты:'
    else
      Result := 'Projects:';
  end
  else if Key = 'Settings' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Настройки'
    else
      Result := 'Settings';
  end
  else if Key = 'AutoStart' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Автозапуск с Windows'
    else
      Result := 'Auto-start with Windows';
  end
  else if Key = 'ZipBackups' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'ZIP архивы'
    else
      Result := 'ZIP Archives';
  end
  else if Key = 'Language' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Язык:'
    else
      Result := 'Language:';
  end
  else if Key = 'Russian' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Русский'
    else
      Result := 'Russian';
  end
  else if Key = 'English' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Английский'
    else
      Result := 'English';
  end
  
  // Кнопки
  else if Key = 'Add' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Добавить'
    else
      Result := 'Add';
  end
  else if Key = 'Remove' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Удалить'
    else
      Result := 'Remove';
  end
  else if Key = 'Browse' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Обзор...'
    else
      Result := 'Browse...';
  end
  else if Key = 'Start' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Сканировать'
    else
      Result := 'Start Scanning';
  end
  else if Key = 'Stop' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Остановить сканирование'
    else
      Result := 'Stop Scanning';
  end
  else if Key = 'ForceBackup' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Прин-ный бэкап'
    else
      Result := 'Force Backup';
  end
  else if Key = 'ResetHashes' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Сбросить хеши'
    else
      Result := 'Reset Hashes';
  end
  else if Key = 'RefreshProjects' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Обновить проекты'
    else
      Result := 'Refresh Projects';
  end
  
  // Сообщения в логах
  else if Key = 'ExclusionSettings' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Настройки исключений:'
    else
      Result := 'Exclusion settings:';
  end
  else if Key = 'Exclusion' then
  begin
    if CurrentLanguage = lgRussian then
      Result := '  Исключение:'
    else
      Result := '  Exclusion:';
  end
  else if Key = 'ProjectsUpdated' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Проекты обновлены.'
    else
      Result := 'Projects updated.';
  end
  else if Key = 'AllHashesReset' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Все хеши сброшены'
    else
      Result := 'All hashes reset';
  end
  else if Key = 'BackupRequired' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Требуется бэкап для: %s'
    else
      Result := 'Backup required for: %s';
  end
  else if Key = 'NoChanges' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Нет изменений: %s'
    else
      Result := 'No changes: %s';
  end
  else if Key = 'BackupCreated' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Бэкап создан: %s'
    else
      Result := 'Backup created: %s';
  end
  else if Key = 'FolderNotFound' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Пропуск (папка не найдена): %s'
    else
      Result := 'Skip (folder not found): %s';
  end
  else if Key = 'UnknownProjectType' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Пропуск (неизвестный тип проекта): %s'
    else
      Result := 'Skip (unknown project type): %s';
  end
  else if Key = 'DeletingOldCopy' then
  begin
    if CurrentLanguage = lgRussian then
      Result := 'Удаляем старую копию: %s'
    else
      Result := 'Deleting old copy: %s';
  end
  else
    Result := Key; // Возвращаем ключ, если перевод не найден
end;

procedure SetLanguage(Lang: TLanguage);
begin
  CurrentLanguage := Lang;
end;

end.
