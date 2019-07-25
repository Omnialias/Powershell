Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "TXT (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}
#################################################
#################################################
$Server = Read-Host "Enter ESXi Host IP"
Connect-VIServer $Server
$Date = Get-Date -Format FileDate
$ImportFile = Get-FileName -initialDirectory 'C:\Scripts'
$Import = Get-Content $ImportFile | Foreach-Object { New-Snapshot -VM $_ -Name "Pre-Update $Date" -Description "Pre-Update $_ $Date" -RunAsync }