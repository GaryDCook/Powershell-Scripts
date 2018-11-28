function Remove-FileSecure 

{
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory = $true, ValueFromPipeline = $true )]
        [System.IO.FileInfo] $File,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch] $DeleteAfterOverwrite = $false
    )
    
    begin{
        $r = new-object System.Security.Cryptography.RNGCryptoServiceProvider
    }

    process {
        $retObj = $null
            
        if ((Test-Path $file -PathType Leaf) -and $pscmdlet.ShouldProcess($file)) {
            $f = $file
            if( !($f -is [System.IO.FileInfo]) ) {
                $f = new-object System.IO.FileInfo($file)
            }

            $l = $f.length

            write-host $f.FullName

            $s = $f.OpenWrite()

            try {
                $w = new-object system.diagnostics.stopwatch
                $w.Start()

                Write-Progress -Activity $f.FullName -Status "Write" -PercentComplete 0 -CurrentOperation ""

                [long]$i = 0
                $b = new-object byte[](1024*1024)
                while( $i -lt $l ) {
                    $r.GetBytes($b)

                    $rest = $l - $i
    
                    if( $rest -gt (1024*1024) ) {
                        $s.Write($b, 0, $b.length)
                        $i += $b.LongLength
                    } else {
                        $s.Write($b, 0, $rest)
                        $i += $rest
                    }

                    [double]$p = [double]$i / [double]$l

                    [long]$remaining = [double]$w.ElapsedMilliseconds / $p - [double]$w.ElapsedMilliseconds

                    Write-Progress -Activity $f.FullName -Status "Write" -PercentComplete ($p * 100) -CurrentOperation "" -SecondsRemaining ($remaining/1000)
                }
                $w.Stop()
            } finally {
                $s.Close()

                if( $deleteAfterOverwrite ) {
                    $j  = Remove-Item $f.FullName -Force -Confirm:$false

                    $retObj = new-object PSObject -Property @{File = $f; Overwritten=$true; Deleted=(Test-Path $f)}
                } else {
                    $retObj = new-object PSObject -Property @{File = $f; Overwritten=$true; Deleted=$false}
                }
            }
        } else {
            $retObj = new-object PSObject -Property @{File = $file; Overwritten=$false; Deleted=$false}
        }

        return $retObj
    }
}










