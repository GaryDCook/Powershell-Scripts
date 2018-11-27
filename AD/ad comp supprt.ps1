Function Get-NetworkConfiguration

{
    param (
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [Alias('__ServerName', 'Server', 'Computer', 'Name')]   
        [string[]]
        $ComputerName = $env:COMPUTERNAME,
        [parameter(Position=1)]
        [System.Management.Automation.PSCredential]
        $Credential
    )
    process
    {
        $WMIParameters = @{
            Class = 'Win32_NetworkAdapterConfiguration'
            Filter = "IPEnabled = 'true'"
            ComputerName = $ComputerName
        }
        if ($Credential -ne $Null)
        {
            $WmiParameters.Credential = $Credential
        }       
        foreach ($adapter in (Get-WmiObject @WMIParameters))
        {
            $OFS = ', '
            Write-Host "Server: $($adapter.DNSHostName)"
            Write-Host "Adapter: $($adapter.Description)"
            Write-Host "IP Address: $($adapter.IpAddress)"
            Write-Host "Subnet Mask: $($adapter.IPSubnet)"
            Write-Host "Default Gateway: $($adapter.DefaultIPGateway)"
            Write-Host "DNS Servers: $($adapter.DNSServerSearchOrder)"
            Write-Host "DNS Domain: $($adapter.DNSDomain)"
            Write-Host
        }
    }
}