$User = "BACKUP\Josephw"
$PasswordFile = "\\NAS1\Josephw\Scripts\PasswordFile.txt" 
$KeyFile = "\\NAS1\JosephW\Scripts\AES.key"
$Key = Get-Content $KeyFile
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
invoke-command -Credential $Credential -ComputerName "Backup" -Scriptblock { ipmo BEMCLI
Get-BEJob Apps.NAS-Full | Select Status }