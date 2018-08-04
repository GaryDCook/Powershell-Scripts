


<#
Used to remove sender domain to whitelist in Exchange Edge
Josh Hensley 11.22.2017
#>

$domain = read-host "Enter domain to remove from whitelist on an Edge server (ie: *.a10networks.com)"


$list = (Get-ContentFilterConfig).BypassedSenderDomains
$list.remove($domain)
set-contentfilterconfig -BypassedSenderDomains:$list


