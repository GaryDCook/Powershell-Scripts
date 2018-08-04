<#
Used to detect mailbox corruption
https://technet.microsoft.com/en-us/library/ff625221(v=exchg.141).aspx
Josh Hensley 11.17.2017
#>
$mbname = read-host "Enter Mailbox Name"
New-MailboxRepairRequest -Mailbox $mbname -CorruptionType ProvisionedFolder,SearchFolder -DetectOnly