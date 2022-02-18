
function Get-WindowsHostArch
{
    if (($Env:PROCESSOR_ARCHITECTURE -eq 'ARM64') -or ($Env:PROCESSOR_ARCHITEW6432 -eq 'ARM64')) {
        return "ARM64"
    } else {
        if ([System.Environment]::Is64BitOperatingSystem) {
            return "x64"
        } else {
            return "x86"
        }
    }
}

function Get-UninstallRegistryKey(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $DisplayName)
{
    $UninstallReg = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" `
        | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -Match $DisplayName }
    
    if (-Not $UninstallReg) {
        $UninstallReg = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" `
            | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -Match $DisplayName }
    }

    $UninstallReg
}

function New-TemporaryDirectory()
{
	$Parent = [System.IO.Path]::GetTempPath()
	$Name = [System.IO.Path]::GetRandomFileName()
	return New-Item -ItemType Directory -Path (Join-Path $Parent $Name)
}
