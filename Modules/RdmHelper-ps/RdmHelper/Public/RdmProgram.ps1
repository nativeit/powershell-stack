
function Get-RdmCommand
{
    [CmdletBinding()]
    param(
        [ValidateSet("Free","Enterprise")]
		[string] $Edition = "Enterprise",
        [ValidateSet("x86","x64")]
        [string] $Architecture
    )

    $RdmCommand = $null

	if ($IsLinux) {
		$ExecutableName = if ($Edition -eq 'Enterprise') {
			"remotedesktopmanager"
		} else {
			"remotedesktopmanager.free"
		}

        $Command = Get-Command $ExecutableName -ErrorAction SilentlyContinue

        if ($Command) {
            $RdmCommand = $Command.Source
        }
    } elseif ($IsMacOS) {
        $Command = Get-Command 'RemoteDesktopManager' -ErrorAction SilentlyContinue

        if ($Command) {
            $RdmCommand = $Command.Source
        } else {
            $RdmAppExe = "/Applications/Remote Desktop Manager.app/Contents/MacOS/RemoteDesktopManager"

            if (Test-Path -Path $RdmAppExe -PathType Leaf) {
                $RdmCommand = $RdmAppExe
            }
        }
    } else { # IsWindows
        if (-Not $Architecture) {
            $HostArch = Get-WindowsHostArch
            $Architecture = 'x64'

            if ($HostArch -eq 'ARM64') {
                $Architecture = 'x86' # default to x86 emulation for ARM64
            }
        }

        if ($Architecture -eq 'x64') {
            $ExecutableName = "RemoteDesktopManager64.exe"
        } else {
            $ExecutableName = "RemoteDesktopManager.exe"
        }

        $DisplayName = 'Remote Desktop Manager'
        $UninstallReg = Get-UninstallRegistryKey $DisplayName
        
        if ($UninstallReg) {
            $InstallLocation = $UninstallReg.InstallLocation
            $RdmCommand = Join-Path $InstallLocation $ExecutableName
        }
	}
    
    return $RdmCommand
}

function Get-RdmProcess
{
    [CmdletBinding()]
    param()

    $RdmProcess = $null

	if ($IsLinux) {
        $RdmProcess = $(Get-Process | Where-Object -Property ProcessName -Like 'remotedesktopmanager')

        if (-Not $RdmProcess) {
            $RdmProcess = $(Get-Process | Where-Object -Property ProcessName -Like 'remotedesktopmanager.free')
        }
	} elseif ($IsMacOS) {
        # Workaround for macOS limitation where process names are truncated to 15 characters
        $TruncatedProcessName = 'RemoteDesktopManager'.Substring(0,14) + '*'
        $RdmProcess = $(Get-Process | Where-Object -Property ProcessName -Like $TruncatedProcessName)
    } else { # IsWindows
        $RdmProcess = $(Get-Process | Where-Object -Property ProcessName -Like 'RemoteDesktopManager64')

        if (-Not $RdmProcess) {
            $RdmProcess = $(Get-Process | Where-Object -Property ProcessName -Like 'RemoteDesktopManager')
        }
    }

    return $RdmProcess
}

function Start-RdmProcess
{
    [CmdletBinding()]
    param()

    $Command = Get-RdmCommand

    if ($Command) {
        Start-Process $Command
    }
}

function Stop-RdmProcess
{
    [CmdletBinding()]
    param()

    $RdmProcess = Get-RdmProcess

    if ($RdmProcess) {
        Stop-Process $RdmProcess.Id
    }
}

function Restart-RdmProcess
{
    [CmdletBinding()]
    param()

    Stop-RdmProcess
    Start-RdmProcess
}
