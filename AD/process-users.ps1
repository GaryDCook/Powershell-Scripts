<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.155
	 Created on:   	10/15/2018 11:10 AM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
[CmdletBinding()]
param
(
	[parameter(Mandatory = $true)]
	[string]$MappingFile,
	[parameter(Mandatory = $false)]
	[System.Management.Automation.PSCredential]$Scredential,
	[parameter(Mandatory = $false)]
	[System.Management.Automation.PSCredential]$Dcredential,
	[parameter(Mandatory = $false)]
	[string]$OutputDirectory,
	[parameter(Mandatory = $false)]
	[string]$FileName,
	[parameter(Mandatory = $true)]
	[string]$DC
	
)

BEGIN 
{
	
}
PROCESS
{
	<# 
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
	#>
	Write-Host "Checking for AD Module"
	if (Get-Module -ListAvailable -Name "ActiveDirectory")
	{
		Write-Host "AD Module exists proceeding to test if it is loaded"
	}
	else
	{
		Write-Host "Module does not exist script will terminate."
		end
	}
	if (!(Get-Module "ActiveDirectory"))
	{
		Write-host "Module is not loaded, Loading Module"
		Install-Module -Name ActiveDirectory -AllowClobber
	}
	else
	{
		Write-Host "Module is loaded proceeding."
	}
	
	if ($Filename -eq $null)
	{
		Write-Host "Collection Logging file information"
		$filename = read-host -Prompt "Enter the base filename for Log files"
	}
	if ($OutputDirectory -eq $null)
	{
		Write-Host "Collecting output Directory Information"
		$OutputDirectory = Read-Host -Prompt "Enter the Target Directory for the output files"
	}
	
	$fullpath = "$($OutputDirectory)\$($Filename)"
	
	<#
	if ($Scredential -eq $null)
	{
		Write-Host "Gathering Source AzureAD Tenant Credential"
		$credential = Get-Credential -Message "Please Enter the credential for the Source Azure AD tenant you wish to process"
		
	}
	#>
	if ($Dcredential -eq $null)
	{
		Write-Host "Gathering Target AD Credential"
		$credential = Get-Credential -Message "Please Enter the credential for the Target AD you wish to process"
		
	}
	
	Write-Host "Did you run the hybrid configuration wizard again after adding the domain in Offcie 365?"
	Pause
	
	Write-Host "Adding Countsy.com upn suffix to AD forest"
	Get-ADForest -Credential $Dcredential -Server $DC | Set-ADForest -UPNSuffixes @{ add = "Countsy.com" } -Credential $Dcredential -Server $DC
	
	
	<#
	Write-Host "Connecting to Source Azure AD"
	connect-azuread -credential $Scredential
	Write-Host "Connecting to Exchange Online"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $SCredential -Authentication Basic -AllowRedirection
	Import-PSSession $Session -DisableNameChecking -AllowClobber
	#$users = get-azureaduser -all $true |  select *
	$mbxs = get-mailbox |select *
	remove-PSSession $Session
	disconnect-azuread
	#>
	
	Write-Host "Reading Mapping File"
	$MFile = Import-Csv -Path $MappingFile
	
	Write-Host "Reading countsy address file"
	$CFile = Get-Content -Path $addrfile | ConvertFrom-Json
	
	
	foreach ($m in $MFile)
	{
		if ($m.userprincipalname -like '*@countsy.com')
		{
			$mb = $CFile | ?{ $_.userprincipalname -eq $m.userprincipalname }
			
			$ADUser = Get-ADUser -Identity $m.Targetuserprincipalname -Properties * -Credential $Dcredential -server $DC
			if (($ADUser | measure).count -eq 0)
			{
				continue
			}
			Write-Host "Setting no primary SMTP adress for user $($ADUser.userprincipalname)"
			$count = 0
			foreach ($adr in $ADUser.proxyaddresses)
			{
				if ($adr -clike 'SMTP')
				{
					$ADUser.proxyaddresses[$count].tolower()
				}
				
				$count += 1
				
			}
			
			
			foreach ($addr in $mb.emailaddresses)
			{
				
				if ($addr -like '*@countsy.com')
				{
					$ADUser.proxyaddresses.add($addr)
					
					
				}
				
			}
			Write-Host "Setting new proxy addresses and Primary Address for user $($ADUser.userprincipalname)"
			#Set-ADUser -Identity $m.targetuserprincipalname -Add @{ Proxyaddresses = $ADUser.proxyaddresses } -Credential $Dcredential -Server $DC
			Set-ADUser -Instance $ADUser -Credential $Dcredential -Server $DC
			
			
			Write-Host "Setting New UPN for user $($ADUser.userprincipalname)"
			set-aduser -Identity $m.targetuserprincipalname -UserPrincipalName $m.userprincipalname -Credential $Dcredential -Server $DC
			
		
		
		
			
			
			
			
			
		}
	}
	
	
}
END
{
	
}
