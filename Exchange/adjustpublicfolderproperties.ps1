$total = ($mpf|measure).count
$count = 1
foreach ($f in $mpf)
{
write-host "Processing Folder $($count) of $($total)"
write-host "Mail Enabling Public folder $($f.name)"
#enable-mailpublicfolder -identity $f.identity -HiddenFromAddressListsEnabled $True
write-host "Getting Old Object"
$of = $pf2 | where {$_.name -eq $f.name}
if ($of -ne $null)
{
write-host "Setting Proxy addresses"
$f.primarysmtpaddress = $of.mail
$f | set-mailpublicfolder #-identity $f.identity -primarysmtpaddress $of.mail
foreach ($p in $of.proxyaddresses)
{

$f.emailaddresses += $p
write-host "adding proxy address $($p)"

}
$f | set-mailpublicfolder #-identity $f.identity -emailaddresses $of.proxyaddresses 
}
else
{
write-host "Object not found"
}

 $count +=1


}