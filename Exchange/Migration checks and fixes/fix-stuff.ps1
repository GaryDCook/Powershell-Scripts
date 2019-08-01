<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.166
	 Created on:   	7/25/2019 8:02 PM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
[CmdletBinding()]
param
(
	[parameter(Mandatory = $true)]
	[string]$type,
	[parameter(Mandatory = $true)]
	[string]$action
)
Install-Module pshelllogging
Import-Module pshelllogging
Install-Module pswritecolor
Import-Module PSWriteColor

New-Alias -Name wc -Value Write-Color


Function Increment-Name
{
    <#
        .SYNOPSIS
			Adds a number to end of name if number exists increments number
        .DESCRIPTION
			Designed to be used in a loop to create a unique string
        .PARAMETER
			$name
				the name to test and add or increment number to
        .EXAMPLE
			Increment-Name -name "thisisatest"
		.OUTPUTS
			a string contaning the changed value for name
        .NOTES
            FunctionName : Increment-name
            Created by   : Gary Cook
            Date Coded   : 07/24/19
    #>
	[CmdletBinding()]
	Param
	(
		[parameter (position = 0, Mandatory = $true)]
		[string]$name
	)
	Begin
	{
	}
	Process
	{
		$len = $name.Length
		#Write-Host "total Length $($len)"
		if ($len -gt 0)
		{
			<#do
			{
				#Write-Host "New Length $($len)"
				$len -= 1
				if ($len -eq 0)
				{
					#Write-Host "No numbers"
					$len = $name.Length
					break
				}
			}
			until ($name[$len] -gt 47 -and $name[$len] -lt 58)
			#>
			#check last character to see if it is a number
			if ($name[$len-1] -gt 47 -and $name[$len-1] -lt 58)
			{
				#last character is a number incriment
				do
				{
					
					$len -= 1
					
				}
				until ($name[$len - 1] -lt 47 -or $name[$len - 1] -gt 58)
				$value = $name.substring(0, $len)
				$numvalue = [int]$name.substring($len, $name.length - $len)
				
				$numvalue += 1
				$rvalue = $value + $numvalue.ToString()
				
				return $rvalue
			}
			else
			{
				#last character is not a number add 1
				return ($name + "1")
			}
			<#if ($len -eq $name.length)
			{
				#Write-Host "No Numbers adding 1"
				return ($name + "1")
			}
			else
			{
				#Write-Host "Number at End"
				$value = $name.substring(0, $len)
				#Write-Host "Name without number $($value) at length $($len)"
				$numvalue = [int]$name.substring($len, $name.length - $len)
				#Write-Host "Number part $($numvalue)"
				$numvalue += 1
				$rvalue = $value + $numvalue.ToString()
				#Write-Host "New value $($rvalue)"
				return $rvalue
			}#>
		}
		
	}
	End
	{
	}
}


function test-pftext
{
	param ([string]$text,
		[string]$type = "Alias")
	$global:charfound = ""
	#$IllegalAliasCharacters = 0 .. 34 + 40 .. 41 + 44, 46 + 58 .. 60 + 62 + 64 + 91 .. 93 + 127 .. 160 + 256
	$IllegalAliasCharacters = 32 .. 38 + 40 .. 45 + 47 + 58 .. 64 + 91 .. 94 + 123 .. 126
	
	#$IllegalAliasCharacters = "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "+", "=", "[", "]", "{", "}", "\", "/", "|", ";", ":", """", "<", ">", "?", ","
	$EmailRegex = '^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$'
	
	$IllegalNameCharacters = 47, 92
	
	$return = $false
	if ($type -eq "alias")
	{
		Foreach ($c in $IllegalAliasCharacters)
		{
			
			$char = [regex]::escape([char]$c)
			
			
			if ($text -match $char)
			{
				$return = $true
				if ($char -eq "\ ")
				{
					$global:charfound = "$($global:charfound),<space>"
				}
				else
				{
					$global:charfound = "$($global:charfound),$($char)"
				}
				
			}
			
			
		}
	}
	if ($type -eq "name")
	{
		if ($text -like ' *')
		{
			$return = $true
			$global:charfound = "$($global:charfound),<Leading Space>"
		}
		if ($text -like '* ')
		{
			$return = $true
			$global:charfound = "$($global:charfound),<Trailing Space>"
		}
		if ($text -like '*.')
		{
			$return = $true
			$global:charfound = "$($global:charfound),<Trailing Period>"
		}
		if ($text -like '.*')
		{
			$return = $true
			$global:charfound = "$($global:charfound),<Leading Period>"
		}
		Foreach ($c in $IllegalnameCharacters)
		{
			
			$char = [regex]::escape([char]$c)
			
			
			if ($text -match $char)
			{
				$return = $true
				$global:charfound = "$($global:charfound),$($char)"
			}
			
			
			
		}
	}
	if ($type -eq "email")
	{
		<#
		if ($text -notmatch $EmailRegex)
		{
			$return = $true
			
		}
		#>
		try
		{
			$x = New-Object System.Net.Mail.MailAddress($text)
			$return = $false
		}
		catch
		{
			$return = $true
		}
	}
	return $return
}

function fix-avalue
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]
		$Value
	)
	# <space>,!,",#,$,%,&,(,),*,+,,,-,/,:,;,<,=,>,?,@,[,\,],^,{,|,},~
	$ichar = @(32 , 33 , 34 , 35 , 36 , 37 , 38 , 40 , 41 , 42 , 43 , 44 , 45 , 47 , 58 , 59 , 60 , 61 , 62 , 63 , 64 , 91 , 92 , 93 , 94 , 123 , 124 , 125 , 126)
	
	#correct value to fix alias invalid characters
	foreach ($i in $ichar)
	{
		#Write-Host "processing $($i)"
		switch ($i)
		{
			38{
				$cchar = "_"
			}
			58{
				$cchar = "_"
			}
			93{
				$cchar = "_"
			}
			126{
				$cchar = "_"
			}
			44{
				$cchar = "_"
			}
			45{
				$cchar = "_"
			}
			47{
				$cchar = "_"
			}
			59{
				$cchar = "_"
			}
			63{
				$cchar = "."
			}
			default{
				$cchar = ""
			}
		}
		#Write-Host "replacement character $($cchar)"
		#Write-Host "current value: $($Value)"
		$Value = $Value -replace "$([regex]::escape([char]$i))", $cchar
		#Write-Host "new value: $($Value)"
		
		
	}
	#lose begining and ending period
	$Value = $Value.trimstart(".")
	$Value = $Value.trimend(".")
	return $Value
}



function fix-alias
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]$Name,
		[parameter(Mandatory = $true)]
		[int]$Count,
		[parameter(Mandatory = $true)]
		[bool]$Valid,
		[parameter(Mandatory = $true)]
		[string]$email
		
	)
	$ret = ""
	#if aliascount is not 1 and alias to primary email address name correct if necessary
	if ($Count -ne 1 )
	{
		#Write-Host "Processing Duplicate Alias's"
		#Write-Host "Current Alias $($Name)"
		$ret = ($email -split "@")[0]
		#Write-Host "Grab Email and Set Alias to Local part of Email"
		#Write-Host "New Alias $($ret)"
		#Write-Host "Test Alias"
		$res = test-pftext -text $ret -type "alias"
		#Write-Host "Test Result $($res)"
		
		if (!$res)
		{
			#Write-Host "No alias Fix necessary"
		}
		else
		{
			#Write-Host "Fix Alias"
			$ret = fix-avalue -Value $ret
			#Write-Host "new value of alias $($ret)"
		}
		
		
	}
	#if alias count is 1 and valid is false fix alias
	if ($Count -eq 1 -and $Valid -eq $false)
	{
		$ret = fix-avalue -Value $Name
	}
	return $ret
}


function fix-pfvalue
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]$Value
	)
	# /,\
	$ichar = @(47, 92)
	
	#correct value to fix alias invalid characters
	foreach ($i in $ichar)
	{
		#Write-Host "processing $($i)"
		switch ($i)
		{
			
			47{
				$cchar = "-"
			}
			92{
				$cchar = "-"
			}
			
		}
		#Write-Host "replacement character $($cchar)"
		#Write-Host "current value: $($Value)"
		$Value = $Value -replace "$([regex]::escape([char]$i))", $cchar
		#Write-Host "new value: $($Value)"
		
		
	}
	#lose begining and ending period
	$Value = $Value.trimstart(".")
	$Value = $Value.trimend(".")
	return $Value
}



function fix-pfname
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]$Name,
		[parameter(Mandatory = $true)]
		[bool]$Valid
		
		
	)
	$ret = ""
	#fix pf name if valid is false
	if ($Valid -eq $false)
	{
		$ret = fix-pfvalue -Value $name
				
	}
	
	return $ret
}


if ($type -eq "User")
{
	Write-Color -text "Processing Users" -color Green
	
	#open log
	$log = Start-Log -Log ".\Userlog.csv" -Type CSV
	Write-Color -Text "Log Created at"," $($log.log)" -Color Green,yellow
	#open user file for processing
	$users = Import-Csv -Path ".\usercheckexport.csv"
	Write-Color -Text "Loaded user CSV for Processing" -Color Green
	$s = $log | Write-Log -Line "User CSV Loaded" -Level Info
	$pusers = $users | ?{ $_.aliascount -gt 1 -or $_.aliasvalid -eq 'FALSE' }
	$s = $log | Write-Log -Line "User CSV filtered" -Level Info
	$pcount = ($pusers | measure).count
	$s = $log | Write-Log -Line "User processing count is $($pcount)" -Level Info
	
	foreach ($user in $pusers) {
		$s = $log | Write-Log -Line "Processing user $($user.samaccountname)" -Level Info
		write-color -Text "Processing user ","$($user.samaccountname)" -Color Green,yellow
		$s = $log | Write-Log -Line "Current Alias $($user.alias)" -Level Info
		#code to get current mailbox emailaddresses array
		$oldea = (get-mailbox -identity $user.useremail | select emailaddresses).emailaddresses
		$s = $log | Write-Log -Line "Current emailaddresses array  $($oldea -join ";")" -Level Info
		$primary = (get-mailbox -identity $user.useremail | select primarysmtpaddress).primarysmtpaddress.address
		$s = $log | Write-Log -Line "Current primary smtp address is  $($primary)" -Level Info
		if ($user.aliasvalid -eq 'TRUE')
		{
			$valid = $true
		}
		else
		{
			$valid = $false
		}
		#Write-Color -Text "generating new alias" -Color green
		$newalias = fix-alias -Name $user.alias -Count $user.aliascount -Valid $valid -email $user.useremail
		#Write-Color -Text "new alias generated" -Color green
		if ($user.aliascount -eq 1)
		{
			$s = $log | Write-Log -Line "User had an invalid alias" -Level Info
			$s = $log | Write-Log -Line "The Corrected alias is $($newalias)" -Level Info
		}
		else
		{
			$s = $log | Write-Log -Line "The User had a duplicate alias" -Level Info
			$s = $log | Write-Log -Line "Checking for corrected alias duplication" -Level Info
			while (($users | ?{ $_.alias -eq $newalias } | measure).count -ne 0)
			{
				$s = $log | Write-Log -Line "The new alias $($newalias) is a duplicate of another user incrementing" -Level Warn
				$newalias = Increment-Name -name $newalias
			}
			$s = $log | Write-Log -Line "Final Alias that passed Testing is $($newalias)" -Level Info
			
		}
		$newemail = "$($newalias)@nbbj.com"
		$s = $log | Write-Log -Line "injecting new alias '$($newemail)' in user EmailAddresses as secondary" -Level Info
		if ($action -eq "Test")
		{
			$s = $log | Write-Log -Line "Selected testing add of new email performing non distructive test of add address" -Level Info
			#code to add addition email address here replace line below
			try
			{
				$s = $log | Write-Log -Line "Starting Test Add of email address $($newemail)" -Level Info
				#code to add email address to user
				Set-Mailbox -identity $user.useremail -EmailAddresses @{ add = $newemail } -ea stop -whatif
				$s = $log | Write-Log -Line "Test Add Succeeded" -Level Info
				$efailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "Test add failed failure message is:    $($_.Exception.Message)" -Level Error
				$efailed = 1
			}
		}
		else
		{
			$s = $log | Write-Log -Line "Non test mode perform actual address injection" -Level Info
			try
			{
				$s = $log | Write-Log -Line "Starting Add of email address $($newemail)" -Level Info
				#code to add email address to user
				Set-Mailbox -identity $user.useremail-EmailAddresses @{ add = $newemail } -ea stop
				$s = $log | Write-Log -Line "Add Succeeded" -Level Info
				$efailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "add failed failure message is:    $($_.Exception.Message)" -Level Error
				$efailed = 1
				
			}
		}
		
		
		#changing user alias
		if ($action -eq "Test")
		{
			$s = $log | Write-Log -Line "Selected testing change of user alias" -Level Info
			try
			{
				
				$s = $log | Write-Log -Line "Starting Test change on alias $($newalias)" -Level Info
				
				set-mailbox -identity $user.useremail -alias $newalias -ea stop -whatif
				$s = $log | Write-Log -Line "Test change succeeded" -Level Info
				$afailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "Test changed failed failure message is:    $($_.Exception.Message)" -Level Error
				$afailed = 1
			}
			
		}
		else
		{
			$s = $log | Write-Log -Line "Non-test change of user alias" -Level Info
			try
			{
				
				$s = $log | Write-Log -Line "Starting change on alias $($newalias)" -Level Info
				
				set-mailbox -identity $user.useremail -alias $newalias -ea stop 
				$s = $log | Write-Log -Line "Change succeeded" -Level Info
				$afailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "Change failed failure message is:    $($_.Exception.Message)" -Level Error
				$afailed = 1
			}
		}
		
		if ($efailed -eq 1)
		{
			$s = $log | Write-Log -Line "failed to change user email error message above manual intervention required" -Level Error
		}
		else
		{
			#code to get new email addresses
			$newea = (get-mailbox -identity $user.useremail | select emailaddresses).emailaddresses
			$s = $log | Write-Log -Line "New emailaddresses array  $($newea -join ";")" -Level Info
		}
		if ($afailed -eq 1)
		{
			$s = $log | Write-Log -Line "failed to change user alias error message above manual intervention required" -Level Error
		}
		else
		{
			$confirm = (get-mailbox -identity $user.useremail | select alias).alias
			$s = $log | Write-Log -Line "Confirm new alias is $($confirm)" -Level Info
			$cprimary = (get-mailbox -identity $user.useremail | select primarysmtpaddress).primarysmtpaddress.address
			$s = $log | Write-Log -Line "Fixing Primary smtp email address from $($cprimary) to $($primary)" -Level Info
			if ($action -eq "Test")
			{
				try
				{
					$s = $log | Write-Log -Line "Starting test change of Primary SMTP Address" -Level Info
					set-mailbox -identity $user.useremail -primarysmtpaddress $primary -ea stop -whatif -emailaddresspolicyenabled $false
					$s = $log | Write-Log -Line "test Change succeeded" -Level Info
				}
				catch
				{
					$s = $log | Write-Log -Line "test Change failed failure message is:    $($_.Exception.Message)" -Level Error
					
				}
			}
			else
			{
				try
				{
					$s = $log | Write-Log -Line "Starting change of Primary SMTP Address" -Level Info
					
					set-mailbox -identity $user.useremail -primarysmtpaddress $primary -ea stop -emailaddresspolicyenabled $false
					$s = $log | Write-Log -Line "Change succeeded" -Level Info
					#code to get new email addresses
					$newea = (get-mailbox -identity $user.useremail | select emailaddresses).emailaddresses
					$s = $log | Write-Log -Line "New emailaddresses array  $($newea -join ";")" -Level Info
					
				}
				catch
				{
					$s = $log | Write-Log -Line "Change failed failure message is:    $($_.Exception.Message)" -Level Error
				}
			}
			
		}
		
		$s = $log | Write-Log -Line "Finished processing user $($user.samaccountname)" -Level Info
		
	}
	
	
}

if ($type -eq "Group")
{
	Write-Color -text "Processing Groups" -color Green
	
	#open log
	$log = Start-Log -Log ".\grouplog.csv" -Type CSV
	Write-Color -Text "Log Created at", " $($log.log)" -Color Green, yellow
	#open user file for processing
	$groups = Import-Csv -Path ".\groupcheckexport.csv"
	Write-Color -Text "Loaded group CSV for Processing" -Color Green
	$s = $log | Write-Log -Line "Group CSV Loaded" -Level Info
	$pgroups = $groups | ?{ $_.aliascount -gt 1 -or $_.aliasvalid -eq 'FALSE' }
	$s = $log | Write-Log -Line "Group CSV filtered" -Level Info
	$pcount = ($pgroups | measure).count
	$s = $log | Write-Log -Line "Group processing count is $($pcount)" -Level Info
	
	foreach ($group in $pgroups)
	{
		$s = $log | Write-Log -Line "Processing Group $($group.samaccountname)" -Level Info
		write-color -Text "Processing group ", "$($group.samaccountname)" -Color Green, yellow
		$s = $log | Write-Log -Line "Current Alias $($group.alias)" -Level Info
		#code to get current mailbox emailaddresses array
		$oldea = (get-distributiongroup -identity $group.groupemail | select emailaddresses).emailaddresses
		$s = $log | Write-Log -Line "Current emailaddresses array  $($oldea -join ";")" -Level Info
		$primary = (get-distributiongroup -identity $group.groupemail | select primarysmtpaddress).primarysmtpaddress.address
		$s = $log | Write-Log -Line "Current primary smtp address is  $($primary)" -Level Info
		if ($group.aliasvalid -eq 'TRUE')
		{
			$valid = $true
		}
		else
		{
			$valid = $false
		}
		#Write-Color -Text "generating new alias" -Color green
		$newalias = fix-alias -Name $group.alias -Count $group.aliascount -Valid $valid -email $group.groupemail
		#Write-Color -Text "new alias generated" -Color green
		if ($group.aliascount -eq 1)
		{
			$s = $log | Write-Log -Line "Group had an invalid alias" -Level Info
			$s = $log | Write-Log -Line "The Corrected alias is $($newalias)" -Level Info
		}
		else
		{
			$s = $log | Write-Log -Line "The Group had a duplicate alias" -Level Info
			$s = $log | Write-Log -Line "Checking for corrected alias duplication" -Level Info
			while (($groups | ?{ $_.alias -eq $newalias } | measure).count -ne 0)
			{
				$s = $log | Write-Log -Line "The new alias $($newalias) is a duplicate of another group incrementing" -Level Warn
				$newalias = Increment-Name -name $newalias
			}
			$s = $log | Write-Log -Line "Final Alias that passed Testing is $($newalias)" -Level Info
			
		}
		$newemail = "$($newalias)@nbbj.com"
		$s = $log | Write-Log -Line "injecting new alias '$($newemail)' in group EmailAddresses as secondary" -Level Info
		if ($action -eq "Test")
		{
			$s = $log | Write-Log -Line "Selected testing add of new email performing non distructive test of add address" -Level Info
			#code to add addition email address here replace line below
			try
			{
				$s = $log | Write-Log -Line "Starting Test Add of email address $($newemail)" -Level Info
				#code to add email address to user
				set-distributiongroup -identity $group.groupemail -EmailAddresses @{ add = $newemail } -ea stop -whatif
				$s = $log | Write-Log -Line "Test Add Succeeded" -Level Info
				$efailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "Test add failed failure message is:    $($_.Exception.Message)" -Level Error
				$efailed = 1
			}
		}
		else
		{
			$s = $log | Write-Log -Line "Non test mode perform actual address injection" -Level Info
			try
			{
				$s = $log | Write-Log -Line "Starting Add of email address $($newemail)" -Level Info
				#code to add email address to user
				set-distributiongroup -identity $group.groupemail -EmailAddresses @{ add = $newemail } -ea stop
				$s = $log | Write-Log -Line "Add Succeeded" -Level Info
				$efailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "add failed failure message is:    $($_.Exception.Message)" -Level Error
				$efailed = 1
				
			}
		}
		
		
		#changing user alias
		if ($action -eq "Test")
		{
			$s = $log | Write-Log -Line "Selected testing change of group alias" -Level Info
			try
			{
				
				$s = $log | Write-Log -Line "Starting Test change on alias $($newalias)" -Level Info
				
				set-distributiongroup -identity $group.groupemail -alias $newalias -ea stop -whatif
				$s = $log | Write-Log -Line "Test change succeeded" -Level Info
				$afailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "Test changed failed failure message is:    $($_.Exception.Message)" -Level Error
				$afailed = 1
			}
			
		}
		else
		{
			$s = $log | Write-Log -Line "Non-test change of group alias" -Level Info
			try
			{
				
				$s = $log | Write-Log -Line "Starting change on alias $($newalias)" -Level Info
				
				set-distributiongroup -identity $group.groupemail -alias $newalias -ea stop
				$s = $log | Write-Log -Line "Change succeeded" -Level Info
				$afailed = 0
			}
			catch
			{
				$s = $log | Write-Log -Line "Change failed failure message is:    $($_.Exception.Message)" -Level Error
				$afailed = 1
			}
		}
		
		if ($efailed -eq 1)
		{
			$s = $log | Write-Log -Line "failed to change group email error message above manual intervention required" -Level Error
		}
		else
		{
			#code to get new email addresses
			$newea = (get-distributiongroup -identity $group.groupemail | select emailaddresses).emailaddresses
			$s = $log | Write-Log -Line "New emailaddresses array  $($newea -join ";")" -Level Info
		}
		if ($afailed -eq 1)
		{
			$s = $log | Write-Log -Line "failed to change group alias error message above manual intervention required" -Level Error
		}
		else
		{
			$confirm = (get-distributiongroup -identity $group.groupemail | select alias).alias
			$s = $log | Write-Log -Line "Confirm new alias is $($confirm)" -Level Info
			$cprimary = (get-distributiongroup -identity $group.groupemail | select primarysmtpaddress).primarysmtpaddress.address
			$s = $log | Write-Log -Line "Fixing Primary smtp email address from $($cprimary) to $($primary)" -Level Info
			if ($action -eq "Test")
			{
				try
				{
					$s = $log | Write-Log -Line "Starting test change of Primary SMTP Address" -Level Info
					set-distributiongroup -identity $group.groupemail -primarysmtpaddress $primary -ea stop -whatif -emailaddresspolicyenabled $false
					$s = $log | Write-Log -Line "test Change succeeded" -Level Info
				}
				catch
				{
					$s = $log | Write-Log -Line "test Change failed failure message is:    $($_.Exception.Message)" -Level Error
					
				}
			}
			else
			{
				try
				{
					$s = $log | Write-Log -Line "Starting change of Primary SMTP Address" -Level Info
					
					set-distributiongroup -identity $group.groupemail -primarysmtpaddress $primary -ea stop -emailaddresspolicyenabled $false
					$s = $log | Write-Log -Line "Change succeeded" -Level Info
					#code to get new email addresses
					$newea = (get-distributiongroup -identity $group.groupemail | select emailaddresses).emailaddresses
					$s = $log | Write-Log -Line "New emailaddresses array  $($newea -join ";")" -Level Info
					
				}
				catch
				{
					$s = $log | Write-Log -Line "Change failed failure message is:    $($_.Exception.Message)" -Level Error
				}
			}
			
		}
		
		$s = $log | Write-Log -Line "Finished processing group $($group.samaccountname)" -Level Info
		
	}
}

if ($type -eq "PF")
{
	
}



