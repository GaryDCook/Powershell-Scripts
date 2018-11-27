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

#function to get wmi information
param
(
	[parameter(Mandatory = $false)]
	[int]
	$Limit
)
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
			$ErrorPath = Split-Path $PSScriptRoot
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


$computers = @()


Import-Module activedirectory

#gather all current environmental Machines
if ($limit -ne $null)
{
	$DComp = Get-ADComputer -Filter * -Properties * | ?{ $_.operatingsystem -like '*server*' -and $_.description -notlike 'failover*' } | select -First $limit
}
else
{
	$DComp = Get-ADComputer -Filter * -Properties * | ?{ $_.operatingsystem -like '*server*' -and $_.description -notlike 'failover*' }
}

$count = ($DComp | measure).count
$i=0
foreach ($c in $DComp)
{
	Write-Progress -Activity "Processing computer in domain" -Status "Processing Computer $($c.dnshostname)" -PercentComplete ($i/$count *100)
	
	$obj = New-Object System.Management.Automation.PSObject
	$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name OS -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name OSVer -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name Model -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name ProcessorCount -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name CoreCount -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name CPUInfo -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name VirtualHost -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name VMCount -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name ClusterMember -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name ClusterName -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name Virtual -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name HostCluster -Value $null
	$obj | Add-Member -MemberType NoteProperty -Name Online -Value $null
	
	#check to see if machine is online
	Write-Host "Checking to see if machine is online"
	$isonline = Test-Connection -ComputerName $c.dnshostname -Quiet -Count 1
	if ($isonline)
	{
		try
		{
			Write-Color -Text "$($c.dnshostname)", " is online" -Color Green, White
			$obj.online = $true
			#check if machine is virtual
			$comp = Get-WmiInventory -wmiclass win32_computersystem -Local $false -computer $c.dnshostname
			$os = Get-WmiInventory -wmiclass win32_operatingsystem -Local $false -computer $c.dnshostname
			$obj.ComputerName = $comp.ComputerName
			$obj.os = $os.caption
			$obj.OSVer = $os.version
			#Write-Host $comp.computername
			#check to see if Hyper-v is enalbed on machine
			$hyperv = Get-WmiInventory -wmiclass Win32_ServerFeature -Local $false -computer $c.dnshostname
			$HV = $false
			$hyperv | %{ if ($_.name -eq 'Hyper-V') { $HV = $true }	else { $HV = $false } }
			if ($HV)
			{
				$obj.VirtualHost = $true
				$obj.vmcount = Invoke-Command -computername $c.dnshostname -scriptblock { (Get-VM | measure).count }
				$temp1 = Get-WMIObject -Class MSCluster_ResourceGroup -ComputerName $c.dnshostname -Namespace root\mscluster -ea SilentlyContinue
				if ($temp1 -ne $null)
				{
					$obj.clustermember = $true
				}
				else
				{
					$obj.clustermember = $false
				}
				if ($obj.clustermember)
				{
					$obj.clustername = Invoke-Command -ComputerName $c.dnshostname -ScriptBlock { (get-cluster).name }
				}
			}
			else
			{
				$obj.VirtualHost = $false
			}
			$obj.manufacturer = $comp.manufacturer
			#Write-Host $comp.manufacturer
			$obj.model = $comp.model
			#Write-Host $comp.model
			$obj.Processorcount = $comp.numberofprocessors
			$obj.corecount = $comp.numberoflogicalprocessors
			$proc = Get-WmiInventory -wmiclass win32_processor -Local $false -computer $c.dnshostname
			$obj.cpuinfo = $proc[0].name
			
			
			if ($comp.model -eq 'Virtual Machine')
			{
				$obj.virtual = $true
				$hostname = invoke-command -ComputerName $c.dnshostname -ScriptBlock { (get-item "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters").GetValue("HostName") }
				$obj.hostcluster = Invoke-Command -ComputerName $hostname -ScriptBlock { (get-cluster).name }
			}
			else
			{
				$obj.virtual = $false
			}
			
		}
		catch
		{ Write-Host "Error Processing computer $($c.dnshostname) the message is $($_.Exception.Message)" }
	}
	else
	{
		Write-Color -Text "$($c.dnshostname)", " is offline" -Color Red, White
		$obj.computername = $c.dnshostname
		$obj.online = $false
	}
	$computers += $obj
	$i += 1
	
	#$computers | select computername, model
	
}
#$computers
$computers | Export-Csv -Path "c:\scripts\qcpout.csv" -NoTypeInformation -force


#software 
$i = 0
foreach ($c in $DComp)
{
	Write-Progress -Activity "Processing software on computers" -Status "Processing Computer $($c.dnshostname)" -PercentComplete ($i/$count * 100)
	$isonline = Test-Connection -ComputerName $c.dnshostname -Quiet -Count 1
	if ($isonline)
	{
		Invoke-Command -cn $c.dnshostname -ScriptBlock { Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.publisher -like 'Microsoft*' } | select DisplayName, DisplayVersion, Publisher, InstallDate } | Export-Csv -Path "C:\scripts\qcpmssoftware.csv" -NoTypeInformation -Append
	}
	$i += 1
	
}


