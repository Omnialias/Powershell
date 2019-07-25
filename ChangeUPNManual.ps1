$Identity = Read-Host "Username"
$USER = Get-ADUser -Identity $Identity
$USER
$Continue = Read-host "Continue?"
If ($Continue -eq "Yes") {
    $SAM = $User.SamAccountName
    $UPN = $SAM + "@HQ.donohoe"
    Set-ADUser -Identity $Identity -UserPrincipalName $UPN}
else { $NULL }