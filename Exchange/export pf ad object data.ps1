 $pf = get-adobject -filter * -properties * | where {$_.objectclass -eq "publicfolder"}
 $res = @()
 foreach ($f in $pf2)
 {

 $data = new-object psobject
$data | Add-Member -MemberType NoteProperty -Name CanonicalName -Value $null
$data | Add-Member -MemberType NoteProperty -Name CN -Value $null
$data | Add-Member -MemberType NoteProperty -Name Description -Value $null
$data | Add-Member -MemberType NoteProperty -Name DisplayName -Value $null
$data | Add-Member -MemberType NoteProperty -Name homeMDB -Value $null
$data | Add-Member -MemberType NoteProperty -Name isDeleted -Value $null
$data | Add-Member -MemberType NoteProperty -Name mail -Value $null
$data | Add-Member -MemberType NoteProperty -Name mailNickname -Value $null
$data | Add-Member -MemberType NoteProperty -Name msExchHomeServerName -Value $null
$data | Add-Member -MemberType NoteProperty -Name Name -Value $null
$data | Add-Member -MemberType NoteProperty -Name proxyAddresses -Value $null



$data.canonicalname = $f.canonicalname
$data.cn = $f.cn
$data.Description = $f.Description
$data.DisplayName = $f.DisplayName
$data.homeMDB = $f.homeMDB
$data.isDeleted = $f.isDeleted
$data.mail = $f.mail
$data.mailNickname = $f.mailNickname
$data.msExchHomeServerName = $f.msExchHomeServerName
$data.name = $f.name

foreach ($address in $f.proxyaddresses)
{

if ($address -like 'SMTP:*')
{

$data.proxyaddresses += "'$($address)'"
$data.proxyaddresses += ";"

}

}



$res += $data


}
$res | export-csv -Path "e:\install\pf.csv" -NoTypeInformation






