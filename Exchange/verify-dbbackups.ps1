<#
Used to verify backups for a single database
Josh Hensley 11.17.2017
#>


$dbname = read-host "Enter Databasename"
Get-MailboxDatabase -Identity #dbname -Status | Select Name,Last*Backup
