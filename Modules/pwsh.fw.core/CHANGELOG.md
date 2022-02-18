# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

> Please read [UPGRADING.md](UPGRADING.md) carrefully

:scroll: is a function \
:package: is a module \
:memo: is a script

## [v1.8.1] - 2021-10-07

### Fixed

-	fix publishing on Powershell Gallery a module with so much functions (exeeded tag char limit)

## [1.8.0] - 2021-10-07

### Added

-	:scroll: `Get-PwShFwConfiguration`
-	:scroll: `Write-Message`. This function cannot be silenced except with `$QUIET = $true`
-	:scroll: `Write-Todo` shortcut. It uses `Write-Message`
-	:scroll: `Write-Error`: added all powershell's Write-Error parameters for future processing. At this time, they are just ignored. Only `-Message` parameter is processed.
-	:scroll: `Set-PwShFwDisplayConfiguration` to configure fields displayed
-	bunch of new variables to tweak display titles, color and format

### Changed

-	:scroll: `Write-Info` does not print anything by default until `$INFO = $true`
-	:package: fix name of `PwSh.Fw.Path` submodule
-	:scroll: improved `Write-End`
-	:scroll: all `Write-*` functions now call `Write-Message` with different parameters

## [1.7.2] - 2021-06-09

### Changed

-	:scroll: `Set-PwShFwConfiguration` initialize (empty) log file

### Fixed

-	:scroll: `ConvertTo-PSCustomObject` support input array
-	:scroll: `Load-Module` display correctly only 1 module when multiple versions of same module are found

## [1.7.1] - 2021-03-31

### Changed

-   remove Powershell Core syntax

## [1.7.0] - 2021-03-31

### Added

-	:scroll: `Set-PwShFwConfiguration`: sets global config without using `skel.ps1`.

### Changed

-   remove requirement to Powershell Core

## [1.6.2] - 2021-03-09

### Fixed

-	fixed :scroll: `Resize-Image` Filename

## [1.6.1] - 2021-03-08

### Fixed

-	:scroll: `ConvertFrom-ConfigFile` with yaml file.

## [1.6.0] - 2021-03-05

### Added

-	:scroll: `Get-ValidValuesFromPath`. It is a helper function to be used in `ArgumentCompleter` parameter definition. See `Get-Help Get-ValidValuesFromPath -full`.
-	:package:`PwSh.Fw.Image`: new module -> :scroll: `Resize-Image` function.
-	:package:`PwSh.Fw.Error`: new module to register common return codes, their meaning and their default color
-	:package:`PwSh.Fw.Write` - :scroll: `Write-ReturnCode` to properly display a return code. User can choose to display it at the beginning or end of the line by setting default with `Set-ReturnCodePosition` or by overriding default with `-Position` parameter
-	if all goes well, `Write-End` will be a wrapper for `Write-ReturnCode -Position END` for the next version (if I remember to do it)
-	new :package:`PwSh.Fw.Path`. Functions :scroll: `Test-FileExist` and :scroll: `TEst-DirExist` moved there.
-	:package:`PwSh.Fw.Path` : new :scroll: `Resolve-PathExtended` and :scroll: `Test-IsUNCPath` functions.
-	:scroll: new `Write-Question` is a wrapper for Read-Host and add DefaultValue capability.
-	:scroll: new `ConvertTo-StringData` function. At the moment it can only convert simple hashtable or simple object.

### Changed

-	:scroll: `Write-My*` functions renamed to `Write-*` thus overriding Powershell default ones. e.g. `Write-MyWarning` -> `Write-Warning`. Aliases are created but are already considered obsoletes.
-	:scroll: `ConvertFrom-ConfigFile` read yaml/yml files
-	:scroll: `Add-PSModulePath` use `[Environment]::GetEnvironmentVariable()` and `[Environment]::SetEnvironmentVariable()`

### Deprecated

-	`Write-My*` aliases to keep old behavior are deprecated

### Removed

-	:scroll: `Write-My*` functions have been replaced by `Write-*` functions, overriding Powershell natives ones (like `Write-Warning`)

## [1.5.5] - 2020-09-28

### Changed

-	:scroll: `Write-Verbose`, `Write-Debug`, `Write-Devel` still write to log file, even if `-v` `-d` or `-dev` is not specified respectively. This allow to not overload screen output but still get verbose, debug and devel loglevel into the logfile.

### Fixed

-	:scroll:`Execute-Command` fixed boolean return value
-	:scroll:`Write-Add` fixed newline in log file

## [1.5.4] - 2020-06-15

### Fixed

-	:package:`PwSh.Fw.Write` does not need confirmation to set aliases (should have been done in 1.5.1.. don't known what happened)

## [1.5.3] - 2020-06-15

### Changed

-	improved Pester test

### Fixed

-	fix Pester test

## [1.5.2] - 2020-06-14

### Changed

-	fix CHANGELOG

## [1.5.1] - 2020-06-14

### Changed

-	:package:`PwSh.Fw.Write` does not need confirmation to set aliases

## [1.5.0] - 2020-06-10

### Added

### Changed

-	:scroll:`Write-Enter` and `Write-Leave` no longer display unneeded parenthesis `()`
-	call to :package:`PwSh.Fw.Log`\\:scroll:`Write-ToLogFile` now append to log file by default
-	call :scroll:`Write-ToLogFile` with `-NoNewLine` parameter

## [1.4.1]

### Fixed

-	call :scroll:`Write-ToLogFile` with `-NoNewLine` parameter

## [1.4.0]

### Added

-	:package:`PwSh.Fw.Core` : new :scroll:`ConvertFrom-ConfigFile` function

### Changed

-	:scroll:`Test-FileExist` and :scroll:`Test-DirExist` accept empty and null parameter
-	:package:`PwSh.Fw.Write` defines Global:QUIET if it is not already set
-	:scroll:`Write-Fatal` now display stack trace in devel mode

## [1.3.0]

### Added

-	:package:`PwSh.Fw.Write` : new :scroll:`Set-Indent` and :scroll:`Reset-Indent` functions
-	:package:`PwSh.Fw.Object` : new :scroll:`Sort-ByProperties`, :scroll:`Get-ObjectProperties`, :scroll:`Get-CustomObjectProperties` and :scroll:`ConvertTo-PSCustomObject` functions
-	new script to auto-generate wiki pages on gitlab's project using comment based help of functions
-	new module `PwSh.Fw.Maths` with just one function : `Convert-Size` which convert size from/to bytes, kilobytes, megabytes, gigabytes and terabytes

### Changed

-	:package:`PwSh.Fw.Core` is now built using [`PwSh.Fw.BuildHelpers`](https://gitlab.com/pwsh.fw/pwsh.fw.buildhelpers)

## [1.2.0]

### Added

-	New modules :package:`PwSh.Fw.Object` and :package:`PwSh.Fw.Write`.
-	CI/CD test on macOS, Linux and Windows

### Changed

-	:package:`PwSh.Fw.Core` splitted into pieces
-	Push to develop branch does not upload to PowerShell Gallery. Only release branches are pushed with a `PreRelease` tag.

## [1.1.0] - 2020.02.13

### Changed

-	Pushs on develop branch upload to Powershell Gallery with a `PreRelease` tag

### Fixed

-	Upload to Powershell Gallery works !! (at last)

## [1.0.2]

### Added

-	`update-script.ps1`: script to update your own script to the latest version of `skel.ps1`

## [1.0.1] - 2020.02.10

### Fixed

-	Publishing module to Powershell Gallery

## [1.0.0] - 2020.02.05

### Added

-	Gitlab continuous integration
-	Publish to PowerShell Gallery
-	Unit tests and code coverage using Pester
