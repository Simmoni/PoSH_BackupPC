## PoSH-BackupPC

A BackupPC client written in PowerShell.
It support Pre/Post scripts to be excuted on a per client basis, so no more manual editing needed of bat/cmd files.

This allows you to extend the backup capabilities, avoiding scheduling tasks etc.

For instance, you could create a SQL dump as part of your Pre-Script, make a Group Policy backup or even interact with cygwin before the backup starts (examples located in the Examples folder).

## Requirements
Windows client

* PowerShell 4.0

Linux host/BackupPC server

* sshpass

### Installation

1. Copy the files in the Windows/Client folder to "C:\BackupPC" on the Windows Machine (Or build an installer with the included NSIS script)
2. Copy the scripts and template files located in the Linux dir to /etc/backuppc on the BackupPC server
3. Use the host\_template\_example.pl file as a configuration template for the host you want to backup, make a copy of it and change change the name of it making it the same as the host you wish to backup

## Usage
##### PowerShell script
The PowerShell script requires two arguments:

* -Action: What type of action the client should perform. Choose from
	* Backup
	* Restore

* A BASE64 encoded string containign the configuration details provided by the BackupPC server

Example:

```BackupPC.ps1 -Action restore -Base64 QmFja3VwUEMgcm9ja3M=```

##### Bash script

The bash script located on the BackupPC server requires at last 3 arguments:

```BackupPC_PowerShell.sh [Action] $hostIP $host [sshpass] [authfile]```

Supported actions:

* --backup
* --post-backup
* --restore
* --post-restore

Example 1:

```BackupPC_PowerShell.sh --backup $hostIP $host```

Example 2: 

```BackupPC_PowerShell.sh --backup $hostIP $host sshpass /etc/backuppc/authfile.txt```

## To do

There are errors and inconsistencies in the code.

* Migrate the code from the VSS helper script in to the main script
* Make logging format consistent
* Check for parameters properly in the PowerShell script

