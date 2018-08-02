# ActiveDirectory
Anonymised AD Import Export and Enable Scripts

Some AD scripts also gathered from other sources

ADAMSync script has a good example of using -Context with Select-String

```powershell
Try{$logError = Get-Content $logPath | Select-String -Pattern "ldap_add_sW: No Such Attribute", "ldap_modify_sW: No Such Attribute" -Context 28,0
```
