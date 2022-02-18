[CmdletBinding()]Param(
	[switch]$i,
	[switch]$v,
	[switch]$d,
	[switch]$dev,
	[switch]$trace,
	[switch]$ask,
	[switch]$quiet,
	[switch]$Force
)

$Global:BASENAME = Split-Path -Leaf $MyInvocation.MyCommand.Definition
Import-Module -FullyQualifiedName $PSScriptRoot/../PwSh.Fw.Core/PwSh.Fw.Core.psm1 -ErrorAction Stop -DisableNameChecking -Force:$Force
Import-Module -FullyQualifiedName $PSScriptRoot/../PwSh.Fw.Core/Includes/PwSh.Fw.Write.psm1 -ErrorAction Stop -DisableNameChecking -Force:$Force
Set-PwShFwConfiguration -i:$i -v:$v -d:$d -dev:$dev -trace:$trace -ask:$ask -quiet:$quiet

function Execute-Main {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		Get-PwShFwDisplayConfiguration
		Write-Title ("$Global:BASENAME")
		Write-Devel "INFO = $Global:INFO"
		Write-Devel "VERBOSE = $Global:VERBOSE"
		Write-Devel "DEBUG = $Global:DEBUG"
		Write-Devel "DEVEL = $Global:DEVEL"
		Write-Devel "QUIET = $Global:QUIET"
		Write-Info "This is an info message"
		Write-Info "Try launching this script with various parameters like -v -d -dev"
		Write-Verbose "This is a verbose message"
		Write-Debug "This is a debug message"
		Write-Devel "This is a message for developer"
		Write-Todo "This is a TODO"
		Write-Begin "Start an action"
		Write-End $true
		Write-Test
		Write-Enter "Enter a loop"
		1..5 | ForEach-Object { Write-Verbose $_ }
		Write-Leave "Leaving the loop"
		Write-Warning "This is a warning"
		Write-Error "This is an error"
		Write-Info "you can execute commands (try it with -d and -dev)"
		$rc = Execute-Command "hostname"
		Write-End $true
		$rc = Ask-Question -Prompt "Was this helpful ?" -DefaultValue "n" -DefaultAnswer "y"
		Write-Host "`n"
		Write-LineBreak
	}

	End {
		Write-LeaveFunction
	}
}

function Write-Test {
	begin {
		Write-EnterFunction
	}
	process {
		Write-Info "Where are we ?"
		Write-Debug "where does this piece of code comes from ?"
		Write-Debug "to know it, run $BASENAME with -trace parameter..."
	}
	end {
		Write-LeaveFunction
	}
}

Get-PwShFwConfiguration
Execute-Main
Set-PwShFwDisplayConfiguration -MessageDisplayFormat "[{0,-4}]:{1,1}{2}" -RCPosition FLOW
Execute-Main
Set-PwShFwDisplayConfiguration -MessageDisplayFormat "[{0,-6}] {1}{2}" -RCDisplayFormat "[{0,6}]" -RCPosition BEGIN
Execute-Main
# Set-PwShFwDisplayConfiguration -MessageDisplayFormat "{0,-3} {1}{2}" -IndentChar "-"
# Execute-Main
