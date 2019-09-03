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

    If ($Prompts.Department -eq 'CBS') {
            Invoke-Command -ComputerName NAS4 -ScriptBlock { New-Item -Path $Using:CreateFolder -ItemType Directory
                New-Item -Path $Using:CreateWord -ItemType Directory
                New-Item -Path $Using:CreateExcel -ItemType Directory
                New-Item -Path $Using:CreateCA400 -ItemType Directory
                                # Add the next line when NAS1 gets upgraded to new powershell
                # New-SMBShare -Name $Using:Prompts.Username -Path $Using:CreateFolder -ContinuouslyAvailable -FullAccess Everyone 
            }
        }
        else {
            Invoke-Command -ComputerName NAS1 -ScriptBlock { New-Item -Path $Using:CreateFolder -ItemType Directory
                New-Item -Path $Using:CreateWord -ItemType Directory
                New-Item -Path $Using:CreateExcel -ItemType Directory
                New-Item -Path $Using:CreateCA400 -ItemType Directory
                # Add the next line when NAS1 gets upgraded to new powershell
                # New-SMBShare -Name $Using:Prompts.Username -Path $Using:CreateFolder -ContinuouslyAvailable -FullAccess Everyone 
            }
        }
    Show-AnyBox -Icon 'Question' -Title 'Ready?' -Message 'Go to NAS and change share settings, then click continue' -Buttons 'Continue' -MinWidth 300

#
# If copying from another user, -Instance, otherwise new user account
#

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
                -Description $Prompts.Department `
                -Path $Path `
                -Enabled 1 `
                -Verbose 
            }

#
# Set Home Folder
# 

    Set-ADUser -Identity $Prompts.Username -HomeDirectory $HomeDirectory -HomeDrive "G:"
    Show-AnyBox -Icon 'Question' -Title 'Ready?' -Message 'Go to NAS and change permissions, then click continue' -Buttons 'Continue' -MinWidth 300

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

    .\Hosting.PowerShell.Custom.ps1 SEH

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

$DistroGroup = Show-AnyBox -Icon 'Question' -Buttons 'Submit' -Message 'Choose Distribution Groups' -Prompt @(
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS BD")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Corporate")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Dept. Managers")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Duty")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Energy Management Corp and Field")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Energy Management Corporate")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Energy Management Field")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Field")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Office Admin")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Operations")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Safety Notification")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Service Corporate")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Service Corporate and Field")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Service Field HVAC")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Service Field MC")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Service Field Plumbing")
            (New-AnyBoxPrompt -Tab "CBS" -InputType 'Checkbox' -Message "CBS Thursday Morning Meeting")
            (New-AnyBoxPrompt -TAB "DAS" -InputType 'Checkbox' -Message "DAS Mgrs")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Admin")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC CR")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Estimating")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Quarterly Reviews")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Site Offices")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Specialty")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Specialty Estimating")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Specialty Field Ops")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCC Specialty OPS")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCCAct")
            (New-AnyBoxPrompt -Tab "DCC" -InputType 'Checkbox' -Message "DCCPM")
            (New-AnyBoxPrompt -TAB "DHS" -InputType 'Checkbox' -Message "DHS Corporate")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES Broker DC")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES Broker MD")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES Broker VA")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES CM / Facilities")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES PMAS")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES Project Managers")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES Property Managers")
            (New-AnyBoxPrompt -TAB "DRES" -InputType 'Checkbox' -Message "DRES VA Office")
            (New-AnyBoxPrompt -Tab "Everyone" -InputType 'Checkbox' -Message "Everyone (Excluding Hotels)")
            (New-AnyBoxPrompt -Tab "Everyone" -InputType 'Checkbox' -Message "Everyone 5151")
            (New-AnyBoxPrompt -Tab "Everyone" -InputType 'Checkbox' -Message "Everyone 7101")
            (New-AnyBoxPrompt -Tab "Everyone" -InputType 'Checkbox' -Message "Everyone CBS")
            (New-AnyBoxPrompt -Tab "Everyone" -InputType 'Checkbox' -Message "Everyone DCC")
            (New-AnyBoxPrompt -Tab "Everyone" -InputType 'Checkbox' -Message "Everyone DRES")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "7101Wisconsin")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "CBS Home")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "CBSUpdates")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "DCC IT Setup")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "DonohoeHR")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "401K Committee")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "7101 Office Admin")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "GSA")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "I.T. Committee")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "MIS")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "O&M FX Mobile")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "Onboarding (Excluding CBS)")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "Risk Management")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "TDC Accounting")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "TDC Board")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "TDC Exec Committee")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "TDC Shareholder")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "ULTIPRO")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "Workflow")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "Hotel Help")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "MISOps")
            (New-AnyBoxPrompt -Tab "General" -InputType 'Checkbox' -Message "Prolog Integration")
        )
    if ( $DistroGroup.Input_0 -eq $True) { Add-DistributionGroupMember -Identity 540429c4-f382-4e87-85f3-6b6ace22411b -Member "$CPUser" } # Display Name Group CBS BD
    if ( $DistroGroup.Input_1 -eq $True) { Add-DistributionGroupMember -Identity 58860c34-fe43-4690-a662-2092494a04e8 -Member "$CPUser" } # Display Name Group CBS Corporate
    if ( $DistroGroup.Input_2 -eq $True) { Add-DistributionGroupMember -Identity b786f611-a1fb-4878-a4cf-4cfc4b1a670d -Member "$CPUser" } # Display Name Group CBS Dept. Managers
    if ( $DistroGroup.Input_3 -eq $True) { Add-DistributionGroupMember -Identity 2900f07a-c3a4-4f47-9713-e0b7e3748e7c -Member "$CPUser" } # Display Name Group CBS Duty
    if ( $DistroGroup.Input_4 -eq $True) { Add-DistributionGroupMember -Identity a3186202-b6c5-4f17-8765-a2edbe3fe2b1 -Member "$CPUser" } # Display Name Group CBS Energy Management Corp and Field
    if ( $DistroGroup.Input_5 -eq $True) { Add-DistributionGroupMember -Identity 26a6a2d0-32b7-4af7-a335-18a84140f50d -Member "$CPUser" } # Display Name Group CBS Energy Management Corporate
    if ( $DistroGroup.Input_6 -eq $True) { Add-DistributionGroupMember -Identity 30d07d9f-4d62-43dd-86a1-f02f402117fb -Member "$CPUser" } # Display Name Group CBS Energy Management Field
    if ( $DistroGroup.Input_7 -eq $True) { Add-DistributionGroupMember -Identity 725bcfc2-ad50-4e1e-8c80-0851133ecc1b -Member "$CPUser" } # Display Name Group CBS Field
    if ( $DistroGroup.Input_8 -eq $True) { Add-DistributionGroupMember -Identity 53f2741c-e5f4-4403-9620-fa25cd1274c7 -Member "$CPUser" } # Display Name Group CBS Office Admin
    if ( $DistroGroup.Input_9 -eq $True) { Add-DistributionGroupMember -Identity cd0379c0-7959-417d-9801-46a1fefa8639 -Member "$CPUser" } # Display Name Group CBS Operations
    if ( $DistroGroup.Input_10 -eq $True) { Add-DistributionGroupMember -Identity 75ebcd06-d3e4-4c79-9e40-53424ac38c82 -Member "$CPUser" } # Display Name Group CBS Safety Notification
    if ( $DistroGroup.Input_11 -eq $True) { Add-DistributionGroupMember -Identity f0a6c57b-3320-4658-842d-7d0e995c2efe -Member "$CPUser" } # Display Name Group CBS Service Corporate
    if ( $DistroGroup.Input_12 -eq $True) { Add-DistributionGroupMember -Identity 41524537-4a45-4434-92bb-9786e13880da -Member "$CPUser" } # Display Name Group CBS Service Corporate and Field
    if ( $DistroGroup.Input_13 -eq $True) { Add-DistributionGroupMember -Identity 08838cd8-1355-4524-80de-86b7a02df66a -Member "$CPUser" } # Display Name Group CBS Service Field HVAC
    if ( $DistroGroup.Input_14 -eq $True) { Add-DistributionGroupMember -Identity 669f117e-660a-49d1-836d-e93a115023b5 -Member "$CPUser" } # Display Name Group CBS Service Field MC
    if ( $DistroGroup.Input_15 -eq $True) { Add-DistributionGroupMember -Identity 1118a1b1-5475-475c-8e49-c9cda831fe2b -Member "$CPUser" } # Display Name Group CBS Service Field Plumbing
    if ( $DistroGroup.Input_16 -eq $True) { Add-DistributionGroupMember -Identity 78a7dece-08d1-4850-be7d-9b79d9cfc2f3 -Member "$CPUser" } # Display Name Group CBS Thursday Morning Meeting
    if ( $DistroGroup.Input_17 -eq $True) { Add-DistributionGroupMember -Identity dd840ac8-201e-4e48-8777-6d5268531135 -Member "$CPUser" } # Display Name CBS Home
    if ( $DistroGroup.Input_18 -eq $True) { Add-DistributionGroupMember -Identity b2510a7e-04d3-4459-9092-754a099646f9 -Member "$CPUser" } # Display Name CBSUpdates
    if ( $DistroGroup.Input_19 -eq $True) { Add-DistributionGroupMember -Identity 77fabee3-073e-4219-a490-9f433d642086 -Member "$CPUser" } # Display Name Group DAS Mgrs
    if ( $DistroGroup.Input_20 -eq $True) { Add-DistributionGroupMember -Identity 554e449e-ffcb-4b2a-8785-697f3e5b4802 -Member "$CPUser" } # Display Name Group DCC Admin
    if ( $DistroGroup.Input_21 -eq $True) { Add-DistributionGroupMember -Identity 2f6dba6e-fd94-4c53-8c2f-2d988ea0db1e -Member "$CPUser" } # Display Name Group DCC CR
    if ( $DistroGroup.Input_22 -eq $True) { Add-DistributionGroupMember -Identity 8723e4bc-dbfa-41eb-9c9a-7fd0ea10014d -Member "$CPUser" } # Display Name Group DCC Estimating
    if ( $DistroGroup.Input_23 -eq $True) { Add-DistributionGroupMember -Identity d0ad16cd-7714-40d6-bc2d-53f0b9d83933 -Member "$CPUser" } # Display Name Group DCC Quarterly Reviews
    if ( $DistroGroup.Input_24 -eq $True) { Add-DistributionGroupMember -Identity 126b3b77-ae05-4282-ad0e-d65c683a183f -Member "$CPUser" } # Display Name Group DCC Site Offices
    if ( $DistroGroup.Input_25 -eq $True) { Add-DistributionGroupMember -Identity 24d65080-0c30-44f3-bf43-e1a85c59f779 -Member "$CPUser" } # Display Name Group DCC Specialty
    if ( $DistroGroup.Input_26 -eq $True) { Add-DistributionGroupMember -Identity a36fe5ef-6662-4cb0-abf2-6de10cf927e9 -Member "$CPUser" } # Display Name Group DCC Specialty Estimating
    if ( $DistroGroup.Input_27 -eq $True) { Add-DistributionGroupMember -Identity 7a91953d-4d52-4b41-960c-9daf2d78ced5 -Member "$CPUser" } # Display Name Group DCC Specialty Field Ops
    if ( $DistroGroup.Input_28 -eq $True) { Add-DistributionGroupMember -Identity fdf10caf-6c40-4909-ae0c-fe063c50a43f -Member "$CPUser" } # Display Name Group DCC Specialty OPS
    if ( $DistroGroup.Input_29 -eq $True) { Add-DistributionGroupMember -Identity 18b633e8-9367-4b8c-8376-2cac868e5c06 -Member "$CPUser" } # Display Name Group DCCAct
    if ( $DistroGroup.Input_30 -eq $True) { Add-DistributionGroupMember -Identity 576747de-2ff2-4280-a39b-36d05ff5ca6d -Member "$CPUser" } # Display Name Group DCCPM
    if ( $DistroGroup.Input_31 -eq $True) { Add-DistributionGroupMember -Identity 986ba560-6997-4347-be9c-ac5d28a92f59 -Member "$CPUser" } # Display Name Group DHS Corporate
    if ( $DistroGroup.Input_32 -eq $True) { Add-DistributionGroupMember -Identity 8b8182bb-9e65-4d14-a764-e04944a27562 -Member "$CPUser" } # Display Name Group DRES Broker DC
    if ( $DistroGroup.Input_33 -eq $True) { Add-DistributionGroupMember -Identity 118bc508-d8de-497d-8b6a-b93e7fbb33a3 -Member "$CPUser" } # Display Name Group DRES Broker MD
    if ( $DistroGroup.Input_34 -eq $True) { Add-DistributionGroupMember -Identity cf3cc417-b65f-44c0-8f23-b2add7600b1e -Member "$CPUser" } # Display Name Group DRES Broker VA
    if ( $DistroGroup.Input_35 -eq $True) { Add-DistributionGroupMember -Identity d0c11ebb-94cb-4743-82ff-4d884898be1e -Member "$CPUser" } # Display Name Group DRES CM / Facilities
    if ( $DistroGroup.Input_36 -eq $True) { Add-DistributionGroupMember -Identity dfdd0d1a-b70a-4095-80f7-2357c230ba2f -Member "$CPUser" } # Display Name Group DRES PMAS
    if ( $DistroGroup.Input_37 -eq $True) { Add-DistributionGroupMember -Identity 8865954d-635d-4b8f-99bd-a431e6e9deb7 -Member "$CPUser" } # Display Name Group DRES Project Managers
    if ( $DistroGroup.Input_38 -eq $True) { Add-DistributionGroupMember -Identity 1b769042-22aa-4c40-8f7c-d0debcb5c35a -Member "$CPUser" } # Display Name Group DRES Property Managers
    if ( $DistroGroup.Input_39 -eq $True) { Add-DistributionGroupMember -Identity f82cae81-3408-4a03-a521-0af22c76718c -Member "$CPUser" } # Display Name Group DRES VA Office
    if ( $DistroGroup.Input_40 -eq $True) { Add-DistributionGroupMember -Identity f77f7d99-73ea-48d6-8bcc-90be3220729b -Member "$CPUser" } # Display Name Group Everyone (Excluding Hotels)
    if ( $DistroGroup.Input_41 -eq $True) { Add-DistributionGroupMember -Identity 0c5b607f-4aa3-405d-8c55-3d9dcb606825 -Member "$CPUser" } # Display Name Group Everyone 5151
    if ( $DistroGroup.Input_42 -eq $True) { Add-DistributionGroupMember -Identity 02e465e6-c175-483e-8fc6-97c182b86ba2 -Member "$CPUser" } # Display Name Group Everyone 7101
    if ( $DistroGroup.Input_43 -eq $True) { Add-DistributionGroupMember -Identity 5cf0dd0f-027f-48b0-bb15-2aff9d95aebc -Member "$CPUser" } # Display Name Group Everyone CBS
    if ( $DistroGroup.Input_44 -eq $True) { Add-DistributionGroupMember -Identity 582b5744-ffe1-43de-9090-bae7ba5c03ca -Member "$CPUser" } # Display Name Group Everyone DCC
    if ( $DistroGroup.Input_45 -eq $True) { Add-DistributionGroupMember -Identity 7ef6dc7e-3c87-4812-950d-96016b232994 -Member "$CPUser" } # Display Name Group Everyone DRES
    if ( $DistroGroup.Input_46 -eq $True) { Add-DistributionGroupMember -Identity 8427caf6-a1a3-471a-a736-bce9004a509f -Member "$CPUser" } # Display Name DCC IT Setup
    if ( $DistroGroup.Input_47 -eq $True) { Add-DistributionGroupMember -Identity 0d611943-33d4-4983-a7fe-8d6d422c8cce -Member "$CPUser" } # Display Name DonohoeHR
    if ( $DistroGroup.Input_48 -eq $True) { Add-DistributionGroupMember -Identity 9a2ae215-4ce1-4aa1-a0bb-678066174a92 -Member "$CPUser" } # Display Name Group 401K Committee
    if ( $DistroGroup.Input_49 -eq $True) { Add-DistributionGroupMember -Identity 31810731-c088-411b-bed1-4383cb07531d -Member "$CPUser" } # Display Name Group 7101 Office Admin
    if ( $DistroGroup.Input_50 -eq $True) { Add-DistributionGroupMember -Identity 41439091-1fbb-4ff4-9d0b-6242bf2c5729 -Member "$CPUser" } # Display Name Group GSA
    if ( $DistroGroup.Input_51 -eq $True) { Add-DistributionGroupMember -Identity 8b92443f-814b-48b7-bdee-b7a40b7bb2b3 -Member "$CPUser" } # Display Name Group I.T. Committee
    if ( $DistroGroup.Input_52 -eq $True) { Add-DistributionGroupMember -Identity 0ebbe303-8333-4df8-9a13-8d3d14e2a9af -Member "$CPUser" } # Display Name Group MIS
    if ( $DistroGroup.Input_53 -eq $True) { Add-DistributionGroupMember -Identity 0ce01c9c-d97d-46ea-8323-0cb21bc5407e -Member "$CPUser" } # Display Name Group O&M FX Mobile
    if ( $DistroGroup.Input_54 -eq $True) { Add-DistributionGroupMember -Identity 5dd0703f-58aa-460b-9873-a10aebab34be -Member "$CPUser" } # Display Name Group Onboarding (Excluding CBS)
    if ( $DistroGroup.Input_55 -eq $True) { Add-DistributionGroupMember -Identity fc44624c-aae6-4a25-aae5-8bbd1a03d6bf -Member "$CPUser" } # Display Name Group Risk Management
    if ( $DistroGroup.Input_56 -eq $True) { Add-DistributionGroupMember -Identity 997f6ea9-52bd-477d-920a-fc5ef6d048b2 -Member "$CPUser" } # Display Name Group TDC Accounting
    if ( $DistroGroup.Input_57 -eq $True) { Add-DistributionGroupMember -Identity 688d2121-5732-41f7-9c6d-a44e4ff926b7 -Member "$CPUser" } # Display Name Group TDC Board
    if ( $DistroGroup.Input_58 -eq $True) { Add-DistributionGroupMember -Identity 6285ddd4-526a-4c84-8790-ca68fef87c53 -Member "$CPUser" } # Display Name Group TDC Exec Committee
    if ( $DistroGroup.Input_59 -eq $True) { Add-DistributionGroupMember -Identity f5370979-cc04-46b9-bb2b-436910d894fe -Member "$CPUser" } # Display Name Group TDC Shareholder
    if ( $DistroGroup.Input_60 -eq $True) { Add-DistributionGroupMember -Identity 7afb31e8-8643-42f7-8018-57cb8c6123a2 -Member "$CPUser" } # Display Name Group ULTIPRO
    if ( $DistroGroup.Input_61 -eq $True) { Add-DistributionGroupMember -Identity 4286e321-9faf-4d39-b0ed-0f45eeacbebd -Member "$CPUser" } # Display Name Group Workflow
    if ( $DistroGroup.Input_62 -eq $True) { Add-DistributionGroupMember -Identity 50d380e7-9142-440b-9c35-27e46c3d8376 -Member "$CPUser" } # Display Name Prolog Integration
#
# Send Welcome E-mail
# 

    $EmailBody = Get-Content .\WelcomeEmail.txt | Out-String
    Send-MailMessage -To $EmailUPN -From "Helpdesk@Donohoe.com" -SmtpServer 'exrelay-nj1.serverdata.net' -Subject "Welcome!" -Body $EmailBody -BodyAsHTML

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