<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.115
	 Created on:   	12/6/2016 12:13 PM
	 Created by:   	Gary Cook
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
function Resolve-DnsName
{
	Param
	(
		[Parameter(Mandatory = $true)]
		[string]$Name,
		[string]$Server = '127.0.0.1'
	)
	Try
	{
		$nslookup = &nslookup.exe $Name $Server
		$regexipv4 = "^(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$"
		
		$name = @($nslookup | Where-Object { ($_ -match "^(?:Name:*)") }).replace('Name:', '').trim()
		
		$deladdresstext = $nslookup -replace "^(?:^Address:|^Addresses:)", ""
		$Addresses = $deladdresstext.trim() | Where-Object { ($_ -match "$regexipv4") }
		
		$total = $Addresses.count
		$AddressList = @()
		for ($i = 1; $i -lt $total; $i++)
		{
			$AddressList += $Addresses[$i].trim()
		}
		
		$AddressList | %{
			
			new-object -typename psobject -Property @{
				Name = $name
				IPAddress = $_
			}
		}
	}
	catch
	{ }
}