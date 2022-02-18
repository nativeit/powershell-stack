[CmdletBinding()]Param(
)

. $PSScriptRoot/00_header.ps1

$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
Write-Host -ForegroundColor Blue ">> $BASENAME"

Update-ModuleManifestRecurse -FullyQualifiedName $ROOTDIR/$($project.Name)/$($project.Name).psm1 -Metadata $project -Recurse -Confirm:$false
Import-Module $ROOTDIR/$($project.Name)/$($project.Name).psd1 -Force
Get-Module $($project.Name) | Format-Table Name, Version, ExportedFunctions
# remove all manifest
# Get-ChildItem -Path $ROOTDIR/$($project.Name) -Recurse -Filter "*.psd1" | Remove-Item

Write-Host -ForegroundColor Blue "<< $BASENAME"
