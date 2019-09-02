$Conf{BackupFilesExclude} = {
  'C' => [
    '/Users/*/AppData/Local/Microsoft/Windows/Temporary Internet Files',
    '/Users/*/AppData/Local/Temp',
    '/Users/*/NTUSER.DAT*',
    '/Users/*/ntuser.dat*',
    '/Users/*/AppData/Local/Microsoft/Windows/UsrClass.dat*',
    '/Users/*/AppData/Local/Microsoft/Windows Defender/FileTracker',
    '/Users/*/AppData/Local/Microsoft/Windows/Explorer/thumbcache_*.db',
    '/Users/*/AppData/Local/Microsoft/Windows/WER',
    '/Users/*/AppData/Local/Mozilla/Firefox/Profiles/*/Cache',
    '/Users/*/AppData/Local/Mozilla/Firefox/Profiles/*/OfflineCache',
    '/Users/*/AppData/Roaming/Microsoft/Windows/Cookies',
    '/Users/*/AppData/Roaming/Microsoft/Windows/Recent',
    'ProgramData/Microsoft/Search',
    'ProgramData/Microsoft/Windows Defender',
    '*.lock',
    'Thumbs.db',
    'IconCache.db',
    '*.ost',
    '*.nst',
    '/Users/*/Downloads',
    '/Users/*/Pictures',
    '/Users/*/Music',
    '/Users/*/Videos'
  ]
};
$Conf{BackupFilesOnly} = {
  'C' => [
    '/Users'
  ]
};
$Conf{DumpPostUserCmd} = '/etc/backuppc/BackupPC_PowerShell.sh --post-backup $hostIP  $host';
$Conf{DumpPreUserCmd} = '/etc/backuppc/BackupPC_PowerShell.sh --backup $hostIP $host';
$Conf{RestorePostUserCmd} = '/etc/backuppc/BackupPC_PowerShell.sh --post-restore $hostIP $host';
$Conf{RestorePreUserCmd} = '/etc/backuppc/BackupPC_PowerShell.sh --restore $hostIP $host';
$Conf{RsyncRestoreArgs} = [
  '--numeric-ids',
  '--chmod=ugo=rwX',
  '--owner',
  '--group',
  '-D',
  '--links',
  '--hard-links',
  '--times',
  '--block-size=2048',
  '--relative',
  '--ignore-times',
  '--recursive'
];
$Conf{XferMethod} = 'rsyncd';
$Conf{RsyncdPasswd} = '<SuperSecretPassword>';
$Conf{RsyncdUserName} = '<BackupPCadmin>';
$Conf{RsyncShareName} = [
  'C'
];
$Conf{UserCmdCheckStatus} = '1';

