# Wait-Debugger
$Date = Get-Date -Format FileDate
$DC4VMname = "new_DC4_Restored" + $Date
$DC5VMname = "new_DC5_Restored" + $Date
$DCCBSVMname = "new_DCCBS_Restored" + $Date
$SafeBoot = 'bcdedit /deletevalue safeboot'
$BackupPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
$BackupCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "Backup\josephw",$Backuppass
Add-PSSnapin VeeamPSSnapin
Connect-VBRServer -Server Backup -Credential $BackupCreds
$DC5RestorePoint = Get-VBRRestorePoint -Name *DC5*
Start-VBRRestoreVM -RestorePoint $DC5RestorePoint[-1] -Server 172.16.4.200 -VMName $DC5VMName
Disconnect-VBRServer