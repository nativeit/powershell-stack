. "$PSScriptRoot/../Private/PlatformHelpers.ps1"

function Get-RdmVersion
{
    [CmdletBinding()]
    param(
		[ValidateSet("Free","Enterprise")]
		[string] $Edition = "Enterprise"
	)

	if ($IsWindows) {
		$UninstallReg = Get-UninstallRegistryKey 'Remote Desktop Manager'
		if ($UninstallReg) {
			$Version = $UninstallReg.DisplayVersion
			return $Version
		}
	} elseif ($IsMacOS) {
		$InfoPlistPath = "/Applications/Remote Desktop Manager.app/Contents/Info.plist"
		$CFBundleVersionXpath = "//dict/key[. ='CFBundleVersion']/following-sibling::string[1]"
		if (Test-Path -Path $InfoPlistPath) {
			$InfoPlistXml = [Xml] $(& 'plutil' '-convert' 'xml1' $InfoPlistPath '-o' '-')
			$Version = $(Select-Xml -Xml $InfoPlistXml -XPath $CFBundleVersionXpath `
				| Foreach-Object {$_.Node.InnerXML }).Trim()
			return $Version
		}
	} elseif ($IsLinux) {
		$PackageName = if ($Edition -eq 'Enterprise') {
			"remotedesktopmanager"
		} else {
			"remotedesktopmanager.free"
		}
		$DpkgStatus = $(dpkg -s $PackageName)
		$DpkgMatches = $($DpkgStatus | Select-String -AllMatches -Pattern 'version: (\S+)').Matches
		if ($DpkgMatches) {
			$Version = $DpkgMatches.Groups[1].Value
			return $Version
		}
	}

	return $null
}

function Get-RdmPackage
{
    [CmdletBinding()]
    param(
		[string] $RequiredVersion,
		[ValidateSet("Windows","macOS","Linux")]
		[string] $Platform,
		[ValidateSet("Free","Enterprise")]
		[string] $Edition = "Enterprise"
	)

	$VersionQuad = '';
	$ProductsUrl = "https://devolutions.net/productinfo.htm"

	if ($Env:RDM_PRODUCT_INFO_URL) {
		$ProductsUrl = $Env:RDM_PRODUCT_INFO_URL
	}

	$ProductsHtm = Invoke-RestMethod -Uri $ProductsUrl -Method 'GET' -ContentType 'text/plain'

	if ($Edition -eq 'Enterprise') {
		$VersionMatches = $($ProductsHtm | Select-String -AllMatches -Pattern "RDM.Version=(\S+)").Matches
	} else {
		$VersionMatches = $($ProductsHtm | Select-String -AllMatches -Pattern "RDMFree.Version=(\S+)").Matches
	}

	$LatestVersion = $VersionMatches.Groups[1].Value

	if ($RequiredVersion) {
		if ($RequiredVersion -Match "^\d+`.\d+`.\d+$") {
			$RequiredVersion = $RequiredVersion + ".0"
		}
		$VersionQuad = $RequiredVersion
	} else {
		$VersionQuad = $LatestVersion
	}

	$VersionMatches = $($VersionQuad | Select-String -AllMatches -Pattern "(\d+)`.(\d+)`.(\d+)`.(\d+)").Matches
	$VersionMajor = $VersionMatches.Groups[1].Value
	$VersionMinor = $VersionMatches.Groups[2].Value
	$VersionPatch = $VersionMatches.Groups[3].Value
	$VersionTriple = "${VersionMajor}.${VersionMinor}.${VersionPatch}"

	$RdmMatches = $($ProductsHtm | Select-String -AllMatches -Pattern "(RDM\S+).Url=(\S+)").Matches

	if ($Edition -eq 'Enterprise') {
		$RdmWindows = $RdmMatches | Where-Object { $_.Groups[1].Value -eq 'RDMmsi' }
		$RdmMacOS = $RdmMatches | Where-Object { $_.Groups[1].Value -eq 'RDMMacbin' }
		$RdmLinux = $RdmMatches | Where-Object { $_.Groups[1].Value -eq 'RDMLinuxbin' }
	} elseif ($Edition -eq 'Free') {
		$RdmWindows = $RdmMatches | Where-Object { $_.Groups[1].Value -eq 'RDMFreemsi' }
		$RdmMacOS = $RdmMatches | Where-Object { $_.Groups[1].Value -eq 'RDMMacFreebin' }
		$RdmLinux = $RdmMatches | Where-Object { $_.Groups[1].Value -eq 'RDMLinuxFreebin' }
	}

	if ($RdmWindows) {
		$DownloadUrlWindows = $RdmWindows.Groups[2].Value
	}

	if ($RdmMacOS) {
		$DownloadUrlMacOS = $RdmMacOS.Groups[2].Value
	}
	
	if ($RdmLinux) {
		$DownloadUrlLinux = $RdmLinux.Groups[2].Value
	}

	$DownloadUrl = $null

	if (-Not $Platform) {
		if ($IsLinux) {
			$Platform = 'Linux'
		} elseif ($IsMacOS) {
			$Platform = 'macOS'
		} else {
			$Platform = 'Windows'
		}
	}

	if ($Platform -eq 'Windows') {
		$DownloadUrl = $DownloadUrlWindows
	} elseif ($Platform -eq 'macOS') {
		$DownloadUrl = $DownloadUrlMacOS
	} elseif ($Platform -eq 'Linux') {
		$DownloadUrl = $DownloadUrlLinux
	}

	if ($RequiredVersion) {
		# both variables are in quadruple version format
		$DownloadUrl = $DownloadUrl -Replace $LatestVersion, $RequiredVersion
	}
 
    $result = [PSCustomObject]@{
        Url = $DownloadUrl
        Version = $VersionTriple
    }

	return $result
}

function Install-RdmPackage
{
    [CmdletBinding()]
    param(
		[ValidateSet("Free","Enterprise")]
		[string] $Edition = "Enterprise",
		[string] $RequiredVersion,
		[switch] $NoDesktopShortcut,
		[switch] $NoStartMenuShortcut,
		[switch] $Quiet,
		[switch] $Force
	)

	$TempDirectory = New-TemporaryDirectory
	$Package = Get-RdmPackage -RequiredVersion:$RequiredVersion -Edition:$Edition
	$LatestVersion = $Package.Version
	$CurrentVersion = Get-RdmVersion

	if (([version]$LatestVersion -gt [version]$CurrentVersion) -Or $Force) {
		Write-Host "Installing Remote Desktop Manager ${Edition} ${LatestVersion}"
	} else {
		Write-Host "Remote Desktop Manager is already up to date"
		return
	}

	$DownloadUrl = $Package.url
	$DownloadFile = Split-Path -Path $DownloadUrl -Leaf
	$DownloadFilePath = Join-Path $TempDirectory $DownloadFile
	Write-Host "Downloading $DownloadUrl"

	$WebClient = [System.Net.WebClient]::new()
	$WebClient.DownloadFile($DownloadUrl, $DownloadFilePath)
	$WebClient.Dispose()
	
	$DownloadFilePath = Resolve-Path $DownloadFilePath

	if (([version]$CurrentVersion -gt [version]$LatestVersion) -And $Force)
	{
		Uninstall-RdmPackage -Edition:$Edition -Quiet:$Quiet
	}

	if ($IsWindows) {
		$Display = '/passive'
		if ($Quiet){
			$Display = '/quiet'
		}
		$InstallLogFile = Join-Path $TempDirectory "RDM_Install.log"
		$MsiArgs = @(
			'/i', "`"$DownloadFilePath`"",
			$Display,
			'/norestart',
			'/log', "`"$InstallLogFile`""
		)
		if ($NoDesktopShortcut){
			$MsiArgs += "INSTALLDESKTOPSHORTCUT=`"`""
		}
		if ($NoStartMenuShortcut){
			$MsiArgs += "INSTALLSTARTMENUSHORTCUT=`"`""
		}

		Start-Process "msiexec.exe" -ArgumentList $MsiArgs -Wait -NoNewWindow

		Remove-Item -Path $InstallLogFile -Force -ErrorAction SilentlyContinue
	} elseif ($IsMacOS) {
		$VolumesPath = "/Volumes/Remote Desktop Manager.app Installer"
		if (Test-Path -Path $VolumesPath -PathType 'Container') {
			Start-Process 'hdiutil' -ArgumentList @('unmount', "`"$VolumesPath`"") -Wait
		}
		Start-Process 'hdiutil' -ArgumentList @('mount', "`"$DownloadFilePath`"") `
			-Wait -RedirectStandardOutput '/dev/null'
		Wait-Process $(Start-Process 'sudo' -ArgumentList @('cp', '-R', `
			"`"${VolumesPath}/Remote Desktop Manager.app`"", "/Applications") -PassThru).Id
		Start-Process 'hdiutil' -ArgumentList @('unmount', "`"$VolumesPath`"") `
			-Wait -RedirectStandardOutput '/dev/null'
	} elseif ($IsLinux) {
		$DpkgArgs = @(
			'-i', $DownloadFilePath
		)
		if ((id -u) -eq 0) {
			Start-Process 'dpkg' -ArgumentList $DpkgArgs -Wait
		} else {
			$DpkgArgs = @('dpkg') + $DpkgArgs
			Start-Process 'sudo' -ArgumentList $DpkgArgs -Wait
		}
	}

	Remove-Item -Path $TempDirectory -Force -Recurse
}

function Uninstall-RdmPackage
{
    [CmdletBinding()]
    param(
		[ValidateSet("Free","Enterprise")]
		[string] $Edition = "Enterprise",
		[switch] $Quiet
	)
	
	Stop-RdmProcess
	
	if ($IsWindows) {
		$UninstallReg = Get-UninstallRegistryKey 'Remote Desktop Manager'
		if ($UninstallReg) {
			$UninstallString = $($UninstallReg.UninstallString `
				-Replace "msiexec.exe", "" -Replace "/I", "" -Replace "/X", "").Trim()
			$Display = '/passive'
			if ($Quiet){
				$Display = '/quiet'
			}
			$MsiArgs = @(
				'/X', $UninstallString, $Display
			)
			Start-Process "msiexec.exe" -ArgumentList $MsiArgs -Wait
		}
	} elseif ($IsMacOS) {
		$RdmAppPath = "/Applications/Remote Desktop Manager.app"
		if (Test-Path -Path $RdmAppPath -PathType 'Container') {
			Start-Process 'sudo' -ArgumentList @('rm', '-rf', "`"$RdmAppPath`"") -Wait
		}
	} elseif ($IsLinux) {
		if (Get-RdmVersion) {
			$AptArgs = @(
				'-y', 'remove', 'remotedesktopmanager', '--purge'
			)
			if ((id -u) -eq 0) {
				Start-Process 'apt-get' -ArgumentList $AptArgs -Wait
			} else {
				$AptArgs = @('apt-get') + $AptArgs
				Start-Process 'sudo' -ArgumentList $AptArgs -Wait
			}
		}
	}
}

function Update-RdmPackage
{
    [CmdletBinding()]
    param(
		[ValidateSet("Free","Enterprise")]
		[string] $Edition = "Enterprise",
		[switch] $Quiet,
		[switch] $Force
	)

	$ProcessWasRunning = Get-RdmProcess

	try {
		Install-RdmPackage -Force:$Force -Quiet:$Quiet
	}
	catch {
		throw $_
	}

	if ($ProcessWasRunning) {
		Start-RdmProcess
	}
}

function Get-RdmPath()
{
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[ValidateSet("ConfigPath","InstallPath")]
		[string] $PathType = "ConfigPath",
		[ValidateSet("Free","Enterprise")]
		[string] $Edition = "Enterprise"
	)

	$HomePath = Resolve-Path '~'

	if ($PathType -eq 'ConfigPath') {
		if ($IsWindows)	{
			$ConfigPath = $Env:LocalAppData + "\Devolutions\RemoteDesktopManager"
		} elseif ($IsMacOS) {
			$ConfigPath = Join-Path $HomePath "/Library/Application Support/com.devolutions.remotedesktopmanager"
		} elseif ($IsLinux) {
			$ConfigPath = Join-Path $HomePath ".rdm"
		}
	
		if (Test-Path Env:RDM_CONFIG_PATH) {
			$ConfigPath = $Env:RDM_CONFIG_PATH
		}

		return $ConfigPath
	} elseif ($PathType -eq 'InstallPath') {
		if ($IsWindows)	{
			$DisplayName = 'Remote Desktop Manager'
			$UninstallReg = Get-UninstallRegistryKey $DisplayName
			
			if ($UninstallReg) {
				$InstallPath = $UninstallReg.InstallLocation
			}
		} elseif ($IsMacOS) {
			$InstallPath = "/Applications/Remote Desktop Manager.app"
		} elseif ($IsLinux) {
			$InstallPath = "/usr/lib/devolutions/RemoteDesktopManager"
		}
	
		if (Test-Path Env:RDM_INSTALL_PATH) {
			$InstallPath = $Env:RDM_INSTALL_PATH
		}

		return $InstallPath
	}
}
