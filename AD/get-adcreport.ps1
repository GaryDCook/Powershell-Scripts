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
		report of the results of the scan in a selected format. (Currently only outputs CSV)
		The results will include:
			Pingable
			ADCompName
			ADDomain
			ADCompDN
			ADDNSHostName
			ADOSName
			ADOSVer
			ADEnabled
			ADLastLogon
			ADPasswordExpired
			ADPasswordLastSet
			ADIPv4Address
			ADIPv6Address
			WMICompName
			WMIDomain
			WMIOSName
			WMIOSVer
			WMIManufacturer
			WMIModel
			WMICPUName
			WMICPUDescription
			WMICPUCurrentClock
			WMICPUMaxClock
			WMICPUAddrWidth
			WMICPUCount
			WMICPUCores
			WMICPUNumLogicalProc
			WMIMemory
			LastPatched
	
		Requirements:
			You must have the Active Directory RSAT powershell admin tools installed on the machine running the script.  It 
			must have ICMP and WMI connectivity to all machines to complete the inventory scan. 

	.PARAMETER
		The following Parameters are available:
		
		-Domain
			The FQDN of the Domain to scan

		-Credential
			The Domain Credntials to use to Query WMI in the online computers
			Must be passed in the form of a System.Management.Automation.PSCredential obtained with the Get-Credential command 
		
		-Type
			The Output type of the resulting file
				CSV (Currently the default)
				XML
				TEXT
				HTML
				
		-SendToFile
			True / False Flag to determine if you would like the output sent to file (Defaults to true)

		-FileName
			The name of the resulting file path included if not supplied will be prompted for it if SaveToFile is True

	
	.EXAMPLE
		To run this script you can use the following examples.

		To execute against a single domain with Username and Password Entered by user outputting simple text results to the screen

			Get-ADComputerInventory -Domain "MyDomain" -Credential (get-credential)
		
		To execute against a single domain with Username and Password passed in a object outputting XML results to a file

			Get-ADComputerInventory -Domain "MyDomain" -Credential $creds - Type XML -SendToFile -FileName "C:\output\results.xml"


	

#>
[cmdletbinding()]
Param (
	[Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName = $True)]
	[string]$Domain,
	[Parameter(Mandatory = $false)]
	[System.Management.Automation.PSCredential]$Credential,
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
	[string]$Type = "CSV",
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
	[switch]$SendToFile = $True,
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
	[string]$FileName
)
#Bring in the AD Powershell Module
import-module activedirectory

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

#parameter processing
#Domain Processing and validation if domain was not supplied end the script
if ($Domain -eq $null)
{
	Write-Color -Text "Unable to proceed without providing a ", "Domain", " via the Command Line." -Color White, Yellow, White
	End
	
}
Write-Color -Text "The following domain will be used ", "$Domain" -Color White, Yellow

#Credential Processing
if ($cred -ne $null)
{
	Write-Color -Text "No Domain Credential Was Provided.", "  Please Enter you Crednetial." -Color white, Green
	$cred = Get-Credential
}
else
{
	$cred = $Credential
	Write-Color -Text "Using ", "$Cred.UserName.ToString", " to access WMI on available Computers" -Color White, Yellow, White
	
}

if ($FileName -eq $null)
{
	Write-Host "You must supply and complete path to save the file" -ForegroundColor White -BackgroundColor Red
	$FileName = Read-Host "Enter the complete path and filename:"
}
else
{
	Write-Color -Text "Using the supplied full path of ", "$FileName" -Color White, Yellow
	
}

#WMI Inventory Function
function Get-WmiInventory
{
	param ($wmiclass = "Win32_OperatingSystem",$Local = $false,$computer)
	PROCESS
	{
		$ErrorActionPreference = "SilentlyContinue"
		
		trap
		{
			$ErrorPath = Split-Path $FileName
			$ErrorFile = $ErrorPath+"\wmicomperror.txt"
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

#Getting all Domain Computers
Write-Color -Text "Gentting Domain Computers for ", "$Domain" -Color White, Green
$computers = get-adcomputer -filter * -server $Domain -properties *
$MaxComp = $computers|measure
Write-Color -Text "Retrieved ", "${MaxComp.count}"," computer records from the domain ","$domain" -Color White,Yellow,White,Green

#initialize counter for progress bars
$counter = 0

#Create object array to hold results
$resObj = @()

#function to process computers
function process-computer ($computer)
{
	#Create new object to hold computer information
	$CompObject = New-Object psobject
	$CompObject | Add-Member -MemberType NoteProperty -Name Pingable -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADCompName -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADDomain -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADCompDN -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADDNSHostName -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADOSName -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADOSVer -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADEnabled -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADLastLogon -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADPasswordExpired -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADPasswordLastSet -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADIPv4Address -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name ADIPv6Address -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICompName -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMIDomain -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMIOSName -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMIOSVer -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMIManufacturer -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMIModel -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUName -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUDescription -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUCurrentClock -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUMaxClock -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUAddrWidth -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUCount -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUCores -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMICPUNumLogicalProc -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name WMIMemory -Value $null
	$CompObject | Add-Member -MemberType NoteProperty -Name LastPatched -Value $null
	
	
	#Begin processing computer information using AD Computer Object
	write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of ${maxcomp.count} Name:$Computer.Name" -Status "Currently Getting Ad Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
	$CompObject.ADCompName = $computer.Name
	$CompObject.ADCompDN = $computer.DistinguishedName
	$CompObject.ADDNSHostName = $computer.DNSHostName
	$CompObject.ADOSName = $computer.OperatingSystem
	$CompObject.ADOSVer = $computer.OperatingSystemVersion
	$CompObject.ADLastLogon = $computer.LastLogonDate
	$CompObject.ADEnabled = $computer.Enabled
	$CompObject.ADPasswordExpired = $computer.PasswordExpired
	$CompObject.ADPasswordLastSet = $computer.PasswordLastSet
	$CompObject.ADDomain = $Domain
	$CompObject.ADIPv4Address = $computer.IPv4Address
	$CompObject.ADIPv6Address = $computer.IPv6Address
	#test computer via 1 Ping
	Write-Host "Testing Computer $computer.DNSHostName"
	$test = test-connection -ComputerName $computer.DNSHostName -count 1 -Quiet
	#if computer responds process WMI
	if ($test)
	{
		#set pingable to true
		$CompObject.Pingable = $True
		#if computer to process is the local computer(localhost) then process WMI differently using current logon (impersonation)
		#if ($computer.CN -eq $env:COMPUTERNAME)
		#{
		write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of ${maxcomp.count} Name:$Computer.Name" -Status "Currently Getting WMI Hardware Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		#$computerResults = Get-WMIObject -ComputerName $computer.ADDNSHostName -class Win32_ComputerSystem
		$computerResults = Get-WmiInventory -wmiclass win32_computersystem -Local $True -computer $computer.DNSHostname
		write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of ${maxcomp.count} Name:$Computer.Name" -Status "Currently Getting WMI Operating System Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		#$OSResults = Get-WMIObject -ComputerName $computer.ADDNSHostName -class Win32_OperatingSystem
		$OSResults = Get-WmiInventory -wmiclass win32_operatingsystem -Local $True -computer $computer.DNSHostname
		write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of ${maxcomp.count} Name:$Computer.Name" -Status "Currently Getting WMI CPU Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		#$property = "Name", "Description", "maxclockspeed", "addressWidth", "numberOfCores", "NumberOfLogicalProcessors"
		#$wmicpuresults = Get-WmiObject -class win32_processor -ComputerName $computer.DNSHostName -Property $property | Select-Object -Property $property
		$wmicpuresults = Get-WmiInventory -wmiclass win32_processor -Local $True -computer $computer.DNSHostname
		write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of ${maxcomp.count} Name:$Computer.Name" -Status "Currently Getting WMI Memory Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		$CompObject.WMIMemory = Get-WmiObject CIM_PhysicalMemory -ComputerName $computer.DNSHostName | Measure-Object -Property capacity -sum | % { [math]::round(($_.sum / 1GB), 2) }
		write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of ${maxcomp.count} Name:$Computer.Name" -Status "Currently Getting Patch Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		$autoUpdate = Get-HotFix -ComputerName $computer.DNSHostName | Measure-Object InstalledOn -Maximum
		#}
		#else
		#{
		#	write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of $maxcomp.count Name:$Computer.Name" -Status "Currently Getting WMI Hardware Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		#	#$computerResults = Get-WMIObject -ComputerName $computer.DNSHostName -class Win32_ComputerSystem -Credential $cred
		#	$computerResults = Get-WmiInventory -wmiclass win32_computersystem -Local $True -computer $computer.ADDNSHostname -credential $cred
		#	
		#	write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of $maxcomp.count Name:$Computer.Name" -Status "Currently Getting WMI CPU Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		#	$property = "Name", "Description", "maxclockspeed", "addressWidth", "numberOfCores", "NumberOfLogicalProcessors"
		#	$wmicpuresults = Get-WmiObject -class win32_processor -ComputerName $computer.DNSHostName -Property $property -Credential $cred | Select-Object -Property $property
		#	write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of $maxcomp.count Name:$Computer.Name" -Status "Currently Getting WMI Memory Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		#	$compobj.Memory = Get-WmiObject CIM_PhysicalMemory -ComputerName $computer.dnshostname -Credential $cred | Measure-Object -Property capacity -sum | % { [math]::round(($_.sum / 1GB), 2) }
		#	write-progress -Activity "Processing Compters" -CurrentOperation "Processing Computer $counter of $maxcomp.count Name:$Computer.Name" -Status "Currently Getting Patch Information" -PercentComplete ((($counter + 1) / $maxcomp.count) * 100)
		#	$autoUpdate = Get-HotFix -ComputerName $computer.dnshostname -Credential $cred | Measure-Object InstalledOn -Maximum
		#}
		
		#Process WMI Information
		$CompObject.WMIModel = $computerResults.Model
		$CompObject.WMIManufacturer = $computerResults.Manufacturer
		$CompObject.WMICompName = $computerResults.DNSHostName
		$CompObject.WMIDomain = $computerResults.Domain
		$CompObject.WMIOSName = $OSResults.caption
		$CompObject.WMIOSVer = $OSResults.Version
		$CompObject.LastPatched = $AutoUpdate.Maximum
		
		
		#Processor Processing 
		if (($wmicpuresults | measure).count -gt 1)
		{
			$CompObject.WMICPUName = $wmicpuResults[0].Name
			$CompObject.WMICPUDescription = $wmicpuResults[0].Description
			$CompObject.WMICPUMaxClock = $wmicpuResults[0].maxclockspeed
			$CompObject.WMICPUCurrentClock = $wmicpuResults[0].CurrentClockspeed
			$CompObject.WMICPUAddrWidth = $wmicpuResults[0].addresswidth
			$CompObject.WMICPUCores = ($wmicpuResults | measure -property numberofcores -sum).sum
			$CompObject.WMICPUNumLogicalProc = ($wmicpuResults | measure -property numberoflogicalprocessors -sum).sum
			$CompObject.WMICPUCount = ($wmicpuresults | measure).count
		}
		else
		{
			$CompObject.WMICPUName = $wmicpuResults.Name
			$CompObject.WMICPUDescription = $wmicpuResults.Description
			$CompObject.WMICPUMaxClock = $wmicpuResults.maxclockspeed
			$CompObject.WMICPUCurrentClock = $wmicpuResults.Currentclockspeed
			$CompObject.WMICPUAddrWidth = $wmicpuResults.addresswidth
			$CompObject.WMICPUCores = $wmicpuResults.numberofcores
			$CompObject.WMICPUNumLogicalProc = $wmicpuResults.numberoflogicalprocessors
			$CompObject.WMICPUCount = ($wmicpuresults | measure).count
		}
		
	}
	else
	{
		#set pingable to false
		$CompObject.Pingable = $false
	}
	write $CompObject
}

#process all computer AD objects
foreach ($comp in $computers)
{
	$tempObj = process-computer -computer $comp
	$counter++
	$resobj += $tempObj
}

#process the output based on how the users selected
if ($SendToFile -eq $True)
{
	
	if ($Type -eq "CSV")
	{
		Write-Color -Text "CSV Output Select saveing File." -Color Green
		$resobj | export-csv -Path $FileName -NoTypeInformation
	}
	elseif ($Type -eq "XML")
	{
		Write-Color -Text "XML Output Select saveing File." -Color Green
		$resObj | Export-Clixml -Path $FileName 
	}
	elseif ($Type -eq "HTML")
	{
		Write-Color -Text "HTML Output Select saveing File." -Color Green
		$resObj | ConvertTo-Html -Title "Computer Report for $Domain" -Body "Report Created on @(get-date)" -PreContent "<p>Generated by Quest</p>" -PostContent "For More Information Please Contact Quest" |Out-File -FilePath $FileName 
	}
	elseif ($Type -eq "TEXT")
	{
		Write-Color -Text "TEXT Output Select saveing File." -Color Green
		$resObj | Out-File -FilePath $FileName
	}
	else
	{
		write-host "No output Type was selected the default CSV will be used." -foregroundColor White -BackgroundColor Red
		$resobj | export-csv -Path $FileName -NoTypeInformation
	}
}
else
{
	write-host "You selected not to sent the data to a file output to the screen will be used." -foregroundColor White -BackgroundColor Red
	$resObj | Out-GridView

	
}

