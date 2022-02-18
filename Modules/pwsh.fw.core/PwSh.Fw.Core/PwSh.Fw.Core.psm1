<#

    .SYNOPSIS
    PwSh.Fw main module : PwSh.Fw.Core

	.DESCRIPTION
	PwSh.Fw.Core contains generic purpose functions.

    .NOTES
		Author: Charles-Antoine Degennes <cadegenn@gmail.com>

#>

# handle $IsWindows prior to Powershell 6
if ($PSVersionTable.PSVersion.Major -lt 6) {
	# Powershell 1-5 is only on windows
	$Global:IsWindows = $true
}

<#
    .SYNOPSIS
    Template function

    .DESCRIPTION
    Skeleton of a typical function to use un PwSh.Fw.Core

    .PARAMETER string
    a string

    .EXAMPLE
    New-TemplateFunction -string "a string"

	.NOTES
	General notes

	.LINK
	https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function New-TemplateFunction {
	[CmdletBinding()]
	[OutputType([System.String])]
	Param (
		[Parameter(Mandatory,ValueFromPipeLine = $true)][string]$string
    )
    Begin {
        Write-EnterFunction
    }

    Process {
		return $string
    }

    End {
        Write-LeaveFunction
    }
}

function Set-PwShFwConfiguration {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[Alias('Devel')]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$dev,
		[Alias('Debug_')]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$d,
		[Alias('Verbose_')]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$v,
		[Alias('Info_')]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$i,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$Trace,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$Ask,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$Quiet,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$Log,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][switch]$OverridePSPreferences
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		$Global:INFO = $i
		$Global:VERBOSE = $v
		$Global:DEBUG = $d
		$Global:DEVEL = $dev
		$Global:TRACE = $trace
		$Global:ASK = $ask
		$Global:QUIET = $quiet
		$Global:LOG = $log
		# keep the order as-is please !
		$Script:oldDebugPreference = $DebugPreference
		$Script:oldVerbosePreference = $VerbosePreference
		$Script:oldInformationPreference = $InformationPreference
		if ($ASK)   { Set-PSDebug -Step }
		if ($TRACE) {
			# Set-PSDebug -Trace 1
			$Global:DEVEL = $true
		}
		if ($DEVEL) {
			$Global:DEBUG = $true;
		}
		if ($DEBUG) {
			# $DebugPreference= ( $OverridePSPreferences ? "Continue" : "SilentlyContinue")
			if ($OverridePSPreferences) { $DebugPreference = "Continue" } else { $DebugPreference = "SilentlyContinue" }
			$Global:VERBOSE = $true
		}
		if ($VERBOSE) {
			# $VerbosePreference= ( $OverridePSPreferences ? "Continue" : "SilentlyContinue")
			if ($OverridePSPreferences) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
			$Global:INFO = $true
		}
		if ($INFO) {
			# $InformationPreference= ( $OverridePSPreferences ? "Continue" : "SilentlyContinue")
			if ($OverridePSPreferences) { $InformationPreference = "Continue" } else { $InformationPreference = "SilentlyContinue" }
		}
		if ($QUIET) {
			$Global:DEVEL = $false
			$Global:DEBUG = $false;
			$Global:VERBOSE = $false
			$Global:INFO = $false
			# $DebugPreference= ( $OverridePSPreferences ? "SilentlyContinue" : "SilentlyContinue")
			# $VerbosePreference= ( $OverridePSPreferences ? "SilentlyContinue" : "SilentlyContinue")
			# $InformationPreference= ( $OverridePSPreferences ? "SilentlyContinue" : "SilentlyContinue")
			if ($OverridePSPreferences) { $DebugPreference = "Continue" } else { $DebugPreference = "SilentlyContinue" }
			if ($OverridePSPreferences) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
			if ($OverridePSPreferences) { $InformationPreference = "Continue" } else { $InformationPreference = "SilentlyContinue" }
		}

		if ($log) {
			if ($TRACE) {
				Start-Transcript -Path $log
			# } else {
			# 	# add -Append:$false to overwrite logfile
			# 	# Write-ToLogFile -Message "Initialize log" -Append:$false
			# 	Write-ToLogFile -Message "Initialize log"
			}
			$null = Load-Module -Name PwSh.Fw.Log -Quiet -Policy Required
		 	Write-ToLogFile -Message "Initialize log"
		}
	}

	End {
		Write-LeaveFunction
	}
}

<#
.SYNOPSIS
Reset PwSh Framework to default configuration

.DESCRIPTION
Reset all configurations previously set by Set-PwShFwConfiguration

.EXAMPLE
Reset-PwShFwConfiguration

#>
function Reset-PwShFwConfiguration {
	[CmdletBinding()]
	[OutputType([void])]
	Param (
		# [Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$string
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		if ($Global:TRACE -and $Global:LOG) {
			Stop-Transcript
		}

		$Global:INFO = $false
		$Global:VERBOSE = $false
		$Global:DEBUG = $false
		$Global:DEVEL = $false
		$Global:TRACE = $false
		$Global:ASK = $false
		$Global:QUIET = $false
		$Global:LOG = $null

		$DebugPreference = $Script:oldDebugPreference
		$VerbosePreference = $Script:oldVerbosePreference
		$InformationPreference = $Script:oldInformationPreference
	}

	End {
		Write-LeaveFunction
	}
}

function Get-PwShFwConfiguration {
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		Write-Message "INFO     = $($Global:INFO)"
		Write-Message "VERBOSE  = $($Global:VERBOSE)"
		Write-Message "DEBUG    = $($Global:DEBUG)"
		Write-Message "DEVEL    = $($Global:DEVEL)"
		Write-Message "TRACE    = $($Global:TRACE)"
		Write-Message "ASK      = $($Global:ASK)"
		Write-Message "QUIET    = $($Global:QUIET)"
		Write-Message "LOG      = $($Global:LOG)"
	}

	End {
		Write-LeaveFunction
	}
}

# function Get-PwShFwModuleInfos {
# 	[CmdletBinding()][OutputType([String])]Param (
# 		# [Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$string
# 	)
# 	Begin {
# 		# eenter($Script:NS + '\' + $MyInvocation.MyCommand)
# 	}

# 	Process {
# 		Write-Output "PSCommandPath = $PSCommandPath"
# 		Write-Output "PSScriptRoot = $PSScriptRoot"
# 	}

# 	End {
# 		# eleave($Script:NS + '\' + $MyInvocation.MyCommand)
# 	}
# }

<#
	.SYNOPSIS
	Execute a DOS/Shell command.

	.DESCRIPTION
	Wrapper for executing a DOS/Shell command. It handle (not yet) logging, (not yet) simulating and (not yet) asking.
	Please use following syntax :
	$rc = Execute-Commande "commande.exe" "arguments"
	to catch return code. Otherwise it will be printed to stdout and its quite ugly.

    .PARAMETER exe
    full path to executable

    .PARAMETER args
	all arguments enclosed in double-quotes. You may have to escape inner quotes to handle args with special characters.

	.PARAMETER AsInt
	Return code will be an int instead of a boolean.

	.EXAMPLE
	$rc = Execute-Command "net" "use w: \\srv\share"

	.EXAMPLE
	$rc = Execute-Command -exe "net" -args "use w: \\srv\share"

	.LINK
	https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function Execute-Command() {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Execute-Command is a more intuitive verb for this function and does not conflict with default Invoke-Command cmdlet.")]
	param(
        [parameter(mandatory=$true, position=0)][string]$exe,
		[parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)][string]$args,
		[switch]$AsInt
    )

	$cmd = Get-Command -Name "$exe"
	switch ($cmd.CommandType) {
		'Application' {
			$exe = "& '" + $exe + "'"
			break
		}
		'ExternalScript' {
			$exe = "& '" + $exe + "'"
			break
		}
		'Cmdlet' {

		}
		default {

		}
	}

    Write-Debug "$exe $args`n"
	# $rcFile = $([System.IO.Path]::GetTempPath() + [IO.Path]::DirectorySeparatorChar + "rc")
	$rcFile = $([System.IO.Path]::GetTempPath() + "rc")
	# edevel("rcFile = $rcFile")
	# try {
		# if ($Global:DEVEL) {
		# 	if ($AsInt) {
		# 		Invoke-Expression ("$exe $args; `$LastExitCode | Out-File '$rcFile'") | Foreach-Object { Write-Devel $_ }
		# 	} else {
		# 		Invoke-Expression ("$exe $args; `$? | Out-File '$rcFile'") | Foreach-Object { Write-Devel $_ }
		# 	}
		# 	#return $?
		# } elseif ($Global:DEBUG) {
		# 	if ($AsInt) {
		# 		Invoke-Expression ("$exe $args; `$LastExitCode | Out-File '$rcFile'") | Out-Null
		# 	} else {
		# 		Invoke-Expression ("$exe $args; `$? | Out-File '$rcFile'") | Out-Null
		# 	}
		# 	#return $?
		# } else {
		# 	if ($AsInt) {
		# 		Invoke-Expression ("$exe $args; `$LastExitCode | Out-File '$rcFile'") | Out-Null
		# 	} else {
		# 		Invoke-Expression ("$exe $args; `$? | Out-File '$rcFile'") | Out-Null
		# 	}
		# 	#return $?
		# }
		if ($AsInt) {
			$out = Invoke-Expression ("$exe $args; `$LastExitCode | Out-File '$rcFile'")
		} else {
			$out = Invoke-Expression ("$exe $args; `$? | Out-File '$rcFile'")
		}
		if ($Global:DEVEL) {
			$out | Foreach-Object { Write-Devel $_ }
		# } elseif ($Global:DEBUG) {
		# 	$out | Foreach-Object { Write-MyDebug $_ }
		}
		# $rc = Get-Content "$rcFile" -Raw
		# # edevel("rc = $rc")
		# Remove-Item "$rcFile"
		# # edevel("return $rc")
		# # if ($null -ne $rc) {
			# return $rc
		# } else {
		# 	return $false
		# }
	# 	return $true
	# } catch {
	# 	return $false
	# }
	if ($AsInt) {
		return Get-Content "$rcFile" -Raw
	} else {
		return Get-Content "$rcFile" | Resolve-Boolean
	}
}

<#
	.SYNOPSIS
	Wrapper for Import-Module

	.DESCRIPTION
	It handle everything to not worry about error messages.
	* check if module exist in module path
	* if an absolute filename is given, check if module exist as well as manifest
	* load-it with an optional $Force parameter
	* write a warning if module cannot be found

	.PARAMETER Name
	Name of the module to load

	.PARAMETER FullyQualifiedName
	Absolute path and name of the module to load. It can be either the manifest file (.psd1) or the module file (.psm1)

	.PARAMETER Force
	Force a reload if module is already loaded

	.LINK
	https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function Load-Module {
    [CmdletBinding(
		DefaultParameterSetName="NAME"
	)]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Load-Module is a more intuitive verb for this function and does not conflict with default Get-Module cmdlet.")]
	Param (
		[Parameter(ParameterSetName="NAME",Mandatory,ValueFromPipeLine = $true)]
		[string]$Name,
		[Parameter(ParameterSetName="FILENAME",Mandatory,ValueFromPipeLine = $true)]
		[string]$FullyQualifiedName,
		[switch]$Force,
		[ValidateSet('Required', 'Optional')]
		[string]$Policy = "Required",
		[switch]$Quiet
    )
    Begin {
        # eenter($MyInvocation.MyCommand)
    }

    Process {
		if ($Quiet) {
			$oldQuiet = $Global:QUIET
			$Global:QUIET = $true
		}
		switch ($PSCmdlet.ParameterSetName) {
			"NAME" {
				$module = Get-Module -ListAvailable $Name | Sort-Object -Property Version | Select-Object -Last 1
				if ($null -eq $module) {
					# fake module to display correct informations
					# PowerShell < 5 does not return anything
					$module = @{ name = $Name; path = $null}
				}
				break
			}
			"FILENAME" {
				$module = Get-Module -ListAvailable $FullyQualifiedName -ErrorAction Ignore | Sort-Object -Property Version | Select-Object -Last 1
				if ($null -eq $module) {
					# fake module to display correct informations
					# PowerShell < 5 does not return anything
					$module = @{ name = (Split-Path -Leaf $FullyQualifiedName); path = $FullyQualifiedName}
				}
				break
			}
		}

		# exit if module is already loaded
		$rc = Get-Module -Name $module.Name
		if ($null -ne $rc) {
			if ($Force -eq $false) {
				Write-Debug "Module $($module.name) already loaded..."
				if ($Quiet) { $Global:QUIET = $oldQuiet	}
				return $true
			}
		}

		if ($Global:VERBOSE) {
			if ($Global:DEBUG) {
				Write-Debug "Importing module $($module.name) from '$($module.Path)'"
			} else {
				Write-Verbose "Importing module $($module.name)"
			}
		}
		switch ($Policy) {
			'Required' {
				$ErrorAction = 'Ignore'
				# $ErrorAction = 'Continue'
			}
			'Optional' {
				$ErrorAction = 'Ignore'
			}
		}

		switch ($PSCmdlet.ParameterSetName) {
			"NAME" {
				Import-Module -Name $module.name -Global -Force:$Force -DisableNameChecking -ErrorAction $ErrorAction
				$rc = $?
				break
			}
			"FILENAME" {
				# -FullyQualifiedName is not supported in PS < 5
				if ($PSVersionTable.PSVersion.Major -lt 5) {
					Import-Module $module.Path -Global -Force:$Force -DisableNameChecking -ErrorAction $ErrorAction
				} else {
					Import-Module -FullyQualifiedName $module.Path -Global -Force:$Force -DisableNameChecking -ErrorAction $ErrorAction
				}
				$rc = $?
				break
			}
		}

		switch ($Policy) {
			'Required' {
				if ($rc -eq $false) {
					efatal("Module $($module.name) was not found and policy is '$Policy'.")
				}
			}
			'Optional' {
			}
		}

		if ($Global:VERBOSE) {
			eend $rc
		}

		if ($Quiet) { $Global:QUIET = $oldQuiet	}

		return $rc
    }

    End {
        # eleave($MyInvocation.MyCommand)
    }
}

<#
	.SYNOPSIS
	Test if a registry property exist

	.DESCRIPTION
	There is not yet a builtin function to test existence of registry value. Thanks to Jonathan Medd, here it is.

	.PARAMETER RegPath
	Registry path to the key

	.EXAMPLE
	Test-RegKeyExist -RegPath HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion

	.NOTES
	General notes

	.LINK
	https://www.jonathanmedd.net/2014/02/testing-for-the-presence-of-a-registry-key-and-value.html
#>

function Test-RegKeyExist {
	param (
		[Alias('Path')]
		[parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$RegPath
	)

	Test-Path -Path $RegPath -PathType Container
}

<#
	.SYNOPSIS
	Test if a registry property exist

	.DESCRIPTION
	There is not yet a builtin function to test existence of registry value. Thanks to Jonathan Medd, here it is.

	.PARAMETER RegPath
	Registry path to the key

	.PARAMETER Name
	Name of the value to test

	.EXAMPLE
	Test-RegValueExist -RegPath HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Value ProgramFilesDir

	.NOTES
	General notes

	.LINK
	https://www.jonathanmedd.net/2014/02/testing-for-the-presence-of-a-registry-key-and-value.html
#>

function Test-RegValueExist {
	param (
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$RegPath,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$Name
	)

	try {
		$null = Get-ItemProperty -Path $RegPath | Select-Object -ExpandProperty $Name -ErrorAction Stop
		return $true
	} catch {
		return $false
	}
}

<#
    .SYNOPSIS
    Test if a variable exist

    .DESCRIPTION
    This function is silent and only return $true if the variable exist or $false otherwise.

    .PARAMETER Name
    a variable name to test

    .EXAMPLE
    Test-Variable -Name "myvar"

	.LINK
	https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function Test-Variable {
    [CmdletBinding()]Param (
		[Parameter(Mandatory,ValueFromPipeLine = $true)][string]$Name
    )
    Begin {
        # eenter($MyInvocation.MyCommand)
    }

    Process {
		Get-Variable -Name $Name -ErrorAction SilentlyContinue | Out-Null
		return $?
    }

    End {
        # eleave($MyInvocation.MyCommand)
    }
}

<#
.SYNOPSIS
Get a property value from a file

.DESCRIPTION
Get a property value from a file. The content of the file must be in the StringData format

.PARAMETER Filename
Path and name of the file to fetch data from

.PARAMETER Propertyname
Property to fetch

.EXAMPLE
Get-PropertyValueFromFile -Filename ./project.conf -PropertyName Version

.NOTES
General notes

.LINK
https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function Get-PropertyValueFromFile {
    [CmdletBinding()]Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Filename,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Propertyname
    )
    Begin {
        # eenter($MyInvocation.MyCommand)
    }

    Process {
        $value = (Get-Content $Filename -Raw | ConvertFrom-StringData).$Propertyname
        # trim quotes
        $value = $value -replace "'", "" -replace '"', ''
		return $value
    }

    End {
        # eleave($MyInvocation.MyCommand)
    }
}

<#
.SYNOPSIS
Add a custom path to the PSModulePath environment variable.

.DESCRIPTION
Add a custom path to the PSModulePath environment variable.

.PARAMETER Path
Path to add

.PARAMETER First
If specified, add the Path at the beginning of PSModulePath

.EXAMPLE
Add-PSModulePath -Path c:\MyProject\MyModules

.EXAMPLE
"C:\MyProject\MyModules" | Add-PSModulePath -First

.NOTES
General notes

.LINK
https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function Add-PSModulePath {
	[CmdletBinding()]Param (
		[Parameter(Mandatory,ValueFromPipeLine = $true)][string]$Path,
		[switch]$First
	)
	Begin {
		# eenter($Script:NS + '\' + $MyInvocation.MyCommand)
	}

	Process {
		try {
			$current = [Environment]::GetEnvironmentVariable('PSModulePath')
			if ($First) {
				$newpath = $PATH + [IO.Path]::PathSeparator + $env:PSModulePath
			} else {
				$newpath = $env:PSModulePath + [IO.Path]::PathSeparator + $PATH
			}
			[Environment]::SetEnvironmentVariable('PSModulePath', $newpath)
			Write-Devel "PSModulePath = $([Environment]::GetEnvironmentVariable('PSModulePath'))"
		} catch {
			ewarn($_.Exception.ItemName + ": " + $_.Exception.Message)
		}
		# edevel("env:PSModulePath = " + $env:PSModulePath)
	}

	End {
		# eleave($Script:NS + '\' + $MyInvocation.MyCommand)
	}
}

<#
    .SYNOPSIS
    Convert a config file in a Hashtable of "key = value" pair

    .DESCRIPTION
	At this time, supported configuration files are
    .yml    containing a list of "key: value" in the YAML language
    .txt    containing a list of "key = value" pair (can be .conf or .whatever)

    .PARAMETER File
    Complete path and filename of a file containing key=value pairs

    .EXAMPLE
    $conf = ConvertFrom-ConfigFile "./config.conf"
    This example will load all "key = value" pair into the $conf object

#>
function ConvertFrom-ConfigFile {
    [CmdletBinding()][OutputType([Hashtable])]Param (
        [Parameter(Mandatory = $true,ValueFromPipeLine = $true)][string]$File
    )
    Begin {
    }

    Process {
        if (-not(fileExist $File)) {
            eerror("Config file '" + $File + "' not found.")
            return @{}
        }
        $item = Get-Item $File
        switch ($item.extension) {
			'.yaml' {
				$conf = Get-Content $File -Raw | ConvertFrom-Yaml
			}
			'.yml' {
				$conf = Get-Content $File -Raw | ConvertFrom-Yaml
			}
            default {
                $conf = Get-Content $File | ConvertFrom-StringData
                if ($conf.Keys.Count -gt 0) {
                    $conf = $conf.Keys | ForEach-Object { $c = @{} } { $c[$_] = $conf.$_.Trim('"') } { $c }
                } else {
                    $conf = @{}
                }
            }
        }

        return $conf
    }

    End {
    }
}

<#
.SYNOPSIS
Helper function for argument completer

.DESCRIPTION
Get valid values from a path to use with ArgumentCompleter object

.PARAMETER Path
Path to search in

.PARAMETER Filter
Optional filter to pass to Get-ChildItem

.EXAMPLE
[ArgumentCompleter(
	{
		param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
		Get-ValidValuesFromPath -Path "/my/path" | Where-Object { $_ -like "$wordToComplete*" }
	}
)]
[ValidateScript(
	{
		$_ -in (Get-ValidValuesFromPath -Path "/my/path")
	}
)]

.NOTES
General notes
#>
function Get-ValidValuesFromPath {
    [CmdletBinding()]
    param($Path, $Filter)

    (Get-ChildItem -Path $Path -File -Filter $Filter).Name
}

Set-Alias -Force -Name eexec		-Value Execute-Command
Set-Alias -Force -Name fileExist	-Value Test-FileExist
Set-Alias -Force -Name dirExist		-Value Test-DirExist
Set-Alias -Force -Name regKeyExist	-Value Test-RegKeyExist
Set-Alias -Force -Name regValueExist	-Value Test-RegValueExist
Set-Alias -Force -Name varExist		-Value Test-Variable

# Export-ModuleMember -Function * -Alias *
