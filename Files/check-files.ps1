<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.178
	 Created on:   	6/30/2020 10:24 AM
	 Modified on:	1/21/2022 09:51 AM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	check-files.ps1
	===========================================================================
	.DESCRIPTION
		Runs a check of the file structure for prep of movement to OneDrive and Offcie 365 Sharepoint Online.
#>

[CmdletBinding()]
param
(
	[parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
	[string]
	$path,
	[parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
	[string]
	$outputfile
)

begin
{
	# requires several modules to run
	# pscommoncore
	
	Write-Color -Text "Starting the capture of files at ", "$($path)", ". Please  be patient as this may take some time if there are alot of files at the location." -Color Green, Yellow, Green
	
	# get all files at and below location of path
	$Objects = Get-childItem -Path $path -Recurse -force
	
	Write-Color -Text "Completed capture of files at ", "$($path)", "." -Color Green, Yellow, Green
	$rslt = @()
	$invchars = """", "*", ":", "<", ">", "?", "/", "\", "|"
	$invext = ".lock", ".tmp"
	$fnlimit = 260
	$invnames = "con","prn","aux","nul","com0","com1","com2","com3","com4","com5","com6","com7","com8","com9","lpt0","lpt1","lpt2","lpt3","lpt4","lpt5","lpt6","lpt7","lpt8","lpt9","desktop.ini","forms"
	
	$count = ($Objects | measure).count
}
Process
{
	#process all objects
	$i = 0
	foreach ($item in $Objects)
	{
		Write-Progress -id 0 -Activity "Processing files." -Status "Processing file $($item.BaseName) file $($i) of $($count)." -PercentComplete ($i/$count*100)
		#create new object to store this items information
		$obj = New-Object System.Management.Automation.PSObject
		#add basic information
		$obj | Add-Member -MemberType NoteProperty -Name Name -Value $item.PSChildName
		$obj | Add-Member -MemberType NoteProperty -Name FullPath -Value $item.FullName
		
		if ($item.Attributes -eq "Directory")
		{
			$obj | Add-Member -MemberType NoteProperty -Name ItemType -Value "Directory"
			$obj | Add-Member -MemberType NoteProperty -Name Parent -Value $item.Parent
		}
		else
		{
			$obj | Add-Member -MemberType NoteProperty -Name ItemType -Value "File"
			$parent = $item.FullName -replace ($item.BaseName, "")
			$parent = $parent -replace ($item.Extension, "")
			
			$obj | Add-Member -MemberType NoteProperty -Name Parent -Value $Parent
		}
		
		#check if total length of filename is over limit
		if ($item.FullName.Length -gt $fnlimit)
		{
			$obj | Add-Member -MemberType NoteProperty -Name FileNameLengthInvalid -Value $true
			
		}
		else
		{
			$obj | Add-Member -MemberType NoteProperty -Name FileNameLengthInvalid -Value $false
			
		}
		#check for invalid characters in filename
		$Reason = ""
		$obj | Add-Member -MemberType NoteProperty -Name FileNameInvalid -Value $false
		$obj | Add-Member -MemberType NoteProperty -Name FileNameInvalidReason -Value $null
		foreach ($char in $invchars)
		{
			if ($item.PSChildName -contains $char)
			{
				$obj.FileNameInvalid = $true
				$Reason += $Reason +" Character $($char) present in filename."
				$obj.FileNameInvalidReason = $Reason
			}
			else
			{
				
			}
		}
		if ($item.PSChildName -contains "_vti_")
		{
			$obj.FileNameInvalid = $true
			$Reason += $Reason + " _VTI_ cannot be present in filename."
			$obj.FileNameInvalidReason = $Reason
		}
		else
		{
			
		}
		#check for invalid filenames
		foreach ($name in $invnames)
		{
			if ($item.PSChildName -eq $name)
			{
				$obj.FileNameInvalid = $true
				$Reason += $Reason + " The filename cannot be $($name)."
				$obj.FileNameInvalidReason = $Reason
			}
		}
		#check for invalid starting character
		if ($item.BaseName -like '~*' -or $item.BaseName -like ' *')
		{
				$obj.FileNameInvalid = $true
				$Reason += $Reason + " The filename cannot start with ~ or space."
				$obj.FileNameInvalidReason = $Reason
		}
		#check for invalid ending character
		if ($item.BaseName -like '* ')
		{
			$obj.FileNameInvalid = $true
			$Reason += $Reason + " The filename cannot end with a space."
			$obj.FileNameInvalidReason = $Reason
		}
		
		#check for invalid extension
		foreach ($ext in $invext)
		{
			if ($item.Extension -eq $ext)
			{
				$obj.FileNameInvalid = $true
				$Reason += $Reason + " The filename cannot have $($ext) as an extension."
				$obj.FileNameInvalidReason = $Reason
			}
			
		}
		
		#determine if acl is same as parent
		$obj | Add-Member -MemberType NoteProperty -Name ParentPermissions -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name ItemPermissions -Value $null
		$obj | Add-Member -MemberType NoteProperty -Name DifferentPermissions -Value $null
		if ($item.PSIsContainer -eq $true)
		{
			$p = $item.FullName -replace ($item.pschildname, "")
			
			$ParentACL = Get-Acl -path $p
			$ParentACE = $ParentACL.Access
			
			$ItemACL = Get-Acl -Path $item.FullName
			$ItemACE = $ItemACL.Access
			$good = $true
			foreach ($a in $itemace)
			{
				if ($a.IsInherited -eq $false)
				{
					$good = $false
					
				}
				
			}
			
			if ($good)
			{
				$obj.differentpermissions = $false
			}
			else
			{
				$obj.differentpermissions = $true
			}
		}
		else
		{
			$ParentACL = Get-Acl -path $item.DirectoryName
			$ParentACE = $ParentACL.Access
			
			$ItemACL = Get-Acl -Path $item.FullName
			$ItemACE = $ItemACL.Access
			$good = $true
			foreach ($a in $itemace)
			{
				if ($a.IsInherited -eq $false)
				{
					$good = $false
					
				}
				
			}
			
			
			if ($good)
			{
				$obj.differentpermissions = $false
			}
			else
			{
				$obj.differentpermissions = $true
			}
		}
		$rslt += $obj
		$i += 1
		
	}
	
	#export results to csv file
	$rslt | Export-Csv -Path $outputfile -NoTypeInformation
}
End
{
	
}