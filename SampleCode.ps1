# put in the path to the extracted TS backup
$path = "<FILEPATH>"
$smstspath = get-childitem $path -Filter sms*
$tsID = $smstspath | get-childitem -Directory
#region Create Package Object from Referencesinfo.xml
[xml]$refxml = Get-Content "$($tsid.FullName)\ReferencesInfo.xml"
$refpkg = ([xml]"<instances>`n$($refxml.ArrayOfString.string)`n</instances>").instances.INSTANCE
$pkgarray = @()
foreach($pkg in $refpkg)
{
    $PSObjPkg = New-Object PSObject
    foreach($proppkg in $pkg.PROPERTY | Where-Object {$_.name -notmatch "__*"})
    {
        $PSObjPkg | Add-Member NoteProperty $proppkg.name $proppkg.VALUE
    }
    $pkgarray += $PSObjPkg
}
#endregion

#region create Application object from AppReferencesinfo.xml
[xml]$refappxml = Get-Content "$($tsid.FullName)\AppReferencesInfo.xml"
$refapp = ([xml]"<instances>`n$($refappxml.arrayofstring.string)`n</instances>").instances.INSTANCE
$appsarray = @()
foreach($app in $refapp)
{
    $PSObjApp = New-Object PSObject
    foreach($propapp in $app.PROPERTY | Where-Object {$_.name -notmatch "__*"})
    {
        $PSObjApp | Add-Member NoteProperty $propapp.name $propapp.value
    }
    $appsarray += $PSObjApp
}
#endregion

#region Get Task Sequence Properties
[xml]$xmobj = Get-Content "$($tsid.FullName)\object.xml"
$xmlprops = $xmobj.INSTANCE.PROPERTY
$PSObjOSDSettings = New-Object PSObject
foreach ($prop in $xmlprops | Where-Object {$_.name -notmatch "__*"}) {
    $PSObjOSDSettings | Add-Member NoteProperty $prop.Name $prop.value
}
$PSObjOSDSettings
#endregion

#region Create Task Sequence object array
$xmlpropsarray = ($xmobj.INSTANCE.'PROPERTY.OBJECTARRAY' | Where-Object {$_.name -eq 'References'}).'VALUE.OBJECTARRAY'.'value.object'.INSTANCE
$objArray = @()
foreach ($steps in $xmlpropsarray) {
    $PSObjObj = New-Object PSObject
    foreach($step in $steps.PROPERTY | Where-Object {$_.name -notmatch "__*"})
    {
        $PSObjObj | Add-Member NoteProperty $step.name $step.Value
    }
    $objArray += $PSObjObj
}
#endregion

$seq = ([xml]($xmobj.INSTANCE.PROPERTY | where-object {$_.name -eq 'Sequence'}).value.'#cdata-section').sequence
$seqversion = $seq.version
#region Global Variable List
$glovarlist = @()
foreach($gvar in $seq.globalVarList.variable)
{
    $PSObjgvar = New-Object PSObject
    $PSObjgvar | Add-Member NoteProperty "Name" $gvar.name
    $PSObjgvar | Add-Member NoteProperty "Property" $gvar.property
    $PSObjgvar | Add-Member NoteProperty "Value" $gvar.'#text'
    $glovarlist += $PSObjgvar
}
#endregion

#region Task Sequence Groups
$tsgroups = @()
foreach($grp in $seq.group)
{
    $psobjgrp = New-Object PSObject
    $psobjgrp | Add-Member NoteProperty "Name" $grp.name
    $psobjgrp | Add-Member NoteProperty "Description" $grp.Description
    $psobjgrp | Add-Member NoteProperty "Condition" $grp.Condition
    $psobjgrp | Add-Member NoteProperty "Steps" $grp.step
    $tsgroups += $psobjgrp
}
#endregion