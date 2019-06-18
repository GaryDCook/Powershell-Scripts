######################################

param
(
     [Parameter(Mandatory=$true, HelpMessage=’username in format DOMAIN\username’)]
     [string]$Username = “”,
     [Parameter(Mandatory=$true, HelpMessage=’url for web application e.g. http://collab’)]
     [string]$WebApplicationUrl = “”
     
)

Write-Host “Setting up user $Username as site collection admin on all sitecollections in Web Application $WebApplicationUrl” -ForegroundColor White;
$webApplication = Get-SPWebApplication $WebApplicationUrl;

if($webApplication -ne $null)
{

foreach($siteCollection in $webApplication.Sites){
     #No Locks Applied?
     if ($siteCollection.ReadOnly -eq $false -and $siteCollection.ReadLocked -eq $false -and $siteCollection.WriteLocked -eq $false) 
     {
       $Result1 = “Unlocked”
       Write-Host “Setting up user $Username as site collection admin for $siteCollection” -ForegroundColor White;
       $userToBeMadeSiteCollectionAdmin = $siteCollection.RootWeb.EnsureUser($Username);
       if($userToBeMadeSiteCollectionAdmin.IsSiteAdmin -ne $true)
       {
           $userToBeMadeSiteCollectionAdmin.IsSiteAdmin = $true;
           $userToBeMadeSiteCollectionAdmin.Update();
           Write-Host “User is now site collection admin for $siteCollection” -ForegroundColor Green;
       }
       else
       {
         Write-Host “User is already site collection admin for $siteCollection” -ForegroundColor DarkYellow;
       }

      Write-Host “Current Site Collection Admins for site: ” $siteCollection.Url ” ” $siteCollection.RootWeb.SiteAdministrators;
     }
     else
     {
        Write-Host “Current Site Collection is locked: ” $siteCollection.Url -ForegroundColor Red;

        #Write the Result to CSV file separeted with Tab character

        $siteCollection.RootWeb.Title +”`t” + $siteCollection.URL + “`t” + $Result1 | Out-File LockStatus.txt -Append
     }
}
}
else
{
     Write-Host “Could not find Web Application $WebApplicationUrl” -ForegroundColor Red;
}