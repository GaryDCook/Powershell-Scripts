<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.155
	 Created on:   	10/18/2018 9:18 PM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		create new shared mailboxes from csv.
#>

#read CSV
[CmdletBinding()]
param
(
	
)
BEGIN
{
	Import-Module azuread
	
	function write-log($logmsg,$logfile)
	{
		$logmsg | Out-File -FilePath $logfile -Append
	}
	
}
PROCESS
{
	$lf = Read-Host "Enter the complete filename (including path) where the log for thsi script will be created"
	write-log -logmsg "****************Shared Mailbox Creation Run********************" -logfile $lf
	write-log -logmsg "Script Run Date/time: $([datetime]::now)" -logfile $lf
	write-log -logmsg "***************************************************************" -logfile $lf
	$cred = Get-Credential -Message "Enter the Credential of a Office 365 Tenant Admin Account"
	Write-Host "Connecting to Azure AD"
	connect-azuread -credential $cred
	Write-Host "Connecting to Exchange Online"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cred -Authentication Basic -AllowRedirection
	Import-PSSession $Session -DisableNameChecking -AllowClobber
	$filename = Read-Host "Enter the complete path to the csv containing the Shared mailbox data"
	$SMBS = Import-Csv -Path $filename
	$count = ($SMBS | measure).count
	$i = 0
	$failurecount = 0
	Write-Host "Processing Data"
	foreach ($smb in $smbs)
	{
		Write-Progress -Activity "Creating Shared Mailboxes" -Status "Processing mailbox $($smb.alias)" -PercentComplete ($i/$count*100)
		write-log -logmsg "Attempting creation of mailbox $($smb.alias)" -logfile $lf
		try
		{
			new-mailbox -shared -name $smb.alias -DisplayName $smb.alias -Alias $smb.alias -PrimarySmtpAddress $smb.primarysmtp
			write-log -logmsg "Successful creation of mailbox $($smb.alias)" -logfile $lf
			Add-MailboxPermission -identity $smb.alias -User $smb.owner -AccessRights FullAccess -InheritanceType All
			write-log -logmsg "Successful setting of owner for mailbox $($smb.alias)" -logfile $lf
			set-mailbox -identity $smb.alias -hiddenfromaddresslistsenabled $true
			write-log -logmsg "Successful hidding from address lists for mailbox $($smb.alias)" -logfile $lf
			
		}
		catch
		{
			write-log -logmsg "Processing of mailbox $($smb.alias) failed" -logfile $lf
			write-log -logmsg "Failure message $($_.Exception.Message)" -logfile $lf
			$failurecount +=1
		}
		$i+=1
	}
	write-log -logmsg "Total Failure count: $($failurecount)" -logfile $lf
}
END
{
	write-log -logmsg "****************Shared Mailbox Creation Run End****************" -logfile $lf
	Remove-PSSession $Session
	disconnect-azuread
}

