Add-NTFSAccess C:\Shared\TestFolder -Account HQ\PeterLe -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
Add-NTFSAccess C:\Shared\TestFolder -Account "HQ\Domain Admins" -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
Remove-NTFSAccess C:\Shared\TestFolder -Account "HQ\Domain Users"
Disable-NTFSAccessInheritance C:\Temp\TestFolder