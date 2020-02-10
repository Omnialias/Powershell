$Users = Get-Aduser -Searchbase "OU=DHS,DC=HQ,DC=Donohoe" -Filter * -Properties SamAccountName | select SAMAccountName
foreach ($user in $users) { 
    $email = $user.SamAccountName+"@donohoe.com"
    Set-ADUser -Identity $user.SamAccountName -Replace @{extensionAttribute1=$email;proxyaddresses=$email}
}