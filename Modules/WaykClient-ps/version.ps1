
$ManifestFile = $(@(Get-ChildItem -Path $PSScriptRoot -Depth 1 -Filter "*.psd1")[0])
$Manifest = Import-PowerShellDataFile -Path $ManifestFile

$ModuleVersion = $Manifest.ModuleVersion
$Prerelease = $Manifest.PrivateData.PSData.Prerelease

if ($Prerelease) {
	$FullVersion = "${ModuleVersion}-${Prerelease}"
} else {
	$FullVersion = "${ModuleVersion}"
}

Write-Host $FullVersion
