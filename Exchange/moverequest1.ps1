


<#
Used to create a new mailbox move request
Josh Hensley 11.22.2017
#>

$UserMailbox = read-host "Enter Mailbox Name (ie: John Doe)"
$targetdb = read-host "Enter Target DB"
$targetarchdb = read-host "Enter Target Archive DB"
$baditems = read-host "Enter Bad Item Limit #"

new-moverequest -identity $usermailbox -TargetDatabase $targetdb -ArchiveTargetDatabase $targetarchdb -baditemlimit $baditems

