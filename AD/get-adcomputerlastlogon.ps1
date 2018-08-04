
##################
#--------Config
##################

$domain = "questsys.corp"

##################
#--------Main
##################

import-module activedirectory
cls
"The domain is " + $domain
####$computername = Read-Host 'What is the computer name?'
$computers = get-adcomputer -Properties * -filter * | Select -First 5
foreach ($computername in $computers)
{
$myForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$domaincontrollers = $myforest.Sites | % { $_.Servers } | Select Name
$RealComputerLastLogon = $null
$LastusedDC = $null
$domainsuffix = "*."+$domain
foreach ($DomainController in $DomainControllers) 
{
       if ($DomainController.Name -like $domainsuffix)
       {
              $ComputerLastlogon = Get-ADComputer -Identity $computername -Properties LastLogon -Server $DomainController.Name
              if ($RealComputerLastLogon -le [DateTime]::FromFileTime($ComputerLastlogon.LastLogon))
              {
                    $RealComputerLastLogon = [DateTime]::FromFileTime($ComputerLastlogon.LastLogon)
                    $LastusedDC =  $DomainController.Name
              }
       }
}
$computername.name
$computername.name + "," + $RealComputerLastLogon + "," + $LastusedDC + "" | Out-File -Encoding Ascii -append C:\scripts\computerlast.txt
} 

