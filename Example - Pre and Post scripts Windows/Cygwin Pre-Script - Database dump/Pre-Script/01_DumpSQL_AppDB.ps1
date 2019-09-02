Write-Host "Executing 01_DumpSQL_AppDB.ps1..."

# Build command from variables
$Cygwin = "C:\cygwin64\bin\bash.exe"
$CygwinAction = "--login"
$CygwinCommand = "/cygdrive/c/BackupPC/UserScripts/Pre-Script/backup-app.sh"

# Execute command
& $Cygwin $CygwinAction $CygwinCommand
Write-Host "Execution of 01_DumpSQL_AppDB.ps1 completed."