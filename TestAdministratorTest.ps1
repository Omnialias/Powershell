#Test Run As Administrator

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

$Test = Test-Administrator

If ( $Test -eq $False) { Exit }
Write-host "Did not break"