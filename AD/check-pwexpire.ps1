<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.115
	 Created on:   	12/7/2016 2:22 PM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	Check-PWExpire.ps1
	===========================================================================
	.DESCRIPTION
		This script will find users with passwords about to expire and generate an email to the user alerting them of the pending expiration. This script skips users with password set to never expire.
		This script requires server 2012 with the .net framework 3.5 or higher and powershell 1.0 or higher.

		You will need to update the following parameters:

			$verbose: Set it to $true if you would like to send the Password Policy settings to the end users. If you not want to use this optional feature, you can set the value to $false.
			
			$notificationstartday: Set the value of the default interval to start notifying the users about the expiry (This is the delta between the current date and the expiry date)

			$sendermailaddress: Set the e-mail address that will be used to send mail notifications. It can be, as an example, your Service Desk e-mail address

			$SMTPserver: Set the DNS name or the IP address of your SMTP server

			$DN: Set the Distinguished Name of the start of search for AD user accounts. You can update it to be your Domain Distinguished Name if you would like to scan all the users in your Active Directory domain

#>

###############Globals##################            
$global:ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue


########################################            

##############Variables#################            
$verbose = $true
$notificationstartday = 14
$sendermailaddress = "password-expire@questsys.com"
$SMTPserver = "webmail.questsys.com"
$DN = "DC=Questsys,DC=Corp"
########################################            

##############Function##################            
function PreparePasswordPolicyMail ($ComplexityEnabled, $MaxPasswordAge, $MinPasswordAge, $MinPasswordLength, $PasswordHistoryCount)
{
	$verbosemailBody = "Below is a summary of the applied Password Policy settings:`r`n`r`n"
	$verbosemailBody += "Complexity Enabled = " + $ComplexityEnabled + "`r`n`r`n"
	$verbosemailBody += "Maximum Password Age = " + $MaxPasswordAge + "`r`n`r`n"
	$verbosemailBody += "Minimum Password Age = " + $MinPasswordAge + "`r`n`r`n"
	$verbosemailBody += "Minimum Password Length = " + $MinPasswordLength + "`r`n`r`n"
	$verbosemailBody += "Remembered Password History = " + $PasswordHistoryCount + "`r`n`r`n"
	return $verbosemailBody
}

function SendMail ($SMTPserver, $sendermailaddress, $usermailaddress, $mailBody)
{
	$smtpServer = $SMTPserver
	$msg = new-object Net.Mail.MailMessage
	$smtp = new-object Net.Mail.SmtpClient($smtpServer)
	$msg.From = $sendermailaddress
	$msg.To.Add($usermailaddress)
	$msg.Subject = "Your password is about to expire"
	$msg.Body = $mailBody
	$smtp.Send($msg)
}
########################################            

##############Main######################  
Import-Module ActiveDirectory

$domainPolicy = Get-ADDefaultDomainPasswordPolicy
$passwordexpirydefaultdomainpolicy = $domainPolicy.MaxPasswordAge.Days -ne 0

if ($passwordexpirydefaultdomainpolicy)
{
	$defaultdomainpolicyMaxPasswordAge = $domainPolicy.MaxPasswordAge.Days
	if ($verbose)
	{
		$defaultdomainpolicyverbosemailBody = PreparePasswordPolicyMail $PSOpolicy.ComplexityEnabled $PSOpolicy.MaxPasswordAge.Days $PSOpolicy.MinPasswordAge.Days $PSOpolicy.MinPasswordLength $PSOpolicy.PasswordHistoryCount
	}
}

foreach ($user in (Get-ADUser -SearchBase $DN -Filter * -properties mail))
{
	$samaccountname = $user.samaccountname
	$PSO = Get-ADUserResultantPasswordPolicy -Identity $samaccountname
	
	if ($PSO -ne $null)
	{
		$TUser = get-aduser -identity $user -properties *
		$PWNeverExpire = $TUser.PasswordNeverExpires
		if ($PWNeverExpire -ne $true)
		{
			$PSOpolicy = Get-ADUserResultantPasswordPolicy -Identity $samaccountname
			$PSOMaxPasswordAge = $PSOpolicy.MaxPasswordAge.days
			$pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)
			$expirydate = ($pwdlastset).AddDays($PSOMaxPasswordAge)
			$delta = ($expirydate - (Get-Date)).Days
			$comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1)
			if ($comparionresults)
			{
				$mailBody = "Dear " + $user.GivenName + ",`r`n`r`n"
				$mailBody += "Your password will expire after " + $delta + " days. You will need to change your password to keep using it.`r`n`r`n"
				if ($verbose)
				{
					$mailBody += PreparePasswordPolicyMail $PSOpolicy.ComplexityEnabled $PSOpolicy.MaxPasswordAge.Days $PSOpolicy.MinPasswordAge.Days $PSOpolicy.MinPasswordLength $PSOpolicy.PasswordHistoryCount
				}
				$mailBody += "`r`n`r`nYour IT Department"
				$usermailaddress = $user.mail
				SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody
			}
		}
	}
	else
	{
		$TUser = get-aduser -identity $user -properties *
		$PWNeverExpire = $TUser.PasswordNeverExpires
		if ($PWNeverExpire -ne $true)
		{
			if ($passwordexpirydefaultdomainpolicy)
			{
				$pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)
				$expirydate = ($pwdlastset).AddDays($defaultdomainpolicyMaxPasswordAge)
				$delta = ($expirydate - (Get-Date)).Days
				$comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1)
				if ($comparionresults)
				{
					$mailBody = "Dear " + $user.GivenName + ",`r`n`r`n"
					$delta = ($expirydate - (Get-Date)).Days
					$mailBody += "Your password will expire after " + $delta + " days. You will need to change your password to keep using it.`r`n`r`n"
					if ($verbose)
					{
						$mailBody += $defaultdomainpolicyverbosemailBody
					}
					$mailBody += "`r`n`r`nYour IT Department"
					$usermailaddress = $user.mail
					SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody
				}
				
			}
		}
	}
}