
function Get-WaykClientCommand
{
    [CmdletBinding()]
    param()

    $WaykClientCommand = $null

	if ($IsLinux) {
        $Command = Get-Command 'wayk-client' -ErrorAction SilentlyContinue

        if ($Command) {
            $WaykClientCommand = $Command.Source
        }
    } elseif ($IsMacOS) {
        $Command = Get-Command 'wayk-client' -ErrorAction SilentlyContinue

        if ($Command) {
            $WaykClientCommand = $Command.Source

            $FileItem = Get-Item $WaykClientCommand -Force -ErrorAction 'SilentlyContinue'
            if ($FileItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $WaykClientCommand = $FileItem.Target # resolve symlink
            }
        } else {
            $WaykClientAppExe = "/Applications/WaykClient.app/Contents/MacOS/WaykClient"

            if (Test-Path -Path $WaykClientAppExe -PathType Leaf) {
                $WaykClientCommand = $WaykClientAppExe
            }
        }
    } else { # IsWindows
        $DisplayName = 'Wayk Client'

		$UninstallReg = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" `
            | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -Match $DisplayName }
            
		if (-Not $UninstallReg) {
			$UninstallReg = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" `
				| ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -Match $DisplayName }
        }
        
        if ($UninstallReg) {
            $InstallLocation = $UninstallReg.InstallLocation
            $WaykClientCommand = Join-Path -Path $InstallLocation -ChildPath "WaykClient.exe"
        }
	}
    
    return $WaykClientCommand
}

function Get-WaykClientProcess
{
    [CmdletBinding()]
    param()

    $WaykClientProcess = $null

	if (Get-IsWindows -Or $IsMacOS) {
        $WaykClientProcess = $(Get-Process | Where-Object -Property ProcessName -Like 'WaykClient')
	} elseif ($IsLinux) {
        $WaykClientProcess = $(Get-Process | Where-Object -Property ProcessName -Like 'wayk-client')
	}

    return $WaykClientProcess
}

function Start-WaykClient
{
    [CmdletBinding()]
    param()

    $Command = Get-WaykClientCommand

    if ($Command) {
        Start-Process $Command
    }
}

function Stop-WaykClient
{
    [CmdletBinding()]
    param()

    $WaykClientProcess = Get-WaykClientProcess

    if ($WaykClientProcess) {
        Stop-Process $WaykClientProcess.Id
    }
}

function Restart-WaykClient
{
    [CmdletBinding()]
    param()

    Stop-WaykClient
    Start-WaykClient
}
