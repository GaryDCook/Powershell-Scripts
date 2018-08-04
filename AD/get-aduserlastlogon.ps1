
<#
Script used to get lastlogon values from all domain controllers for all AD users.
Joshua Hensley 12.14.17
#>


function Get-ADUsersLastLogon()
{
  $dcs = Get-ADDomainController -Filter {Name -like "*"}
  $users = Get-ADUser -Filter * -Properties name,samaccountname,passwordlastset,enabled
  $time = 0
  $exportFilePath = "c:\temp\lastLogon.csv"
  $columns = "name,username,datetime,PasswordLastSet,enabled"
  $counter = 1
 
  Out-File -filepath $exportFilePath -force -InputObject $columns
 
  foreach($user in $users)
  {
  write-progress -Activity "Processing User" -Status "User $user.name" -PercentComplete ($counter/$users.count*100)
  $counter+=1
    foreach($dc in $dcs)
    { 
      $hostname = $dc.HostName
      $currentUser = Get-ADUser $user.SamAccountName | Get-ADObject -Server $hostname -Properties lastLogon
 
      if($currentUser.LastLogon -gt $time) 
      {
        $time = $currentUser.LastLogon
      }
    }
 
    $dt = [DateTime]::FromFileTime($time)
    $row = $user.Name+","+$user.SamAccountName+","+$dt+","+$user.PasswordLastSet+","+$user.enabled
 
    Out-File -filepath $exportFilePath -append -noclobber -InputObject $row
 
    $time = 0
  }
}
 
Get-ADUsersLastLogon