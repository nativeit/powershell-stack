[CmdletBinding()]Param(
)

. $PSScriptRoot/00_header.ps1

# $ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
Write-Host -ForegroundColor Blue ">> $BASENAME"

Get-Location
Get-ChildItem Env:\ | Format-Table Name, Value

Write-Host -ForegroundColor Blue "<< $BASENAME"
