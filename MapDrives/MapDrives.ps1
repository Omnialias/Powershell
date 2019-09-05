# Remove existing L and G drive mappings
$ErrorActionPreference = "SilentlyContinue"
net use L: /delete >nul 2>&1
net use G: /delete >nul 2>&1

# Prompt for credentials
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Please type in your network username and password",0,"Done",0x1)
$Cred = Get-Credential
$rawuser = $cred.UserName

# Check if user typed "SAM@donohoe.com." Replace with "HQ\SAM." Otherwise if user typed "SAM," replace with "HQ\SAM." Result should always be $user = "HQ\SAM"
if ( $rawuser -like "*@donohoe.com" ) { $user = "HQ\"+$rawuser.Substring(0,$rawuser.Length-12) } elseif ( $rawuser -notlike "HQ\*" ) { $user = "HQ\"+$rawuser }


# Define static variables
$LDrive = "L:"
$LDrivePath = "\\NAS6\DCC"
$GDrive = "G:"
$GDrivePath = "\\NAS1\"+$user.Substring(3)

# Map the drives
$net = New-Object -com WScript.Network
$net.mapnetworkdrive($Gdrive, $GDrivepath, $true, $user, $cred.GetNetworkCredential().Password)
$net.mapnetworkdrive($Ldrive, $LDrivepath, $true, $user, $cred.GetNetworkCredential().Password)