<#

	.SYNOPSIS
	Update module manifest according to a simple configuration file.

	.DESCRIPTION
	Simply create a file project.conf in a StringData format :
	NAME =
	VERSION =
	AUTHORS =
	OWNERS =
	LICENSEURL =
	URL =
	ICONURL =
	DESCRIPTION =
	TAGS =
	RELEASENOTES =
	COPYRIGHT =

	Then just call update-moduleManifest.ps1 against your module(s) to update its metadata.

	.PARAMETER h
	display help screen. Use Get-Help instead.

	.PARAMETER d
	debug mode

	.PARAMETER dev
	devel mode

	.PARAMETER Force
	This parameter causes a module to be loaded, or reloaded, over top of the current one

	.PARAMETER FullyQualifiedName
	Full path to a module file or module manifest.

	.PARAMETER Path
	Path containing module files or manifests

	.PARAMETER VERSION
	Version number to use. It must be in [system.version] format

	.PARAMETER NuSpec
	This parameter causes this script to also write a .nuspec nuget specification file.

	.PARAMETER RecurseInclude
	This parameter causes this script to recurse through 'Libraries', 'Private', 'Includes' and 'Dictionaries' subfolders to process.
	It will write VERSION, AUTHORS, OWNERS, and all metadata to these modules except DESCRIPTION and NAME.
	The following policies will apply :
	* functions from modules found in Includes subfolder will be exported from main module
	* functions from modules found in Private subfolder will NOT be exported
	* modules found in Libraries or Dictionaries subfolder live on their own : they must be imported explicitely

	.PARAMETER Recurse
	If specified, recurse through PATH parameter to find every module files.

	.NOTES
	Author: Charles-Antoine Degennes <cadegenn@gmail.com>

	.LINK
		https://gitlab.com/pwsh.fw/pwsh.fw.core
#>

[CmdletBinding(DefaultParameterSetName = "FILENAME")]Param(
	[switch]$h,
	[switch]$v,
	[switch]$d,
	[switch]$dev,
	[Parameter(ParameterSetName = "FILENAME", Mandatory = $true,  ValueFromPipeLine = $true)][string]$FullyQualifiedName,
	[Parameter(ParameterSetName = "FILENAME", Mandatory = $false, ValueFromPipeLine = $true)][switch]$RecurseInclude,
	[Parameter(ParameterSetName = "PATH", 	  Mandatory = $true,  ValueFromPipeLine = $true)][string]$Path,
	[Parameter(ParameterSetName = "PATH", 	  Mandatory = $false, ValueFromPipeLine = $true)][switch]$Recurse,
	[switch]$Force,
	[system.version]$Version,
	[switch]$NuSpec
)

$Global:BASENAME = Split-Path -Leaf $MyInvocation.MyCommand.Definition
$Global:VERBOSE = $v
$Global:DEBUG = $d
$Global:DEVEL = $dev
$Global:QUIET = $quiet

if ($h) {
	Get-Help $MyInvocation.MyCommand.Definition
	Exit
}

# keep the order as-is please !
$oldDebugPreference = $DebugPreference
$oldVerbosePreference = $VerbosePreference
$oldInformationPreference = $InformationPreference
if ($DEVEL) {
	$Global:DEBUG = $true;
}
if ($DEBUG) {
	$DebugPreference = "Continue"
	$Global:VERBOSE = $true
}
if ($VERBOSE) {
	$VerbosePreference = "Continue"
	$InformationPreference = "Continue"
}
if ($QUIET) {
	$Global:DEVEL = $false
	$Global:DEBUG = $false;
	$Global:VERBOSE = $false
}

# write-output "Language mode :"
# $ExecutionContext.SessionState.LanguageMode

<#

  ######  ########    ###    ########  ########
 ##    ##    ##      ## ##   ##     ##    ##
 ##          ##     ##   ##  ##     ##    ##
  ######     ##    ##     ## ########     ##
       ##    ##    ######### ##   ##      ##
 ##    ##    ##    ##     ## ##    ##     ##
  ######     ##    ##     ## ##     ##    ##

#>

function Update-ModuleNuspec {
	[CmdletBinding()]Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$FullyQualifiedName,
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][hashtable]$Project,
		[Parameter(Mandatory = $true)][system.version]$VERSION
	)
	Begin {
		# eenter($MyInvocation.MyCommand)
	}

	Process {
		$module = Get-Module -ListAvailable -FullyQualifiedName $FullyQualifiedName
		Write-Debug $module.Name
		Import-Module -FullyQualifiedName "$($module.ModuleBase)/$($module.Name).psm1" -Force:$Force -DisableNameChecking | Out-Null
		$rc = $?
		if ($rc -eq $false) { return $false }

		if (!(Test-Path "$($module.ModuleBase)/$($module.Name).nuspec" -Type Leaf)) {
			$rc = Execute-Command -exe nuget -args "spec $($module.ModuleBase)/$($module.Name).nuspec" -AsInt
			if ($rc -gt 0) { return $false }
		}

		if (Test-Path "$($module.ModuleBase)/$($module.Name).nuspec" -Type Leaf) {
			[XML]$nuspec = Get-Content "$($module.ModuleBase)/$($module.Name).nuspec" -Raw
			$nuspec.package.metadata.id = $Project.Name
			$nuspec.package.metadata.version = [string]$VERSION
			$nuspec.package.metadata.authors = $Project.AUTHORS
			$nuspec.package.metadata.owners = $Project.AUTHORS
			$nuspec.package.metadata.licenseUrl = $Project.LICENSEURL
			$nuspec.package.metadata.projectUrl = $Project.URL
			$nuspec.package.metadata.iconUrl = $Project.ICONURL
			$nuspec.package.metadata.description = $Project.DESCRIPTION
			$nuspec.package.metadata.releaseNotes = $Project.releaseNotes
			$nuspec.package.metadata.tags = $Project.TAGS
			$nuspec.package.metadata.copyright = $Project.COPYRIGHT
			$nuspec.Save("$($module.ModuleBase)/$($module.Name).nuspec")
		}
		# eend $?
	}

	End {
		# eleave($MyInvocation.MyCommand)
	}
}

<#
.SYNOPSIS
Create / Update module manifest to current VERSION.

.DESCRIPTION
Update module metadata :
* update VERSION
* update functions list
* update alias export list
If module manifest does not exist, it is created.
It also trim trailing spaces of module code and module's manifest

.PARAMETER FullyQualifiedName
Full path to module file. Either an already existing manifest (.psd1), or a module content (.psm1)

.PARAMETER VERSION
version number to use. It must be in [system.version] format e.g. 4 dotted numbers : 1.2.3.4

.PARAMETER UpdateMetaData
Update metadata as well, not only bump version number.
Note that if ModuleManifest does not exist, it is created with metadata regardless of this parameter.

.EXAMPLE
Update-ModuleManifestEx -FullyQualifiedName /path/to/my/module.psm1 -Version '1.0.0.0'

.OUTPUTS
System.Management.Automation.PSModuleInfo

This cmdlet returns objects that represent modules.

.NOTES
General notes
#>

function Update-ModuleManifestEx {
	[CmdletBinding()]Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$FullyQualifiedName,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][hashtable]$Project,
		[Parameter(Mandatory = $true)][system.version]$VERSION,
		[Parameter(Mandatory = $false)][switch]$UpdateMetaData
	)
	Begin {
		# eenter($MyInvocation.MyCommand)
		$file = $null
	}

	Process {
		$rc = Test-Path -Path $FullyQualifiedName -PathType Leaf -ErrorAction SilentlyContinue
		if ($rc -eq $false) { return $false }
		$file = Get-Item $FullyQualifiedName
		if (!($file)) { return $false }
		# $VERSION | Set-Content "$($file.DirectoryName)/VERSION"
		$module = Get-Module -ListAvailable -FullyQualifiedName $FullyQualifiedName
		Write-Information "Updating module $($module.Name)"
		Import-Module -FullyQualifiedName "$($module.ModuleBase)/$($module.Name).psm1" -Force:$Force -DisableNameChecking | Out-Null
		$rc = $?
		if ($rc -eq $true) {
			switch ($file.Extension) {
				'.psd1' {
					$ACTION = "update"
				}
				'.psm1' {
					if (Test-Path "$($module.ModuleBase)/$($module.Name).psd1" -Type Leaf) {
						$ACTION = "update"
					} else {
						$ACTION = "create"
					}
					break
				}
				default {
					Throw "The file extension $($file.Extension) is not a Powershell module extension."
				}
			}
			# edevel("ACTION = $ACTION")
			Write-Debug "ACTION = $ACTION"
			# edevel ("Functions list :")
			$functionsList = Get-Command -Module $module.Name
			# $functionsList.Name | ForEach-Object { edevel $_}
			# edevel ("Aliases list :")
			$aliasesList = Get-Alias | Where-Object { $_.ModuleName -eq $module.Name }
			# $aliasesList.Name | ForEach-Object { edevel $_}
			if ($aliasesList.count -eq 0) { $aliasesList = '' }
			# handle privateData
			# Private metadata handling does not work,
			# @see issue with New-ModuleManifest @url https://github.com/PowerShell/PowerShell/issues/5922
			# and issue with Update-ModuleManifest @url https://github.com/PowerShell/PowerShellGet/issues/294
			# $PrivateData = @{}
			# if ($null -ne $Project) {
			# 	$PrivateData.PSData = @{}
			# 	$PrivateData.PSData.licenseUri = $Project.LICENSEURL
			# 	$PrivateData.PSData.projectUri = $Project.URL
			# 	$PrivateData.PSData.iconUri = $Project.ICONURL
			# 	$PrivateData.PSData.description = $Project.DESCRIPTION
			# 	$PrivateData.PSData.releaseNotes = $Project.RELEASENOTES
			# 	$PrivateData.PSData.tags = $Project.TAGS
			# }
			switch ($ACTION) {
				'create' {
					New-ModuleManifest -RootModule "$($module.Name).psm1" -Path "$($module.ModuleBase)/$($module.Name).psd1" -FunctionsToExport $functionsList -AliasesToExport $aliasesList -ModuleVersion $VERSION -Description $Project.DESCRIPTION -Tags ($Project.TAGS -Split " ") -ProjectUri $Project.URL -LicenseUri $Project.LICENSEURL -IconUri $Project.ICONURL -ReleaseNotes $Project.RELEASENOTES -Author $Project.AUTHORS -Copyright $Project.COPYRIGHT
					$rc = $?
				}
				'update' {
					# $module.PrivateData.PSData | ft *
					if ($UpdateMetaData) {
						Update-ModuleManifest -Path "$($module.ModuleBase)/$($module.Name).psd1" -FunctionsToExport $functionsList -AliasesToExport $aliasesList -ModuleVersion $VERSION -Description $Project.DESCRIPTION -Tags ($Project.TAGS -Split " ") -ProjectUri $Project.URL -LicenseUri $Project.LICENSEURL -IconUri $Project.ICONURL -ReleaseNotes $Project.RELEASENOTES -Author $Project.AUTHORS -Copyright $Project.COPYRIGHT
					} else {
						Update-ModuleManifest -Path "$($module.ModuleBase)/$($module.Name).psd1" -FunctionsToExport $functionsList -AliasesToExport $aliasesList -ModuleVersion $VERSION
					}
					$rc = $?
				}
				default {
					Throw "ACTION '$ACTION' is not supported."
				}
			}
			# trim triling spaces
			if (Test-Path "$($module.ModuleBase)/$($module.Name).psd1" -Type Leaf) {
				$content = Get-Content "$($module.ModuleBase)/$($module.Name).psd1"
				$content | ForEach-Object {$_.TrimEnd()} | Set-Content "$($module.ModuleBase)/$($module.Name).psd1"
			} else {
				Write-Error "Module manifest not found."
			}
			$content = Get-Content "$($module.ModuleBase)/$($module.Name).psm1"
			$content | ForEach-Object {$_.TrimEnd()} | Set-Content "$($module.ModuleBase)/$($module.Name).psm1"
		}
		# eend $?
		$module = Get-Module -ListAvailable -FullyQualifiedName "$($module.ModuleBase)/$($module.Name).psd1"
		return $module
	}

	End {
		# eleave($MyInvocation.MyCommand)
	}
}

$rc = Test-Path $PSScriptRoot/../project.conf -Type Leaf
if ($rc -eq $true) {
	$project = Get-Content $PSScriptRoot/../project.conf -Raw | ConvertFrom-StringData
} else {
	$project = @{}
	Write-Warning "For optimal use of $BASENAME, please create a file project.conf at the root fo your project and add following variables :"
	Write-Warning "NAME = "
	Write-Warning "VERSION = "
	Write-Warning "AUTHORS = "
	Write-Warning "OWNERS = "
	Write-Warning "LICENSEURL= "
	Write-Warning "URL = "
	Write-Warning "ICONURL = "
	Write-Warning "DESCRIPTION = "
	Write-Warning "TAGS = "
	Write-Warning "RELEASENOTES = "
	Write-Warning "COPYRIGHT = "
}

if ($null -eq $VERSION) {
	$VERSION = Get-Content (Resolve-Path "$PSScriptRoot/../VERSION") -Raw
	if ($null -eq $VERSION) {
		$VERSION = "0.0.1"
		$VERSION | Set-Content "$PSScriptRoot/../VERSION" -Encoding utf8
	}
}
Write-Debug "VERSION = $VERSION"

# CHANGELOG is present
$CHANGELOG = Resolve-Path "$PSScriptRoot/../CHANGELOG.md"
$rc = Test-Path $CHANGELOG -Type Leaf
if ($rc -eq $false) { Write-Error "This project lacks a CHANGELOG.md file. See https://keepachangelog.com/en/1.0.0/ to begin." }
# parse CHANGELOG.md
# below command line explained :
# Get-Content $CHANGELOG | Select-String -NotMatch -Pattern '(?ms)^$'		--> get CHANGELOG content without empty lines
# -replace "^## ", "`n##  "													--> add empty lines only before h2 title level (## in markdown). This way, we got proper paragraph from ## tag to next empty line
$TMP = [system.io.path]::GetTempPath()
(Get-Content $CHANGELOG | Select-String -NotMatch -Pattern '(?ms)^$') -replace "^## ", "`n##  " | Out-File $TMP/changelog.tmp
# To extract correct §, we need to read the file with -Raw parameter
# (?ms) sets regex options m (treats ^ and $ as line anchors) and s (makes . match \n (newlines) too`.
# ^## .*? matches any line starting with ##  and any subsequent characters *non-greedily* (non-greedy is '.*?' set of characters at the end of pattern).
# -AllMatches to get... well... all mathes
# [1] because the last changelog is allways [1] from array of matches. [0] is ## [Unreleased]
$MESSAGES = Get-Content -Raw $TMP/changelog.tmp | Select-String -Pattern '(?ms)^## .*?^$' -AllMatches
# edevel("MESSAGES = " + $MESSAGES.Matches[0])
# reduce title level to render more readable in github release page
$MESSAGE = ($MESSAGES.Matches[0]) -replace "# ", "## " -replace "'", "``" -replace "unreleased", "$VERSION"
Write-Debug "MESSAGE = $MESSAGE"

$project.RELEASENOTES = $MESSAGE

# $project | fl *

switch ($PSCmdlet.ParameterSetName) {
	'FILENAME' {
		if (Test-Path $FullyQualifiedName -PathType Leaf) {
			$Filenames = @($FullyQualifiedName)
		}
	}
	'PATH' {
		if (Test-Path $Path -PathType Container) {
			$Filenames = (Get-ChildItem -Recurse:$Recurse -Filter "*.psm1" $Path).fullname
		}
	}
}


# if (![string]::IsNullOrEmpty($FullyQualifiedName)) {
ForEach ($file in $Filenames) {
	$mainModule = Update-ModuleManifestEx -VERSION $VERSION -FullyQualifiedName $file -Project $project -UpdateMetaData
	$FunctionsToExport = $mainModule.ExportedFunctions.Values.Name
	$AliasesToExport = $mainModule.ExportedAliases.Values.Name
	if ($DEBUG) {
		$FunctionsToExport | Format-List *
	}
	if ($RecurseInclude) {
		$NestedModules = @()
		# $RequiredModules = @()
		Get-ChildItem -Path $MainModule.ModuleBase -Recurse -Name "*.psm1" -Exclude $mainModule.RootModule | ForEach-Object {
			$m = $_
			Write-Debug "Found $m"
			# skip mainModule
			# if ($mainModule.RootModule -eq $_) { continue }
			$subModule = Update-ModuleManifestEx -VERSION $VERSION -FullyQualifiedName "$($MainModule.ModuleBase)/$_" -Project $project -UpdateMetaData:$false
			# $folder = ($m -split [io.path]::DirectorySeparatorChar)[0]
			$folder = Split-Path -Parent $m
			# treat Includes as RequiredModules
			# $psm = Get-Item -Path "$($MainModule.ModuleBase)/$($_)"
			switch ($folder) {
				'Includes' {
					# $RequiredModules += $m
					$NestedModules += @("." + [io.path]::DirectorySeparatorChar + "$m")
					$FunctionsToExport += $subModule.ExportedFunctions.Values.Name
					$AliasesToExport += $subModule.ExportedAliases.Values.Name
				}
				'Private' {
					$NestedModules += @("." + [io.path]::DirectorySeparatorChar + "$m")
				}
				default {
				}
			}
			# clean tracks
			Remove-Module -Name $subModule.Name
		}
		# if ($RequiredModules) {
		# 	# $RequiredModules | fl
		# 	Update-ModuleManifest -Path $mainModule.Path -RequiredModules $RequiredModules
		# }
		if ($NestedModules) {
			if ($DEBUG) {
				$FunctionsToExport | Format-List *
			}
			Update-ModuleManifest -Path $mainModule.Path -NestedModules $NestedModules -FunctionsToExport ($FunctionsToExport | Sort-Object) -AliasesToExport ($AliasesToExport | Sort-Object)
		}
	}
	if ($NuSpec) { Update-ModuleNuspec -VERSION $VERSION -FullyQualifiedName $file -Project $project }
}

if ($DEBUG) {
	$mainModule = Get-Module -ListAvailable -FullyQualifiedName "$($mainModule.ModuleBase)/$($mainModule.Name).psd1"
	$mainModule | Format-List *
}
# clean tracks
Remove-Module -Name $mainModule.Name

<#

	######## ##    ## ########
	##       ###   ## ##     ##
	##       ####  ## ##     ##
	######   ## ## ## ##     ##
	##       ##  #### ##     ##
	##       ##   ### ##     ##
	######## ##    ## ########

#>

# reinit values
$Global:DebugPreference = $oldDebugPreference
$Global:VerbosePreference = $oldVerbosePreference
$Global:InformationPreference = $oldInformationPreference
Set-PSDebug -Off
