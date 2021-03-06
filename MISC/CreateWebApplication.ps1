$ver = $host | select version
if ($ver.Version.Major -gt 1)  {$Host.Runspace.ThreadOptions = "ReuseThread"}
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Import-Module WebAdministration -ErrorAction SilentlyContinue

##
#This Script Creates SharePoint Web Applications
##

##
#Load Script Variables
##

Write-Progress -Activity "Creating Web Application" -Status "Creating Script Variables"

#This is the Web Application URL
$WebApplicationURL = "http://Contoso.com"

#This is the Display Name for the SharePoint Web Application
$WebApplicationName = "Contoso Web Application"

#This is the Content Database for the Web Application
$ContentDatabase = "Contoso_ContentDB"

#This is the Display Name for the Application Pool
$ApplicationPoolDisplayName = "Contoso App Pool"

#This is identity of the Application Pool which will be used (Domain\User)
$ApplicationPoolIdentity = "Contoso\ContentAppPool"

#This is the password of the Appliation Pool account which will be used
$ApplicationPoolPassword = "Passw0rd1"

#This is the Account which will be used for the Portal Super Reader Account
$PortalSuperReader = "Contoso\SuperReader"

#This is the Account which will be used for the Portal Super User Account
$PortalSuperUser = "Contoso\SuperUser"

##
#Begin Script
##


$AppPoolStatus = $False
Write-Progress -Activity "Creating Web Application" -Status "Checking if Web Application Already Exists"

if(get-spwebapplication $WebApplicationURL -ErrorAction SilentlyContinue)
{
    #If a web application with the specifid URL already exists, exit
    Write-Progress -Activity "Aborting Web Application Creation" -Status "Web Application with URL $WebApplication Already Exists"
    Write-Host "Aborting: Web Application $WebApplicationURL Already Exists" -ForegroundColor Red
    sleep 5
}
else
{
    Write-Progress -Activity "Creating Web Application" -Status "Checking if Application Pool Already Exists"
    
    #Check to see if the specified application pool alrady exists. If it exists, use the existing app pool
    if($AppPool = Get-SPServiceApplicationPool $ApplicationPoolDisplayName -ErrorAction SilentlyContinue)
    {
        Write-Progress -Activity "Creating Web Application" -Status "Re-Using Existing SharePoint Application Pool"
        Set-Variable -Name AppPoolStatus -Value "IsSharePoint" -scope "script"
    }
    else
    {
        if((Test-Path IIS:\AppPools\$ApplicationPoolDisplayName).tostring() -eq "True")
        {
           Write-Progress -Activity "Creating Web Application" -Status "Application Pool with name $ApplicationPoolDisplayName exists and is not used by SharePoint"
           Set-Variable -Name AppPoolStatus -Value "IsNotSharePoint" -scope "script"
        }
    }
    
        
    if($AppPoolStatus -eq "IsNotSharePoint")
    {
        Write-Host "Aborting: Application Pool $ApplicationPoolDisplayName already exists on the server and is not a SharePoint Application Pool" -ForegroundColor Red
        Write-Progress -Activity "Creating Web Application" -Status "Aborting: SharePoint Cannot use the specified Application Pool"
    }
    elseif($AppPoolStatus -eq "IsSharePoint")
    {
        #Check to see if the URL starts with HTTP or HTTPS.  This can be used to determine the appropriate host header to assign
        if($WebApplicationURL.StartsWith("http://"))
        {
            $HostHeader = $WebApplicationURL.Substring(7)
            $HTTPPort = "80"
        }
        elseif($WebApplicationURL.StartsWith("https://"))
        {
            $HostHeader = $WebApplicationURL.Substring(8)
            $HTTPPort = "443"
        }
        Write-Progress -Activity "Creating Web Application" -Status "Application Pool $ApplicationPoolDisplayName Already Exists, Using Existing Application Pool"
        
        #Grab the existing application pool, assign it to the AppPool variable
        Set-Variable -Name AppPool -Value (Get-SPServiceApplicationPool $ApplicationPoolDisplayName) -scope "script"
        
        Write-Progress -Activity "Creating Web Application" -Status "Creating Web Application $WebapplicationURL"
        #Create a new web application using the existing parameters, assign it to the WebApp variable such that object cache user accounts can be configured
        $WebApp = New-SPWebApplication -ApplicationPool $ApplicationPoolDisplayName -Name $WebApplicationName -url $WebApplicationURL -port $HTTPPort -DatabaseName $ContentDatabase -HostHeader $hostHeader
        
        Write-Progress -Activity "Creating Web Application" -Status "Configuring Object Cache Accounts"
        
        #Assign Object Cache Accounts
        $WebApp.Properties["portalsuperuseraccount"] = $PortalSuperUser
        $WebApp.Properties["portalsuperreaderaccount"] = $PortalSuperReader
        
        Write-Progress -Activity "Creating Web Application" -Status "Creating Object Cache User Policies for Web Application"
        
        #Create a New Policy for the Super User
        $SuperUserPolicy = $WebApp.Policies.Add($PortalSuperUser, "Portal Super User Account")
        #Assign Full Control To the Super User
        $SuperUserPolicy.PolicyRoleBindings.Add($WebApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl))

        #Create a New Policy for the Super Reader
        $SuperReaderPolicy = $WebApp.Policies.Add($PortalSuperReader, "Portal Super Reader Account")
        #Assign Full Read to the Super Reader
        $SuperReaderPolicy.PolicyRoleBindings.Add($WebApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead))
        
        Write-Progress -Activity "Creating Web Application" -Status "Updating Web Application Properties"
        #Commit changes to the web application
        $WebApp.update()

    }
    else
    {
        Write-Progress -Activity "Creating Web Application" -Status "Creating Application Pool"
        
        #Since we have to create a new application pool, check to see if the account specified is already a managed account
        if(get-spmanagedaccount $ApplicationPoolIdentity)
        {
            #If the specified account is already a managed account, use that account when creating a new application pool
            Set-Variable -Name AppPoolManagedAccount -Value (Get-SPManagedAccount $ApplicationPoolIdentity | select username) -scope "Script"
            Set-Variable -Name AppPool -Value (New-SPServiceApplicationPool -Name $ApplicationPoolDisplayName -Account $ApplicationPoolIdentity) -scope "Script"
        }
        else
        {
            #If the specified account is not already a managd account create a managed account using the credentials provided
            $AppPoolCredentials = New-Object System.Management.Automation.PSCredential $ApplicationPoolIdentity, (ConvertTo-SecureString $ApplicationPoolPassword -AsPlainText -Force)
            Set-Variable -Name AppPoolManagedAccount -Value (New-SPManagedAccount -Credential $AppPoolCredentials) -scope "Script"
            
            #Create an application pool using the new managed account
            Set-Variable -Name AppPool -Value (New-SPServiceApplicationPool -Name $ApplicationPoolDisplayName -Account (get-spmanagedaccount $ApplicationPoolIdentity)) -scope "Script"
            
        }
        #Check to see if the URL starts with HTTP or HTTPS.  This can be used to determine the appropriate host header to assign
        if($WebApplicationURL.StartsWith("http://"))
        {
            $HostHeader = $WebApplicationURL.Substring(7)
            $HTTPPort = "80"
        }
        elseif($WebApplicationURL.StartsWith("https://"))
        {
            $HostHeader = $WebApplicationURL.Substring(8)
            $HTTPPort = "443"
        }
        
        Write-Progress -Activity "Creating Web Application" -Status "Creating Web Application $WebapplicationURL"
        
        #Create a new web application using the existing parameters, assign it to the WebApp variable such that object cache user accounts can be configured
        $WebApp = New-SPWebApplication -ApplicationPool $AppPool.Name -ApplicationPoolAccount $AppPoolManagedAccount.Username -Name $WebApplicationName -url $WebApplicationURL -port $HTTPPort -DatabaseName $ContentDatabase -HostHeader $hostHeader
        
        Write-Progress -Activity "Creating Web Application" -Status "Configuring Object Cache Accounts"
        
        #Assign Object Cache Accounts
        $WebApp.Properties["portalsuperuseraccount"] = $PortalSuperUser
        $WebApp.Properties["portalsuperreaderaccount"] = $PortalSuperReader
        
        Write-Progress -Activity "Creating Web Application" -Status "Creating Object Cache User Policies for Web Application"
        
        #Create a New Policy for the Super User
        $SuperUserPolicy = $WebApp.Policies.Add($PortalSuperUser, "Portal Super User Account")
        #Assign Full Control To the Super User
        $SuperUserPolicy.PolicyRoleBindings.Add($WebApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl))

        #Create a New Policy for the Super Reader
        $SuperReaderPolicy = $WebApp.Policies.Add($PortalSuperReader, "Portal Super Reader Account")
        #ASsign Full Read to the Super Reader
        $SuperReaderPolicy.PolicyRoleBindings.Add($WebApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead))
        
        Write-Progress -Activity "Creating Web Application" -Status "Updating Web Application Properties"
        
        #Commit changes to the web application
        $WebApp.update()
        
    }
    
}