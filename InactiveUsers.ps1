$Users = Get-Content "C:\Scripts\Temp\InactiveUsers.csv"
$Date = Get-Date -Format MM/dd/yy
Foreach ($User in $Users) {
    $Identity = Get-ADUser -Identity $User
    Set-ADUser -Identity $Identity -Enabled $False -Description "Deactivated on $Date"
    Move-ADObject -Identity $Identity -TargetPath "OU=Inactive Users,DC=HQ,DC=Donohoe"
}