$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Please type in your network username and password",0,"Done",0x1)
$Cred = Get-Credential
$user = $cred.UserName
while ( $user -like "*@donohoe.com" ) {
$wshell2 = New-Object -ComObject Wscript.Shell
$wshell2.Popup("Please enter only your username. Do not enter @donohoe.com.",0,"Done",0x1)
$Cred = Get-Credential
$user = $cred.UserName
}
$LDrive = "L:"
$LDrivePath = "\\NAS6\DCC"
$GDrive = "G:"
if ( $user -like "HQ\*" ) { $GDrivePath = "\\NAS1\"+$user.Substring(3) } else { $GDrivePath = "\\NAS1\"+$user }
$net = New-Object -com WScript.Network
$net.mapnetworkdrive($Ldrive, $LDrivepath, "true", $user, $cred.GetNetworkCredential().Password)
$net.mapnetworkdrive($Gdrive, $GDrivepath, "true", $user, $cred.GetNetworkCredential().Password)