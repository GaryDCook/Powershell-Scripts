<#
Used for scanning file shares for file types and sizes.
Josh Hensley 2.27.18

#>




 $ext = read-host "Enterentention to scan for"
$spath = read-host "Enter Starting path"
$ext = "*." + $ext
$files = get-childitem -recurse -Path $spath |?{$_.name -like $ext}
$res = @()

foreach($file in $files)
{
$output = New-Object psobject
$output | Add-Member -MemberType NoteProperty -Name Filename -Value $null
$output | Add-Member -MemberType NoteProperty -Name SizeGB -Value $null
$output | Add-Member -MemberType NoteProperty -Name LastAccess -Value $null
$output.Filename = $file.versioninfo.filename
$output.SizeGB = $file.length / 1GB
$output.LastAccess = $file.LastAccessTime

$res += $output


}
$res | export-csv -path "$spath\output-ova.csv" -NoTypeInformation  
