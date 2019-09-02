#!/bin/bash
# Title: BackupPC_PowerShell.sh
# Description: Script for BackupPC pre-command for Windows hosts using SSH and PowerShell
# Authour:  Simon Utter
# Version:  2.1
# Date:  2019-06-27
# Requirements: 
# - SSH server running on the host
# - BackupPC user with admin rights on the host 
# - BackupPC SSH key deployed to host (for passwordless SSH authentication)
# - BackupPC PowerShell package v2.1 or above
# - sshpass (Optional)
# Usage: BackupPC_PowerShell.sh [Action] $hostIP $host [sshpass] [authfile]
# Supported actions:
#  --backup
#  --post-backup
#  --restore
#  --post-restore
#
# Example 1: BackupPC_PowerShell.sh --backup $hostIP $host
# Example 2: BackupPC_PowerShell.sh --backup $hostIP $host sshpass /etc/backuppc/authfile
#
# The $hostIP $host are variables provided by BackupPC when the script is used as any of the dump commands in BackupPC
#
# This script can use sshpass, if enabling cyglsa on the Windows hosts for passwordless SSH authentication is not an option.
# Reasoning for using sshpass as per below:
# - Keybased authentication will not work for all hosts, as it requires an "active" console to get th correct security context; 
# - cyglsa requires a reboot after every update of the cygwin package. This can be hard on servers in order to keep up to date; https://www.cygwin.com/ml/cygwin-developers/2006-11/msg00000.html, https://cygwin.com/ml/cygwin/2004-09/msg00087.html

# Set variables
hostIP=$2
host=$3
authmethod=$4
authfile=$5
sshexitcode=

###################
#### Functions ####
###################

function CreateBase64String {

	echo "BackupPC Info: Creating Base64 configuration string..."
	#####
	# Get Rsync username from configuration file
	# 1. Print relevant configuration block from host config
	# 2. Strip out single quotes "'"
	RsyncdUserName=`grep RsyncdUserName /etc/backuppc/$host.pl | \
			cut -d"'" -f2`

	# DEBUG: Write RsyncdUserName to console
	#echo "DEBUG: RsyncdUsername is =" $RsyncdUserName


	#####
	# Get Rsync password from configuration file
	# 1. Print relevant configuration block from host config
	# 2. Strip out single quotes "'"
	RsyncdPasswd=`grep RsyncdPasswd /etc/backuppc/$host.pl | \
		      cut -d"'" -f2`

	# DEBUG: Write RsyncdPasswd to console
	#echo "DEBUG: RsyncdPasswd is =" $RsyncdPasswd

	#####
	# Get Rsync share names
	# 1. Print relevant configuration block from host config
	# 2. Strip out square brackets "[" and "]"
	# 3. Remove all non alpanumeric chars from string 
	RsyncShareName=`sed -n '/RsyncShareName/,/\]/p' /etc/backuppc/$host.pl | \
			cut -d"[" -f2 | \
			cut -d"]" -f1 | \
			tr -cd '[:alnum:]'`

	# DEBUG: Write RsyncShareName to console
	#echo "DEBUG: RsyncShareName is =" $RsyncShareName


	# Encode our string in Base64
	RsyncConfigString="RsyncdUserName='$RsyncdUserName'||RsyncdPasswd='$RsyncdPasswd'||RsyncShareName='$RsyncShareName'"
	# DEBUG: Write the base64 string to console
	#echo "DEBUG: RsyncConfigString =" $RsyncConfigString

	#echo $RsyncConfigString | base64
	Base64string=`echo $RsyncConfigString | base64 | tr -cd '[:alnum:]'`
	# DEBUG: Write the base64 string to console
	#echo "DEBUG: Base64string =" $Base64string
}


function StartBackup {
	echo "BackupPC Info: Starting Backup function..."
	#####
	# SSH section
	# Remove existing IP entried in local SSH known hosts file
	ssh-keygen -R $hostIP

	# SSH in to the client, and pass all the arguements needed
	if [[ $authmethod == "sshpass" ]]; then
		echo "BackupPC Info: Using sshpass..."
		sshpass -f $authfile ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action backup -Base64 '$Base64string'"
	else
		ssh -o StrictHostKeyChecking=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action backup -Base64 '$Base64string'"
	fi

	# Save exit code and pid from SSH command
	sshexitcode=`echo $?`
	sshpid=$!

	echo "BackupPC Info: SSH exit code"
	echo $sshexitcode

	echo "BackupPC Info: SSH pid"
	echo $sshpid
}


function PostBackup {
        echo "BackupPC Info: Starting Post-backup function..."
        #####
        # SSH section
        # Remove existing IP entried in local SSH known hosts file
        ssh-keygen -R $hostIP

        # SSH in to the client, and pass all the arguements needed
		if [[ $authmethod == "sshpass" ]]; then
			echo "BackupPC Info: Using sshpass..."
			sshpass -f $authfile ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action post-backup"
		else
			ssh -o StrictHostKeyChecking=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action post-backup"
		fi

        # Save exit code and pid from SSH command
        sshexitcode=`echo $?`
        sshpid=$!

        echo "BackupPC Info: SSH exit code"
        echo $sshexitcode

        echo "BackupPC Info: SSH pid"
        echo $sshpid
}


function StartRestore {
        echo "BackupPC Info: Starting restore function..."
        #####
        # SSH section
        # Remove existing IP entried in local SSH known hosts file
        ssh-keygen -R $hostIP

        # SSH in to the client, and pass all the arguements needed
		if [[ $authmethod == "sshpass" ]]; then
			echo "BackupPC Info: Using sshpass..."
			sshpass -f $authfile ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action restore -Base64 '$Base64string'"
		else
			ssh -o StrictHostKeyChecking=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action restore -Base64 '$Base64string'"
		fi


        # Save exit code and pid from SSH command
        sshexitcode=`echo $?`
        sshpid=$!

        echo "BackupPC Info: SSH exit code"
        echo $sshexitcode

        echo "BackupPC Info: SSH pid"
        echo $sshpid
}


function PostRestore {
        echo "BackupPC Info: Starting PostRestore function..."
        #####
        # SSH section
        # Remove existing IP entried in local SSH known hosts file
        ssh-keygen -R $hostIP

        # SSH in to the client, and pass all the arguements needed
		if [[ $authmethod == "sshpass" ]]; then
			echo "BackupPC Info: Using sshpass..."
			sshpass -f $authfile ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action post-restore"
		else
			ssh -o StrictHostKeyChecking=no BackupPC@$hostIP "powershell.exe -ExecutionPolicy Bypass -file c:/BackupPC/BackupPC.ps1 -Action post-restore"
		fi

        # Save exit code and pid from SSH command
        sshexitcode=`echo $?`
        sshpid=$!

        echo "BackupPC Info: SSH exit code"
        echo $sshexitcode

        echo "BackupPC Info: SSH pid"
        echo $sshpid
}



##############
#### Main ####
##############

# Check number of params
if [ "$#" -lt "3" ]; then
	echo "Critical: Illegal number of parameters"
        echo "Usage: Script [option] [\$hostIP] [\$host] [authmethod + Auth file]"
		echo "Example 1: BackupPC_PowerShell.sh --Backup \$hostIP \$host"
		echo "Example 2: BackupPC_PowerShell.sh --Backup \$hostIP \$host sshpass /etc/backuppc/auth.txt"
        echo "--backup : Backup files on host"
        echo "--restore : Restore files to host"
        echo "--post-backup : Post-backup command to unload rsync deamon on host"
		echo "--post-restore : Post-backup command to unload rsync deamon on host"
		echo ""
		echo "authmethod - Use sshpass if keyless SSH is not available on host"
	exit 1
fi


case $1 in
  --backup)
        CreateBase64String
        StartBackup
	;;
  --post-backup)
	PostBackup
	;;
  --restore)
	 CreateBase64String
	StartRestore
	;;
  --post-restore)
        PostRestore
        ;;
  -?*) 
	action='unknown'
	echo "BackupPC Critical: Unknown parameter supplied. Exiting script!"
	exit 1
	;;
esac



# If SSH command exits with staus non-zero status, we print the error code, and exit the script.
if [ "$sshexitcode" -ne 0 ]; then
	echo "BackupPC Critical: SSH connection failed with status code: $sshexitstatus"
	echo "BackupPC Critical: Exiting script!"
	exit 1
else
	sleep 5
	echo "BackupPC Info: Pre-command completed succesfully"
	exit 0
fi
