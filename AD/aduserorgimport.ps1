<#
Created to update AD user account objects based off of CSV file

SAMPLE
firstname,lastname,username,managerfirstname,managerlastname,mgrusername,dept,title,company
Chris,Scarabino,cscarabino,Georgina,Hastings,ghastings,ADMIN - ACTG,RMA Receiving Coordinator/Billing Clerk,Quest

#>






$file = import-csv -path "C:\Scripts\userinput.csv"

foreach ($item in $file)
{
$Un = $item.username
$mun = $item.mgrusername
$dept = $item.dept
$title = $item.title
$company = $item.company

$user = get-aduser -identity $un -properties * 
set-aduser -identity $user -Department $dept -title $title -company $company
$mgr = get-aduser -identity $mun -properties * | select distinguishedname
set-aduser -identity $user -Manager $mgr.distinguishedname
}
