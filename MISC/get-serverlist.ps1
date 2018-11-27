<#
    .SYNOPSIS
        get ad server list
    .DESCRIPTION
        This script retrieves a list of all server in the supplied domain.
    .PARAMETER DomainName
        The domain to operate against.
    .PARAMETER Credential
        User credentials to access the objects in the domain.
    .PARAMETER FileName
        The output csv file including the path.
    .EXAMPLE
    get-serverlist -domainname example.com - credential (get-credential) -filename c:\temp\serverlist.csv
    This will output all servers in example.com to a file in c:\temp called serverlist.csv using prompted creds.
    .NOTES
        ScriptName : get-serverlist
        Created By : Gary Cook
        Date Coded : 01/11/2018 11:42:18
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
 
        ErrorCodes
            100 = Success
            101 = Error
            102 = Warning
            104 = Information
    ****************************************************************
    * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
    * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
    * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
    * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
    ****************************************************************
    .LINK
    .INPUTS
    .OUTPUTS
 #>
 [CmdletBinding()]
Param
    (
    [parameter(Mandatory = $false,ValueFromPipelineByPropertyName = $true,Position = 1)]
	[string]
    [ValidateNotNullOrEmpty()]
	$DomainName,
    [parameter(Mandatory = $false,ValueFromPipelineByPropertyName = $true,Position = 2)]
	[System.Management.Automation.PSCredential]
    [ValidateNotNullOrEmpty()]
	$Credential,
    [parameter(Mandatory = $false,ValueFromPipelineByPropertyName = $true,Position = 3)]
	[string]
    [ValidateNotNullOrEmpty()]
	$FileName
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
        #if Domain was not supplied get domain
        if (!$DomainName)
        {
            $DomainName = Read-Host -Prompt "Enter Domain to Export"
        }
        #if the credential was not supplied get credntial
        if (!$Credential)
        {
            $credential = Get-Credential -Message "Enter Account for domain $($DomainName)"
        }
        #if the filename was not supplied get a file to output the information to
        if (!$FileName)
        {
            write-host "The Filename entered below will be destroyed if it exists"
            $FileName = read-host -Prompt "Enter filename to export (include path)"
        }
        write-host "Finding DC for domain $($DomainName)"
        $DC=get-addomaincontroller -discover -domain $DomainName
        $DCIP = $DC.ipv4address
        write-host "DC found at IP address $($DCIP)"
        write-host "Getting list of all servers in domain"
        $Servers = get-adcomputer -Filter * -Properties * -Credential $Credential -Server $DCIP| ?{$_.operatingsystem -like '*server*'}
        write-host "List of server retrieved"
        $slist = $servers | select dnshostname,ipv4address,created,distinguishedname,enabled,lastlogondate,lockedout,modified,operatingsystem,operatingsystemhotfix,operatingsystemservicepack,operatingsystemversion,passwordexpired,passwordlastset,primarygroup
        write-host "Saving List to file"
        $slist | export-csv -Path $FileName -NoTypeInformation -Force 
        write-host "File Save Complete"

        }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message	
        }


