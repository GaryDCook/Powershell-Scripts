<#
    .SYNOPSIS
        Save all share Information to CSV
    .DESCRIPTION
        Gets all share information and saves it to CSV at thee location provided.
    .PARAMETER
        Filename
            The path and filename of the CSV.
    .EXAMPLE
        save-shareinfo - filename "c:\test\shares.csv"
    .NOTES
        ScriptName : save-shareinfo
        Created By : Gary Cook
        Date Coded : 08/27/2018 09:47:08
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
	[string]$Filename
	
    )
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $LogName = "Application"
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\" + $env:USERNAME
 
        New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue
 
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
 


        
        #	Dotsource in the functions you need.
        }
Process
    {
    if ($Servername -eq $null)
    {
        $Servername = "LocalHost"
    }
    $results = @()
    $shares = Get-SmbShare -IncludeHidden | select *
    foreach ($share in  $shares)
    {
        
        
        $access = Get-SmbShareAccess -Name $share.name
        $results += combine-objects -Object1 $share -Object2 $access


    }
    #write results to csv file
    $results | export-csv -Path $filename -NoTypeInformation

        }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message	
        }
