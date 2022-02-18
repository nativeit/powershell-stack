$PSVersionTable
Set-Variable -Name VERSION -Value (Get-Content $PSScriptRoot/../VERSION)
Write-Output "VERSION = $VERSION"
$project = Get-Content $PSScriptRoot/../project.conf -Raw | ConvertFrom-StringData
$project | Format-Table Name, Value

# install / update powershellget
if (!(Get-PackageProvider -Name NuGet)) { Install-PackageProvider -Name NuGet -Force -Confirm:$false }
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name PowerShellGet -Confirm:$false
Update-ModuleManifest -Path $PSScriptRoot/../$env:CI_PROJECT_TITLE/$env:CI_PROJECT_TITLE.psd1 -ModuleVersion "$VERSION" -PreRelease "-pre$($env:CI_PIPELINE_IID)"
Publish-Module -Name $PSScriptRoot/../$env:CI_PROJECT_TITLE -NuGetApiKey $env:NUGET_API_KEY_2020 -Verbose -Force -AllowPrerelease
