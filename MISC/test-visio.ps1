<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.155
	 Created on:   	10/29/2018 10:43 AM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

#computer Inventory

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


$phy = @()
$vir = @()

Import-Module activedirectory

#gather all current environmental Machines

$DComp = Get-ADComputer -Filter * -Properties *

foreach ($c in $DComp)
{
	$obj = New-Object System.Management.Automation.PSObject
	$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name ProcessorCount -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name CoreCount -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name CPUInfo -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name VirtualHost -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name VMCount -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name ClusterMember -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name ClusterName -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name Virtual -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name HostCluster -Value $null
	
	#check if machine is virtual
	$v = get
}


