
@{
    GUID = '3af1699d-cc54-4e54-81cf-28d2df5cce0a'
    Author="Microsoft Corporation"
    CompanyName="Microsoft Corporation"
    Copyright="© Microsoft Corporation. All rights reserved."
    HelpInfoUri="http://go.microsoft.com/fwlink/?linkid=390827"
    NestedModules = @('SmbShare.cdxml',
                      'SmbSession.cdxml',
                      'SmbServerNetworkInterface.cdxml',
                      'SmbServerConfiguration.cdxml',
                      'SmbOpenFile.cdxml',
                      'SmbMultichannelConnection.cdxml',
                      'SmbMapping.cdxml',
                      'SmbGlobalMapping.cdxml',
                      'SmbClientNetworkInterface.cdxml',
                      'SmbClientConfiguration.cdxml',
                      'SmbConnection.cdxml',
                      'SmbMultichannelConstraint.cdxml',
                      'SmbBandwidthLimit.cdxml',
                      'SmbScriptModule.psm1')
    FormatsToProcess = @('Smb.format.ps1xml')
    TypesToProcess = @('Smb.types.ps1xml')
    ModuleVersion = '2.0.0.0'
    AliasesToExport = @('gsmbs',
                        'nsmbs',
                        'rsmbs',
                        'ssmbs',
                        'gsmba',
                        'grsmba',
                        'rksmba',
                        'blsmba',
                        'ulsmba',
                        'gsmbse',
                        'cssmbse',
                        'gsmbo',
                        'cssmbo',
                        'gsmbsc',
                        'ssmbsc',
                        'gsmbcc',
                        'ssmbcc',
                        'gsmbc',
                        'gsmbm',
                        'nsmbm',
                        'rsmbm',
                        'gsmbcn',
                        'gsmbsn',
                        'gsmbmc',
                        'udsmbmc',
                        'gsmbt',
                        'nsmbt',
                        'rsmbt',
                        'ssmbp',
                        'gsmbb',
                        'ssmbb',
                        'rsmbb',
                        'gsmbd',
                        'esmbd',
                        'dsmbd',
                        'gsmbgm',
                        'nsmbgm',
                        'rsmbgm')
    CmdletsToExport = @()
    FunctionsToExport = @('Get-SmbShare',
                          'Remove-SmbShare',
                          'Set-SmbShare',
                          'Block-SmbShareAccess',
                          'Unblock-SmbShareAccess',
                          'Grant-SmbShareAccess',
                          'Revoke-SmbShareAccess',
                          'Get-SmbShareAccess',
                          'New-SmbShare',
                          'Get-SmbSession',
                          'Close-SmbSession',
                          'Get-SmbServerNetworkInterface',
                          'Get-SmbServerConfiguration',
                          'Set-SmbServerConfiguration',
                          'Get-SmbOpenFile',
                          'Close-SmbOpenFile',
                          'Get-SmbMultichannelConnection',
                          'Update-SmbMultichannelConnection',
                          'Get-SmbMapping',
                          'Remove-SmbMapping',
                          'New-SmbMapping',
                          'Get-SmbClientNetworkInterface',
                          'Get-SmbClientConfiguration',
                          'Set-SmbClientConfiguration',
                          'Get-SmbConnection',
                          'Get-SmbMultichannelConstraint',
                          'New-SmbMultichannelConstraint',
                          'Remove-SmbMultichannelConstraint',
                          'Set-SmbPathAcl',
                          'Get-SmbBandWidthLimit',
                          'Set-SmbBandwidthLimit',
                          'Remove-SmbBandwidthLimit',
                          'Get-SmbDelegation',
                          'Enable-SmbDelegation',
                          'Disable-SmbDelegation',
                          'Get-SmbGlobalMapping',
                          'Remove-SmbGlobalMapping',
                          'New-SmbGlobalMapping')
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop','Core')
}
