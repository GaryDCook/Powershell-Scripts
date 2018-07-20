#get list of servers in Dag
$DAG = get-databaseavailabilitygroup
$DAGServers = $DAG.Servers
$dbname = read-host "Enter Database Name"
$edbpath = read-host "Enter Database Path and name (ie. c:\test\test.edb)"
$logpath = read-host "Enter Log Path (enter just the path)"
write-host "Select the production server to host the primary copy of the database (1-4)"
$counter = 0
foreach($server in $DAGServers)
{
Write-host $counter + ") " + $server.name
}
$aserver = read-host 

if ($aserver -eq 0)
{
$order = @(0,1,2,3)
}
if ($aserver -eq 1)
{
$order = @(1,0,3,2)
}
if ($aserver -eq 2)
{
$order = @(2,3,0,1)
}
if ($aserver -eq 3)
{
$order = @(3,2,1,0)
}
write-host "Adding Database to Server"
new-mailboxdatabase -server $DAGServers[$order[0]] -name $dbname -logfolderpath $logpath -edbfilepath $edbpath
for ($i=1;$i -le 3;$i++)
{
if($i -eq 3)
{
add-mailboxdatabasecopy -identity $dbname -mailboxserver $DAGServers[$order[$i]] -activationprefence $order[$i] -replaylagtime 7
}
else
{
add-mailboxdatabasecopy -identity $dbname -mailboxserver $DAGServers[$order[$i]] -activationprefence $order[$i]
}
}

write-host "Database and copies added"


