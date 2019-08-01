<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.164
	 Created on:   	6/26/2019 10:34 AM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	pffix.ps1
	===========================================================================
	.DESCRIPTION
		Fix script for pfcheck results.
#>

param
(
	[parameter(Mandatory = $true)]
	[bool]
	$test = $false
)
BEGIN 
{
	function fix-name ($name)
	{
		$newvalue = $name
		$af = $false
		While ($af -eq $false)
		{
			if ($newvalue -like ' *')
			{
				$af = $false
				#fix leading space
				$newvalue = $newvalue.trimstart()
				
			}
			else
			{
				$af = $true
			}
			
			if ($newvalue -like '* ')
			{
				$af = $false
				#fix trailing space
				$newvalue = $newvalue.trimend()
			}
			else
			{
				$af = $true
			}
			if ($newvalue -like '*.')
			{
				$af = $false
				
				#fix trailing period
				$newvalue = $newvalue.substring(0, $newvalue.length - 1)
			}
			else
			{
				$af = $true
			}
			if ($newvalue -like '.*')
			{
				$af = $false
				
				#fix leading period
				$newvalue = $newvalue.substring(1)
			}
			else
			{
				$af = $true
			}
		}
		
		
		Foreach ($c in $IllegalnameCharacters)
		{
			#fix other bad characters	
			$char = [regex]::escape([char]$c)
			
			
			if ($newvalue -match $char)
			{
				if ($c -eq 32)
				{
					#replace bad character with null
					$newvalue = $newvalue | ?{ $_ -ne [char]$c }
				}
				else
				{
					#replace bad character with "-"
					$newvalue = $newvalue -replace $char, [char]45
				}
				
			}
			
		}
		return $newvalue
	}
	function fix-alias ($alias)
	{
		$newvalue = $alias
		$count = 0
		#convert alias to char array
		$temp = $newvalue.tochararray()
		Foreach ($c in $IllegalAliasCharacters)
		{
			#Write-Host "fixing character $($c)"
			#fix other bad characters	
			
			#$char = [regex]::escape([char]$c)
			
			if ($illegalaliasreplacements[$count] -eq 0)
			{
				#Write-Host "remove all characters numbered $($c)"
				$temp = $temp | ?{ $_ -ne [char]$c }
				#Write-Host "New value of temp is $($temp)"
				
			}
			else
			{
				#Write-Host "replace with new character $([char]$illegalaliasreplacements[$count])"
				$temp = $temp -replace [regex]::Escape([char]$c), [char]$illegalaliasreplacements[$count]
				#Write-Host "New value of temp is $($temp)"
			}
			$count += 1
		}
		$newvalue = -join $temp
		if ($newvalue -like '*.')
		{
			#fix trailing period
			$newvalue = $newvalue.substring(0, $newvalue.length - 1)
		}
		if ($newvalue -like '.*')
		{
			#fix leading period
			$newvalue = $newvalue.substring(1)
		}
		return $newvalue
	}
	
	function create-log($log, $level, $action)
	{
		$obj = New-Object System.Management.Automation.PSObject
		$obj | Add-Member -MemberType NoteProperty -Name "Time" -Value "$([datetime]::Now.DateTime)"
		$obj | Add-Member -MemberType NoteProperty -Name "Level" -Value $level
		$obj | Add-Member -MemberType NoteProperty -Name "Action" -Value $action
		
		$obj | Export-Csv -Path $log -Force
		
	}
	
	function add-log ($log, $level, $action)
	{
		$obj = New-Object System.Management.Automation.PSObject
		$obj | Add-Member -MemberType NoteProperty -Name "Time" -Value "$([datetime]::Now.DateTime)"
		$obj | Add-Member -MemberType NoteProperty -Name "Level" -Value $level
		$obj | Add-Member -MemberType NoteProperty -Name "Action" -Value $action
		
		$obj | Export-Csv -Path $log -Append
		
	}
}
PROCESS
{
	$IllegalAliasCharacters = 32 .. 38 + 40 .. 45 + 47 + 58 .. 64 + 91 .. 94 + 123 .. 126
	$illegalaliasreplacements = 0, 0, 0, 0, 0, 0, 95, 0, 0, 0, 0, 95, 95, 95, 95, 95, 0, 0, 0, 46, 0, 0, 95, 0, 0, 0, 0, 0, 95
	$IllegalNameCharacters = 47, 92, 32
	
	$file = Import-Csv -Path '.\pfcheckexport.csv'
	
	
	
	$log = ".\pffixlog.csv"
	create-log -log $log -level "Information" -action "Started Processing"
	add-log -log $log -level "Information" -action "Testing is $($test)"
	
	$count = 0
	$rec = ($file | measure).count
	foreach ($f in $file)
	{
		$nf = $false
		$af = $false
		$ma = $false
		$newname = ""
		$newalias = ""
		
		Write-Progress -Activity "Processing Public Folders" -Status "Processing folder $($f.pfname) - test mode" -PercentComplete ($count/$rec * 100)
		add-log -log $log -level "information" -action "Processing Folder $($f.pfname)"
		if ($f.namevalid -eq "false")
		{
			$newname = fix-name -name $f.pfname
			$nf = $true
		}
		if ($f.mailenabled -eq "true")
		{
			if ($f.aliasvalid -eq "false")
			{
				$newalias = fix-alias -alias $f.alias
				$af = $true
			}
			if ($f.aliascount -ne 1)
			{
				#set alias to primary email local name
				$newalias = $f.pemail.Split("@")[0]
				$ma = $true
			}
			
		}
		if ($test -eq $false)
		{
			#log chages with out witing new values to exchange
			if ($nf - $true)
			{
				add-log -log $log -level "Information" -action "Name will be changed from $($f.pfname) to $($newname) - testing only"
				try
				{
					set-publicfolder -identity $f.pfidentity -name $newname -force -ea stop -whatif
					add-log -log $log -level "information" -action "Testing rename of public folder successfull - testing only no change"
				}
				catch
				{
					add-log -log $log -level "Error" -action "Testing rename of public folder failed with message $($_.Exception.Message) - testing only no chage"
					
				}
				
			}
			if ($af = $true)
			{
				if ($ma -eq $true)
				{
					add-log -log $log -level "Information" -action "Multiple alias's found for this public folder alias $($f.alias) setting alias to primaty email name $($newalias) -testing only"
					
				}
				else
				{
					add-log -log $log -level "Information" -action "Alias will be changed from $($f.alias) to $($newalias) -testing only"
				}
				try
				{
					set-mailpublicfolder -identity $f.pfidentity -alias $newalias -force -ea stop -whatif
					add-log -log $log -level "information" -action "Testing rename of public folder alias successfull - testing only"
				}
				catch
				{
					add-log -log $log -level "Error" -action "Testing rename of public folder alias failed with message $($_.Exception.Message) - testing only"
					
				}
			}
			if ($nf -eq $false -and $af -eq $false)
			{
				add-log -log $log -level "Information" -action "No changes to this folder needed"
			}
			
			
		}
		else
		{
			#log changes and write values to exchange
			if ($nf - $true)
			{
				add-log -log $log -level "Information" -action "Name will be changed from $($f.pfname) to $($newname)"
				try
				{
					set-publicfolder -identity $f.pfidentity -name $newname -force -ea stop
					add-log -log $log -level "information" -action "Rename of public folder successfull"
				}
				catch
				{
					add-log -log $log -level "Error" -action "Rename of public folder failed with message $($_.Exception.Message)"
					
				}
				
				
				
				
			}
			if ($af = $true)
			{
				if ($ma -eq $true)
				{
					add-log -log $log -level "Information" -action "Multiple alias's found for this public folder alias $($f.alias) setting alias to primaty email name $($newalias)"
					
				}
				else
				{
					add-log -log $log -level "Information" -action "Alias will be changed from $($f.alias) to $($newalias)"
				}
				try
				{
					set-mailpublicfolder -identity $f.pfidentity -alias $newalias -force -ea stop
					add-log -log $log -level "information" -action "Rename of public folder alias successfull"
				}
				catch
				{
					add-log -log $log -level "Error" -action "Rename of public folder alias failed with message $($_.Exception.Message)"
					
				}
			}
			if ($nf -eq $false -and $af -eq $false)
			{
				add-log -log $log -level "Information" -action "No changes to this folder needed"
			}
		}
		
		$count += 1
		
	}
	add-log -log $log -level "Information" -action "Processing completed"
	
	
}
END
{
	
}




