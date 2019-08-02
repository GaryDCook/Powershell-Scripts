import-module visio
New-VisioApplication
$doc = New-VisioDocument
$flex = Open-VisioDocument "C:\Users\b_mag\Documents\My Shapes\Microsoft\Microsoft FLEX\FLEX_Stencil_121412.vss"
$dommaster = Get-VisioMaster "Domain" $flex
$shape = new-visioshape $dommaster 4,5
$shape.text = "Realm.Local"
$shape_c1 = Get-VisioShapeCells -Shapes $shape
$shape_c = New-VisioShapeCells
$scprop = $shape_c | get-member |?{$_.membertype -eq 'Property'}
foreach ($m in $scprop)
{
    $shape_c."$($m.name)" = $shape_c1."$($m.name)"
}
$shape_c.charsize = "10 pt"
$font = $doc.Fonts["Segoe UI"]
$fontid = $font.ID
$shape_c.CharFont = $font.ID
$shape_c.textformpiny = 0
$shape_c.textformpinx = 0
$shape_c.textformlocpinx = 0
$shape_c.TextFormLocPinY = $shape_c.charsize
$shape_c.textformwidth = $shape_c.xformwidth



Set-VisioShapeCells -Cells $shape_c -Shapes $shape
