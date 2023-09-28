<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2023 v5.8.225
	 Created on:   	7/21/2023 12:17 PM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	Update-IntuneDeviceInformation
	===========================================================================
	.DESCRIPTION
		This script updates device owner and category based on csv inport
		containing ID,DeviceCategory,and DeviceOwner columns.

	.EXAMPLE
		Update-IntuneDeviceInformation -inputfile "C:\Temp\devices.csv"
#>

[CmdletBinding()]

param
(
	[parameter(Mandatory = $true)]
	[string]
	$InputFile
)


BEGIN
{
	#import the graph modules
	$moduleName = "Microsoft.Graph.Intune"
	if (-not (Get-Module-ListAvailable -Name $moduleName))
	{
		try
		{
			Install-Module-Name $moduleName -Scope CurrentUser -Repository PSGallery -Force
		}
		catch
		{
			Write-Error "Failed to install $moduleName"
			Exit
		}
	}
	Import-Module $moduleName
	
	Connect-MSGraph
	
	#read input file
	$Machines = Import-Csv -Path $InputFile
	$DeviceCategories = Get-IntuneDeviceCategory
	
}
PROCESS
{
	#create log file for run
	$file = New-Item ".\Intuneupdaterunlog.txt"
	
	#process machines
	foreach ($Machine in $Machines)
	{
		
		Write-Host "Getting current Device Values"
		$old = get-intunemanageddevice -managedDeviceId $Machine.id
		$oldowner = $old.manageddeviceownertype
		$oldcategory = $old.devicecategorydisplayname
		
		$Name = $old.deviceName
		$workingcategory = ($DeviceCategories | ?{ $_.displayname -eq $machine.devicecategory }).id
		$requestBody = @{ "@odata.id" = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/$workingcategory" }
		if ($Machine.DeviceOwnership -like 'c*'){
			$Owner = "company"
		}else{
			$Owner = "personal"
		}
		Write-Host "Preparing to update device $($Name)"
		try
		{
			update-intunemanageddevice -managedDeviceId $Machine.id -managedDeviceOwnerType $Owner -ea Stop
			$requestBody = @{ "@odata.id" = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/$workingcategory" }
			$id = $machine.id
			Invoke-MSGraphRequest -HttpMethod PUT -Url "deviceManagement/managedDevices/$id/deviceCategory/`$ref" -Content $requestBody -ea Stop
			Write-Host "Device updated"
			Add-Content -Path ".\intuneupdaterunlog.txt" -Value "Device $($Name) successfully updated"
		}
		catch
		{
			Write-Host "Error updating Device $($Name) the returned message was:"
			Write-Host "$($_.ErrorDetails.Message)"
			Add-Content -Path ".\intuneupdaterunlog.txt" -Value "Device $($Name) failed to update"
		}
		
	}
	
}
END
{
	EndBlock
}
