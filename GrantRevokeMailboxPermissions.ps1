$Butler = Show-AnyBox -Message 'Will we be granting or revoking permissions today, sir?' -Buttons 'Grant','Revoke'
$InterCheck = Get-User josephw@donohoe.com -ErrorVariable "ErrorThrowAway"
If ( $Intercheck -eq $null ) { Show-Anybox -Message 'Very good, sir. Now, if you will please log in?' -Buttons 'Ok'
C:\Scripts\Hosting.PowerShell.Custom.ps1 SEH }

# Granting Permissions

If ( $Butler.Grant -eq 'True' ) {
    While ( $Identity -eq $null -or $Recipient -eq $null ) {
        $Prompt = Show-AnyBox -Buttons 'Submit' -Prompts @(
            ( New-AnyBoxPrompt -InputType Text -Name 'Identity' -Message 'And whose mailbox will we be granting rights to? (Please include the domain)' -ValidateNotEmpty -ValidateScript { $_ -like '*@donohoe.com' } )
            ( New-AnyBoxPrompt -InputType Text -Name 'Recipient' -Message 'And to whom will we be granting those rights? (Please include the domain)' -ValidateNotEmpty -ValidateScript { $_ -like '*@donohoe.com' } )
        )
        $Identity = Get-ExchangeMailbox $Prompt.Identity
        $Recipient = Get-ExchangeMailbox $Prompt.Recipient
        If ( $Identity -eq $null ) { $PromptID = Show-Anybox -Message 'Terribly sorry, sir. There is no Identity by that name. Would you please try again?' -Buttons 'Ok','Never mind' -CancelButton 'Never mind' }
        If ( $PromptID.'Never mind' -eq 'True' ) { Break }
        If ( $Recipient -eq $null ) { $PromptRec = Show-Anybox -Message 'Terribly sorry, sir. There is no Recipient by that name. Would you please try again?' -Buttons 'Ok','Never mind' -CancelButton 'Never mind' }
        If ( $PromptRec.'Never mind' -eq 'True' ) { Break }
    }
    Grant-ExchangeMailboxPermission -Identity $Identity.DistinguishedName -Recipients $Recipient.DistinguishedName -AccessRights FullAccess
    $Test = Get-ExchangeMailbox $Prompt.Identity | Select GrantFullAccessToRecipients
    Show-Anybox -Message 'Here are the DNs of all users with full access to the requested mailbox' -GridData @( $Test.GrantFullAccessToRecipients | Select DisplayName,EmailAddress ) -NoGridSearch -Buttons 'Thanks, Jeeves'
}

# Revoking Permissions

If ( $Butler.Revoke -eq 'True' ) {
    While ( $Identity -eq $null -or $Recipient -eq $null ) {
        $Prompt = Show-AnyBox -Buttons 'Submit' -Prompts @(
            ( New-AnyBoxPrompt -InputType Text -Name 'Identity' -Message 'And whose mailbox will we be revoking rights on? (Please include the domain)' -ValidateNotEmpty -ValidateScript { $_ -like '*@donohoe.com' } )
            ( New-AnyBoxPrompt -InputType Text -Name 'Recipient' -Message 'And to which account will have its rights revoked? (Please include the domain)' -ValidateNotEmpty -ValidateScript { $_ -like '*@donohoe.com' } )
        )
        $Identity = Get-ExchangeMailbox $Prompt.Identity
        $Recipient = Get-ExchangeMailbox $Prompt.Recipient
        If ( $Identity -eq $null ) { $PromptID = Show-Anybox -Message 'Terribly sorry, sir. There is no Identity by that name. Would you please try again?' -Buttons 'Ok','Never mind' -CancelButton 'Never mind' }
        If ( $PromptID.'Never mind' -eq 'True' ) { Break }
        If ( $Recipient -eq $null ) { $PromptRec = Show-Anybox -Message 'Terribly sorry, sir. There is no Recipient by that name. Would you please try again?' -Buttons 'Ok','Never mind' -CancelButton 'Never mind' }
        If ( $PromptRec.'Never mind' -eq 'True' ) { Break }
    }
    Revoke-ExchangeMailboxPermission -Identity $Identity.DistinguishedName -Recipients $Recipient.DistinguishedName
    $Test = Get-ExchangeMailbox $Prompt.Identity | Select GrantFullAccessToRecipients
    Show-Anybox -Message 'Here are the remaining DNs of all users with full access to the requested mailbox' -GridData @( $Test.GrantFullAccessToRecipients | Select DisplayName,EmailAddress ) -NoGridSearch -Buttons 'Thanks, Jeeves'
    }
Remove-Variable * -ErrorAction SilentlyContinue