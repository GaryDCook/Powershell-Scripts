
<#
Used to get mailbox retention settings
Josh Hensley 11.17.2017
#>

$dbname = read-host "Enter Databasename"
Get-MailboxDatabase -Identity $dbname | Select MailboxRetention,DeletedItemRetention,Retain*