<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.153
	 Created on:   	7/18/2018 10:55 AM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

param
(
	[parameter(Mandatory = $false)]
	[string]
	$domain,
	[parameter(Mandatory = $false)]
	[credential]$credential
	
)
BEGIN 
{
	
}
PROCESS
{
	if ($credential -eq $null)
	{
		read-Host "Enter Credential"
	}
}
END
{
	EndBlock
}

