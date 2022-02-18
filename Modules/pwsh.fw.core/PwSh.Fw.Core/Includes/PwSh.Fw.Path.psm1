<#
.SYNOPSIS
Test if a file exist

.DESCRIPTION
Never know if -PathType is Leaf or File, or whatever. Just use Test-FileExist.
If a directory is given to Name parameter it will return $false. Use Test-DirExist instead.

.PARAMETER Name
Absolute or relative path to filename

.EXAMPLE
if (Test-FileExist "c:\windows\notepad.exe") { echo "notepad is present" } else { echo "notepad is NOT present" }

.NOTES
General notes

.LINK
https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function Test-FileExist {
    [CmdletBinding()]
	[OutputType([System.Boolean])]
	Param (
		[AllowNull()][AllowEmptyString()]
		[Parameter(Mandatory,ValueFromPipeLine = $true)]
		[string]$Name
    )
    Begin {
        # eenter($MyInvocation.MyCommand)
    }

    Process {
		if ([string]::IsNullOrEmpty($Name)) { return $false }
		Test-Path $Name -PathType Leaf
    }

    End {
        # eleave($MyInvocation.MyCommand)
    }
}

<#
.SYNOPSIS
Test if a directory exist

.DESCRIPTION
Never know if -PathType is Container or Directory, or whatever. Just use Test-DirExist.
If a file is given to Path parameter it will return $false. Use Test-FileExist instead.

.PARAMETER Path
Absolute or relative path to test

.EXAMPLE
if (Test-DirExist "c:\windows") { echo "you are on Windows" } else { echo "you are NOT on Windows" }

.NOTES
General notes

.LINK
https://gitlab.com/pwsh.fw/pwsh.fw.core

#>
function Test-DirExist {
    [CmdletBinding()][OutputType([System.Boolean])]Param (
		[Parameter(Mandatory,ValueFromPipeLine = $true)]
		[AllowNull()][AllowEmptyString()]
		[string]$Path
    )
    Begin {
        # eenter($MyInvocation.MyCommand)
    }

    Process {
		if ([string]::IsNullOrEmpty($Path)) { return $false }
		Test-Path $Path -PathType Container
    }

    End {
        # eleave($MyInvocation.MyCommand)
    }
}

<#
	.SYNOPSIS
	Convert a Path from local to UNC and vice-versa.

	.DESCRIPTION
	The official Microsoft Resolve-Path do not resolve local path to UNC, nor UNC to local path.
	This function does.

	.PARAMETER Path
	The path to resolve. It is not mandatory for Path to exist.

	.PARAMETER ToUNC
	Resolve the path to an UNC path if applicable. The default is to resolve to a local path.

	.OUTPUTS [System.String]
	A string representing the resolved path.

#>
function Resolve-PathExtended {
    [CmdletBinding()]Param (
		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)]
		[string]$Path,
		[switch]$ToUNC
    )
    Begin {
        # eenter($MyInvocation.MyCommand)
    }

    Process {
		# sanitize a bit whole path
		# convert every "\" to "/"
		$Path = $Path -replace "\\", "/"
		# edevel("Path = " + $Path)
		# reduce double-slash, but only if we see "////" pattern
		# because "//" can be a legitimate UNC string
		if ($Path -match "////") {
			$Path = $Path -replace "//", "/"
		}

		# given Path is an absolute local path
		if ($Path -match ":") {
			# sanitize a bit
			$qual = Split-Path $Path -Qualifier
			$remain = Split-Path $Path -NoQualifier
			# remove non-alphabethic char from qualitifier
			$qual = $qual -replace "[^a-zA-Z]", ''
			$Path = $qual + ":" + $remain
		}
		# given Path contains //server/login
		elseif ($Path -match "//\w*/\w*") {
			# is this UNC path connected locally to a PSDrive ?
			$Path = $Path.Trim("./")
			$ServerShare = "\\" + $Path.Split("/",3)[0] + "\" + $Path.Split("/",3)[1]
			# edevel("ServerShare = " + $ServerShare)
			$drive = (Get-PSDrive | Where-Object { $_.DisplayRoot -eq $ServerShare }).Name
			# edevel("drive = " + $drive)
			if (!$drive) {
				# process fallback here
			} else {
				$Path = $drive + ":/" + $Path.Split("/",3)[2]
			}
			# edevel("Path = " + $Path)
		} else {
			$Path = Resolve-Path $Path -ErrorAction:SilentlyContinue
			if ($? -eq $false) {
				Throw "Given Path cannot be resolved in any way."
				return $Path
			}
		}

		# $Path = Resolve-Path $Path
		# edevel("Path = " + $Path)
		if ($ToUNC) {
			$qual = Split-Path $Path -Qualifier
			# edevel("qual = " + $qual)
			$uncQual = (Get-PSDrive | Where-Object { $_.Root -eq "$qual\" }).DisplayRoot
			# edevel("uncQual = " + $uncQual)
			$Path = $uncQual + (Split-Path $Path -NoQualifier)
		}

		$Path = $Path -replace "\\", "/"
		return $Path
    }

    End {
       # eleave($MyInvocation.MyCommand)
    }
}

<#
.SYNOPSIS
Test if a path is an UNC path

.DESCRIPTION
Test if a path is of the Universal Naming Convention form

.PARAMETER Path
The path to test given as a string

.EXAMPLE
"c:\users" | Test-IsUNCPath

.EXAMPLE
Test-IsUNCPath -Path "\\server\share"

.NOTES
General notes

.LINK
founs simple way to test from @url https://vijayakumarsubramaniyan.wordpress.com/2016/10/01/check-given-path-is-unc-path-or-local-path/
#>

function Test-IsUNCPath {
	[CmdletBinding()][OutputType([System.Boolean])]Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][System.Uri]$Path
	)
	Begin {
		# eenter($Script:NS + '\' + $MyInvocation.MyCommand)
	}

	Process {
		return $Path.IsUNC
	}

	End {
		# eleave($Script:NS + '\' + $MyInvocation.MyCommand)
	}
}

