#!/bin/bash
# Title: BackupPC_Git_UpdateConfigs.sh
# Author: Simon Utter
# Version: 0.1
# Purpose: Cronjob to to pull and update the BackupPC configuration periodically on the BackupPC server

# Set your variables below
GitUsername=
GitPassword=
GitURL=

git config --global user.name $GitUsername
git config --global user.email $GitEmailAddress

if [ ! -d /etc/backuppc/git_backuppc ]; then
    mkdir /etc/backuppc/git_backuppc
    git clone --branch master $GitURL /etc/backuppc/git_backuppc
else
    cd /etc/backuppc/git_backuppc
    git checkout master
    git pull
fi

chown -R backuppc:backuppc /etc/backuppc/git_backuppc
cp /etc/backuppc/git_backuppc/Linux/* /etc/backuppc/

chmod +x /etc/backuppc/*.sh

crontab -l > mycron
if grep -q BackupPC_Git_UpdateConfigs mycron;then
    echo "Crontab entry already in file, nothing to do."
else
    echo "0 * * * *         /etc/backuppc/BackupPC_Git_UpdateConfigs.sh" >> mycron
    crontab mycron
fi
rm mycron

exit 0