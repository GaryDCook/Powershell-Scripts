<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.166
	 Created on:   	7/25/2019 3:14 PM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	Logging Module
	===========================================================================
	.DESCRIPTION
		Module for generation of logging files for script runs.  Each function will have specific information in a headder.

	.FUNCTIONALITY
		Included Functions are:
			Start-Log
			Write-Log
			Stop-Log
	.INPUTS
		users should create a custom object by calling create-log which returns the object to pass to the other functions. 
#>

function Start-Log
{
	<#
        .SYNOPSIS
			Creates the supplied log file $Log.
        .DESCRIPTION
        .PARAMETER
			$Log
				the complete path to the log to write to. required.
			$type
				the type of log file to generate TXT is assumed.  Possible Values are TXT, CSV, JSON.
        .EXAMPLE
			creates a log at location and returns object representing the log and type
			Start-Log -Log "C:\applog.txt" -Type CSV
        .NOTES
            FunctionName :	Write-Log
            Created by   :	Gary Cook
            Date Coded   : 	07/26/2019
		.OUTPUTS
			Returns and object containing the path to the log and the type of the log.
    #>
	[CmdletBinding()]
	Param
	(
		[parameter (position = 0, Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
		[string]$Log,
		[Parameter (Position = 1, Mandatory = $false, ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
		[ValidateSet("TXT", "CSV", "JSON")]
		[string]$Type = "TXT"
	)
	Begin
	{
	}
	Process
	{
		
		# Format Date for our Log File 
		$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		#if log does not exists create log with application runtime banner
		if (!(Test-Path $Log -PathType Leaf))
		{
			if (!(Test-Path $Log))
			{
				#create file including path if the path does not exist
				$NewLogFile = New-Item $Log -Force -ItemType File
			}
			if ($Type -eq "TXT")
			{
				#create file with banner
				$Banner = "*************************************************"
				$Banner | Out-File -FilePath $Log -Append -force
				$Banner = "Application log created $($FormattedDate) on computer $($env:COMPUTERNAME)"
				$Banner | Out-File -FilePath $Log -Append
				$Banner = "*************************************************"
				$Banner | Out-File -FilePath $Log -Append
			}
			if ($Type -eq "CSV")
			{
				#open out file with headder
				$Banner = "Date,Level,Message"
				$Banner | Out-File -FilePath $Log -Append -force
				$Banner = "$($FormattedDate),INFO:,Application Log file Created for computer $($env:COMPUTERNAME)"
				$Banner | Out-File -FilePath $Log -Append
			}
			if ($Type -eq "JSON")
			{
				$Banner = "{`"DATE`": `"$($FormattedDate)`",`"LEVEL`": `"INFO:`",`"MESSAGE`": `"Application Log file Created for computer $($env:COMPUTERNAME)`"}"
				$Banner | Out-File -FilePath $Log -Append -force
			}
			
		}
		$obj = new-object System.Management.Automation.PSObject
		$obj | Add-Member -MemberType NoteProperty -Name Log -Value (get-item $log).VersionInfo.filename
		$obj | Add-Member -MemberType NoteProperty -Name Type -Value $Type
		
		return $obj
		
	}
	end
	{
		
	}
	
	
}



Function Write-Log
{
    <#
        .SYNOPSIS
			Writes the Entry in $Line to the supplied log file $Log.  Built to take pipeline input from object returned from start-log.
        .DESCRIPTION
        .PARAMETER
			$Line
				String of data to write to the log file. required.
			$Log
				the complete path to the log to write to. required.
			$Level
				The type of line to write to the log.  Valid vales are Error,Warn,Info. Default is Info.
			$Type
				the type of log file to generate TXT is assumed.  Possible Values are TXT, CSV, JSON.
        .EXAMPLE
			$mylog | Write-Log -Line "This is an entry for the log" -level Info
        .NOTES
            FunctionName :	Write-Log
            Created by   :	Gary Cook
            Date Coded   : 	07/26/2019
		.OUTPUTS
			Returns 0 if log exists or -1 if the log file does not exist
    #>
	[CmdletBinding()]
	Param
	(
		[parameter (position = 0, Mandatory = $true)]
		[string]$Line,
		[parameter (position = 1, Mandatory = $true, ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
		[string]$Log,
		[Parameter (position = 2, Mandatory = $false)]
		[ValidateSet("Error", "Warn", "Info")]
		[string]$Level = "Info",
		[Parameter (Position = 3, Mandatory = $false, ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
		[ValidateSet("TXT", "CSV", "JSON")]
		[string]$Type = "TXT"
	)
	Begin
	{
	}
	Process
	{
		
		# Format Date for our Log File 
		$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		# Write message to error, warning, or verbose pipeline and specify $LevelText 
		switch ($Level)
		{
			'Error' {
				
				$LevelText = 'ERROR:'
			}
			'Warn' {
				
				$LevelText = 'WARNING:'
			}
			'Info' {
				
				$LevelText = 'INFO:'
			}
		}
		#if log does not exists reutrn -1 else return 0
			if (!(Test-Path $Log -PathType Leaf))
			{
				if (!(Test-Path $Log))
				{
				return -1
				break
				
			}
			
			
		}
		# Write message to proper log type 
			switch ($Type)
			{
				'TXT' {
					"$($FormattedDate) $($LevelText) $($Line)" | Out-File -FilePath $Log -Append
				}
				'CSV' {
					"$($FormattedDate),$($LevelText),$($Line)" | Out-File -FilePath $Log -Append
				}
				'JSON' {
					"{`"DATE`": `"$($FormattedDate)`",`"LEVEL`": `"$($LevelText)`",`"MESSAGE`": `"$($Line)`"}" | Out-File -FilePath $Log -Append
				}
			}
			
		
		return 0
	}
	End
	{
	}
}


Function Close-Log
{
	<#
        .SYNOPSIS
			Closes the supplied log file $Log.  Built to take pipeline input from object returned from start-log.
        .DESCRIPTION
        .PARAMETER
			$Log
				the complete path to the log to write to. required.
			$Type
				the type of log file to generate TXT is assumed.  Possible Values are TXT, CSV, JSON.
        .EXAMPLE
			$mylog | Close-Log 
        .NOTES
            FunctionName :	Write-Log
            Created by   :	Gary Cook
            Date Coded   : 	07/26/2019
    #>
		[CmdletBinding()]
		Param
		(
			[parameter (position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
			[string]$Log,
			[Parameter (Position = 1, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
			[ValidateSet("TXT", "CSV", "JSON")]
			[string]$Type = "TXT"
		)
		Begin
		{
		}
		Process
		{
			
			# Format Date for our Log File 
			$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			if ($Type -eq "TXT")
			{
				#close out file with footer
				$Footer = "*************************************************"
				$Footer | Out-File -FilePath $Log -Append
				$Footer = "Application log end $($FormattedDate) on computer $($env:COMPUTERNAME)"
				$Footer | Out-File -FilePath $Log -Append
				$Footer = "*************************************************"
				$Footer | Out-File -FilePath $Log -Append
			}
			if ($Type -eq "CSV")
			{
				#close out file with footer
				$Footer = "$($FormattedDate),INFO:,Application Log file end for computer $($env:COMPUTERNAME)"
				$Footer | Out-File -FilePath $Log -Append
			}
			if ($Type -eq "JSON")
			{
				$Footer = "{`"DATE`": `"$($FormattedDate)`",`"LEVEL`": `"INFO:`",`"MESSAGE`": `"Application Log file end for computer $($env:COMPUTERNAME)`"}"
				$Footer | Out-File -FilePath $Log -Append
			}
				
			
			
		}
		End
		{
		}
	
	
}