# Create Trap Folders and Files
$A = Test-Path "C:\AAA_CompanyDirectory"
$Z = Test-Path "C:\ZZZ_Archive"
If ($A -eq $False) { Copy-Item "\\NAS10\Public\Installs\Ransomware\AAA_CompanyDirectory" -Destination "C:\AAA_CompanyDirectory" -recurse
   (Get-Item C:\AAA_CompanyDirectory).Attributes += "Hidden"
}
If ($Z -eq $False) { Copy-Item "\\NAS10\Public\Installs\Ransomware\ZZZ_Archive" -Destination "C:\ZZZ_Archive" -recurse
   (Get-Item C:\ZZZ_Archive).Attributes += "Hidden"
}
New-SMBShare -Name "AAA_CompanyDirectory" -Path "C:\AAA_CompanyDirectory" -FullAccess "Everyone"
New-SMBShare -Name "ZZZ_Archive" -Path "C:\ZZZ_Archive" -FullAccess "Everyone"
Add-NTFSAccess -Path "C:\AAA_CompanyDirectory" -Account "Authenticated Users" -AccessRights "Modify" -AppliesTo ThisFolderSubfoldersAndFiles
Add-NTFSAccess -Path "C:\ZZZ_Archive" -Account "Authenticated Users" -AccessRights "Modify" -AppliesTo ThisFolderSubfoldersAndFiles

# Set FSRM Settings
Set-FSRMSetting `
    -SMtPServer "exrelay-va-1.serverdata.net"`
    -AdminEmailAddress "josephw@donohoe.com; zoltank@donohoe.com"`
    -FromEmailAddress "FSRM@donohoe.com"`
    -EmailNotificationLimit "5"`
    -CommandNotificationLimit "0"`
    -EventNotificationLimit "0"
$ExcludePattern = "_DONT_CHANGE.docx","_DONT_CHANGE.png","_DONT_CHANGE.txt"
$Email = New-FSRMAction `
    -Type "Email" `
    -MailTo "[Admin Email]" `
    -Subject "Unauthorized file from the [Violated File Group] file group detected" `
    -Body "User [Source Io Owner] attempted to save [Source File Path] to [File Screen Path] on the [Server] server. This file is in the [Violated File Group] file group, which is not permitted on the server." `
    -SecurityLevel None
$Event = New-FSRMAction `
    -Type "Event" `
    -EventType "Error" `
    -Body "User [Source Io Owner] attempted to save [Source File Path] to [File Screen Path] on the [Server] server. This file is in the [Violated File Group] file group, which is not permitted on the server." `
    -SecurityLevel None
$Command = New-FSRMAction `
    -Type "Command" `
    -Command "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -CommandParameters "-Command `"& { `$Date=Get-Date | Out-String; `$User='[Source Io Owner]'; `$Date + `$User | Out-file C:\Temp\TestContent.txt -Append }" `
    -KillTimeOut "0" `
    -SecurityLevel LocalService
$TemplateAction = @($Email,$Event,$Command)
New-FSRMFileGroup -Name "All File Types" -IncludePattern '*.*' -ExcludePattern $ExcludePattern
New-FSRMFileScreenTemplate -Name "Ransomware" -IncludeGroup "All File Types" -Notification $TemplateAction
New-FSRMFileScreen -Path "C:\AAA_CompanyDirectory" -Template "Ransomware"
New-FSRMFileScreen -Path "C:\ZZZ_Archive" -Template "Ransomware"