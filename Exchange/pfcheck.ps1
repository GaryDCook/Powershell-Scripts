$global:charfound = ""
function test-pftext
{
    param( [string]$Alias )
   $global:charfound = ""
    $IllegalAliasCharacters = 0..34+40..41+44,46+58..60+62+64+91..93+127..160+256
    $return = $false
   Foreach ($c in $IllegalAliasCharacters) 
   {
       
        $char = [regex]::escape([char]$c)
        

        if($Alias -match $char)
        {
            $return = $true
            $global:charfound = "$($global:charfound)$($char)"
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
    $nametest = test-pftext -Alias $p.name
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
        $mp = get-mailpublicfolder -identity $p.name | select *
        $obj | Add-Member -MemberType NoteProperty -Name alias -Value $mp.alias
        $aliastest = test-pftext -Alias $mp.alias
    if ($aliastest -eq $true)
    {
    $obj | Add-Member -MemberType NoteProperty -Name Aliasvalid -Value $false
    $obj | Add-Member -MemberType NoteProperty -Name Aliasinvalidchar -Value ($global:charfound)
    }
    else
    {
    $obj | Add-Member -MemberType NoteProperty -Name Aliasvalid -Value $true
    $obj | Add-Member -MemberType NoteProperty -Name Aliasinvalidchar -Value ""
    }
        $obj | Add-Member -MemberType NoteProperty -Name pemail -Value $mp.primarysmtpaddress
        $pemailtest = test-pftext -Alias $mp.primarysmtpaddress
    if ($pemailtest -eq $true)
    {
    $obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value $false
    $obj | Add-Member -MemberType NoteProperty -Name pemailinvalidchar -Value ($global:charfound)
    }
    else
    {
    $obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value $true
    $obj | Add-Member -MemberType NoteProperty -Name pemailinvalidchar -Value ""
    }
    }
    else
    {
        
        $obj | Add-Member -MemberType NoteProperty -Name alias -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name aliasvalid -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name pemail -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value ""
    }
    $results += $obj
    $count += 1
}
write-host "Expoting File to current Directory"
$results | export-csv -path ".\pfcheckexport.csv" -NoTypeInformation
