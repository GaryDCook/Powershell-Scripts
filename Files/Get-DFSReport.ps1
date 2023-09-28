
<#
	# All date time formates in the notes should conform to the following syntax:     mm/dd/yyyy hh:mm am/pm
	.NOTES
	===========================================================================
	 Created on:   	09/18/2022 11:49 AM        
	 Last Modified: 09/20/2022 02:04 PM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	Get-DFSReport.ps1
	===========================================================================
	.DESCRIPTION
		Powershell script to get the current AD DFS Structure and export XML Data for reporting.
	.PARAMETER
		Credential
			Username and password in the form of a PowerShell Crednetial object. If not supplied the current user will be tried.
		Domain
			The name of the domain from which to get DFS information.
		Output
			The full path to the directory to store the output of the script.
	.EXAMPLE
		Get-DFSReport.ps1 -Credential (get-credential) -Domain "MyDom.com" -Output "C:\Temp"
			Getthe DFS configuration from the domain "MyDom.com" using the username and password supplied via interactive process and
			Stores the output in the "c:\Temp" directory.
#>

[CmdletBinding()]

param
(
	[parameter(Mandatory = $true)]
	[parameterType]
	$parameterName
)

BEGIN 
{
	BeginBlock
}
PROCESS
{
     ProcessBlock
}
END
{
	EndBlock
}

