<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the basic framework that I use for all my scripts.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : 
        Created By : b_mag
        Date Coded : 08/23/2018 16:13:02
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
 
        ErrorCodes
            100 = Success
            101 = Error
            102 = Warning
            104 = Information
 #>
 [CmdletBinding()]
Param
    (
    [parameter(Mandatory = $true)]
	[string]$base,
	[parameter(Mandatory = $true)]
	[string]$totalIP
    )
Begin
    {
        
 
        #	Dotsource in the functions you need.
        }
Process
    {
        $ip = $base
        $count = (1..$totalip)
        foreach ($i in $count)
            {
                $pip = "$($ip)$($i)"
                write-host "Testing $($pip)"
                $good = test-connection -Count 1 -Quiet -ComputerName $pip
                if ($good)
                    {
                        write-host "$($pip) is alive" -ForegroundColor Green
                    }
                else
                    {
                        write-host "$($pip) is dead" -ForegroundColor Red
                    }

            }
     }
End
    {
       
        }
