[CmdletBinding()]Param(
)

$ErrorActionPreference = "Stop"

$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
Write-Host -ForegroundColor Blue ">> header"

# clean to avoid doubles
Remove-Module PwSh.Fw.*
if (!(Get-PackageProvider -Name NuGet)) { Install-PackageProvider -Name NuGet -Force -Confirm:$false }
$PSGallery = Get-PSRepository -Name PSGallery
if (!($PSGallery)) {
	Register-PSRepository -Default -InstallationPolicy Trusted
} else {
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
Install-Module PwSh.Fw.BuildHelpers -ErrorAction stop -Force -AllowClobber
Import-Module PwSh.Fw.BuildHelpers -ErrorAction stop

Get-Module -Name PwSh.Fw.* -ListAvailable
$PSVersionTable | Format-Table Name, Value -AutoSize

$project = Get-Project -Path $ROOTDIR
$project | Format-Table Name, Value -AutoSize
# $project

Write-Host -ForegroundColor Blue "<< header"
