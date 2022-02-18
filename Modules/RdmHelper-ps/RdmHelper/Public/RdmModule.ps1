
function Import-RdmModule
{
    [CmdletBinding()]
    param(
    )
    
    $InstallPath = Get-RdmPath 'InstallPath'
    $ManifestFile = Join-Path $InstallPath "RemoteDesktopManager.PowerShellModule.psd1"
    Import-Module $ManifestFile -Scope 'Global'
}
