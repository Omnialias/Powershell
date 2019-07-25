# Get all the users who have proxyAddresses under the @donohoe.com domain
# In testing, -SearchBase to limit scope.
foreach ($user in (Get-ADUser -filter * )) {
	# Grab the SAMAccountName
	$SAM = Get-ADUser $user -Properties SAMAccountName | Select -property SAMAccountName
	$newUPN = $SAM.SAMAccountName + "@hq.donohoe.com"
	# Update the user with their new UPN
	Set-ADUser $user -UserPrincipalName $newUPN
}