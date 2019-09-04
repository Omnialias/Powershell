$User = "BACKUP\Josephw"
$PasswordFile = "C:\Scripts\PasswordFile.txt" 
$KeyFile = "C:\Scripts\AES.key"
$Key = Get-Content $KeyFile
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
$ResultInc = Invoke-Command -ComputerName "Backup" -Credential $Credential -ScriptBlock { ipmo BEMCLI
Get-BEJob Apps.NAS-VBK | Get-BEJobHistory -FromLastJobRun }
$ResultFull = Invoke-Command -ComputerName "Backup" -Credential $Credential -ScriptBlock { ipmo BEMCLI
Get-BEJob Apps.NAS-Full }
if ( ( ( $ResultInc.JobStatus -eq "Succeeded") -or ( $ResultInc.JobStatus -eq $null) -or ( $ResultInc.JobStatus -eq "SucceededWithExceptions") ) -and ( ( $ResultFull.Status -eq "Succeeded" ) -or ( $ResultFull.Status -eq "Active" ) ) ) { write-host "0:Ok" } else { write-host "2:Failed" }