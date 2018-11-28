write-host "Reading Current Public Folder List from Server NTAAMBX03"

$mpf = get-publicfolder "\COSCO North America" -server ntaambx03 -recurse | where {$_.mailenabled -eq $true}
$pf2 = import-csv -path "e:\install\pf.csv" 

$total = ($mpf|measure).count
$count = 1
foreach ($f in $mpf)
{
write-progress -status "Processing Folder $($count) of $($total)" -Activity "Setting Email Attributes of Public Folders" -CurrentOperation "Processing folder $($f.name)" -PercentComplete (($count/$total) *100)
$f2 = get-mailpublicfolder $f

$of = $pf2 | where {$_.name -eq $f.name}

if ($of -ne $null)
{
$prime = $f2.primarysmtpaddress
#remove adobject mail prperties

get-adobject -identity $of.identitiy |set-adobject -clear mail,mailnickname,proxyaddress
$f2.primarysmtpaddress = $of.mail
$f2 | set-mailpublicfolder #-identity $f.identity -primarysmtpaddress $of.mail

$nof = $of.proxyaddresses2 -split ';'

#remove existing proxy addresses from 'SMTP
foreach ($proxy in $f2.emailaddresses)
{

if ($proxy.prefix -eq "'smtp")
{
#$pa.prefix = "smtp"
#$pa.prefixstring = "smtp"
#$len1 = $pa.addressstring.length
#$pa.addressstring = $pa.addressstring.substring(0,$len1-1)
#$pa.proxyaddressstring = $pa.proxyaddressstring.remove(0,1)
#$len2 = $pa.proxyaddressstring.length
#$pa.proxyaddressstring = $pa.proxyaddressstring.substring(0,$len1-1

set-mailpublicfolder -identity $f2.identity -emailaddresses @{remove=$proxy.proxyaddressstring} -domaincontroller ntaadcs03

}



}

#set-mailpublicfolder -identitiy $f2.identitiy -emailaddresses "smtp:$($prime)" 

foreach ($p in $nof)
{
if ($p -ne '')
{

write-host "adding proxy address $($p)"
set-mailpublicfolder -identity $f2.identity -emailaddresses @{Add=$p} -domaincontroller ntaadcs03
}

}

}
else
{
write-host "Object not found"
}

 $count +=1


}