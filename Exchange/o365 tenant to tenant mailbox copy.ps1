


$SourceMailbox = Read-Host -Prompt "Source mailbox"
$TargetMailbox = Read-Host -Prompt "Target mailbox"

Import-Module -Name "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService -ArgumentList Exchange2013_SP1

#Provide the credentials 
$credential = Get-Credential -Message "Provide the credentials of the Exchange Online mailbox that has full access permissions on the source and on the target mailboxes"
$service.Credentials = new-object Microsoft.Exchange.WebServices.Data.WebCredentials -ArgumentList $credential.UserName, $credential.GetNetworkCredential().Password

#Exchange Online URL
$service.Url= new-object Uri("https://outlook.office365.com/EWS/Exchange.asmx")

function MoveFolderItems ($Source, $Target)
{

$ItemView = new-object Microsoft.Exchange.WebServices.Data.ItemView(1000)

$FindItemResults = $service.FindItems($Source,$ItemView)

if($FindItemResults.TotalCount)

{

write-host "$($FindItemResults.TotalCount) item(s) has/have been found in the Source mailbox folder and will be moved to the Target mailbox folder (if its/their item class is within the scope of the current operation)." -ForegroundColor White

do
{
foreach ($Item in $FindItemResults.Items)
{

if ($Item.ItemClass -match "IPM.Note" -or $Item.ItemClass -match "IPM.StickyNote" -or $Item.ItemClass -match "IPM.Activity" -or $Item.ItemClass -match "IPM.File")
 { $Message = [Microsoft.Exchange.WebServices.Data.EmailMessage]::Bind($service,$Item.Id); $Message.Move($Target); continue; }

if ($Item.ItemClass -match "IPM.Appointment")
 { $Message = [Microsoft.Exchange.WebServices.Data.Appointment]::Bind($service,$Item.Id); $Message.Move($Target); continue; }

if ($Item.ItemClass -match "IPM.Contact")
 { $Message = [Microsoft.Exchange.WebServices.Data.Contact]::Bind($service,$Item.Id); $Message.Move($Target); continue; }

if ($Item.ItemClass -match "IPM.Task")
 { $Message = [Microsoft.Exchange.WebServices.Data.Task]::Bind($service,$Item.Id); $Message.Move($Target); continue; }
 }

$ItemView.offset += $FindItemResults.Items.Count

}while($FindItemResults.MoreAvailable -eq $true)

}
 else { Write-Host "Source folder empty!" -ForegroundColor Yellow }

}


#Source mailbox Traversal
$SourceFolderId= new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$SourceMailbox)

$psPropertySet = new-object Microsoft.Exchange.WebServices.Data.PropertySet([Microsoft.Exchange.WebServices.Data.BasePropertySet]::IdOnly,
                                                                            [Microsoft.Exchange.WebServices.Data.FolderSchema]::FolderClass, 
                                                                            [Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName)

$FolderPath = new-object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(26293, [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::String) 

$psPropertySet.Add($FolderPath)

$FolderView = new-object Microsoft.Exchange.WebServices.Data.FolderView(100)

$FolderView.PropertySet = $psPropertySet

$FolderView.Traversal = [Microsoft.Exchange.Webservices.Data.FolderTraversal]::Deep

$SFindFolderResults = $service.FindFolders($SourceFolderId,$FolderView)


#Target mailbox Traversal
$TargetFolderId= new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$TargetMailbox)

$TFindFolderResults = $service.FindFolders($TargetFolderId,$FolderView)


function CreateFolder($FPath, $Folder)
{
$FolderId = new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot, $TargetMailbox)     
     
$FolderArray = $FPath.Split("\")  
          
$FolderView = new-object Microsoft.Exchange.WebServices.Data.FolderView(1) 

$FolderView.Traversal = [Microsoft.Exchange.Webservices.Data.FolderTraversal]::Shallow
        
   
for ($j = 1; $j -lt $FolderArray.Length; $j++) { 
            
$SearchFilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName,$FolderArray[$j])  
       
$FindFolderResults = $service.FindFolders($FolderId,$SearchFilter,$FolderView)  
        
        
if ($FindFolderResults.TotalCount){ $FolderId = $FindFolderResults.Id  }

   else { 
         write-host "The folder $($FolderArray[$j]) is missing from the target mailbox" -ForegroundColor Yellow
         
         Write-Host "Creating the folder $($FolderArray[$j])..." -ForegroundColor White
                           
         $NewFolder = new-object Microsoft.Exchange.WebServices.Data.Folder($service)
    
         $NewFolder.DisplayName = $FolderArray[$j]
    
         $NewFolder.FolderClass = $Folder.FolderClass

         #Create the folder and move the items within
         $NewFolder.Save($FolderId)
    
         MoveFolderItems $Folder.Id $NewFolder.Id
              
                            }                    }

}


foreach($SFolder in $SFindFolderResults.Folders)
{
$i=0;

if($SFolder.FolderClass) {

foreach ($TFolder in $TFindFolderResults.Folders) 
{

if($TFolder.FolderClass -and $SFolder.ExtendedProperties[0].Value.ToString() -eq $TFolder.ExtendedProperties[0].Value.ToString()) 
{

Write-Host "Source Folder: $($SFolder.ExtendedProperties[0].Value)" -ForegroundColor White

MoveFolderItems $SFolder.Id $TFolder.Id

$i++;

break;

}

}
if(!$i) {  CreateFolder $SFolder.ExtendedProperties[0].Value $SFolder; continue; }

}

}