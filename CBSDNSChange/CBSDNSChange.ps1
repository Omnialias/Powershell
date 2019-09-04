# To prevent false runs, the Return command has been placed below. To enable the script, comment out line 2. 
Return

# Test-Connection -Quiet returns $True if any ping succeeds and returns $False if all pings fail
$pingASA = Test-Connection 172.16.4.1 -Quiet 
$pingSwitch = Test-Connection 172.16.4.150 -Quiet
# If both IPs can't be reached, change internal DNS record to match external IP
If ( 
    ( $pingASA -eq $false ) -and ( $pingSwitch -eq $false )
) { 
    $New = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $Old = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $New.RecordData.IPv4Address = [System.Net.IPAddress]::parse("65.242.101.155")
    Set-DNSServerResourceRecord -NewInputObject $New -OldInputObject $Old -ZoneName 'donohoe.com'
} 
# Check connectivity to ASA or Switch every 30 seconds
While ( 
    ( $pingASA -eq $false ) -and ( $pingSwitch -eq $false )
 ) {
    sleep 30
    $pingASA = Test-Connection 172.16.4.1 -Quiet 
    $pingSwitch = Test-Connection 172.16.4.150 -Quiet
}
# If IPs can be reached, change internal DNS records to match internal IP
If ( 
    ( $pingASA -eq $true ) -Or ( $pingSwitch -eq $true )
) { 
    $New = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $Old = Get-DNSServerResourceRecord -zoneName "donohoe.com" -name "work" -RRType A
    $New.RecordData.IPv4Address = [System.Net.IPAddress]::parse("172.16.4.119")
    Set-DNSServerResourceRecord -NewInputObject $New -OldInputObject $Old -ZoneName 'donohoe.com'
} 
