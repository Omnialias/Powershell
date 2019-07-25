$usersTable = New-Object system.Data.DataTable “UsersTable”
$column1 = New-Object System.Data.DataColumn userPrincipalName,([String])
$column2 = New-Object System.Data.DataColumn immutableId,([String])
$usersTable.Columns.Add($column1)
$usersTable.Columns.Add($column2)
$users=Import-Csv -Path users.csv -Header “userSamAccountName”
foreach($user in $users)
{
$adUser = Get-ADUser -Identity $user.userSamAccountName
$adUserGuid = $adUser.ObjectGUID
$byteArray = $adUserGuid.ToByteArray()
$immutableId = “”
$immutableId = [system.convert]::ToBase64String($byteArray)
$row = $usersTable.NewRow()
$row.userPrincipalName = $adUser.userPrincipalName
$row.immutableId = $immutableId
$usersTable.Rows.Add($row)
}
$usersTable | Export-Csv “userExportIds.csv”