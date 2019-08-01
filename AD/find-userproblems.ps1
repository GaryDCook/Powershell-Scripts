$res = @()
$users = get-aduser -filter * -properties *
foreach ($user in $users){
$obj = new-object psobject
$obj | add-member -MemberType NoteProperty -Name Displayname -Value $user.displayname
$obj | add-member -MemberType NoteProperty -Name samaccountname -Value $user.samaccountname
$obj | add-member -MemberType NoteProperty -Name Userprincipalname -Value $user.userprincipalname
$tempupn = $user.userprincipalname.split('@')[0]
if ($user.userprincipalname -eq $tempupn)
{
$obj | add-member -MemberType NoteProperty -Name upnmatch -Value $true
}
else
{
$obj | add-member -MemberType NoteProperty -Name upnmatch -Value $false
}
if ($user.userprincipalname -like '*questsys.com*')
{
$obj | add-member -MemberType NoteProperty -Name upncorrect -Value $true
}
else
{
$obj | add-member -MemberType NoteProperty -Name upncorrect -Value $false
}
$res += $obj
}
