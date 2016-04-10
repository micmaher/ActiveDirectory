break

# Implicit Remoting
$session = New-PSSession -computerName dc.contoso.ie -Credential contoso\srv_maher_m
Invoke-command { import-module activedirectory } -session $session
Export-PSSession -session $session -commandname *-AD* -outputmodule RemoteAD -allowclobber
Remove-PSSession -session $session
Import-Module RemoteAD -prefix DC
Get-DCADUser -filter "Name -like 'Micha*'"

break


# Get Test and Prod OU DN
$target = Get-ADOrganizationalUnit -LDAPFilter "(name=Workstations)"
$source = Get-ADOrganizationalUnit -LDAPFilter "(name=Test Workstations)"

# What computers are in test OU
Get-ADComputer -filter * -SearchBase "OU=Workstations, DC=contoso, DC=ie"

break

# Move from Test OU to Prod OU
Move-ADObject "CN=h76q262,$source" -TargetPath $target
Get-ADComputer -filter * -SearchBase $target | where name -eq 'h76q262' 
Get-ADComputer -Identity 'h76q262' | Move-ADObject -TargetPath "OU=Workstations,DC=ad,DC=contoso,DC=ie"

break

# Run a full script remotely
Invoke-Command -ComputerName domaincontroller01 -Credential 'contoso\maher_m' -ScriptBlock {$searcher = New-Object DirectoryServices.DirectorySearcher
$searcher.Filter = '(&(!(LegacyExchangeDN=*))(objectClass=contact))'
$searcher.pageSize = 1000
$ADSearchResults = $searcher.FindAll() | select @{n='DistinguishedName';e={$_.Properties.distinguishedname}} -First 1
$ADSearchResults}

# GP Report
Get-GPResultantSetOfPolicy -Computer localhost -User SMITH_J -Path -ReportType HTML c:\temp\1.htm
