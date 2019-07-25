#Test Run As Administrator

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

$Admintest = Test-Administrator
If ( $Admintest -eq $False) {
    Write-host "This session is not running as an administrator. Please restart the Powershell session as a domain admin." -ForegroundColor "Red"
    Exit }

# Input username.
$Username = Show-AnyBox -prompts @(
    New-AnyBoxPrompt -InputType Text -Name 'Username' -Message "What is the username?" -ValidateNotEmpty
    New-AnyBoxPrompt -InputType Text -Name 'Division' -Message "What division are they from?" -ValidateSet @('DCC, DHS, DAS, DRES, DEV','CBS') 
) -Buttons @(
    New-AnyBoxButton -Name 'Cancel' -Text 'Cancel' -IsCancel
    New-AnyBoxButton -Name 'Submit' -Text 'Submit' -IsDefault
)

#
#Define Variables
#

$Filename = $Email + ".pst"
If ( $Username.Division -eq "CBS") {
    $Server = "\\NAS4\Personal\"
    } else {
    $Server = "\\NAS1\Shared\"
}
# Start Hostpilot Powershell
Write-host "Logging in to Intermedia..." -ForegroundColor "Green"
.\Hosting.PowerShell.Custom.ps1 SEH
$GUID = Get-ExchangeMailbox -Identity $Email | Select GUID | Out-String -Stream
New-ExchangeMailboxBackupRequest -Identity $GUID[3] -PstFileName $Filename
Write-Host "Backup has started. Check the Intermedia Admin panel for status, and to download" -ForegroundColor "Green"

# Archive User Profile folders
Write-Host "Moving User Profile folder to Archive" -ForegroundColor "Green"
$Year = Get-Date -Format yyyy
$ArchivePath = "\\Archive\Archived Users\" + $Year + "\"
$ArchiveSource = $Server + $Username.Username + "\*"
$ArchiveSourceFolder = $Server + $Username.Username
$ArchiveDest = $ArchivePath + $Username.Username
New-Item -Path $ArchivePath -Name $Username.Username -ItemType "Directory"
Move-Item -Path $ArchiveSource -Destination $ArchiveDest -Force

# Checking user profile folder is, indeen, empty
$FolderCheck = Get-ChildItem -Path $ArchiveSource
If ( $FolderCheck -eq $null ) {
Remove-Item $ArchiveSourceFolder -Force
} else {
Read-Host "User profile folder doesn't seem to be empty. Please move all files and folders out of the User Profile folder and delete manually."
}