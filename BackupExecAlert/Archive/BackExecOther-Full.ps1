$User = "BACKUP\Josephw"
$PasswordFile = "C:\Scripts\PasswordFile.txt" 
$KeyFile = "C:\Scripts\AES.key"
$Key = Get-Content $KeyFile
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
$Result = Invoke-Command -ComputerName "Backup" -Credential $Credential -ScriptBlock { ipmo BEMCLI
Get-BEJob Other-Full | Select Status }
if ( $Result.Status.Value -eq "Succeeded" ) { write-host "0:Ok" } else { write-host "4:Failed" }