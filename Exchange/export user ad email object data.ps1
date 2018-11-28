$users = get-mailbox -resultsize unlimited | ?{$_.servername -like 'ntaamb*'}
$res = @()
foreach ($user in $users)
{
write-host "Processing User $($user.samaccountname)"
$data = new-object psobject
$data | Add-Member -MemberType NoteProperty -Name Samaccountname -Value $null
$data | Add-Member -MemberType NoteProperty -Name Database -Value $null
$data | Add-Member -MemberType NoteProperty -Name Alias -Value $null
$data | Add-Member -MemberType NoteProperty -Name Primarysmtpaddress -Value $null
$data | Add-Member -MemberType NoteProperty -Name Emailaddresses -Value $null
$data | Add-Member -MemberType NoteProperty -Name Windowsemailaddress -Value $null
$data | Add-Member -MemberType NoteProperty -Name issuewarningquota -Value $null
$data | Add-Member -MemberType NoteProperty -Name rulesquota -Value $null
$data | Add-Member -MemberType NoteProperty -Name usedatabasequotadefaults -Value $null

$data.samaccountname = $user.samaccountname
$data.database = $user.database
$data.alias = $user.alias
$data.primarysmtpaddress = $user.primarysmtpaddress
$data.windowsemailaddress = $user.windowsemailaddress
$data.usedatabasequotadefaults = $user.usedatabasequotadefaults
$data.rulesquota = $user.rulesquota
$data.issuewarningquota = $user.issuewarningquota
$count = 0
$total = ($user.emailaddresses|measure).count
foreach ($address in $user.emailaddresses)
{
#write-host "Processing Email Address $($count) of $($total)"
#write-host "Processing Address:  $($address.proxyaddressstring)"
if ($address.prefixstring -eq "SMTP")
{
if($count -eq 0)
{
$data.emailaddresses += "$($address.proxyaddressstring)"
}
else
{
$data.emailaddresses += ";"
$data.emailaddresses += $($address.proxyaddressstring)
}
$count +=1
}
}


$res += $data

}

$res | export-csv -Path "e:\install\output.csv" -NoTypeInformation