<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	9/4/2018 3:06 PM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	Create-UserReport.ps1
	===========================================================================
	.DESCRIPTION
		Creates an AD USer Report in CSV for the Current Domain referenced by the Supplied DC.
	.PARAMETER
		Directory
			The directory to save the generated csv files.
		DC
			The Domain Controller to use to generate the user information
	.NOTES
		All Domain Controllers need to be online and able to answer the get-aduser command from the machine running the script.
		
#>
[CmdletBinding()]
param
	(
	[parameter(Mandatory = $true)]
	[string]$Directory,
	[parameter(Mandatory = $true)]
	[string]$DC
	
	)

BEGIN
{
	$ScriptName = $MyInvocation.MyCommand.ToString()
	$LogName = "Application"
	$ScriptPath = $MyInvocation.MyCommand.Path
	$Username = $env:USERDOMAIN + "\" + $env:USERNAME
	
	New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue
	
	$Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
	Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
	
	#Function to Display multiple colors in One output line for Write-Host
	function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int]$LinesBefore = 0, [int]$LinesAfter = 0)
	{
		$DefaultColor = $Color[0]
		if ($LinesBefore -ne 0) { for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
		if ($StartTab -ne 0) { for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } } # Add TABS before text
		if ($Color.Count -ge $Text.Count)
		{
			for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
		}
		else
		{
			for ($i = 0; $i -lt $Color.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
			for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
		}
		Write-Host
		if ($LinesAfter -ne 0) { for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } } # Add empty line after
	}
	
}
PROCESS
{
	#clear the screen
	cls
	#test to see if ad powershell module is available
	if (!(get-module ActiveDirectory))
	{
		Write-Color -Text "The Active Directory Module is not loaded" -Color Red
		Write-Color -Text "Checking the module availability" -Color Yellow
		If (!(Get-Module -ListAvailable activedirectory))
		{
			Write-Color -Text "The Active Directory Module is not available on this system!!" -Color Red
			Write-Color -Text "Unable to proceed!!!" - Red
			exit
		}
		else
		{
			Write-Color -Text "Attempting to load the Active Directory Module" -Color Green
			Import-Module ActiveDirectory -ErrorAction SilentlyContinue
			if (!(Get-Module activedirectory))
			{
				Write-Color -Text "Unable to load module!!!" -Color Red
				Write-Color -Text "Unable to proceed!!!" - Red
				exit
			}
			else
			{
				Write-Color -Text "Module Loaded proceeding...." -Color Green
			}
		}
		
	}
	else
	{
		Write-Color -Text "Active Directory Module Loaded proceeding...." -Color Green
	}
	Write-Color -Text "Getting all users in Domain" -Color Green
	$users = Get-ADUser -Filter * -Properties * -Server $DC
	Write-Color -Text "Creating CSV output" -Color Green
	$Ousers = @()
	foreach ($user in $users)
	{
		Write-Color -Text "Processing user $($user.samaccountname)" -Color Green
		$LastL = $user.lastlogondate
		Write-Color -Text "Last Logon $($LastL)" -Color Yellow
		$Ousers += $user
	}
	$Ousers | Export-Csv -Path "$($directory)\ADUserReport.csv" -NoTypeInformation -Force
	
	
}
END
{
	$Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
	Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
}

