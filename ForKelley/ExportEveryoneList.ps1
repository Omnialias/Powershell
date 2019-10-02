﻿Write-host "Please enter Intermedia credentials..."
C:\Scripts\Hosting.PowerShell.Custom.ps1 SEH
$GetEveryone = Get-DistributionGroupMember "f77f7d99-73ea-48d6-8bcc-90be3220729b"
if ($GetEveryone -ne $null) 
{
    $GetEveryone | Select DisplayName,EmailAddress | Export-CSV ".\EveryoneEmail.csv"
    Send-MailMessage -To "KelleyD@donohoe.com", "josephw@donohoe.com" -From "JosephW@Donohoe.com" -SmtpServer 'exrelay-va-1.serverdata.net' -Subject "Monthly Everyone Email List Export" -Body "Please find attached the monthly export of members of the Everyone e-mail group." -BodyAsHTML -Attachments ".\EveryoneEmail.csv"
}
$GetEveryone7101 = Get-DistributionGroupMember "02e465e6-c175-483e-8fc6-97c182b86ba2"
if ($GetEveryone7101 -ne $null) 
{
    $GetEveryone7101 | Select DisplayName,EmailAddress | Export-CSV ".\Everyone7101Email.csv"
    Send-MailMessage -To "KelleyD@donohoe.com", "josephw@donohoe.com" -From "JosephW@Donohoe.com" -SmtpServer 'exrelay-va-1.serverdata.net' -Subject "Monthly Everyone 7101 Email List Export" -Body "Please find attached the monthly export of members of the Everyone 7101 e-mail group." -BodyAsHTML -Attachments ".\Everyone7101Email.csv"
}
$GetEveryone5151 = Get-DistributionGroupMember "0c5b607f-4aa3-405d-8c55-3d9dcb606825"
$GetCorporate = Get-DistributionGroupMember "58860c34-fe43-4690-a662-2092494a04e8"
$GetEnergy = Get-DistributionGroupMember "26a6a2d0-32b7-4af7-a335-18a84140f50d"
$GetService = Get-DistributionGroupMember "f0a6c57b-3320-4658-842d-7d0e995c2efe"
if ($GetEveryone5151 -ne $null) 
{
    $GetEveryone5151 | Select DisplayName,EmailAddress | Export-CSV ".\Everyone5151EmailRAW.csv"
    $GetCorporate | Select DisplayName,EmailAddress | Export-CSV ".\Everyone5151EmailRAW.csv" -append
    $GetEnergy | Select DisplayName,EmailAddress | Export-CSV ".\Everyone5151EmailRAW.csv" -append
    $GetService | Select DisplayName,EmailAddress | Export-CSV ".\Everyone5151EmailRAW.csv" -append
    Import-csv ".\Everyone5151EmailRAW.csv" | sort DisplayName -Unique | Where { $_.EmailAddress -notlike "Group*"} | Export-CSV ".\Everyone5151Email.csv"
    Send-MailMessage -To "KelleyD@donohoe.com", "josephw@donohoe.com" -From "JosephW@Donohoe.com" -SmtpServer 'exrelay-va-1.serverdata.net' -Subject "Monthly Everyone 5151 Email List Export" -Body "Please find attached the monthly export of members of the Everyone 5151 e-mail group." -BodyAsHTML -Attachments ".\Everyone5151Email.csv"
}
