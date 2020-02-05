$Users = Get-Aduser -Searchbase "OU=DRES,DC=HQ,DC=Donohoe" -Filter * -Properties SamAccountName | select SAMAccountName
foreach ($user in $users) { 
    $email = $user.SamAccountName+"@donohoe.com"
    Set-ADUser -Identity $user.SamAccountName -Replace @{extensionAttribute1=$email}
}