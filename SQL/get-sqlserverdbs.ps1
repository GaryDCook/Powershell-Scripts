<#
Used to get list of all SQL server databases on servers named in 'SQL_Servers.txt'""
Be sure to update directory paths if needed.
Josh Hensley 12/14/17
#>



ForEach ($instance in Get-Content "c:\scripts\SQL_Servers.txt")
{
     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instance
     $dbs=$s.Databases       
     $dbs | SELECT Parent, Urn, Name, Collation, CompatibilityLevel, AutoShrink, RecoveryModel, Size, SpaceAvailable
     $export = $dbs | SELECT Parent, Urn, Name, Collation, CompatibilityLevel, AutoShrink, RecoveryModel, Size, SpaceAvailable 
     $export | export-csv -path "c:\scripts\sqldbexport.csv" -append
     
} 

