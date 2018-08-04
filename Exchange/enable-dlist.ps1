<#
Use this to enable a distribution list in Exchange that already exists in Active Directory
https://technet.microsoft.com/en-us/library/aa998916(v=exchg.160).aspx
Josh Hensley 11.17.2017
#>



$dlistname = read-host "Enter Distribution List Name"
Enable-DistributionGroup -identity $dlistname

