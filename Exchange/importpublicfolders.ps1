$folders = import-csv -path "E:\install\pfpathinput.csv"
$total = ($folders|measure).count
$count = 1
foreach($folder in $folders)
{
write-host "Processing Folder $($count) of $($total)"
write-host "Creating Folder $($folder.newpath)\$($folder.newname)" 
$name = $folder.newname
$ppath = $folder.newpath
$server = "ntaambx03"

new-publicfolder -name $name -path $ppath -server $server
write-host "Folder Created"

}