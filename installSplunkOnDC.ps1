break
$dcs = Get-ADDomainController -Filter * 


$pwd = Get-Credential -Message "Enter the password" -UserName "admin" -Verbose
$pwd.Password
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd.Password)
$pwdstring = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$splunkApp = (Get-Item -Path "C:\temp\splunkforwarder-8.2.11-e73c56f930c5-x64-release.msi")
$cmdhash=@{}
$cmdhash['FilePath']    = 'C:\Windows\System32\msiexec.exe'
$cmdhash['Wait']        = $true
$cmdhash['NoNewWindow'] = $true
$cmdhash['ArgumentList']=@()
$cmdhash['ArgumentList'] += "/i $splunkApp"
$cmdhash['ArgumentList'] += "/l*v C:\TEMP\splunk-mm.log"
$cmdhash['ArgumentList'] += '/quiet'
$cmdhash['ArgumentList'] += 'DEPLOYMENT_SERVER="splunk01.domain.com:8089"'
$cmdhash['ArgumentList'] += 'AGREETOLICENSE="Yes"'
$cmdhash['ArgumentList'] += 'SPLUNKUSERNAME="admin"'
$cmdhash['ArgumentList'] += "SPLUNKPASSWORD=$pwdstring"

# Install Splunk
ForEach ($d in $dcs) {

    Write-Host "Working on $($d.name)"
    $alreadyInstalled = $null

    $alreadyInstalled = Get-WmiObject -ComputerName $d.name Win32_Product | Where {$_.name -like "UniversalF*"}
    
    If ($alreadyInstalled.Version -ne '8.2.12.0'){
        
        Write-Host "Version $($alreadyInstalled.version) of the UniversalForwarder is already installed on $($d.name) and will be replaced"

        If ($alreadyInstalled.Version -eq '8.2.11.0'){
            Write-Host "Uninstalling 8.2.11.0 and installing a compatible version"
            $msiString = $alreadyInstalled.IdentifyingNumber
            $s = New-PSSession -ComputerName $d.name
            Invoke-Command -Session $s -ScriptBlock {msiexec.exe /x $Using:msistring /qn /norestart}
            Start-Sleep -Seconds 40
            Invoke-Command -Session $s -ScriptBlock {Get-WinEvent -FilterHashtable @{LogName="Application";ID="1034";StartTime=(Get-Date).AddMinutes(-2)} | Select Message}

        }

        Write-Host -ForegroundColor Green "Copying installer to $($d.name)"
        
        If ((Get-PSSession).ComputerName -eq $d.Name){
            Write-Host "Using an existing open session"
        }
        Else{
            Write-Host "Opening a new session to $($d.name)"
            $s = New-PSSession -ComputerName $d.name
        }
        Invoke-Command -Session $s -ScriptBlock {If(-not(Test-Path 'C:\Temp\')){New-Item -Path C:\temp -ItemType Directory} }

        Copy-Item -Path $splunkApp.FullName -Destination "\\$($d.name)\C$\Temp" -Verbose

        Start-Sleep -Seconds 5

        Write-Host "Performing fresh install of Splunk Universal Forwarder on $($d.name)"

        Invoke-Command -Session $s -ScriptBlock {Start-Process @Using:cmdhash -Verbose}

        Start-Sleep -Seconds 20

        Invoke-Command -Session $s -ScriptBlock {Get-WinEvent -FilterHashtable @{LogName="Application";ID="11707";StartTime=(Get-Date).AddMinutes(-2)} }

        Remove-PSSession $s

    }

    Else {
        Write-Host -ForegroundColor Cyan "Skipped $($d.name) as its already installed"
    }

}

#Validate Install Splunk
ForEach ($d in $dcs) {
    Write-Host -ForegroundColor Green "Checking $($d.name)"
    (Get-WmiObject -ComputerName $d.name Win32_Product | Where {$_.name -like "UniversalForwarder*"}).Version
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
