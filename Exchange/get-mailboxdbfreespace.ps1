<#
Check's available database white space.
Josh Hensley 11.17.2017
#>

Get-MailboxDatabase -Status | Select Name,Available*
