break

# Get Test and Prod OU DN
$target = Get-ADOrganizationalUnit -LDAPFilter "(name=Workstations)"
$source = Get-ADOrganizationalUnit -LDAPFilter "(name=Test Workstations)"

# What computers are in test OU
Get-ADComputer -filter * -SearchBase "OU=Test Workstations, DC=ad, DC=contoso, DC=ie"

break

# Move from Test OU to Prod OU
Move-ADObject "CN=h76q262,$source" -TargetPath $target
Get-ADComputer -filter * -SearchBase $target | where name -eq 'h76q262' 
Get-ADComputer -Identity 'h76q262' | Move-ADObject -TargetPath "OU=Workstations,DC=ad,DC=contoso,DC=ie"

break



# GP Report
Get-GPResultantSetOfPolicy -Computer localhost -User SMITH_J -Path -ReportType HTML c:\temp\1.htm

# Group Membership
$m = 'CZC0058VTX$', 'CZC9505FH7$'
Add-ADGroupMember 'Deny on Windows Update GPO' -members $m -Server 'dc.contoso.com' -PassThru

# Force Replication
$dc = get-addomaincontroller -filter * | select Name
foreach ($d in $dc){			
					Write-Host "Forcing Replication on $domainController" -ForegroundColor Cyan
					$domainController.SyncReplicaFromAllServers(([ADSI]"").distinguishedName,'CrossSite')
				}

# Check differences
$x = Get-ADGroupMember 'Deny on Windows Update GPO' -Server dc01 | select name 
$y = Get-ADGroupMember 'Deny on Windows Update GPO' -Server dc05 | select name 
$x.count
$y.count
Compare-Object -ReferenceObject $x -DifferenceObject $y
