<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.115
	 Created on:   	10/13/2017 12:56 PM
	 Created by:   	Gary Cook
	 Organization: 	Quest
	 Filename:     	Create-Documentation -template.ps1
	===========================================================================
	.DESCRIPTION
		This is the template for the create documentation set of scripts I plane to create for AD, Exchange, and Windows OS.
#>
param
(
	[parameter(Mandatory = $true)]
	[string]
	$filename
)
#install from psgallery word module
Install-Module -Name worddoc -Confirm $false 

function Add-WordText ($Selection, $Style, $Content, $Para, $font, $size) {
	if ($font -eq $null)
	{
	$font = "Trebuchet MS"
	}
	if ($size -eq $null)
	{
	$size = 12
	}
	if ($Style -eq $null)
	{
		$Style = "Normal"
	}
	if ($Style -like '*heading*' -and $size -eq $null)
	{
		$size = 14
	}
	$selection.style = $Style
	$Selection.font.name = $font
	$selection.font.size = $size
	$selection.TypeText($Content)
	if ($Para -eq $true -or $Para -eq $null)
	{
		$selection.TypeParagraph()
	}
	
}
function Add-WordTable ($Range, $rows, $columns, $columnText, $Content) {
	$table = $doc.Tables.add($range, $rows, $columns)
	
}

#Create word opbject
$word = New-Object -ComObject word.application
#comment line below when debugging is complete
$word.Visible = $true
#uncomment line below for production
#$word.Visible = $false
#create new document in Word
$doc = $word.documents.add()
#adjust the style of the docuemnt formatting
$doc.Styles
$doc.Styles["Normal"].ParagraphFormat.SpaceAfter = 0
$doc.Styles["Normal"].ParagraphFormat.SpaceBefore = 0
$margin = 36 # 1.26 cm
$doc.PageSetup.LeftMargin = $margin
$doc.PageSetup.RightMargin = $margin
$doc.PageSetup.TopMargin = $margin
$doc.PageSetup.BottomMargin = $margin
#create a new selection to add test to the document
$Wselection = $word.Selection
#create a new table object to add tables to the word document
$Wrange = $word.range




#save word doc to disk and close
$doc.saveas([ref]$filename, [ref]$SaveFormat::wdFormatDocumentDefault)

$doc.close()

$word.quit()