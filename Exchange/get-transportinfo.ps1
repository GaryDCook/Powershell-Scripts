<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.115
	 Created on:   	12/6/2016 10:41 AM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	get-transportinfo.ps1
	===========================================================================
	.DESCRIPTION
		Retrieves the transport role information for all servers in Exchange. Must be run from exchange management Shell.
#>

Write-Host "Getting transport server information...."
$servers = get-transportserver
foreach ($server in $servers)
{
	Write-Host "Processing Transport Server "$server.name
	
}