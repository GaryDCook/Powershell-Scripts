<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.115
	 Created on:   	9/12/2017 2:56 PM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

#WMI Inventory Function
function Get-WmiInventory
{
	param ($wmiclass = "Win32_OperatingSystem",
		$Local = $false,
		$computer)
	PROCESS
	{
		$ErrorActionPreference = "SilentlyContinue"
		
		trap
		{
			$ErrorPath = Split-Path $FileName
			$ErrorFile = $ErrorPath + "\wmicomperror.txt"
			$computer | out-file $ErrorFile -append
			set-variable skip ($true) -scope 1
			continue
		}
		$skip = $false
		if ($Local -eq $True)
		{
			$wmi = Get-WmiObject -class $wmiclass -computer $computer -ea stop | Select-Object * -excludeproperty "_*"
		}
		else
		{
			$wmi = Get-WmiObject -class $wmiclass -computer $computer -ea stop -Credential $cred | Select-Object * -excludeproperty "_*"
		}
		if (-not $skip)
		{
			foreach ($obj in $wmi)
			{
				$obj | Add-Member NoteProperty ComputerName $computer
				write $obj
			}
		}
	}
}

Import-Module ActiveDirectory

$results = @()

$adcomputers = Get-ADComputer -filter *

foreach ($comp in $adcomputers)
{
	
	#Create new object to hold computer information
	$CompObject = New-Object psobject
	$CompObject | Add-Member -MemberType NoteProperty -Name SystemName -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name MachineType -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name OS -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name OSVersion -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name Memory -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name CPUCount -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name CPULogical -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name Model -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ManagementIP -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name IMCIP -Value $null
	
	if ($comp.cn -eq $env:computername)
	{
		$win32os = Get-WmiInventory -wmiclass "Win32_OperatingSystem" -computer $comp.cn -Local $true
		$win32cs = Get-WmiInventory -wmiclass "Win32_ComputerSystem" -computer $comp.cn -Local $true
	}
	else
	{
		$win32os = Get-WmiInventory -wmiclass "Win32_OperatingSystem" -computer $comp.cn
		$win32cs = Get-WmiInventory -wmiclass "Win32_ComputerSystem" -computer $comp.cn
	}
	$CompObject.SystemName = $comp.cn
	if ($win32cs.model -eq "Virtual Machine")
	{
		$CompObject.MachineType = "Virtual"	
	}
	else
	{
		$CompObject.MachineType = "Physical"
	}
	
}