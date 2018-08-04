
# Import the AD module to the session
Import-Module ActiveDirectory 
# Retrieve the dNSHostName attribute from all computer accounts in AD
$ComputerNames = Get-ADComputer -Filter * -Properties * |?{$_.operatingsystem -like '*server*'} | Select-Object -ExpandProperty dNSHostName

$AllComputerShares = @()

foreach($Computer in $ComputerNames)
{
    try{
        $Shares = Get-WmiObject -ComputerName $Computer -Class Win32_Share
        $AllComputerShares += $Shares
    }
    catch [system.exception]
    {
        Write-Error "$($Computer) has thrown system errror $($_)"
    }
    catch
    {
        write-error "An unhandled exception was detected for computer $($computer)"
    }
    finally 
    {

    }
}

# Select the computername and the name, path and comment of the share and Export
$AllComputerShares |Select-Object -Property PSComputerName,Name,Path,Description |Export-Csv -Path C:\temp\fileshares.1.25.18.csv -NoTypeInformation

