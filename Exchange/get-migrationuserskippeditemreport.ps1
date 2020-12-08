$mu = get-migrationuser -resultsize unlimited | select *
$count = ($mu | measure).count
$res = @()
$c = 0
foreach ($u in $mu){
    Write-Progress -Activity "Processing users" -Status "processing user $($u.identity)" -PercentComplete ($c/$count*100)

    
    $ms = $u | get-migrationuserstatistics -includeskippeditems | select *
    foreach ($si in $ms.skippeditems)    {
    $obj = new-object psobject
    $obj | add-member -MemberType NoteProperty -Name Identity -Value $U.identity
    $obj | add-member -MemberType NoteProperty -Name FolderName -Value $si.foldername
    $obj | add-member -MemberType NoteProperty -Name Kind -Value $si.kind
    $obj | add-member -MemberType NoteProperty -Name failure -Value $si.failure
    $res += $obj
    }
    $c +=1 
}
$res | export-csv -path "C:\Users\b_mag\OneDrive\Quest\Quest Clients\NBBJ\skippeditems.csv" -NoTypeInformation
 