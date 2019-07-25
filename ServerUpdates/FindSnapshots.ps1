$Prod = "172.16.4.140"
$HQ = "172.16.4.30"
$CBS = "172.16.5.20"
$DMZ = "192.168.1.20"
Write-host "
-----------
Prod
-----------"
Connect-VIServer $Prod
Get-Snapshot -VM *| Select Name,VM
Write-host "
-----------
HQ
-----------"
Connect-VIServer $HQ
Get-Snapshot -VM * | Select Name,VM
Write-host "
-----------
CBS
-----------"
Connect-VIServer $CBS
Get-Snapshot -VM * | Where-Object {$_.Name -NotLike "Restore Point*"} | Select Name,VM
Write-host "
-----------
DMZ
-----------"
Connect-VIServer $DMZ
Get-Snapshot -VM * | Select Name,VM