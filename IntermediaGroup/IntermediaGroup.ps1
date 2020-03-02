$IMDLs = Get-DistributionGroup
Foreach ( $IMDL in $IMDLs ) { New-ADGroup -Name $IMDL.DisplayName -DisplayName $IMDL.DisplayName -GroupCategory Distribution -GroupScope Global }
Foreach ( $IMDL in $IMDLS ) { 
    $Members = Get-ADGroupMember -Identity $IMDL.DistinguishedName
    Foreach ( $Member in $Members ) {
        Add-ADGroupMember -Identity $IMDL.DisplayName -Members $Member
    }
}