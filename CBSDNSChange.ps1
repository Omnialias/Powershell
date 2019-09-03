Return

# Test-Connection -Quiet returns $True if any ping succeeds and returns $False if all pings fail
$pingASA = Test-Connection 172.16.4.1 -Quiet 
$pingSwitch = Test-Connection 172.16.4.150 -Quiet
while ( 
    ( $pingASA -eq $false ) -and ( $pingSwitch -eq $false )
) { 
    $New = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $Old = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $New.RecordData.IPv4Address = [System.Net.IPAddress]::parse("65.242.101.155")
    Set-DNSServerResourceRecord -NewInputObject $New -OldInputObject $Old -ZoneName 'donohoe.com'
} else {
    $New = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $Old = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $New.RecordData.IPv4Address = [System.Net.IPAddress]::parse("172.16.4.119")
    Set-DNSServerResourceRecord -NewInputObject $New -OldInputObject $Old -ZoneName 'donohoe.com'
}