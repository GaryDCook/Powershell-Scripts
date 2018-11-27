

function convert-wpltom3u($file)
{
$wpl = get-content -path $file
$plxml = [xml]$wpl
$dest = $file.replace("wpl","m3u")
write-host "Creating M3U playlist $($dest)"
$cpl = "#EXTM3U"
$cpl | out-file -FilePath $dest 
foreach ($song in $plxml.smil.body.seq.media.src)
{
#$song
write-host "Processing song $($song), getting length"
$path = $song
#$path
$shell = New-Object -COMObject Shell.Application
$folder = Split-Path $path
$folder = $folder.trimstart(".","\")
$folder = "e:\$($folder)"
$file = Split-Path $path -Leaf
#$file
$shellfolder = $shell.Namespace($folder)
#$shellfolder
$shellfile = $shellfolder.ParseName($file)
#$shellfile

#write-host $shellfolder.GetDetailsOf($shellfile, 27); 
#conver to seconds
$len = $shellfolder.GetDetailsOf($shellfile, 27)
$authors = $shellfolder.getdetailsof($shellfile,13)
$name = $shellfolder.getdetailsof($shellfile,0)
$name = $name.replace(".mp3","")
$timeString = $len
$timeStringWithPeriod = $timeString.Replace(",",".")
$timespan = [TimeSpan]::Parse($timestringWithPeriod)
$totalSeconds = $timespan.TotalSeconds
#$totalseconds
$line = "#EXTINF:$($totalSeconds),$($name) - $($authors)"
$line | out-file -FilePath $dest -Append
$song | out-file -FilePath $dest -Append



}

return $plxml
}
