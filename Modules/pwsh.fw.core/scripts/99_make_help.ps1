[CmdletBinding()]Param(
)

Write-Verbose "Init"
Set-ExecutionPolicy RemoteSigned -Force
$PSVersionTable
Set-Variable -Name VERSION -Value (Get-Content $PSScriptRoot/../VERSION)
Write-Output "VERSION = $VERSION"
$project = Get-Content $PSScriptRoot/../project.conf -Raw | ConvertFrom-StringData
$project | Format-Table Name, Value

Write-Verbose "Load PlatyPS"
Install-Module -Name platyPS
Import-Module platyPS
Write-Verbose "Build modules"
& $PSScriptRoot/update-moduleManifest.ps1 -Path $PSScriptRoot/../$($project.Name) -Version "$VERSION.$env:CI_PIPELINE_IID" -Recurse -Force

Write-Verbose "Build help"
# git clone https://gitlab-ci-token:${CI_BUILD_TOKEN}@gitlab.com/PwSh.Fw/$($project.Name).wiki.git $PSScriptRoot/../../$($project.Name).wiki
if (-not (Test-Path $PSScriptRoot/../../$($project.Name).wiki)) {
	git clone git@gitlab.com:pwsh.fw/pwsh.fw.core.wiki.git $PSScriptRoot/../../$($project.Name).wiki
}
if (Test-Path $PSScriptRoot/../../$($project.Name).wiki) {
	Push-Location $PSScriptRoot/../../$($project.Name).wiki
	Write-Verbose "PWD = $(Get-Location)"
	git pull
	Pop-Location
	Get-ChildItem -Path $PSScriptRoot/.. -Recurse -Name "*.psm1" | ForEach-Object {
		Write-Debug "Processing $_"
		$file = Get-Item $_
		Import-Module -FullyQualifiedName $file.FullName
		New-MarkdownHelp -Module $($file.BaseName) -OutputFolder "$PSScriptRoot/../../$($project.Name).wiki/References/$($file.BaseName)" -Force
	}
	Push-Location $PSScriptRoot/../../$($project.Name).wiki
	Update-MarkdownHelp "./References"
	# git push https://gitlab-ci-token:${CI_BUILD_TOKEN}@gitlab.com/PwSh.Fw/$($project.Name).wiki.git
	git add References/*
	# git commit -am "wiki: update auto-generated documentation"
	# git push
	Pop-Location
	Write-Verbose "PWD = $(Get-Location)"
} else {
	Write-Error "Path '$PSScriptRoot/../../$($project.Name).wiki' not found. An error occured."
}

Write-Verbose "Clean"
# remove all manifest
Get-ChildItem -Recurse -Filter "*.psd1" | Remove-Item	
