
<#
Used to remove move requests
Josh Hensley 11.22.2017
#>

$UserMailbox = read-host "Enter Mailbox Name to remove move request for (ie: John Doe)"

remove-moverequest -identity $usermailbox

