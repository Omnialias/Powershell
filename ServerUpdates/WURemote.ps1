$Server = Read-Host "Enter ESXi Host IP"
Connect-VIServer $Server
If ( $Server  -eq "172.16.4.140" ) {
    $ImportFile = "C:\Scripts\ServerUpdates\MonthlyFreeUpdateProd.txt" }
    else {
        If ( $Server -eq "172.16.4.30" ) {
            $ImportFile = "C:\Scripts\ServerUpdates\MonthlyFreeUpdateHQ.txt" }
            else {
                If ( $Server -eq "172.16.5.20" ) {
                    $ImportFile = "C:\Scripts\ServerUpdates\MonthlyFreeUpdateCBS.txt" }
                    else { If ( $Server -eq 192.168.1.20 ) {
                        $ImportFile = "C:\Scripts\ServerUpdates\MonthlyFreeUpdateCBS.txt" }
                        else { Break }
                        }
                }
            }                       
    
$Date = Get-Date -Format FileDate
Get-Content $ImportFile | Foreach-Object { New-Snapshot -VM $_ -Name "Pre-Update $Date Joe" -Description "Pre-Update $_ $Date Joe" -RunAsync }
Read-Host "Wait for snapshots to finish, then press enter to continue..."
Get-Content $ImportFile | % {Invoke-WUJob -ComputerName $_ -RunNow -Script { ipmo PSWindowsUpdate; Install-WindowsUpdate -serviceid "3da21691-e39d-4da6-8a4b-b43877bcb1b7" -AcceptAll -IgnoreReboot } -Confirm:$false -Verbose }