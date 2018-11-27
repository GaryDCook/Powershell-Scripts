<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	10/9/2018 10:01 AM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

$path = Read-Host -Prompt "Enter fill path to json user file"
$file = Get-Content -Path $path
$users = $file | ConvertFrom-Json
foreach ($user in $users)
{
	Write-Host "Processing user $($user.givenname) $($user.surname)"
	Write-Host "UPN: $($user.userprincipalname)"
	Write-Host "Primary Email: $($user.primarysmtpaddress)"
	foreach ($email in $user.emailaddresses)
	{
		if ($email -like '*$thecookshouse.com*')
		{
		Write-Host "Processing email: $($email)"	
		}
	}
}
