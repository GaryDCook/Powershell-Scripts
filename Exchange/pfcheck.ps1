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
					$global:charfound = "$($global:charfound) <space>"
				}
				else
				{
					$global:charfound = "$($global:charfound) $($char)"
				}
				
			}
			
			
		}
	}
	if ($type -eq "name")
	{
		if ($text -like ' *')
		{
			$return = $true
			$global:charfound = "$($global:charfound) <Leading Space>"
		}
		if ($text -like '* ')
		{
			$return = $true
			$global:charfound = "$($global:charfound) <Trailing Space>"
		}
if ($text -like '*.')
		{
			$return = $true
			$global:charfound = "$($global:charfound) <Trailing Period>"
		}
if ($text -like '.*')
		{
			$return = $true
			$global:charfound = "$($global:charfound) <Leading Period>"
		}
		Foreach ($c in $IllegalnameCharacters)
		{
			
			$char = [regex]::escape([char]$c)
			
			
			if ($text -match $char)
			{
				$return = $true
				$global:charfound = "$($global:charfound) $($char)"
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
write-host "Getting Public Folders"
if ($pf -eq $null)
{
$pf = get-publicfolder -resultsize unlimited -recurse
}
else 
{
$pf = $pf}
write-host "Processing public Folders"
$results = @()
$count = 0
$npf = ($pf | measure).count
foreach ($p in $pf)
{

    Write-Progress -Activity "Processing Public Folders" -Status "Processing folder $($p.name)" -PercentComplete ($count/$npf*100)
    $obj = new-object psobject
    $obj | Add-Member -MemberType NoteProperty -Name PFidentity -Value $p.identity
    $obj | Add-Member -MemberType NoteProperty -Name PFName -Value $p.name
	$nametest = test-pftext -text $p.name -type name
	
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
    $obj | Add-Member -MemberType NoteProperty -Name MailEnabled -Value $p.mailenabled
    if ($p.mailenabled -eq $true)
    {
		$mp = get-mailpublicfolder -identity $p.identity.tostring() | select *
		$ac = (get-mailboxpublicfolder -alias $mp.alias | measure ).count
		$obj | Add-Member -MemberType NoteProperty -Name alias -Value $mp.alias
		$obj | Add-Member -MemberType NoteProperty -Name aliascount -Value $ac
		$aliastest = test-pftext -text $mp.alias -type alias
		
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
        $obj | Add-Member -MemberType NoteProperty -Name pemail -Value $mp.primarysmtpaddress
        $pemailtest = test-pftext -text $mp.primarysmtpaddress -type email
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
    }
    else
    {
		
		$obj | Add-Member -MemberType NoteProperty -Name alias -Value ""
		$obj | Add-Member -MemberType NoteProperty -Name aliascount -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name aliasvalid -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name Ainvalidchar -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name pemail -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name pinvalidchar -Value ""
    }
    $results += $obj
    $count += 1
}
write-host "Expoting File to current Directory"
$results | export-csv -path ".\pfcheckexport.csv" -NoTypeInformation
