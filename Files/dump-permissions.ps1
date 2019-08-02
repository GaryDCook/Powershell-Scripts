$Items = (Get-ChildItem "c:\program files" -Recurse | Where { $_.PSIsContainer } | select fullname | %{$_.fullname.trim()})
$Path = "C:\scripts\testACLs.csv"

$Table = @()
$Record = [ordered]@{
"Directory" = ""
"Owner" = ""
"FileSystemRights" = ""
"AccessControlType" = ""
"IdentityReference" = ""
"IsInherited" = ""
"InheritanceFlags" = ""
"PropogationFlags" = ""

}

Foreach ($Item in $Items)
{

$ACL = (Get-Acl -Path $Item)

$Record."Directory" = $ACL.path.Replace("Microsoft.PowerShell.Core\FileSystem::","")
$Record."Owner" = $ACL.Owner

Foreach ($SItem in $ACL.access)
{
write-host "$($SItem.identityreference.value) is being processed"
if (!$SItem.identityreference.value.contains("\"))
{
write-host "Item does not contain a \"
$query = $SItem.identityreference.value

}
else
{
write-host "Item Contains a \"
$query = ($SItem.identityreference.value -split "\\")[1]

}
$type = (get-adobject -filter * | ?{$_.name -eq $query}).objectclass
write-host "The name is $($query)"
write-host "The type is $($type)"
if ($type -eq 'group')
{
$members = (get-adgroup -identity $query -properties *).members
foreach ($m in $members)
{
try
{
$user = get-aduser -identity $m -properties *
$Record."FileSystemRights" = $SItem.FileSystemRights
$Record."AccessControlType" = $SItem.AccessControlType
$Record."Type" = "Group"
$Record."ParentObject" = $Sitem.identityreference.value
$Record."IdentityReference" = $user.userprincipalname
$Record."IsInherited" = $SItem.IsInherited
$Record."InheritanceFlags" = $SItem.InheritanceFlags
$Record."PropogationFlags" = $SItem.PropagationFlags
$objRecord = New-Object PSObject -property $Record
$Table += $objrecord
}
catch
{
write-host "non AD User in group"
}
}
}
else
{
$Record."FileSystemRights" = $SItem.FileSystemRights
$Record."AccessControlType" = $SItem.AccessControlType
$Record."Type" = "User"
$Record."ParentObject" = $Sitem.identityreference
$Record."IdentityReference" = $SItem.IdentityReference
$Record."IsInherited" = $SItem.IsInherited
$Record."InheritanceFlags" = $SItem.InheritanceFlags
$Record."PropogationFlags" = $SItem.PropagationFlags
$objRecord = New-Object PSObject -property $Record
$Table += $objrecord
}


}
}
$Table | Export-Csv -Path $Path -NoTypeInformation