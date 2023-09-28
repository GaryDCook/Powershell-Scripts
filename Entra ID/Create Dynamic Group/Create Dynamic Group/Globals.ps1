#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------

$Dquerytext = ""

Function Get-GraphIntuneDeviceCateogry
{
<#
    .SYNOPSIS
        Retrieves Intune device categories
 
    .DESCRIPTION
        Calls get from deviceManagement/deviceCategories
 
    .EXAMPLE
        Get-GraphIntuneDeviceCateogry -DisplayName 'MyCategory'
        Will search for the category with display name of MyCategory
 
    .PARAMETER DisplayName
        Filters the results based on displayName
 
    .PARAMETER Id
        Retrieves a specific device category
 
    .LINK
        https://github.com/Ryan2065/MSGraphCmdlets
     
    .Notes
        Author: Ryan Ephgrave
#>	
	Param (
		[Parameter(ParameterSetName = 'DisplayName')]
		[ValidateNotNullOrEmpty()]
		[string]$DisplayName,
		[Parameter(ParameterSetName = 'Id')]
		[ValidateNotNullOrEmpty()]
		[string]$Id
	)
	$InvokeHash = @{
		query   = "deviceManagement/deviceCategories"
		Version = Get-GraphIntuneVersion
		Method  = 'Get'
	}
	if ($DisplayName)
	{
		$InvokeHash['Search'] = "displayName:$($DisplayName)"
	}
	elseif ($Id)
	{
		$InvokeHash['query'] = "deviceManagement/deviceCategories/$($Id)"
	}
	Invoke-GraphMethod @InvokeHash
}

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



