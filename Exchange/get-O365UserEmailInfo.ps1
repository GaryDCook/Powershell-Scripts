
<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	10/9/2018 9:42 AM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	get-O365UserEmailInfo.ps1
	===========================================================================
	.DESCRIPTION
		Connects to Azure AD and processes all users creating JSON and CSV files for basic user information and Email Address Information.
#>
[CmdletBinding()]
param
(
	[parameter(Mandatory = $false)]
	[System.Management.Automation.PSCredential]$credential,
	[parameter(Mandatory = $false)]
	[string]$OutputDirectory,
	[parameter(Mandatory = $false)]
	[string]$Filename
)
begin
{
	
}
process
{
	$users = @()
	Write-Host "Checking for AZureAD Module"
	if (Get-Module -ListAvailable -Name "AzureAD")
	{
		Write-Host "Azure AD Module exists proceeding to test if it is loaded"
	}
	else
	{
		Write-Host "Module does not exist script will terminate."
		end
	}
	if (!(Get-Module "AzureAD"))
	{
		Write-host "Module is not loaded, Loading Module"
		Install-Module -Name AzureAD -AllowClobber
	}
	else
	{
		Write-Host "Module is loaded proceeding."
	}
	if ($Filename -eq $null)
	{
		Write-Host "Collection output file information"
		$filename = read-host -Prompt "Enter the base filename for output files"
	}
	if ($OutputDirectory -eq $null)
	{
		Write-Host "Collecting output Directory Information"
		$OutputDirectory = Read-Host -Prompt "Enter the Target Directory for the output files"
	}
	
	$fullpath = "$($OutputDirectory)\$($Filename)"
	
	if ($credential -eq $null)
	{
		Write-Host "Gathering AzureAD Tenant Credential"
		$credential = Get-Credential -Message "Please Ente the credential for the Azure AD tenant you with to process"
	}
	
		
	Write-Host "Connecting to Azure AD"
	connect-azuread -credential $credential
	
	Write-Host "Connecting to Exchange Online"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
	Import-PSSession $Session -DisableNameChecking -AllowClobber
	
	Write-Host "Getting all Azure AD Users"
	$azusers = get-azureaduser -all $true 
	$count = ($azusers | measure).count
	$i = 0
	foreach ($u in $azusers)
	{
		Write-Progress -Activity "Processing Users" -Status "Processing User $($u.givenname) $($u.surname)" -PercentComplete ($i/$count * 100)
		$obj = New-Object System.Management.Automation.PSObject
		$obj | Add-Member -MemberType NoteProperty -Name Enabled -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name DirSyncEnabled -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name Givenname -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name Surname -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name Displayname -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name Mailbox -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name MailNickName -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name Userprincipalname -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name Primarysmtpaddress -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name Emailaddresses -Value $null
		
		$obj.Givenname = $u.givenname
		$obj.Surname = $u.surname
		$obj.Enabled = $u.AccountEnabled
		$obj.DirSyncEnabled = $u.DirSyncEnabled
		$obj.Displayname = $u.DisplayName
		$obj.Userprincipalname = $u.userprincipalname
		$Mb = get-mailbox -identity $u.userprincipalname
		if (($Mb | measure).count -lt 1)
		{
			$obj.Mailbox = "No"
		}
		else
		{
			$obj.Mailbox = "Yes"
			$obj.Primarysmtpaddress = (get-mailbox -identity $u.userprincipalname).primarysmtpaddress
			$obj.Emailaddresses = (get-mailbox -identity $u.userprincipalname).emailaddresses
			$obj.MailNickName = $u.MailNickName
			
		}
		$i += 1
		$users += $obj
	}
	$ujson = $users | ConvertTo-Json -Depth 2
	$ujson | Out-File -FilePath "$($fullpath).txt" -Force
	$users | Export-Csv -Path "$($fullpath).csv" -Force -NoTypeInformation
}
end
{
	Remove-PSSession $Session
	disconnect-azuread
	
}
