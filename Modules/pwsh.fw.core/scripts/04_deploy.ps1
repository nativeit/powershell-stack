[CmdletBinding()]Param(
)

. $PSScriptRoot/00_header.ps1

$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
Write-Host -ForegroundColor Blue ">> $BASENAME"

Update-ModuleManifest -Path $ROOTDIR/$($project.Name)/$($project.Name).psd1 -ModuleVersion $($project.Version) -PreRelease $($project.PreRelease)
if (($env:CI_COMMIT_BRANCH -eq "master") -or (![string]::IsNullOrEmpty($env:CI_COMMIT_TAG))) {
	Publish-Module -Path $ROOTDIR/$($project.Name) -NuGetApiKey $env:NUGET_API_KEY_2020 -SkipAutomaticTags -Verbose -Force
} else {
	Publish-Module -Name $ROOTDIR/$($project.Name) -NuGetApiKey $env:NUGET_API_KEY_2020 -SkipAutomaticTags -Verbose -Force -AllowPrerelease
}

Write-Host -ForegroundColor Blue "<< $BASENAME"
