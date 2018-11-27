<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.115
	 Created on:   	4/28/2017 9:50 AM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	Get-ADComputerInventory.ps1
	===========================================================================
	.DESCRIPTION
		This script will retrieve a list of domain computer accounts, verify online status of the computer and output a 
		report of the results of the scan in a selected format.
		The results will include:
			Computer name
			Operating System Name
			OS Version
			Computer Model
			Computer Manufacturer
			CPU Information
			Memory
			Disk Information
			Network Information
			Last Patched Date
			Last Logon Date
			Domain
	
		Requirements:
			You must have the Active Directory RSAT powershell admin tools installed on the machine running the script.  It 
			must have ICMP and WMI connectivity to all machines to complete the inventory scan. 

	.PARAMETER

	.OUTPUTS

	.EXAMPLE
		To run this script you can use the following examples.

		To execute against a single domain with Username and Password Entered by user outputting simple text results to the screen

			Get-ADComputerInventory -Domain "MyDomain" -Credential (get-credential)
		
		To execute against a single domain with Username and Password passed in a object outputting XML results to a file

			Get-ADComputerInventory -Domain "MyDomain" -Credential $creds - Type XML -SendToFile -FileName "C:\output\results.xml"



#>
[cmdletbinding()]
Param (
	[Parameter(Mandatory = $True, Position = 1,ValueFromPipelineByPropertyName = $True)]
	[string]$Domain,
	[Parameter(Mandatory = $false)]
	[System.Management.Automation.PSCredential]$Credential,
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
	[string]$Type = "Text",
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
	[switch]$SendToFile,
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
	[string]$FileName
)
#global objects
#$ADComputerList
#$ActiveComputerList
Import-Module ActiveDirectory

#Create Custom Object to store Network data
$NetObject = New-Object psobject
$NetObject | Add-Member -MemberType NoteProperty -Name DNSHostName -Value $null
$NetObject | Add-Member -MemberType NoteProperty -Name Adapter -Value $null
$NetObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value (New-object System.Collections.Arraylist)
$NetObject | Add-Member -MemberType NoteProperty -Name SubnetMask -Value (New-object System.Collections.Arraylist)
$NetObject | Add-Member -MemberType NoteProperty -Name DefaultGateway -Value (New-object System.Collections.Arraylist)
$NetObject | Add-Member -MemberType NoteProperty -Name DNSServers -Value (New-object System.Collections.Arraylist)
$NetObject | Add-Member -MemberType NoteProperty -Name DNSDomain -Value $null
$NetObject | Add-Member -MemberType NoteProperty -Name MACAddress -Value $null
#Create Custom Object to store Disk data
$DiskObject = new-object psobject
$DiskObject | Add-Member -MemberType NoteProperty -Name DeviceID -Value $null
$DiskObject | Add-Member -MemberType NoteProperty -Name FreeSpace -Value $null
$DiskObject | Add-Member -MemberType NoteProperty -Name Size -Value $null
$DiskObject | Add-Member -MemberType NoteProperty -Name VolumeName -Value $null
# Object to hold computer information for results
$CompObject = New-Object psobject
$CompObject | Add-Member -MemberType NoteProperty -Name Name -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name OSName -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name OSVer -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name Model -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name CPU -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name Memory -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name Network -Value [array]$NetObject
$CompObject | Add-Member -MemberType NoteProperty -Name Alive -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name LastLogonDate -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name LastPatchDate -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name DNSServer -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name DNSDomain -Value $null
$CompObject | Add-Member -MemberType NoteProperty -Name Disk -Value [array]$DiskObject


#create array of objects to store all retrived computer information
[array]$ComputerResults = $CompObject

function Get-ADComputers ($Domain, $Creds)
{
	Write-Host "Fetching Computers from the Domain "$Domain
	$ADCompList = Get-ADComputer -filter * -Credential $Creds -server $Domain
	Write-Host ($ADCompList|measure).count" Computers Found"
	return $ADCompList
}

function Get-ComputerInfo ($ComputerName, $Creds)
{
	#check computer to see if it is online
	$OnlineResult = Test-Connection -ComputerName $ComputerName -Quiet
	
	if ($OnlineResult)  #if the computer is online get results via WMI
	{
		Write-Progress -Activity "Processing Computer $ComputerName" -CurrentOperation "Testing Connectivity" -Status "Perfoming"
		
	}
	IfElse     #if the computer is not online provide AD/DNS information instead
	{
		
	}
}

#begin to build report
#get current date for Report Title
$today = Get-Date
$cutoffdate = $today.AddDays(-15)

Get-ADComputer -Properties * -Filter { LastLogonDate -gt $cutoffdate } | Select -Expand DNSHostName | out-file C:\All-Computers.txt
$ComputerList = get-content "C:\All-Computers.txt"
$Amount = $ComputerList.count
$a = 0

foreach ($hosts in $ComputerList)
{
	$Ping = test-connection -ComputerName $hosts -count 1
	if ($Ping -eq "True")
	{
		echo $hosts >> "C:\Online-Computers.txt"
		$a++
		Write-Progress -Activity "Working..." -CurrentOperation "$a complete of $Amount" -Status "Please wait testing connections"
		
		
	}
	
}

$allhost = get-content "C:\Online-Computers.txt"
"Hostname,MAC Address,Serial Number" >> C:\Inventory.csv
$a = 0
$OnlineAmount = $allhost.count

foreach ($computer in $allhost)
{
	
	$Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $computer | ? { $_.IPEnabled }
	foreach ($Network in $Networks)
	{
		$IsDHCPEnabled = $false
		If ($Network.DHCPEnabled)
		{
			$IsDHCPEnabled = $true
		}
		$mac = $Network.MACAddress
	}
	
	$enclosure = Get-WmiObject -Class win32_systemenclosure -ComputerName $computer
	$serial = $enclosure.SerialNumber
	$output = $computer + "," + $mac + "," + $serial
	$output >> C:\Inventory.csv
	$a++
	
	
	Write-Progress -Activity "Working..." -CurrentOperation "$a complete of $OnlineAmount" -Status "Please wait testing connections"
}


Del "C:\Online-Computers.txt"
Del "C:\All-Computers.txt"