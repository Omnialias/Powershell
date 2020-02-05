$InterCheck = Try {Get-User josephw@donohoe.com } Catch { write-host "" }
If ( $Intercheck -eq $null ) { Show-Anybox -Message 'If you would, sir. please log into Intermedia?' -Buttons 'Ok'
C:\Scripts\Hosting.PowerShell.Custom.ps1 SEH }
$Groups = Get-DistributionGroup * | Select Name,GUID
$Prompt = Show-AnyBox -Buttons 'Submit' -Prompts @(
            ( New-AnyBoxPrompt -InputType Text -Name 'Source' -Message 'Which account should I copy the distribution lists from?' -ValidateNotEmpty -ValidateScript { $_ -like '*@donohoe.com' } )
            ( New-AnyBoxPrompt -InputType Text -Name 'Destination' -Message 'And which account should I copy the distribution lists to?' -ValidateNotEmpty -ValidateScript { $_ -like '*@donohoe.com' } )
        )
$Source = Get-ExchangeMailbox $Prompt.Source
$Destination = Get-ExchangeMailbox $Prompt.Destination
$Distros = foreach ( $Group in $Groups ) { $Check = Get-DistributionGroupMember $Group.GUID 
  If ( $Check.Identity.DistinguishedName -contains $Source.identity ) { $Group } }
 Foreach ( $Distro in $Distros.GUID ) { Add-DistributionGroupMember -Identity $Distro -Member $Destination.Identity }