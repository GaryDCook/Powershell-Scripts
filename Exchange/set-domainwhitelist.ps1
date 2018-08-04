
<#
Used to whitelist a sender domain
Josh Hensley 11.22.2017
#>

$domain = read-host "Enter domain to whitelist (ie: *.a10networks.com)"

Set-ContentFilterConfig -BypassedSenderDomains $domain



