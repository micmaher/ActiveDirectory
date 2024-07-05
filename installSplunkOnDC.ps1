break
$dcs = Get-ADDomainController -Filter * 

$pwd = Get-Credential -Message "Enter the password" -UserName "admin" -Verbose
$pwd.Password
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd.Password)
$pwdstring = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$splunkApp = (Get-Item -Path "C:\scripts\splunkforwarder-8.0.2.1-f002026bad55-x64-release.msi")
$cmdhash=@{}
$cmdhash['FilePath']    = 'C:\Windows\System32\msiexec.exe'
$cmdhash['Wait']        = $true
$cmdhash['NoNewWindow'] = $true
$cmdhash['ArgumentList']=@()
$cmdhash['ArgumentList'] += "/i $splunkApp"
$cmdhash['ArgumentList'] += "/l*v C:\Windows\TEMP\splunk-mm.log"
$cmdhash['ArgumentList'] += '/quiet'
$cmdhash['ArgumentList'] += 'DEPLOYMENT_SERVER="splunk01.domain.com:8089"'
$cmdhash['ArgumentList'] += 'AGREETOLICENSE="Yes"'
$cmdhash['ArgumentList'] += 'SPLUNKUSERNAME="admin"'
$cmdhash['ArgumentList'] += "SPLUNKPASSWORD=$pwdstring"

# Install Splunk
ForEach ($d in $dcs) {

 $alreadyInstalled = $null

    $alreadyInstalled = Get-WmiObject -ComputerName $d.name Win32_Product | Where {$_.name -like "Splunk*"}

    If (-not($alreadyInstalled)){

        Write-Host -ForegroundColor Green "Working on $($d.name)"
            
        $s = New-PSSession -ComputerName $d.name
    
        Invoke-Command -Session $s -ScriptBlock {If(-not(Test-Path 'C:\Temp\')){New-Item -Path C:\temp -ItemType Directory} }

        Copy-Item -Path $splunkApp.FullName -Destination "\\$($d.name)\C$\Temp" -Verbose

        Start-Sleep -Seconds 5

        Write-Host "Installing Splunk Universal Forwarder on $($d.name)"

        Invoke-Command -Session $s -ScriptBlock {Start-Process @Using:cmdhash -Verbose}

        Start-Sleep -Seconds 10

        Invoke-Command -Session $s -ScriptBlock {Get-WinEvent -FilterHashtable @{LogName="Application";ID="11707";StartTime=(Get-Date).AddMinutes(-2)} }

        Remove-PSSession $s

    }
    Else{
        Write-Host -ForegroundColor Cyan "Skipped $($d.name) as its already installed"
    }

}

#Validate Install Splunk
ForEach ($d in $dcs) {
    Write-Host -ForegroundColor Green "Checking $($d.name)"
    Get-WmiObject -ComputerName $d.name Win32_Product | Where {$_.name -like "UniversalForwarder*"}
}


# Rollback
ForEach ($d in $dcs) {
    Write-Host -ForegroundColor Green "Checking $($d.name)"
    $installed = Get-WmiObject -ComputerName $d.name Win32_Product | Where {$_.name -like "UniversalF*"}
    $msiString = $installed.IdentifyingNumber

    If ($Installed){
            
            $s = New-PSSession -ComputerName $d.name
 
            Invoke-Command -Session $s -ScriptBlock {msiexec.exe /x $Using:msistring /qn /norestart}

            Write-Host "Uninstalling Splunk on $($d.name)"

            Start-Sleep -Seconds 10

            Invoke-Command -Session $s -ScriptBlock {Get-WinEvent -FilterHashtable @{LogName="Application";ID="1034";StartTime=(Get-Date).AddMinutes(-2)} }

            Start-Sleep -Seconds 5
  

            Remove-PSSession $s
        }
    Else{ 
            Write-Host -ForegroundColor Cyan "Skipped $($d.name) - was not installed"
            }
}
