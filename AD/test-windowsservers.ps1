<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	11/17/2017 10:40 AM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

function Test-PsRemoting
{
	param (
		[Parameter(Mandatory = $true)]
		$computername,
		[Parameter(Mandatory = $true)]
		$cred
	)
	
	try
	{
		$errorActionPreference = "Stop"
		$result = Invoke-Command -ComputerName $computername { 1 } -Credential $cred
	}
	catch
	{
		Write-Verbose $_
		return $false
	}
	
	## I've never seen this happen, but if you want to be 
	## thorough.... 
	if ($result -ne 1)
	{
		Write-Verbose "Remoting to $computerName returned an unexpected result."
		return $false
	}
	
	$true
}

#WMI Inventory Function
function Get-WmiInventory
{
	param ($wmiclass = "Win32_OperatingSystem",
		$Local = $false,
		$computer,
		$cred)
	PROCESS
	{
		$ErrorActionPreference = "SilentlyContinue"
		
		trap
		{
			$ErrorPath = "c:\scripts"
			$ErrorFile = $ErrorPath + "\wmicomperror.txt"
			$computer | out-file $ErrorFile -append
			set-variable skip ($true) -scope 1
			$obj = "failed"
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
		else
		{
			return $obj
		}
	}
}

$HQcred = Get-Credential -Message "Enter your HQ credential"
$titcred = Get-Credential -Message "Enter your Titanium credential"

#input file and process
$data = import-csv -Path .\windowsservers.csv
$recordcount = ($data | measure).count
$counter = 1
#create output file
$filename = "ScanResults.csv"
#$headder = "IP","Name","PSOK","Online","Domain","PSComputerName","Caption","Version","Manufacturer","Model"
$path = ".\" + $filename
if (Test-Path $path)
{
	Remove-Item $path
}
add-content -Force -Path $path -Value '"IP","Name","PSOK","Online","Domain","PSComputerName","Caption","Version","Manufacturer","Model"'
#$headder | export-csv -Path $path -Force -NoTypeInformation 

foreach ($record in $data)
{
	$res = new-object psobject
	$res | add-member -MemberType NoteProperty -Name IP -Value $null
	$res | add-member -MemberType NoteProperty -Name Name -Value $null
	$res | add-member -MemberType NoteProperty -Name PSOK -Value $null
	$res | add-member -MemberType NoteProperty -Name Online -Value $null
	$res | add-member -MemberType NoteProperty -Name Domain -Value $null
	$res | add-member -MemberType NoteProperty -Name PSComputerName -Value $null
	$res | add-member -MemberType NoteProperty -Name Caption -Value $null
	$res | add-member -MemberType NoteProperty -Name Version -Value $null
	$res | add-member -MemberType NoteProperty -Name Manufacturer -Value $null
	$res | add-member -MemberType NoteProperty -Name Model -Value $null
	Write-Progress -Activity "Processing Windows Servers" -status "Processing Server $($record.DeviceName) at IP $($record.IP)" -PercentComplete ($counter/$recordcount * 100)
	
	$res.IP = $record.ip
	$res.Name = $record.DeviceName
	
	Write-host "Testing ping."
	
	$res.online = Test-Connection -computername $record.IP -count 1 -quiet
	write-host "Trying Remote PowerShell with HQ Cred."
	if (Test-PsRemoting -computername $record.ip -cred $HQcred)
	{
		$HQPS = $true
	}
	else
	{
		$HQPS = $false
	}
	write-host "Trying Remote PowerShell with Titanium Cred."
	if (Test-PsRemoting -computername $record.ip -cred $titcred)
	{
		$TITPS = $true
	}
	else
	{
		$TITPS = $false
	}
	if ($HQPS -eq $true -and $TITPS -eq $false)
	{
		#HQ Available get WMI Inventory
		$res.PSOK = $true
		write-host "Attempting to get WMI Information"
		$cs = Get-WmiInventory -wmiclass "win32_operatingsystem" -Local $false -computer $record.ip -cred $HQcred
		$cs2 = Get-WmiInventory -wmiclass "win32_computersystem" -Local $false -computer $record.ip -cred $HQcred
		if ($cs -ne $null)
		{
			
			$res.Domain = $cs2.domain
			$res.PSComputerName = $cs.pscomputername
			$res.caption = $cs.caption
			$res.version = $cs.version
			$res.manufacturer = $cs2.manufactureer
			$res.model = $cs2.model
		}
	}
	if ($HQPS -eq $false -and $TITPS -eq $true)
	{
		#Titanium available get wmi inventory   
		$res.PSOK = $true
		write-host "Attempting to get WMI Information"
		$cs = Get-WmiInventory -wmiclass "win32_operatingsystem" -Local $false -computer $record.ip -cred $titcred
		$cs2 = Get-WmiInventory -wmiclass "win32_computersystem" -Local $false -computer $record.ip -cred $titcred
		if ($cs -ne $null)
		{
			
			$res.Domain = $cs2.domain
			$res.PSComputerName = $cs.pscomputername
			$res.caption = $cs.caption
			$res.version = $cs.version
			$res.manufacturer = $cs2.manufactureer
			$res.model = $cs2.model
		}
	}
	if ($HQPS -eq $false -and $TITPS -eq $false)
	{
		#not available test wmi inventory collection
		$res.PSOK = $false
		write-host "Attempting to get WMI Information"
		$cs = Get-WmiInventory -wmiclass "win32_operatingsystem" -Local $false -computer $record.ip -cred $titcred
		$cs2 = Get-WmiInventory -wmiclass "win32_computersystem" -Local $false -computer $record.ip -cred $titcred
		if ($cs -ne $null)
		{
			
			$res.Domain = $cs2.domain
			$res.PSComputerName = $cs.pscomputername
			$res.caption = $cs.caption
			$res.version = $cs.version
			$res.manufacturer = $cs2.manufactureer
			$res.model = $cs2.model
		}
		$cs = Get-WmiInventory -wmiclass "win32_operatingsystem" -Local $false -computer $record.ip -cred $HQcred
		$cs2 = Get-WmiInventory -wmiclass "win32_computersystem" -Local $false -computer $record.ip -cred $HQcred
		if ($cs -ne $null)
		{
			
			$res.Domain = $cs2.domain
			$res.PSComputerName = $cs.pscomputername
			$res.caption = $cs.caption
			$res.version = $cs.version
			$res.manufacturer = $cs2.manufactureer
			$res.model = $cs2.model
		}
	}
	
	$res | Export-Csv -Path $path -Append -NoTypeInformation
	
	
	$counter += 1
}