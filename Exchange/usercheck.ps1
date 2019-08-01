$global:charfound = ""
function test-pftext
{
    param( [string]$text,[string]$type = "Alias" )
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
	$return
}
write-host "Getting users"
if ($users -eq $null)
{
$users = get-mailbox -resultsize unlimited
}
else 
{
	$users = $users
}
write-host "Processing Users"
$results = @()
$count = 0
$nusers = ($users | measure).count
foreach ($p in $users)
{
	
	Write-Progress -Activity "Processing Users" -Status "Processing user $($p.alias)" -PercentComplete ($count/$nusers * 100)
	$obj = new-object psobject
	$obj | Add-Member -MemberType NoteProperty -Name UserEmail -Value $p.primarysmtpaddress
	$obj | Add-Member -MemberType NoteProperty -Name UserName -Value $p.displayname
	$obj | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value $p.userprincipalname
	$obj | Add-Member -MemberType NoteProperty -Name SAMAccountname -Value $p.samaccountname
	$nametest = test-pftext -text $p.displayname -type name
	
	if ($nametest -eq $true)
	{
		$obj | Add-Member -MemberType NoteProperty -Name Namevalid -Value $false
		$obj | Add-Member -MemberType NoteProperty -Name Nameinvalidchar -Value ($global:charfound)
	}
	else
	{
		$obj | Add-Member -MemberType NoteProperty -Name Namevalid -Value $true
		$obj | Add-Member -MemberType NoteProperty -Name Nameinvalidchar -Value ""
	}
	$ac = ($users | ?{ $_.alias -eq $p.alias } | measure).count
	$obj | Add-Member -MemberType NoteProperty -Name alias -Value $p.alias
	$obj | Add-Member -MemberType NoteProperty -Name aliascount -Value $ac
	$aliastest = test-pftext -text $p.alias -type alias
	
	if ($aliastest -eq $true)
	{
		#write-host "Alias valid is $($aliastest)"
		$obj | Add-Member -MemberType NoteProperty -Name Aliasvalid -Value $false
		#write-host "Alias invalid characters are $($global:charfound)"
		$obj | Add-Member -MemberType NoteProperty -Name Ainvalidchar -Value ($global:charfound)
	}
	else
	{
		$obj | Add-Member -MemberType NoteProperty -Name Aliasvalid -Value $true
		$obj | Add-Member -MemberType NoteProperty -Name Ainvalidchar -Value ""
	}
	
	$pemailtest = test-pftext -text $p.primarysmtpaddress -type email
	if ($pemailtest -eq $true)
	{
		$obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value $false
		$obj | Add-Member -MemberType NoteProperty -Name pinvalidchar -Value ($global:charfound)
	}
	else
	{
		$obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value $true
		$obj | Add-Member -MemberType NoteProperty -Name pinvalidchar -Value ""
	}

<#else
{
	
	$obj | Add-Member -MemberType NoteProperty -Name alias -Value ""
	$obj | Add-Member -MemberType NoteProperty -Name aliascount -Value ""
	$obj | Add-Member -MemberType NoteProperty -Name aliasvalid -Value ""
	$obj | Add-Member -MemberType NoteProperty -Name Ainvalidchar -Value ""
	$obj | Add-Member -MemberType NoteProperty -Name pemail -Value ""
	$obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value ""
	$obj | Add-Member -MemberType NoteProperty -Name pinvalidchar -Value ""
}#>
$results += $obj
    $count += 1
}
write-host "Expoting File to current Directory"
$results | export-csv -path ".\usercheckexport.csv" -NoTypeInformation
