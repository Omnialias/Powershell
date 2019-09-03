﻿$User = "BACKUP\Josephw"
$PasswordFile = "\\NAS1\Josephw\Scripts\PasswordFile.txt" 
$KeyFile = "\\NAS1\JosephW\Scripts\AES.key"
$Key = Get-Content $KeyFile
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
$Jobs = @("Applications","DC","NAS.1","NAS.7","NAS.3","NAS.9","NAS.6")
$Results = ForEach ( $Job in $Jobs ) { 
    Invoke-Command -ComputerName "Backup" -Credential $Credential -ScriptBlock {
        Add-PSSnapin VeeamPSSnapin
        $Jobject = Get-VBRJob -Name $using:Job
        $Jobdate = $Jobject.ScheduleOptions.LatestRunLocal
        $Date = Get-Date
        $DateDiff = $Date-$Jobdate
        $DateDiff.Days
        }
    }
Foreach ( $Result in $Results ) { if ( $Result -lt 1 ) { continue } else { write-host "4:Failed"; Return } }
write-host "0:Ok"