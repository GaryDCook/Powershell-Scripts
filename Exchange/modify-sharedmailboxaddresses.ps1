<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.155
	 Created on:   	10/18/2018 10:43 PM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Add email addrersses and change Primary SMTP address.
#>
[CmdletBinding()]
param
(
	
)
BEGIN
{
	Import-Module azuread
	
	function write-log($logmsg, $logfile)
	{
		$logmsg | Out-File -FilePath $logfile -Append
	}
	
}
PROCESS
{
	$lf = Read-Host "Enter the complete filename (including path) where the log for thsi script will be created"
	write-log -logmsg "****************Shared Mailbox Addr Mod Run********************" -logfile $lf
	write-log -logmsg "Script Run Date/time: $([datetime]::now)" -logfile $lf
	write-log -logmsg "***************************************************************" -logfile $lf
	$domain = Read-Host "Enter the email domain to process"
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
		Write-Progress -Activity "Modifing Shared Mailboxes" -Status "Processing mailbox $($smb.alias)" -PercentComplete ($i/$count * 100)
		write-log -logmsg "Attempting to add email addresses for mailbox $($smb.alias)" -logfile $lf
		try
		{
			$ErrorActionPreference = "Stop" #Make all errors terminating
			$mb = get-mailbox -identity $smb.alias -ea stop
			$mb.emailaddresses = $mb.emailaddresses.tolower()
			$eas = $smb.addresses.split(";")
			foreach ($ea in $eas)
			{
				if ($ea -like "*@$($domain)")
				{
					set-mailbox -identity $smb.alias -emailaddresses @{ add = "$($ea)" }-ea stop
				}
			}
			set-mailbox -identity $smb.alias -emailaddresses @{ add = "SMTP:$($smb.primarysmtp)" } -ea stop
			write-log -logmsg "Successful adding email addresses to mailbox $($smb.alias)" -logfile $lf
			#set-mailbox -identity $smb.alias -primarysmtpaddress $smb.primarysmtp -ea stop
			
		}
		catch
		{
			write-log -logmsg "Processing of mailbox $($smb.alias) failed" -logfile $lf
			write-log -logmsg "Failure message $($error[0].Exception)" -logfile $lf
			$failurecount += 1
		}
		finally
		{
			$ErrorActionPreference = "Continue"; #Reset the error action pref to default	
		}
		$i += 1
	}
	write-log -logmsg "Total Failure count: $($failurecount)" -logfile $lf
}
END
{
	write-log -logmsg "****************Shared Mailbox Creation Run End****************" -logfile $lf
	Remove-PSSession $Session
	disconnect-azuread
}

