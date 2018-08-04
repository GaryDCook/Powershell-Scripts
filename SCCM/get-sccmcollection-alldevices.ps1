<#
Script to pull all devices from device collection "All Servers" with Name,Domain,DeviceOS,IP and save to memory.
First half of generating device list to store in SharePoint list. 

Will be run on QCBRCMGMT01
11/17/2017 Josh Hensley


#>
#$ErrorActionPreference ="silentlycontinue"



import-module "c:\program files (x86)\microsoft configuration manager\adminconsole\bin\configurationmanager.psd1"
cd qc1:



$results = @()
$servers = Get-CMCollection -name "All Servers" | Get-CMCollectionMember | select Name,Domain,DeviceOS


foreach($server in $servers){
$serverobj = new-object psobject

$serverobj | add-member -membertype NoteProperty -name Name -Value $null
$serverobj | add-member -membertype NoteProperty -name DNS_HostName -Value $null
$serverobj | add-member -membertype NoteProperty -name IP -value $null
$serverobj | add-member -membertype NoteProperty -name Application -value $null
$serverobj | add-member -membertype NoteProperty -name Application_Owner -value $null
$serverobj | add-member -membertype NoteProperty -name Application_Department -value $null
$serverobj | add-member -membertype NoteProperty -name Domain -value $null
$serverobj | add-member -membertype NoteProperty -name OperatingSystem -value $null
$serverobj | add-member -membertype NoteProperty -name OperatingSystemVersion -value $null
$serverobj | add-member -membertype NoteProperty -name Description -value $null

$object = Get-ADComputer -identity $server.name -Properties *

if(test-connection -computername $server.name -count 1 -quiet)
{

$ip = (Test-Connection -ComputerName $server.name -count 1).ipv4address.tostring()
}
else
{
$ip = $object.ipv4address
}
$serverobj.Name = $server.name
$serverobj.dns_hostname = $object.dnshostname
$serverobj.ip = $ip
$serverobj.application = $object.extensionattribute10
$serverobj.application_owner = $object.extensionattribute11
$serverobj.application_department = $object.extensionattribute12
$serverobj.Domain = $server.domain
$serverobj.operatingsystem = $object.operatingsystem
$serverobj.operatingsystemversion = $object.operatingsystemversion
$serverobj.description = $object.description


$results += $serverobj
}
#$results | ft -autosize



<#


if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell" }


$spWeb = Get-SPWeb -Identity http://intranet.questsys.com/NOC
$spList = $spWeb.Lists["Dynamic Server List"]
$spitems = $splist.getitems()
$spitems
#$spItem = $spList.GetItemById(10013) //or another way that you prefer.
#$spItem["Name"] = "MyName"
#$spItem.Update() 

#>

##############################################



<#InvFile="appinvent.csv" 
# Get Data from Inventory CSV File 
$FileExists = (Test-Path $InvFile -PathType Leaf) 
if ($FileExists) { 
   "Loading $InvFile for processing..." 
   $tblData = Import-CSV $InvFile 
} else { 
   "$InvFile not found - stopping import!" 
   exit 
}
#>
pwd
"changing to local c drive"
c:
$results | export-csv -path "\\qcbrcsp03\c$\scripts\export.csv" -NoTypeInformation

"loading results from SCCM"
$tblData = $results
"Results Loaded: $(($tbldata | measure).count)"
pause
"connecting to remote SP server"
$password = "01000000d08c9ddf0115d1118c7a00c04fc297eb01000000e4b901f7c53c7c4c8d942fcc48c556640000000002000000000003660000c00000001000000004d42f2da2ae356cf2fccd7db00f36e80000000004800000a000000010000000ee65a221cd8407b290e9b81c80c4144c38000000feb00a889d663eb54778b2be62dae536a67c3fca5325c321a26c6e4c49c778f88ce07c3da6f193f5d32cfa1847d691ac210db187b864d74b14000000b91a57da3692ffabf2d561a2c405beeb4cb0a5fc"

$pass = $password | ConvertTo-SecureString  -force
$cred = new-object system.management.automation.pscredential("questsys\sp_farm",$pass)


"Switching session"
$session = New-PSSession -ComputerName qcbrcsp03.questsys.corp -Authentication Credssp -Credential $cred
#invoke-command -Session $session -ArgumentList $tbldata -ScriptBlock {$tbldata = $args[0];
Enter-PSSession $session
#"Remote connection successful"
$tbldata = import-csv -path "\\qcbrcsp03\c$\scripts\export.csv"
pause
# Setup the correct modules for SharePoint Manipulation 

Add-PsSnapin Microsoft.SharePoint.PowerShell 

Get-SPServer
 
"getting list"
pause
#Open SharePoint List 
$SPServer="http://intranet.questsys.com" 
$SPAppList="Dynamic Server List"

$spWeb = Get-SPWeb -site $SPServer 
#$spData = $spWeb.getList($SPAppList)

$list = $spWeb.Lists | ?{$_.title -eq $SPAppList}

"getting items"



$items = $list.getitems()

"Items in list: $(($items|measure).count)"
"processing results"

# Loop through Applications add each one to SharePoint
pause
"Uploading data to SharePoint...."
#$spdata
foreach ($row in $tblData) 
{ 
    "Processing $($row.Name)"
    $found = $false
    foreach($item in $items)
    {
    if ($item["Name"] -eq $row.Name.tostring())
    {
        "found entry for $($row.Name.ToString()) Updateing Entry"
        $item["DNS Host Name"] = $row.DNS_Hostname.tostring()
        $item["IP Address"] = $row.ip.tostring()
        $item["Application"] = $row.Application.tostring() 
        $item["Application Owner"] = $row.Application_owner.tostring() 
        $item["Application Department"] = $row.Application_department.tostring() 
        $item["Domain"] = $row.Domain.tostring() 
        $item["Operating System"] = $row.Operatingsystem.tostring() 
        $item["Build"] = $row.Operatingsystemversion.tostring() 
        $item["Description"] = $row.Description.tostring() 
        $item.Update()

        $found = $true
    }
    }
    if ($found -ne $true)
    {

   "Adding entry for $($row.Name.tostring())" 
   
      
    $spItem = $list.AddItem()
   #$spitem
      $spitem["Name"] = $row.name.tostring()
   $spitem["DNS Host Name"] = $row.DNS_Hostname.tostring()
        $spitem["IP Address"] = $row.ip.tostring()
        $spitem["Application"] = $row.Application.tostring() 
        $spitem["Application Owner"] = $row.Application_owner.tostring() 
        $spitem["Application Department"] = $row.Application_department.tostring() 
        $spitem["Domain"] = $row.Domain.tostring() 
        $spitem["Operating System"] = $row.Operatingsystem.tostring() 
        $spitem["Build"] = $row.Operatingsystemversion.tostring() 
        $spitem["Description"] = $row.Description.tostring() 
   $spItem.Update() 
   }

}

"---------------" 
"Upload Complete"

#$spWeb.Dispose()

#Exit-PSSession

#}
