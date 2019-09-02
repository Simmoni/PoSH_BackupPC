#!/bin/bash

cd /cygdrive/c
rm -rf backup/* |true
echo "Dumping DB..."
sqlcmd -S <SERVERNAME>\\<INSTANCENAME> -d <DATABASENAME> -U <DATABASEUSER> -P <PASSWORD> -i C:\BackupPC\UserScripts\Pre-Scripts\backup-app.sql
echo "Gzipping..."
gzip -c /cygdrive/c/Backup.bak > /cygdrive/c/backup/$(date +%Y%m%d%H%M%S)-backup.bak.gz
rm -f Backup.bak
exit 0
