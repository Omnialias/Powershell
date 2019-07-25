## To Do - Fix CBSVeeam to use same "version"

### Check for Existing VBRServer Connection and kill it

Add-PSSnapin VeeamPSSnapin
$AmIConnected = Get-VBRServerSession
If ( $AmIConnected -ne $null ) { Write-host "Existing session found. Disconnecting session..."; Disconnect-VBRServer } 

### Define some variables for later
$Date = Get-Date -Format MMddyy
$DC4VMname = "new_DC4_Restored" + $Date
$DC5VMname = "new_DC5_Restored" + $Date
$DCCBSVMname = "new_DCCBS_Restored" + $Date
$SafeBoot = 'bcdedit /deletevalue safeboot'
$AdminPass = Read-Host "Type password for DC4\Administrator. It will stored as a Secure String." -AsSecureString
$BackupPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
$BackupCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "Backup\josephw",$Backuppass
$DC4Args = ($DC4VMname,$BackupCreds)
$DC5Args = ($DC5VMname,$BackupCreds)


### Restore DC VMs to LabHost

# Disable CBSVeeam as Proxy to force local proxy
Connect-VBRServer -Server Backup -Credential $BackupCreds
Disable-VBRViProxy -Proxy "172.16.5.25"
Disconnect-VBRServer

# Define job scripts
$DC4Job = {
    $Date = Get-Date -Format MMddyy
    $DC4VMname = "new_DC4_Restored" + $Date
    $BackupPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
    $BackupCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "Backup\josephw",$Backuppass
    Add-PSSnapin VeeamPSSnapin
    Connect-VBRServer -Server Backup -Credential $BackupCreds
    $DC4RestorePoint = Get-VBRRestorePoint -Name *DC4*
    Start-VBRRestoreVM -RestorePoint $DC4RestorePoint[-1] -Server 172.16.4.200 -VMName $DC4VMName
    Disconnect-VBRServer}
$DC5Job = {
    $Date = Get-Date -Format MMddyy
    Add-PSSnapin VeeamPSSnapin
    $DC5VMname = "new_DC5_Restored" + $Date
    $BackupPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
    $BackupCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "Backup\josephw",$Backuppass
    Connect-VBRServer -Server Backup -Credential $BackupCreds
    $DC5RestorePoint = Get-VBRRestorePoint -Name *DC5*
    Start-VBRRestoreVM -RestorePoint $DC5RestorePoint[-1] -Server 172.16.4.200 -VMName $DC5VMName
    Disconnect-VBRServer}
#$DCCBSJob = {
#    Add-PSSnapin VeeamPSSnapin
#    $Date = Get-Date -Format FileDate
#    $DCCBSVMname = "new_DCCBS_Restored" + $Date       
#    $CBSPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
#    $CBSCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "CBSVEEAM\josephw",$CBSpass
#    Connect-VBRServer -Server 172.16.5.25 -Credential $CBSCreds
#    $DCCBSRestorePoint = Get-VBRBackup -Name "CBS" | Get-VBRRestorePoint -Name *DCCBS* | Sort-Object –Property CreationTime –Descending | Select -First 1
#    Start-VBRRestoreVM -RestorePoint $DCCBSRestorePoint -Server 172.16.4.200 -VMName $DCCBSVMName
#    Disconnect-VBRServer}
#Run jobs
Start-Job -Name DC4 -Scriptblock $DC4Job
Start-Job -Name DC5 -Scriptblock $DC5Job -ArgumentList $DC5VMname,$BackupPass,$BackupCreds
#Start-Job -Name DCCBS -Scriptblock $DCCBSJob -ArgumentList $DCCBSVMname
#Wait for jobs to finish before continuing
$GetDC4Job = Get-job -Name DC4
$GetDC5Job = Get-job -Name DC5
#$GetDCCBSJob = Get-job -Name DCCBS
While ( ( ($GetDC4Job.State -eq "Running") -or ($GetDC5Job.state -eq "Running") ) ) {
    Write-host "Waiting for restore..."
    Start-sleep -Seconds 60
}
# Re-enable proxy
Connect-VBRServer -Server Backup -Credential $BackupCreds
Enable-VBRViProxy -Proxy "172.16.5.25"
Disconnect-VBRServer
#

# Change some VM settings
Connect-VIServer -Server 172.16.4.200
$DC4 = Get-VM -Name $DC4VMName
$DC4 | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName "Isolated w Internet" -Confirm:$false -StartConnected:$true
$DC5 = Get-VM -Name $DC5VMName
$DC5 | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName "Isolated w Internet" -Confirm:$false -StartConnected:$false
#$DCCBS = Get-VM -Name $DCCBSVMName
#$DCCBS | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName "Isolated w Internet" -Confirm:$false -StartConnected:$false

# Start DC4, get it out of safe mode, then start other DCs.

Start-VM -VM $DC4
Do {
    write-host "Waiting for DC4 startup..."
    Start-Sleep -s 60
    $DC4Check = Get-VMGuest -VM $DC4
    } while ( $DC4Check.State -ne "Running" )
Write-host "Continuing..."
Invoke-VMScript -GuestUser "DC4\administrator" -GuestPassword $AdminPass -VM $DC4 -ScriptText $SafeBoot -ScriptType Bat
Restart-VMGuest -VM $DC4
Do {
    write-host "Waiting for DC4 startup..."
    Start-Sleep -s 60
    $DC4Check = Get-VMGuest -VM $DC4
    } while ( $DC4Check.State -ne "Running" )
Write-Host "Done. Starting other DCs."
Start-VM -VM $DC5
#Start-VM -VM $DCCBS

Read-Host "Open the CBSVeeam console then press any button to continue..."

### Define some variables for later
Add-PSSnapin VeeamPSSnapin
$Date = Get-Date -Format MMddyy
$DCCBSVMname = "new_DCCBS_Restored" + $Date
$BackupPass = get-content C:\Scripts\CBSVeeamPass.txt | Convertto-securestring
$CBSCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist "CBSVeeam\josephw",$Backuppass
Connect-VBRServer -Server 172.16.5.25 -Credential $CBSCreds
$DCCBSRestorePoint = Get-VBRRestorePoint -Name *DCCBS*
Start-VBRRestoreVM -RestorePoint $DCCBSRestorePoint[-1] -Server 172.16.4.200 -VMName $DCCBSVMName
Disconnect-VBRServer

# Change some VM settings
Connect-VIServer -Server 172.16.4.200
$DCCBS = Get-VM -Name $DCCBSVMName
$DCCBS | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName "Isolated w Internet" -Confirm:$false -StartConnected:$false

Start-VM -VM $DCCBS