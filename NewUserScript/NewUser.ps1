#
# Check script pre-req
#

if (Get-Module -ListAvailable -Name Anybox) {
    Write-Host "Required Modules exist"
} else {
    Install-Module -Name Anybox
}

$AS400KMPCheck = Test-Path "C:\AS400\AS400.KMP"
$CA400WSCheck = Test-Path "C:\AS400\CA400.WS"
If ( $AS400KMPCheck -eq $TRUE -and $CA400WSCheck -eq $True ) {
	Write-Host "CA400 Prereq check passed" -ForegroundColor Green
} else {
	Write-Host "CA400 folder missing. Please create a folder at C:\AS400 and save AS400.KMP and CA400.WS in the folder before re-running the script." -ForegroundColor Red
	Exit
}
#
# Prompt for user account variables
#

    $Prompts = Show-AnyBox -Buttons 'Submit' -Prompt @(
        ( New-AnyBoxPrompt -InputType Text -Name 'FirstName' -Message 'First Name' -ValidateNotEmpty )
        ( New-AnyBoxPrompt -InputType Text -Name 'LastName' -Message 'Last Name' -ValidateNotEmpty )
        ( New-AnyBoxPrompt -InputType Text -Name 'Username' -Message 'Username' -ValidateNotEmpty )
        ( New-AnyBoxPrompt -InputType Password -Name 'Password' -Message 'Password' -ValidateNotEmpty )
        ( New-AnyBoxPrompt -Name 'Department' -ValidateSet @('CBS','DAS','DCC','DHS','DRES','Other') -Message 'Department' -ValidateNotEmpty )
        ( New-AnyBoxPrompt -InputType Checkbox -Name 'Copy' -Message 'Is this a copy of another user account?')
       )
#
# Check Username
#
$ErrorActionPreference = "silentlycontinue"
$CheckUsername = Get-ADUser $Prompts.Username
If ( $CheckUsername -ne $null ) {
    Write-Host "Username is taken. Please re-run script with a new username."
    Break}
$ErrorActionPreference = "Stop"

#
# Check $Prompt.Copy for $True
#

    if ( $Prompts.Copy -eq $True ) {
        $PromptCopy = Show-AnyBox -Buttons 'Submit' -Prompt @(
             New-AnyBoxPrompt -InputType Text -Name 'CopyName' -Message 'Copy which user account?'
             )
        }

#
# Defining some variable for later
#

    $Name = $Prompts.FirstName + " " + $Prompts.LastName
    If ($Prompts.Department -eq 'CBS') {
            $HomeDirectory = "\\NAS4\" + $Prompts.UserName
            }
        else {
            $HomeDirectory = "\\NAS1\" + $Prompts.UserName
            }
    $Email = $Prompts.Username + "@TDC2013.hostpilot.com"
    $UPN = $Prompts.Username + "@hq.Donohoe.com"
    $EmailUPN = $Prompts.Username + "@donohoe.com"

#
# Check if a Department was specified, otherwise drop in Unsorted Users
#

    If ( $Prompts.Department -eq "Other" ) 
            { $Path = "OU=Unsorted Users,DC=HQ,DC=donohoe" }
        else 
            { $Path = "OU=Users,OU=" + $Prompts.Department + ",DC=HQ,DC=donohoe" }

#
# Create Home Folder
# 

    If ($Prompts.Department -eq 'CBS') {
            $CreateFolder = "C:\Personal\" + $Prompts.Username
            $CreateWord = $CreateFolder + "\Word"
            $CreateExcel = $CreateFolder + "\Excel"
            $CreateCA400 = $CreateFolder + "\CA400"
        }
        else {
            $CreateFolder = "C:\Shared\" + $Prompts.Username
            $CreateWord = $CreateFolder + "\Word"
            $CreateExcel = $CreateFolder + "\Excel"
            $CreateCA400 = $CreateFolder + "\CA400"
        }

write-host "Creating Home Folder Share"
    If ($Prompts.Department -eq 'CBS') {
            Invoke-Command -ComputerName NAS4 -ScriptBlock { New-Item -Path $Using:CreateFolder -ItemType Directory
                New-Item -Path $Using:CreateWord -ItemType Directory
                New-Item -Path $Using:CreateExcel -ItemType Directory
                New-Item -Path $Using:CreateCA400 -ItemType Directory
                New-SMBShare -Name $Using:Prompts.Username -Path $Using:CreateFolder -FullAccess Everyone 
            }
        }
        else {
            Invoke-Command -ComputerName NAS1 -ScriptBlock { New-Item -Path $Using:CreateFolder -ItemType Directory
                New-Item -Path $Using:CreateWord -ItemType Directory
                New-Item -Path $Using:CreateExcel -ItemType Directory
                New-Item -Path $Using:CreateCA400 -ItemType Directory
                New-SMBShare -Name $Using:Prompts.Username -Path $Using:CreateFolder -FullAccess Everyone 
            }
        }

#
# If copying from another user, -Instance, otherwise new user account
#
write-host "Creating User account"
    If ( $Prompts.Copy -eq $True )
            { New-ADUser `
                -GivenName $Prompts.FirstName `
                -Surname $Prompts.LastName `
                -Name $Name `
                -SamAccountName $Prompts.Username `
                -EmailAddress $Email `
                -Path $Path `
                -AccountPassword $Prompts.Password `
                -UserPrincipalName $UPN `
                -OtherAttributes @{'proxyaddresses'=$EmailUPN;'extensionAttribute1'=$EmailUPN} `
                -Description $Prompts.Department `
                -Enabled 1
             Get-ADUser -Identity $PromptCopy.CopyName -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $Prompts.Username -PassThru }
        else 
            { New-ADUser `
                -GivenName $Prompts.FirstName `
                -Surname $Prompts.LastName `
                -Name $Name `
                -SamAccountName $Prompts.Username `
                -EmailAddress $Email `
                -AccountPassword $Prompts.Password `
                -UserPrincipalName $UPN `
                -OtherAttributes @{'proxyaddresses'=$EmailUPN;'extensionAttribute1'=$EmailUPN} `
                -Description $Prompts.Department `
                -Path $Path `
                -Enabled 1 `
                -Verbose 
            }

# Set ACL on home folder.
write-host "Setting ACL on home folder"
If ($Prompts.Department -eq 'CBS') { 
    Invoke-Command -ComputerName NAS4 -ScriptBlock {
        Disable-NTFSAccessInheritance -Path $Using:CreateFolder
        Add-NTFSAccess -Path $Using:CreateFolder -Account "Administrators" -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
        Add-NTFSAccess -Path $Using:CreateFolder -Account "Domain Admins" -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
        Remove-NTFSAccess -Path $Using:CreateFolder -Account "Domain Users" -AccessRights ReadAndExecute
        Add-NTFSAccess -Path $Using:CreateFolder -Account $Using:Prompts.Username -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
    }
}
else {
    Invoke-Command -ComputerName NAS1 -ScriptBlock {
       Disable-NTFSAccessInheritance -Path $Using:CreateFolder
       Add-NTFSAccess -Path $Using:CreateFolder -Account "Administrators" -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
       Add-NTFSAccess -Path $Using:CreateFolder -Account "Domain Admins" -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
       Remove-NTFSAccess -Path $Using:CreateFolder -Account "Domain Users" -AccessRights ReadAndExecute
       Add-NTFSAccess -Path $Using:CreateFolder -Account $Using:Prompts.Username -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles 
    }
}

#
# Set Home Folder
# 

    Set-ADUser -Identity $Prompts.Username -HomeDirectory $HomeDirectory -HomeDrive "G:"

#
# Set Remote Desktop Settings
#

    Start-Sleep -s 5
    $UserDN = Get-ADUser $Prompts.Username -Properties DistinguishedName | Select -ExpandProperty DistinguishedName
    $RDSetPath = "\\NAS3\Profiles\" + $Prompts.UserName
    $RDSettings = "LDAP://" + $UserDN
    $RDSet = [ADSI] $RDSettings
    $RDSet.psbase.Invokeset("terminalservicesprofilepath",$RDSetPath)
    $RDSet.psbase.Invokeset("terminalservicesHomeDirectory",$HomeDirectory)
    $RDSet.psbase.Invokeset("terminalservicesHomeDrive","Z:")
    $RDSet.setinfo()

#
# Copy AS400 files
#

If ($Prompts.Department -eq 'CBS') {
            $AS400Folder = "\\NAS4\Personal\" + $Prompts.Username + "\CA400"
            Copy-item "C:\AS400\ca400.ws" -Destination $AS400Folder
            Copy-item "C:\AS400\as400.kmp" -Destination $AS400Folder
        }
        else {
            $AS400Folder = "\\NAS1\Shared\" + $Prompts.Username + "\CA400"
            Copy-item "C:\AS400\ca400.ws" -Destination $AS400Folder
            Copy-item "C:\AS400\as400.kmp" -Destination $AS400Folder
        }

#
# Create TDCDocs Folder
#

    $ScanFolder = "C:\Scans\" + $Prompts.Username
    Invoke-Command -ComputerName TDCDocs -ScriptBlock { New-Item -Path $Using:ScanFolder -ItemType Directory
        New-SMBShare -Name $Using:Prompts.Username -Path $Using:ScanFolder -FullAccess "Everyone"
        Add-NTFSAccess -Path $Using:ScanFolder -Account $Using:Prompts.Username -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
        }
#
# Moving on to Intermedia
# 

    $HostpilotPrompt = Show-AnyBox -Message 'Is this user getting an e-mail account?' -Buttons 'Yes','No'

    if ( $HostpilotPrompt.No -eq $True ) 
        { Break }

#
# Start Intermedia Shell?
#

    C:\Scripts\Active\NewUserScript\Hosting.PowerShell.Custom.ps1 SEH

    New-User -DisplayName $Name -UserPrincipalName $EmailUPN -Password $Prompts.Password
    Write-Host "
########################################################    
This part always takes some time. Please wait a minute.#
########################################################    
"
    Get-User -Identity $EmailUPN | Set-User -FirstName $Prompts.FirstName -LastName $Prompts.LastName
    Get-User -Identity $EmailUPN | Enable-ExchangeMailbox
    $ADSyncObject = Get-ADSyncObjectUnlinked -Identity $Email | Select-Object -ExpandProperty ObjectID
    $CPUser = Get-User -Identity $EmailUPN | Select -ExpandProperty DistinguishedName
    Set-AdSyncObjectLinked -Identity $ADSyncObject -TargetIdentity $CPUser

#
# Copy Distribution List
#

If ( $Prompts.Copy -eq $True ) {
    $CopyUPN = $PromptCopy.CopyName + "@donohoe.com"
    $Groups = Get-DistributionGroup * | Select Name,GUID
    $Source = Get-ExchangeMailbox $CopyUPN
    $Destination = Get-ExchangeMailbox $EmailUPN
    $Distros = foreach ( $Group in $Groups ) {
        $Check = Get-DistributionGroupMember $Group.GUID 
        If ( $Check.Identity.DistinguishedName -contains $Source.identity ) {
             $Group
        }
    }
        Foreach ( $Distro in $Distros.GUID ) { Add-DistributionGroupMember -Identity $Distro -Member $Destination.Identity }
}

#
# Send Welcome E-mail
# 

    $EmailBody = Get-Content .\WelcomeEmail.txt | Out-String
    Send-MailMessage -To $EmailUPN -From "Helpdesk@Donohoe.com" -SmtpServer 'exrelay-nj1.serverdata.net' -Subject "Welcome!" -Body $EmailBody -BodyAsHTML

#
# Enable SecuriSync
#

$SecuriSyncPrompt = Show-AnyBox -Message 'Will this user use SecuriSync' -Buttons 'Yes','No'
if ( $SecuriSyncPrompt.Yes -eq $True ) 
   { Enable-FileUser -Identity $CPUser }

#
# Check Everything
#

    $ADCheck = Get-ADUser -Identity $Prompts.UserName -Properties "mail","HomeDirectory","HomeDrive" | Select Name,SamAccountName,Mail,HomeDirectory,HomeDrive
    $HostCheck = Get-User -Identity $EmailUPN | Select Name,DisplayName,UserPrincipalName,Enabled,RecipientType
      Show-AnyBox -Title 'Double-Check' -Message 'Double check items below',' ', `
            "AD Items", `
            $ADCheck.Name, `
            $ADCheck.SamAccountName, `
            $ADCheck.Mail, `
            $ADCheck.HomeDirectory, `
            $ADCheck.HomeDrive, `
            ' ', `
            'Intermedia Items', `
            $HostCheck.Name, `
            $HostCheck.DisplayName, `
            $HostCheck.UserPrincipalName, `
            $HostCheck.Enabled, `
            $HostCheck.RecipientType `
        -Buttons 'Looks Good'
#
# Reminder to add user to KnowBe4
#

Show-AnyBox -Icon 'Question' -Title 'KnowBe4' -Message "Add User $Name ($EmailUPN) to KnowBe4." -Buttons 'Continue' -MinWidth 300