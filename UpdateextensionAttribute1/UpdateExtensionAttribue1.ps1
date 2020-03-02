$Users = Get-Aduser -Searchbase "OU=MIS,DC=HQ,DC=Donohoe" -Filter * -Properties SamAccountName | select SAMAccountName
foreach ($user in $users) { 
    $email = $user.SamAccountName+"@donohoe.com"
    $proxy = "SMTP:" + $email
    Set-ADUser -Identity $user.SamAccountName -Replace @{extensionAttribute1=$email;proxyaddresses=$proxy}
}