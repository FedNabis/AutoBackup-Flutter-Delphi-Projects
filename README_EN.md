# AutoBackup Flutter & Delphi Projects

Automatic backup solution for Flutter and Delphi projects with rotation and smart exclusions.

**Developed with GitHub Copilot** 🤖

## ⚠️ IMPORTANT! Before Use

**Always create copies of your projects before first run!**

1. Copy all projects to a separate folder (e.g., `C:\TestProjects\`)
2. Configure the program to work with copies
3. Test on test data first
4. Only use on original projects after successful testing

## Features

- ✅ Automatic detection of Flutter and Delphi projects
- ✅ Smart exclusions (`.dcu`, `.exe`, `build`, `node_modules`, etc.)
- ✅ Backup rotation (maximum 4 copies per project)
- ✅ Hash-based change detection (copies only when changed)
- ✅ Configurable intervals (seconds, minutes, 30 min, hour)
- ✅ Multiple root folders support
- ✅ ZIP archiving of backups

## Technical Details

- **Language**: Object Pascal (Delphi)
- **Architecture**: VCL Application
- **Hash Algorithm**: FNV-1a (64-bit)
- **Compression**: System.Zip
- **Configuration**: JSON

## Usage

1. Run `AutoBackupFlutter.exe`
2. Add root folders with projects
3. Select backup destination folder
4. Configure scan interval
5. Enable required projects
6. Start automatic scanning

## Backup Structure

```
BackupFolder/
├── RootFolder1/
│   ├── Project1_20250908_143025.zip
│   ├── Project1_20250908_143525.zip
│   └── Project1_20250908_144025.zip (max 4 copies)
└── RootFolder2/
    └── Project2_20250908_143030.zip
```

## Automatic Exclusions

- **Delphi**: `*.dcu`, `*.exe`, `*.res`, `*.rsm`, `*.identcache`, `*.local`
- **Flutter**: `build/`, `.dart_tool/`, `.flutter-plugins*`
- **General**: `.git/`, `.idea/`, `node_modules/`, `__history/`

## Development

This project was created through collaborative development between a human and GitHub Copilot AI assistant. All key architectural decisions, algorithms, and implementation were done with AI assistance.

## System Requirements

- Windows 10/11
- Delphi/RAD Studio (for compilation)
- .NET Framework (for runtime)

## License

MIT License

---
*Created with ❤️ by GitHub Copilot*
