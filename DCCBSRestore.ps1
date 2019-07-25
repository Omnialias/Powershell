## To Do - Fix CBSVeeam to use same "version"

### Get Connected
Add-PSSnapin VeeamPSSnapin

### Define some variables for later
$Date = Get-Date -Format MMddyy
$DCCBSVMname = "new_CBSDHCP_Restored" + $Date
$SafeBoot = 'bcdedit /deletevalue safeboot'
$BackupPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
$CBSCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "CBSVeeam\josephw",$Backuppass
# Define job scripts
$DCCBSJob = {
    Add-PSSnapin VeeamPSSnapin
    $Date = Get-Date -Format MMddyy
    $DCCBSVMname = "new_CBSDHCP_Restored" + $Date
    $BackupPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
    $CBSCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "CBSVeeam\josephw",$Backuppass
    Connect-VBRServer -Server 172.16.5.25 -Credential $CBSCreds
    $DCCBSRestorePoint = Get-VBRRestorePoint -Name *DHCP*
    Start-VBRRestoreVM -RestorePoint $DCCBSRestorePoint[-1] -Server 172.16.4.200 -VMName $DCCBSVMName
    Disconnect-VBRServer}
#Run jobs
Start-Job -Name DCCBS -Scriptblock $DCCBSJob
#Wait for jobs to finish before continuing
$GetDCCBSJob = Get-job -Name DCCBS
While ( $GetDCCBSJob.State -eq "Running" ) {
    Write-host "Waiting for restore..."
    Start-sleep -Seconds 60
}
# Change some VM settings
Connect-VIServer -Server 172.16.4.200
$DCCBS = Get-VM -Name $DCCBSVMName
$DCCBS | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName "Isolated w Internet" -Confirm:$false -StartConnected:$false

Start-VM -VM $DCCBS