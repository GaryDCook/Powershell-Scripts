<#
Used to get message tracking logs by recipient
Sample 1
Josh Hensley 11.17.2017
#>

$startdate = read-host "Enter Start Date & Time (MM/DD/YYYY HH:MMAM)"
$enddate = read-host "Enter End Date & Time (MM/DD/YYYY HH:MMPM)"
$recipient1 = read-host "Enter recipipent e-mail address"
$filepath = read-host "Enter file path (ie: c:\scripts\exports.csv)"


Get-MessageTrackingLog -ResultSize Unlimited -Start $startdate -End $enddate -Recipients $recipient1 | Export-Csv $filepath





