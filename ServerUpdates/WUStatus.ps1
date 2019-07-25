Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "txt (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$ImportFile = Get-FileName -initialDirectory 'C:\Scripts\ServerUpdates'
Get-Content $ImportFile | % { Invoke-WUJob -ComputerName $_ -RunNow -Script { Get-WUInstallerStatus -SendReport; Get-WURebootStatus -SendReport -Silent } -Confirm:$false -Verbose }