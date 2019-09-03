$path = "\\nas6\DCC\My Securisync" #define path to the shared folder 
$directories = Get-ChildItem -Directory $path -Recurse -Depth 1
$folderpaths = $directories.fullname
Foreach ( $folderpath in $folderpaths ) { $ACLS = Get-ACL $folderpath 
    Foreach ( $ACL in $ACLs.Access ) { $ACL | Where { $_.IsInherited -eq $False } | Add-Member -MemberType NoteProperty 'Path' -Value $folderpath -passthru | Export-CSV C:\Temp\Permissions.csv -Append } 
}