# BackupPC - Powershell implementation
# File:   BackupPC.ps1 
# Description:  Backup host to BackupPC server using VSS
# Requirements: Windows PowerShell 4.0
# Authour:  Simon Utter
# Version:  2.2
# Date:  2019-08-01

# TODO:
# - Add check if variable is passed to script
# - Consistent logging format between scripts
# - Change -Include Username checks to use PoSH v2 compatible syntax

#######################
###### Arguments ######
#######################

# Possible actions:
# "-Action backup"
#     - Base64 Parameter is required for the backup action
#     - Example: "PowerShell.exe -file c:/BackupPC/BackupPC.ps1 -Action backup -Base64 '$Base64string'"
#
# "-Action post-backup"
#     - Example: "PowerShell.exe -file c:/BackupPC/BackupPC.ps1 -Action post-backup"
#
# "-Action restore"
#     - Base64 Parameter is required for the restore action
#     - Example: "PowerShell.exe -file c:/BackupPC/BackupPC.ps1 -Action restore -Base64 '$Base64string'"
#
# "-Action post-restore"
#     - Example: "PowerShell.exe -file c:/BackupPC/BackupPC.ps1 -Action post-restore"

########################################
###### Additional pre-cmd scripts ######
########################################

# To run any additinal pre/post backup command scripts (eg. dumping a sql server db), place the .ps1 scripts in the following folders:
# - For Pre-command scripts: C:\BackupPC\UserScripts\Pre-Scripts
# - For Post-command scripts: C:\BackupPC\UserScripts\Post-Scripts
# All scripts in these folders are executed recursivly, so take care of what scripts resides in these folders.
# Make sure you have the right security measures in place to restrict execution.
# Potentially a security hole as a malicious user could place a script in these folders and run them at elivated previlages.
# I recommend applying folder permissions and script signing.



Param (
    [String]$Action, 
    [String]$Base64
    )


#######################
###### Variables ######
#######################

Write-host "INFO: Setting variables..."
Write-host $Base64


# Setting BackupPC location variable
$BackupPCLocation = "C:/BackupPC"
$TempDir = "C:/BackupPC/temp"
$PSTempDir = "C:/BackupPC/temp"

# Rsync binary variables
$rsync32Folder = "rsync_32"
$rsync64Folder = "rsync_64"
$rsyncEXE = "/rsync.exe"

# Rsync config file settings
$rsyncSecretsFile = "/cygdrive/C/BackupPC/temp/rsyncd.secrets"
$rsyncSecretsFileWin = "C:\BackupPC\temp\rsyncd.secrets"
$rsyncPIDFile = "/cygdrive/C/BackupPC/temp/rsyncd.pid"

$rsyncConfigFile = "C:\BackupPC\temp\rsyncd.conf"

$wakeupFile = $TempDir + "/wake.up"
$sleepSecrets = $backupPCLocation + "/sleep.secrets"
  
$localLogFile  = "C:\BackupPC\temp\PoSH.log"
$rsynclocalLogFile  = "C:/BackupPC/temp/rsyncd.log"



#######################
###### Functions ######
#######################

function CreateTempdir(){
    $TempDirExists = Test-Path $PSTempDir
    if ($TempDirExists -eq $False){
        Write-Host "Temp directory does not exsist. Creating..."
        New-Item -ItemType directory -Path $PSTempDir\
    }
}

function LogIt($logText){
      
    $logTime = Get-Date -UFormat "%Y-%m-%d-%H:%M:%S"
    $text = $logTime + " " + $logText
    
    Write-Host "$text"
    if (!(Test-Path "C:\BackupPC\temp\PoSH.log"))
    {
        New-Item -path C:\BackupPC\temp -name PoSH.log -type "file"
        Add-Content $localLogFile $text
     }
     else
     {
         Add-Content $localLogFile $text
     }
}


  function convertThing($Message){
      $CipherText=$Message
      Return "$CipherText"
  }


 function CreateConfigFile($Message){    
    
}


  function DriveDetection(){
    $RsyncShareName = $RsyncShareName.ToCharArray()

    foreach ($HostPhysicalDrive in $RsyncShareName){

        $DosDevDrive = ls function:[d-z]: -n | ?{ !(test-path $_) } | select -Last 1

        $temp =  "Info: Selected Drive to mount VSS copy at..." + $DosDevDrive
        LogIt $temp

        $temp =  "Info: Selected Physical Drive ..." + $HostPhysicalDrive
        LogIt $temp

        $VssSnapShotScript = "C:\BackupPC\VssSnapshotV2.ps1 Create -Target $DosDevDrive -Volume $HostPhysicalDrive -DosDev"
        Invoke-Expression ((Split-Path $MyInvocation.InvocationName) + $VssSnapShotScript)
        
        $script:VSSDosDevDrive += $DosDevDrive -Replace "\:", ""
    }

  }


 function UnmountSnapshots() {
    LogIt "Info: Checking if BackupPC has previosuy mounted Snapshots on system..."
    $SnapshotsFile = Test-Path C:\BackupPC\temp\ShadowID.log
    if ($SnapshotsFile -eq $True){
        LogIt "Info: Deleting all shadow copies on host..."
        foreach($line in Get-content C:\BackupPC\temp\ShadowID.log){
            LogIt "Info: Deleting snapshot $line"
            Get-WmiObject Win32_Shadowcopy | ForEach-Object {
                If ($_.ID -eq $line) {
                    $_.Delete()
                }           
            }
        }
     LogIt "Info: Deleted all shadow copies on host!"
    }
}

function Cleanup() {
    $TempDirExists = Test-Path $PSTempDir
    if ($TempDirExists -eq $True){
        Write-Host "Info: Temp directory exists. Removing old files..."
        Remove-Item -Recurse -Force -Path $PSTempDir\*
    }

    # If Powershell is below version 4
    if ($PSVersionTable.PSVersion -lt "4.0"){
        # PS2 compatability
        # https://stackoverflow.com/questions/43746452/powershell-script-to-get-logged-in-user
        $owners = @{}
        gwmi win32_process |% {$owners[$_.handle] = $_.getowner().user}
        # Kill all BackupPC processes except the current PowerShell session
        get-process | select processname,Id,@{l="Owner";e={$owners[$_.id.tostring()]}} | Where-Object { $_.Owner -Match "backuppc" } | Where-Object {$_.Id -NotMatch $pid} | Stop-Process -Force
    }
    else {
        # Kill all BackupPC processes except the current PowerShell session
        Get-Process -IncludeUserName | Where-Object { $_.ID -ne $pid } | Where UserName -Match BackupPC | Stop-Process -Force    
    }

    # Kill other rsync processes
    # NOTE: This is probaly not the best idea, as it can kill other users rsync transfers. If not killed, the backup process will never start
    # NOTE: We need to kill all rsync instances as this blocks port 873 whcih rsync uses
    Get-Process | Where ProcessName -Match rsync | Stop-Process -Force



}

function Base64Decode() {
    $encodeString = $Base64
    $decodeString=""
    Try
    {
        $decodeString=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodeString))
    }
    Catch
    {
        Try
        {   
            # Try appending a equals charachter
            $encodeString = $encodeString + "="
            $decodeString=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodeString))
        }
        Catch
        {
            Try
            {
                # Try appending a second set of equals char
                $encodeString = $encodeString + "="
                $decodeString=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodeString))
            }
            Catch
            {
                LogIt "Base64 Info: Unable to get decode base64 string"
                Exit 1
            }
        }
    }
    
    # Decoder should output as below example, where "||" is a unique separator
    # RsyncdUserName= 'BackupPC'||RsyncdPasswd= 'Password'||RsyncShareName= 'C E'
    $arr = $decodeString -split '\|\|'
    
    # Create variables based of decoded string
    # Values assigned in the foreach loop
    $RsyncdUserName=""
    $RsyncdPasswd=""
    $script:RsyncShareName=""
    
    foreach ($section in $arr) {
        $current = $section -split '='
        if($current[0] -eq "RsyncdUserName"){
            $a = $current[1]
            # Strip the '' and space from each one
            $a = $a -replace "\ ",""
            $a = $a -replace "\'",""
            $a = $a -replace "`n|`r"
            $script:RsyncdUserName = $a
        }
  
        elseif($current[0] -eq "RsyncdPasswd"){
            $a = $current[1]
            # Strip the '' and space from each one
            $a = $a -replace "\ ",""
            $a = $a -replace "\'",""
            $a = $a -replace "`n|`r"
            $script:RsyncdPassword = $a
        }
        
        elseif($current[0] -eq "RsyncShareName"){
            $a = $current[1]
            # Strip the '' and space from each one
            $a = $a -replace "\ ",""
            $a = $a -replace "\'",""
            $a = $a -replace "`n|`r"
            $RsyncShareName = ""

            # Set variable in script scoe as we need to use this outside this functions
            $script:RsyncShareName = $a

            LogIt "Debug; decode base64: RsyncSharename is $RsyncShareName"
        }
    }


}

function StartRsync() {

# If 32 bit environment
if ($env:PROCESSOR_ARCHITECTURE -eq "x86"){
    LogIt "Info: 32bit Windows"
    LogIt "Info: setting Rsync Variables"
    $rsyncEXE = $backupPCLocation + "/" +$rsync32Folder + $rsyncEXE
    $env:CWRSYNCHOME = "\BACKUPPC\" + $rsync32Folder
    $env:CYGWIN = 'nontsec'
    $env:CWOLDPATH = $env:PATH
    $env:PATH = ("\BACKUPPC\" + $rsync32Folder + ";" + $env:PATH)

}
# If 64bit environment
elseif ($env:PROCESSOR_ARCHITECTURE -eq 'amd64') {
    LogIt "Info: 64bit windows"
    LogIt "Info: setting Rsync Variables"
    $rsyncEXE = $backupPCLocation + "/" + $rsync64Folder + $rsyncEXE
    $env:CWRSYNCHOME = "\BACKUPPC\" + $rsync64Folder
    $env:CYGWIN = 'nontsec'
    $env:CWOLDPATH = $env:PATH
    $env:PATH = ("\BACKUPPC\" + $rsync64Folder + ";" + $env:PATH)
}
else {
    LogIt "Info: FATAL ERROR: Unable to determine Architecture"
    Exit 1
}

LogIt "Info: Starting Rsync"
$rsyncVAR = "-vvv --daemon --no-detach --config=" + $rsyncConfigFile + " --log-file=" + $rsynclocalLogFile

# Start the Rsync process
Start-Process $rsyncEXE $rsyncVAR

}

function BuildConfigurationFile() {
LogIt "Info: Creating New Config files"

$temp = $RsyncdUserName + ":" + $RsyncdPassword
Add-Content $rsyncSecretsFileWin $temp
  
# Add content to Rsyncd config file
Add-Content $rsyncConfigFile "use chroot = false"
Add-Content $rsyncConfigFile "strict modes = false"
$PidFileLocation = "pid file = " + $rsyncPIDFile
Add-Content $rsyncConfigFile $PidFileLocation
Add-Content $rsyncConfigFile "socket options = SO_RCVBUF=65536 SO_SNDBUF=65536"


if ($Action -like "backup"){
    $VssDriveArray = $VSSDosDevDrive.ToCharArray()
}

$PhysicalDriveArray = $RsyncShareName.ToCharArray()
$i=0
    foreach ($HostPhysicalDrive in $PhysicalDriveArray){
        
        if ($Action -like "backup"){
                $temp = "Info: Adding DosDev drive mount point to config: " + $VssDriveArray[$i]
            }

        if ($Action -like "restore"){
                $temp = "Info: Adding Physical drive mount point to config: " + $HostPhysicalDrive
            }

        LogIt $temp
        
        
        Add-Content $rsyncConfigFile " "
        $ShadowDrive = "[" + $HostPhysicalDrive + "]"
        Add-Content $rsyncConfigFile $ShadowDrive
        
        $variable = "secrets file = " + $rsyncSecretsFile
        Add-Content $rsyncConfigFile $variable

        if ($Action -like "backup"){
                $variable = "path = /cygdrive/" + $VssDriveArray[$i] + "/"
                $temp = "Info: Adding VSS mount point " + $HostPhysicalDrive + " to Rsyncd config"
            }

        if ($Action -like "restore"){
            $temp = "Info: Adding physical drive " + $HostPhysicalDrive + " to Rsyncd config"
                $variable = "path = /cygdrive/" + $HostPhysicalDrive + "/"
            }

        LogIt $temp

        Add-Content $rsyncConfigFile $variable
        
        $variable = "auth users = " + $RsyncdUserName
        Add-Content $rsyncConfigFile $variable
          
        Add-Content $rsyncConfigFile "read only = false"  
        $i++
    }
    
    
    LogIt "Info: Config creation completed!"
}

function Pre_command_scripts(){
    LogIt "Info: Executing pre-command scripts..."
    $Files = @(Get-ChildItem 'C:\BackupPC\UserScripts\Pre-Scripts')
    if ($Files.length -eq 0) {
        write-host "Info: Pre-command scripts - No scripts to execute." 
    } else {
        Get-ChildItem 'C:\BackupPC\UserScripts\Pre-Scripts' | ForEach-Object {
            & $_.FullName
          }
    }
}

function Post_command_scripts(){
    LogIt "Info: Executing post-command scripts..."
    $Files = @(Get-ChildItem 'C:\BackupPC\UserScripts\Post-Scripts')
    if ($Files.length -eq 0) {
        write-host "Info: Post-command scripts - No scripts to execute." 
    } else {
        Get-ChildItem 'C:\BackupPC\UserScripts\Post-Scripts' | ForEach-Object {
            & $_.FullName
          }
    }
}

##################
###### Main ######
##################

    Switch ($Action) {
        "backup" {
            UnmountSnapshots
            Cleanup
            CreateTempdir
            Pre_command_scripts
            Base64Decode       
            DriveDetection
            BuildConfigurationFile
            StartRsync
        }
        "post-backup" {
            Post_command_scripts
            UnmountSnapshots
            Cleanup
        }
        "restore" {
            Cleanup
            CreateTempdir
            Base64Decode
            BuildConfigurationFile
            StartRsync
        }
        "post-restore" {
            Cleanup
        }
    }
