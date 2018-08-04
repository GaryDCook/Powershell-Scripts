


<#
Used to get room mailbox properties
Josh Hensley 11.22.2017
#>

$roommailbox = read-host "Enter room mailbox name"

get-mailbox -identity $roommailbox -recipienttypedetails roommailbox | fl

