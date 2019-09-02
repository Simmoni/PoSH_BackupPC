Write-Host "Info: 01_sql_deletefiles starting..."
Get-ChildItem -Path C:\Backup -Include *.bak -File -Recurse | foreach { $_.Delete()}
Write-Host "Info: 01_sql_deletefiles completed"