$Server = Read-Host "Enter ESXi Host IP"
Connect-VIServer $Server
$Snapshots = Get-Snapshot -VM * -Name "Pre-Update*"
$Snapshots | Format-Table -Autosize
Read-Host "Press Enter if Ready To Delete The Above Snapshots"
Remove-snapshot -Snapshot $Snapshots -RunAsync