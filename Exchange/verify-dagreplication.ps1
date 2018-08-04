<#
Used to check DAG replication status
Josh Hensley 11.17.2017
#>


Get-MailboxDatabaseCopyStatus * | Select Name,Status,*QueueLength,ContentIndexState

