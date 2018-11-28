<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.155
	 Created on:   	10/17/2018 12:53 PM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     test-adactions.ps1	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Import-Module ActiveDirectory
$user = read-host "Enter User UPN Name"
$newupn = Read-Host "Enter New UPN Name for User"
$emailadd = Read-Host "Enter New Email Address to add to proxy addresses(Use SMTP: to make new primarySMTP address)"
$cred = Get-Credential -Message "Enter AD Credential"
$DC = Read-Host "Enter the name of the domain controller"


Write-Host "Reading User Properties"
$aduser = Get-ADUser -Identity $user -Properties *

Write-Host "removing the primary SMTP address from user"
$aduser.proxyaddresses = $aduser.proxyaddresses.tolower()

Write-Host "Adding Email address to proxy addresses"
$aduser.proxyaddresses.add($emailadd)

Write-Host "Writing new proxy and primary smtp addresses to AD"
Set-ADUser -Identity $aduser.userprincipalname -Add @{ Proxyaddresses = $aduser.proxyaddresses } -Credential $cred -Server $DC

Write-Host "Setting new UPN"
set-aduser -Identity $aduser.userprincipalname -UserPrincipalName $newupn -Credential $cred -Server $DC



