

<#
Used to get message tracking logs by sender
Sample 2
Josh Hensley 11.22.2017
#>

$server = read-host "Enter server name"
$startdate = read-host "Enter Start Date & Time (MM/DD/YYYY HH:MMAM)"
$enddate = read-host "Enter End Date & Time (MM/DD/YYYY HH:MMPM)"
$sender1 = read-host "Enter sender e-mail address"
$filepath = read-host "Enter file path (ie: c:\scripts\exports.csv)"


Get-MessageTrackingLog -Server $server -start $startdate -end $enddate -sender $sender1 | Export-Csv -path $filepath


