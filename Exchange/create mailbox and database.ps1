import-module activedirectory
foreach ($user in $users)
{
write-host "Processing user $($user.samaccountname)"

#create database if it does not exist
$dbname = "USA_$($user.database)"
write-host "User origional database is $($dbname)"
if ((get-mailboxdatabase|?{$_.name -eq $dbname}|measure).count -eq 0)
{
write-host "Database does not exist creating"
#create database
new-mailboxdatabase -name $dbname -edbfilepath "f:\exchdatabases\$($dbname)\$($dbname).edb" -server "ntaambx03" -logfolderpath "i:\exchlogs\$($dbname)"
$newdb = get-mailboxdatabase -server "ntaambx03" -identity $dbname
write-host "Enabling Circular Logging"
$newdb | set-mailboxdatabase -circularloggingenabled:$true
sleep -Seconds 10
write-host "Mounting Database"
mount-database -name $dbname
writee-host "Restarting IS"
invoke-command -ComputerName ntaambx03 -ScriptBlock "restart-service msexchangeis"


}
else
{
write-host "Database exists"
}

Write-host "Removing mailnickname"
#remove the mailnickname attribute in AD
Get-ADUser $user.samaccountname -Properties MailNickName | Set-ADUser -clear MailNickName

write-host "Creating Mailbox"
#create mailbox
enable-mailbox -identity $user.samaccountname -database $dbname -primarysmtpaddress $user.primarysmtpaddress 


}