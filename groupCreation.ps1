$csvFile = 'C:\Scripts\groups.csv'
$groups = Import-csv $csvFile

foreach ($g in $groups)
{
    # Create Domain Local Groups   
    $params1 = @{
        Name = "DL_$($g.name)"
        Path = 'ou=Domain Local,ou=Fileshare Access, ou=security groups,dc=domain,dc=contoso, dc=com'
        GroupScope = 'DomainLocal'
        GroupCategory = 'Security'
        Description = $g.accesslevel
    }
    New-ADGroup @params1 -passthru

    # Create Global Groups
    $params2 = @{
        Name = $g.name
        Path = 'ou=Global,ou=Fileshare Access, ou=security groups,dc=domain,dc=contoso, dc=com'
        GroupScope = 'Global'
        GroupCategory = 'Security'
        Description = $g.accesslevel
    }
    New-ADGroup @params2 -passthru

    # Add the Global Group to the Domain Local
    Add-ADGroupMember -Identity "DL_$($g.name)" -Members $g.name

}

