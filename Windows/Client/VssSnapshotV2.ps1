## Name: VssSnapshotV2.ps1

## Source: https://serverfault.com/questions/119120/how-to-use-a-volume-shadow-copy-to-make-backups
## Aurthor: john Holmer, https://serverfault.com/users/104911/john-homer 
## Note: Script needs to be elevated to run

Param ([String]$Action, [String]$Target, [String]$Volume, [Switch]$DosDev, [Switch]$Debug)
$ScriptCommandLine = $MyInvocation.Line
$vshadowPath = "."

$localLogFile = "C:\BackupPC\temp\log_VSS.txt"
$ShadowID_log = "C:\BackupPC\temp\ShadowID.log"


#Functions

Function Check-Environment {
  Write-Dbg "Checking environment..."
 
$UsageMsg = @'
VssSnapshot
 
Description:
  Create, mount or delete a Volume Shadow Copy Service (VSS) Shadow Copy (snapshot)
 
Usage:
  VssSnapshot.ps1 Create -Target <Path> -Volume <Volume> [-Debug]
  VssSnapshot.ps1 Delete -Target <Path> [-Debug]
 
Paremeters:
  Create  - Create a snapshot for the specified volume and mount it at the specified target
  Delete  - Unmount and delete the snapshot mounted at the specified target
  -Target - The path (quoted string) of the snapshot mount point
  -Volume - The volume (drive letter) to snapshot
  -Debug  - Enable debug output (optional)
  -DosDev - Mounts the Drive via the old DosDev Method (Note: Assumes $Target is a drive letter rathe then a folder)
 
Examples:
  VssSnapshot.ps1 Create -Target D:\Backup\DriveC -Volume C
  - Create a snapshot of volume C and mount it at "D:\Backup\DriveC"
 
  VssSnapshot.ps1 Delete -Target D:\Backup\DriveC
  - Unmount and delete a snapshot mounted at "D:\Backup\DriveC"
 
Advanced:
  VssSnapshot.ps1 create -t "c:\vss mount\c" -v C -d
  - Create a snapshot of volume C and mount it at "C:\Vss Mount\C"
  - example mounts snapshot on source volume (C: --> C:)
  - example uses shortform parameter names
  - example uses quoted paths with whitespace
  - example includes debug output
'@
 
  If ($Action -eq "Create" -And ($Target -And $Volume)) {
    $Script:Volume = (Get-PSDrive | Where-Object {$_.Name -eq ($Volume).Substring(0,1)}).Root
    If ($Volume -ne "") {
      Write-Dbg "Verified volume: $Volume"
    } Else {
      Write-Dbg "Cannot find the specified volume"
      Exit-Script "Cannot find the specified volume"
    }
    Write-Dbg "Argument check passed"
  } ElseIf ($Action -eq "Delete" -And $Target) {
    Write-Dbg "Argument check passed"
  } Else {
    Write-Dbg "Invalid arguments: $ScriptCommandLine"
    Exit-Script "Invalid arguments`n`n$UsageMsg"
  }
 
 
 Write-Log "Checking types on data"
 Write-Log "Target = $Target"
 $testVariable = "[byte][char] = " + [byte[]][char[]]$Target
 Write-Log "$testVariable"
 $testVariable = "Target - Get Type = " + $Target.GetType()
 Write-Log "$testVariable"
 $testVariable = "Target - Get FullName Type = " + $Target.GetType().FullName
 Write-Log "$testVariable"
 
 Write-Log "Volume = $Volume"
 $testVariable = "Volume - Get Type = " + $Volume.GetType()
 Write-Log "$testVariable"
 $testVariable = "Volume - Get FullName Type = " + $Volume.GetType().FullName
 Write-Log "$testVariable"
 
 
 Write-Dbg "Environment ready"
}

#Target = mounting path
Function Prepare-Target {
  Write-Log "STANDARD - Preparing target..."
  Write-Dbg "STANDARD - Preparing target $Target"
 
 
  If (!(Test-Path (Split-Path $Target -Parent))) {
  Write-Dbg "Target parent does not exist"
  Exit-Script "Invalid target $Target"
  }
  If ((Test-Path $Target)) {
    Write-Dbg "Target already exists"
    If (@(Get-ChildItem $Target).Count -eq 0) {
      Write-Dbg "Target is empty"
    } Else {
      Write-Dbg "Target is not empty"
      Exit-Script "Target contains files/folders"
    }
  } 
  
  Write-Log "Target ""$Target"" ready"
  Write-Dbg """$Target"" ready"
}



Function Create-Snapshot {
  Write-Log "STANDARD - Creating snapshot..."
  Write-Dbg "STANDARD - Creating snapshot of $Volume"
  
  $driveLetter = $Volume
  Write-Dbg "Letter is $driveLetter"
  
  $class = [WMICLASS]"root\cimv2:win32_shadowcopy"
   
  $s1 = $class.Create($driveLetter, "ClientAccessible")
 
  Write-Dbg "Snapshot created successfully"
 
  #get the volume/shadow ID
  #get created volume ID

  $SnapshotID = $s1.ShadowID
  If ($SnapshotID) {
    #$SnapshotID = $Matches[1]
    Write-Dbg "SnapshotID: $SnapshotID"
    Write-Log "Snapshot $SnapshotID created"
    
    #$ShadowID_log_temp = $SnapshotID.replace("{", "")
    #$ShadowID_log_temp = $ShadowID_log_temp.replace("}", "")
    add-content $ShadowID_log $SnapshotID
  } Else {
    Write-Dbg "Unable to determine SnapshotID"
    Exit-Script "Unable to determine SnapshotID"
  }
 
  Return $SnapshotID
}



Function Mount-Snapshot ($SnapshotID) {
  Write-Log "STANDARD - Mounting snapshot..."
  Write-Dbg "STANDARD - Mounting $SnapshotID at ""$Target"""
 
  $object = gwmi Win32_ShadowCopy | ? { $_.ID -eq $SnapshotID }
 
  # add the trailing slash thats missing
  # Needs the \ slash due to it being a URL based field
  $mountPoint  = $object.DeviceObject + "\"
  
  Write-Dbg "Before Target: $Target"
  #reverse the / with \ if there are any
  $safeString = $Target -replace "/","\"
  Write-Dbg "After Target: $safeString"
  
  $Cmd = "cmd /c mklink /d `"$safeString`" '$mountPoint'"
  $CmdResult = Run-Command $Cmd
 
  Write-Log "Snapshot $SnapshotID mounted at target ""$Target"""
  Write-Dbg "$SnapshotID mounted at ""$Target"""
}

#Delete-Snapshot
Function Delete-Snapshot {
  Write-Log "Deleting snapshot..."
  Write-Dbg "Deleting snapshot at target ""$Target"""
 
  #remove the target directory / unmount the snapshot
  #Remove-Item $Target -Confirm:$false -Force  
  
  Write-Dbg "Before Target: $Target"
  #reverse the / with \ if there are any
  $safeString = $Target -replace "/","\"
  Write-Dbg "After Target: $safeString"
  
    
  $Cmd = "cmd /c rmdir $safeString"
  $CmdResult = Run-Command $Cmd
  
  Write-Dbg "Directory ""$Target"" Removed"
 
  Write-Dbg "Deleting all possible Snapshots..."
  
  Get-WmiObject -class win32_shadowcopy | Foreach-Object `
	{
		$shadow_date=$_.ConvertToDateTime($_.InstallDate)
		$age=(Get-Date)-($shadow_date)
		if(($age.TotalDays) -gt '1') {
            Write-Dbg "Deleting Snapshot with ID $SnapshotID from $shadow_date"
			$_.Delete()
		}
	}
 
  Write-Log "Snapshots removed"
  Write-Dbg "$SnapshotID deleted at ""$Target"""
}

 #Target = mounting path
Function Prepare-DosDev {
  Write-Log "DOSDEV - Preparing target..."
  Write-Dbg "DOSDEV - Preparing target $Target"
 
 $temptget = ""
  #Add the trailing : that's missing
    If(!($Target -match '^[a-zA-Z]:')){
    $temptget = $Target + ":"
    Write-Dbg "temptget was changed to: $temptget"
    }
    else{
    Write-Dbg "$Target was fine"
    $temptget = $Target
    
    }
 
  #Check if the drive exists
  If (!(Test-Path $temptget)){
    Write-Dbg "$Target doesn't exist, Safe for mounting"
  }
  else {
    Exit-Script "Drive Exists, unable to mount"
  }
  
  If(!($Target -match '^[a-zA-Z]')){
    Exit-Script "incorrect syntax for drive letter"
  }
  
  
  Write-Log "Target ""$Target"" ready"
  Write-Dbg """$Target"" ready"
}
 
 
Function Mount-DosDev ($SnapshotID) {
    Write-Log "DOSDEV - Mounting snapshot..."
    Write-Dbg "DOSDEV - Mounting snapshot at target ""$Target"""
        
    #Get the snapshot in question
    $object = gwmi Win32_ShadowCopy | ? { $_.ID -eq $SnapshotID }
    
    
    
    # add the trailing slash that's missing
    $mountPoint  = $object.DeviceObject + "\"
    Write-Log "DOSDEV - mount point = $mountPoint"
    
    $env:SHADOW_SET_ID = $object.SetID
    $env:SHADOW_ID_1 = $SnapshotID
    $env:SHADOW_DEVICE_1 = $object.DeviceObject
    
    # add the trailing :, if it's missing the mount will fail
    If(!($Target -match '^[a-zA-Z]:')){
    $TempTarget = $Target + ":"
    Write-Dbg "TempTarget was changed to: $TempTarget"
    }
    else{$TempTarget = $Target}
    
#Does not like being shifted away from the start of a line. i.e. WHITE SPACE SENSITIVE
$MethodDefinition = @'
[DllImport("kernel32.dll", CharSet=CharSet.Auto, SetLastError=true)]
public static extern bool DefineDosDevice(int dwFlags, string lpDeviceName, string lpTargetPath);
'@

    $Kernel32 = Add-Type -MemberDefinition $MethodDefinition -Name 'Kernel32' -Namespace 'Win32' -PassThru
    [uint32]$Flag = 0
    $DefineDosDeviceResult = $Kernel32::DefineDosDevice($Flag, $TempTarget, $mountPoint)

    
    if($DefineDosDeviceResult)
    { 
        Write-Log "Drive Mounted Successfully"
    }
    else{
        Exit-Script "Drive Failed to mount"
    }
    
    
    Write-Log "Mounted snapshot..."
    Write-Dbg "Mounted snapshot at target ""$Target"""
    
  
}

Function Remove-DosDev  {
    Write-Log "DOSDEV - Deleting snapshot..."
    Write-Dbg "DOSDEV - Deleting snapshot at target ""$Target"""
  
    #Add the trailing : that's missing
    If(!($Target -match '^[a-zA-Z]:')){
    $Target = $Target + ":"
    }
        
Add-Type @"
using System;
using System.Runtime.InteropServices;
 
public class MountPoint
{
[DllImport("kernel32.dll", CharSet=CharSet.Auto, SetLastError=true)]
public static extern bool DeleteVolumeMountPoint(string mountPoint);
}
"@
 
[MountPoint]::DeleteVolumeMountPoint($Target)

Write-Dbg "Deleting all possible Snapshots..."
  
  Get-WmiObject -class win32_shadowcopy | Foreach-Object `
	{
		$shadow_date=$_.ConvertToDateTime($_.InstallDate)
		$age=(Get-Date)-($shadow_date)
		if(($age.TotalDays) -gt '1') {
            Write-Dbg "Deleting Snapshot with ID $SnapshotID from $shadow_date"
			$_.Delete()
		}
	}
 
  Write-Log "Snapshots removed"
  Write-Dbg "$SnapshotID deleted at ""$Target"""

}


Function Run-Command ([String]$Cmd, [Switch]$AsString=$False, [Switch]$AsArray=$False) {
  Write-Dbg "Running: $Cmd"
 
  $CmdOutputArray = Invoke-Expression $Cmd
  $CmdOutputString = $CmdOutputArray | Out-String
  $CmdErrorCode = $LASTEXITCODE
 
  If ($CmdErrorCode -eq 0 ) {
    Write-Dbg "Command successful. Exit code: $CmdErrorCode"
    Write-Dbg $CmdOutputString
  } Else {
    Write-Dbg "Command failed. Exit code: $CmdErrorCode"
    Write-Dbg $CmdOutputString
    Exit-Script "Command failed. Exit code: $CmdErrorCode"
  }
 
  If (!($AsString -or $AsArray)) {
    Return $CmdErrorCode
  } ElseIf ($AsString) {
    Return $CmdOutputString
  } ElseIf ($AsArray) {
    Return $CmdOutputArray
  }
}
 
 
Function Write-Msg ([String]$Message) {
  If ($Message -ne "") {
    Write-Host $Message
    Add-Content $localLogFile $Message
  }
}
 
Function Write-Log ([String]$Message) {
  Write-Msg "[$(Get-Date -Format G)] $Message"
}
 
Function Write-Dbg ([String]$Message) {
  If ($Debug) {
    Write-Msg ("-" * 80)
    Write-Msg "[DEBUG] $Message"
    Write-Msg ("-" * 80)
  }
}
 
Function Exit-Script ([String]$Message) {
  If ($Message -ne "") {
    Write-Msg "`n[FATAL ERROR] $Message`n"
  }
  Exit 1
}
 
# Main
Write-Log "VssSnapshot started"
Check-Environment
If ($DosDev) {
    Switch ($Action) {
        "Create" {
            Prepare-DosDev
            $SnapshotID = Create-Snapshot          
            Mount-DosDev $SnapshotID
        }
        "Delete" {
            Remove-DosDev
        }
    }
} else {
    Switch ($Action) {
        "Create" {
            Prepare-Target
            $SnapshotID = Create-Snapshot

            Mount-Snapshot $SnapshotID
        }
        "Delete" {
            Delete-Snapshot
        }
    }
}
 
Write-Log "VssSnapshot finished"
