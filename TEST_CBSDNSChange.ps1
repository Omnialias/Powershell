# Test-Connection -Quiet returns $True if any ping succeeds and returns $False if all pings fail
$pingASA = Get-content C:\temp\test1.txt
$pingSwitch = Get-content C:\Temp\test2.txt
If ( 
    ( $pingASA -eq "Off" ) -and ( $pingSwitch -eq "Off" )
) { 
    $Date = Get-Date
    "$Date" + " - It ain't working." | Out-file -FilePath C:\Temp\TestOut.txt -Append 
} 
While ( 
    ( $pingASA -eq "Off" ) -and ( $pingSwitch -eq "Off" )
 ) {
    $Date = Get-Date
    "$Date" + " - It still ain't working." | Out-file -FilePath C:\Temp\TestOut.txt -Append 
    sleep 10
    $pingASA = Get-content C:\temp\test1.txt
    $pingSwitch = Get-content C:\Temp\test2.txt
}
If ( 
    ( $pingASA -eq "On" ) -Or ( $pingSwitch -eq "On" )
) { 
    $Date = Get-Date
    "$Date" + " - It started working." | Out-file -FilePath C:\Temp\TestOut.txt -Append 
} 
