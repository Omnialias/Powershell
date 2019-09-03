$User = "BACKUP\Josephw"
$PasswordFile = "\\NAS1\Josephw\Scripts\PasswordFile.txt" 
$KeyFile = "\\NAS1\JosephW\Scripts\AES.key"
$Key = Get-Content $KeyFile
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
$Jobs = Invoke-Command -ComputerName "Backup" -Credential $Credential -ScriptBlock {
    Add-PSSnapin VeeamPSSnapin
    Get-VBRJob | Where { $_.IsBackup -eq $True } | Where { $_.Name[0] -ne "#" } | Select Name
}
$Result = @( ForEach ( $Job in $Jobs ) { 
    Invoke-Command -ComputerName "Backup" -Credential $Credential -ScriptBlock {
        Add-PSSnapin VeeamPSSnapin
        $Jobject = Get-VBRJob -Name $using:Job.Name
        $Jobdate = $Jobject.ScheduleOptions.LatestRunLocal
        $Date = Get-Date
        $DateDiff = $Date-$Jobdate
        $DateDiff.Days
        }
    }
)