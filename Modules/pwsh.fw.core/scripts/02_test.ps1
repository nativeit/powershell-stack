[CmdletBinding()]Param(
)

. $PSScriptRoot/00_header.ps1

$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
Write-Host -ForegroundColor Blue ">> $BASENAME"

Install-Module PsScriptAnalyzer
Import-Module PSScriptAnalyzer
Install-Module Pester -SkipPublisherCheck
Install-Module PesterMatchHashtable
Import-Module Pester
Get-Module Pester | Format-Table Name, Version, ExportedFunctions
Invoke-ScriptAnalyzer $ROOTDIR -Recurse | Format-Table -AutoSize
# Invoke-Pester $ROOTDIR
$files = Get-ChildItem $ROOTDIR -File -Recurse -Include *.psm1
Invoke-Pester $ROOTDIR -Codecoverage $files | Format-Table -AutoSize

Write-Host -ForegroundColor Blue "<< $BASENAME"
