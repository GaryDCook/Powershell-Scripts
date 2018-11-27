$head = @"
<title>Server Drive Report</title><meta http-equiv=”refresh” content=”120″ />
<style type=”text/css”>
<!–
body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}
 
#report { width: 835px; }
 
table{
border-collapse: collapse;
border: none;
font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
color: black;
margin-bottom: 10px;
}
 
table td{
font-size: 12px;
padding-left: 0px;
padding-right: 20px;
text-align: left;
}
 
table th {
font-size: 12px;
font-weight: bold;
padding-left: 0px;
padding-right: 20px;
text-align: left;
}
 
h2{ clear: both; font-size: 130%;color:#354B5E; }
 
h3{
clear: both;
font-size: 75%;
margin-left: 20px;
margin-top: 30px;
color:#475F77;
}
 
p{ margin-left: 20px; font-size: 12px; }
 
table.list{ float: left; }
 
table.list td:nth-child(1){
font-weight: bold;
border-right: 1px grey solid;
text-align: right;
}
 
table.list td:nth-child(2){ padding-left: 7px; }
table tr:nth-child(even) td:nth-child(even){ background: #BBBBBB; }
table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
div.column { width: 320px; float: left; }
div.first{ padding-right: 20px; border-right: 1px grey solid; }
div.second{ margin-left: 30px; }
table{ margin-left: 20px; }
–>
</style>
"@

$TotalGB = @{Name="Capacity(GB)";expression={[math]::round(($_.Capacity/ 1073741824),2)}}
$FreeGB = @{Name="FreeSpace(GB)";expression={[math]::round(($_.FreeSpace / 1073741824),2)}}
$FreePerc = @{Name="Free(%)";expression={[math]::round(((($_.FreeSpace / 1073741824)/($_.Capacity / 1073741824)) * 100),0)}}
function get-mountpoints {
$mpvolumes = Get-WmiObject -computer $server win32_volume | Where-object {$_.DriveLetter -eq $null}
$mp = $mpvolumes | Select Caption, Label, $TotalGB, $FreeGB, $FreePerc 
return $mp
}
function get-drpoints {
$drvolumes = Get-WmiObject -computer $server win32_volume | Where-object {$_.DriveLetter -ne $null}
$dr = $drvolumes | Select DriveLetter,Label, $TotalGB, $FreeGB, $FreePerc 
return $dr
}
$date = get-date | select datetime
$servers = (Get-Content .\servers.txt)
$title = "Drive Report for " + $date.datetime
$pre = "<h1>Drive Space Report for Servers</h1><br><h2>$title</h2>"
$post = "<h3>For more information please contact the Platforms Group</h3>"
convertto-html  -head $head -pre $pre -post $post -cssuri "c:\scripts\style.css" | set-content "C:\scripts\drivereport.html"

foreach ($server in $servers){
$mpp = get-mountpoints 
$dpp = get-drpoints
$htmlsn = "<h1>Server: " + $server + "</h1>" 
$htmlsn | add-content "C:\scripts\drivereport.html"
$dpp | convertto-html -fragment -Pre "<p>Lettered Drives</p>" | add-content "C:\scripts\drivereport.html"
$mpp | convertto-html -fragment -pre "<p>Mount Points</p>" | add-content "C:\scripts\drivereport.html"

Add-PSSnapin Microsoft.Exchange.Management.Powershell.Admin -erroraction silentlyContinue
$file = "C:\scripts\drivereport.html"


$smtpServer = "webmail.questsys.com"


$att = new-object Net.Mail.Attachment($file)


$msg = new-object Net.Mail.MailMessage


$smtp = new-object Net.Mail.SmtpClient($smtpServer)


$msg.From = "Platforms@questys.com"


$msg.To.Add("jhensley@questsys.com")


$msg.Subject = "Server Drive Report"


$msg.Body = "Attached is the Server Drive report"


$msg.Attachments.Add($att)


$smtp.Send($msg)


$att.Dispose()
} 
