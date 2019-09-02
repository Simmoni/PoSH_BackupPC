# Requirement: Place the bin directory in the BackupPC Root folder, C:\BackupPC\ 
Write-Host "01_DumpGPO.ps1 is executing..."
New-Item -ItemType Directory -Path "C:\Temp\GroupPolicy_Backups"
Backup-GPO -All -Path C:\Temp\GroupPolicy_Backups

Write-host "01_DumpGPO.ps1; Compressing to zip archive..."
& C:\BackupPC\bins\7z.exe a -mmt=4 -mx=1 -y C:\ServerBackups\GroupPolicy.zip C:\Temp\GroupPolicy_Backups

Write-host "01_DumpGPO.ps1; Deleting Temp dir..."
Remove-Item -LiteralPath "C:\Temp\GroupPolicy_Backups" -Force -Recurse

Write-Host "01_DumpGPO.ps1 is completed"