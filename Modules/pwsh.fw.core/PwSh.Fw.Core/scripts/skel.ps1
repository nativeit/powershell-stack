<#

	.SYNOPSIS
	Skeleton script for my tiny powershell framework

	.DESCRIPTION
	Tiny powershell framework.

	To ease programming here is debugging levels :
	    -v :     display VERBOSE level messages
		-d :	 display DEBUG level messages
		-dev :   display DEVEL level messages (including DEBUG ones)
		-trace : display the line of script currently executed as well as DEVEL and DEBUG level messages
		-ask :   ask user before each execution
		-q :	silence all displays

	.PARAMETER h
	display help screen. Use Get-Help instead.

	.PARAMETER v
	enable verbose mode

	.PARAMETER d
	enable debug mode

	.PARAMETER dev
	enable devel mode

	.PARAMETER trace
	.enable trace mode. With this mode on you can trace entering and leaving every single function that use the Write-EnterFunction and Write-LeaveFunction calls.
	Very useful while developing a new script.

	.PARAMETER ask
	ask for each action

	.PARAMETER quiet
	quiet output completely

	.PARAMETER log
	log calls to e*() functions into specified logfile.
	If used in conjunction with -trace, it will use PowerShell Start-Transcript to log everything, including output of commands.
	Useful if you can't see the output of script for whatever reason. In this case, Write-ToLog() is deactivated.

	.NOTES
	Author: Charles-Antoine Degennes <cadegenn@gmail.com>

	.LINK
		https://github.com/cadegenn/pwsh_fw
#>

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
Import-Module PwSh.Fw.Core -ErrorAction Stop -DisableNameChecking -Force:$Force
Set-PwShFwConfiguration -i:$i -v:$v -d:$d -dev:$dev -trace:$trace -ask:$ask -quiet:$quiet
Set-PwShFwDisplayConfiguration -MessageDisplayFormat "[{0,4}]:{1,1}{2}"

#############################
## YOUR SCRIPT BEGINS HERE ##
#############################

<#

  ######  ########    ###    ########  ########
 ##    ##    ##      ## ##   ##     ##    ##
 ##          ##     ##   ##  ##     ##    ##
  ######     ##    ##     ## ########     ##
       ##    ##    ######### ##   ##      ##
 ##    ##    ##    ##     ## ##    ##     ##
  ######     ##    ##     ## ##     ##    ##

#>

function Write-Test {
	begin {
		Write-EnterFunction
	}
	process {
		Write-Info "Where are we ?"
		Write-Debug "where does this piece of code comes from ?"
		Write-Debug "to know it, run $BASENAME with -dev parameter..."
	}
	end {
		Write-LeaveFunction
	}
}
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
Write-Question -Prompt "Was this helpful ?" -DefaultValue "n" -DefaultAnswer "y"

<#

 ######## ##    ## ########
 ##       ###   ## ##     ##
 ##       ####  ## ##     ##
 ######   ## ## ## ##     ##
 ##       ##  #### ##     ##
 ##       ##   ### ##     ##
 ######## ##    ## ########

#>

#############################
## YOUR SCRIPT ENDS   HERE ##
#############################

if ($log) {
	if ($TRACE) {
		Stop-Transcript
	} else {
		Write-ToLogFile -Message "------------------------------------------"
	}
}

Set-PSDebug -Off
