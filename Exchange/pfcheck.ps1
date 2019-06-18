function test-pftext
{
    param( [string]$Alias )
   
    $IllegalAliasCharacters = 0..34+40..41+44,46+58..60+62+64+91..93+127..160+256

   Foreach ($c in $IllegalAliasCharacters) 
   {
       
        $char = [regex]::escape([char]$c)

        if($Alias -match $char)
        {
            $return = $true
        }
        else
        {
            $return = $false
        }

    }
       
    $return
}
write-host "Getting Public Folders"
$pf = get-publicfolder-resultsize unlimited -recurse
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
    $obj | Add-Member -MemberType NoteProperty -Name MailEnabled -Value $p.mailenabled
    $obj | Add-Member -MemberType NoteProperty -Name Namevalid -Value (test-pftext -Alias $p.name)
    $obj | Add-Member -MemberType NoteProperty -Name Identityvalid -Value (test-pftext -Alias $p.identity)
    if ($p.mailenabled -eq $true)
    {
        $mp = get-mailpublicfolder -identity $p.name | select *
        $obj | Add-Member -MemberType NoteProperty -Name alias -Value $mp.alias
        $obj | Add-Member -MemberType NoteProperty -Name aliasvalid -Value (test-pftext -Alias $mp.alias)
        $obj | Add-Member -MemberType NoteProperty -Name pemail -Value $mp.primarysmtpaddress
        $obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value (test-pftext -Alias $mp.primarysmtpaddress)
    }
    else
    {
        $obj | Add-Member -MemberType NoteProperty -Name pemail -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name pemailvalid -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name alias -Value ""
        $obj | Add-Member -MemberType NoteProperty -Name aliasvalid -Value ""
    }
    $results += $obj
    $count += 1
}
write-host "Expoting File to current Directory"
$results | export-csv -path ".\pfcheckexport.csv" -NoTypeInformation

