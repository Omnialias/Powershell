# $Servers = Get-Content "C:\Scripts\ServerUpdates\MonthlyFreeUpdate.txt"
$Servers = "CTXXA1", "CTXXA2", "CTXXA3", "CTXXA5"
$Credential = Get-Credential
foreach ($server in $Servers) { write-host $server ; invoke-command -ComputerName $server -Credential $Credential -ScriptBlock { 
    gpupdate /force
 } }