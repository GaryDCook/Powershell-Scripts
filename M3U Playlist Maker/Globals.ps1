#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------

#global varibles	
$Playlist = @()


#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory


Function Get-MP3MetaData
{
	[CmdletBinding()]
	[Alias()]
	[OutputType([Psobject])]
	Param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.IO.FileInfo]$File
	)
	
	Begin
	{
		$shell = New-Object -ComObject "Shell.Application"
	}
	Process
	{
		
		$Dir = $File.directoryname
			$ObjDir = $shell.NameSpace($Dir)
		
		$ObjFile = $ObjDir.parsename($File.Name)
		#$ObjFile = $File.name
		
				$MetaData = @{ }
				$MP3 = ($ObjDir.Items() | ?{ $_.path -like "*.mp3" -or $_.path -like "*.mp4" })
				$PropertArray = 0, 1, 2, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 27, 28, 36, 220, 223
				
				Foreach ($item in $PropertArray)
				{
					If ($ObjDir.GetDetailsOf($ObjFile, $item)) #To avoid empty values 
					{
						$MetaData[$($ObjDir.GetDetailsOf($MP3, $item))] = $ObjDir.GetDetailsOf($ObjFile, $item)
					}
					
				}
				
				New-Object psobject -Property $MetaData | select @{ n = "Directory"; e = { $Dir } }, @{ n = "Fullname"; e = { Join-Path $Dir $File.Name -Resolve } } ,*
			
		
	}
	End
	{
	}
}
