$Box = Show-AnyBox -Title 'InputBoxDemo' -Buttons 'Cancel','Submit' -Prompts @(
    New-AnyBoxPrompt -InputType Text -Message 'ESXI Host IP'
    New-AnyBoxPrompt -InputType Text -Message 'Servers (seperated by ; no spaces)'
)
$Servers = $Box.Input_1 -Split ";"
Connect-VIServer $Box.Input_0
$Date = Get-Date -Format FileDate
Foreach ($Server in $Servers) { 
    New-Snapshot -VM $Server -Name "Pre-Update $Date" -Description "Pre-Update $Server $Date" -RunAsync 
    }