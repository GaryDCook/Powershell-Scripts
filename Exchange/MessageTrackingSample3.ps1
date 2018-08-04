


<#
Used to get message tracking logs by sender in transport and displays recipients by line
Sample 3
Josh Hensley 11.22.2017
#>

$startdate = read-host "Enter Start Date & Time (MM/DD/YYYY HH:MMAM)"
$enddate = read-host "Enter End Date & Time (MM/DD/YYYY HH:MMPM)"
$sender1 = read-host "Enter sender e-mail address"
$filepath = read-host "Enter file path (ie: c:\scripts\exports.csv)"


get-transportservice | get-messagetrackinglog -resultsize 5000 -start $startdate -end $enddate -sender $sender1 | Select {$_.Recipients}, {$_.RecipientStatus}, * | export-csv -path $filepath


