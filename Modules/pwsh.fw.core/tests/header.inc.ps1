Write-Output ">> header.inc.pc1"

# load Pester helper file
. $PSScriptRoot/pester.inc.ps1

$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$TEMP = [System.IO.Path]::GetTempPath()
# Directory Separator char
$DS = [IO.Path]::DirectorySeparatorChar

# set logging
$Global:QUIET = $false
$Global:VERBOSE = $true
$Global:DEBUG = $true
$Global:DEVEL = $true

if ((Get-Module Pester).Version -lt [version]'4.0.0') { throw "Pester > 4.0.0 is required." }
if ((Get-Module Pester).Version -ge [version]'5.0.0') { throw "Pester < 5.0.0 is required." }
# $null = Import-Module PwSh.Fw.Core -DisableNameChecking

# get config
Write-Output "Get-Location = $(Get-Location)"
Write-Output "PSScriptRoot = $PSScriptRoot"
Write-Output "ROOTDIR = $ROOTDIR"
Write-Output "BASENAME = $BASENAME"
Write-Output "ModuleName = $ModuleName"

$project = Get-Content "$ROOTDIR/project.conf" -Raw | ConvertFrom-StringData
# just in case
Uninstall-Module -name $($project.name) -ErrorAction SilentlyContinue
Remove-Module PwSh.Fw.*
Import-Module -DisableNameChecking -FullyQualifiedName "$ROOTDIR/$($project.name)/$($project.name).psm1" -Force -ErrorAction stop
Import-Module PesterMatchHashtable

$VerbosePreference = 'continue'

# Mock Write-Error { } -ModuleName $ModuleName
Mock Write-Host { }
Mock Write-Host { } -ModuleName PwSh.Fw.Core
# Mock Write-Host { } -ModuleName PwSh.Fw.Write
# Mock Write-Host { } -ModuleName $ModuleName
# Mock New-Item { } -ModuleName $ModuleName

Write-Output ">> header.inc.pc1"
