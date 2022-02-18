<#

	.SYNOPSIS
	Update a script to the latest skeleton version

	.DESCRIPTION
	skel.ps1 is improved regularly. These improvements are hard to integrate in each customer's script. That's what update-script.ps1 tries to solve.

	!! WARNING !! WARNING !! WARNING !!
	For update-script.ps1 to work flawlessly, you have to respect theese guidlines :
	* Add your parameters to the CmdletBinding() block
	* Keep the comment block ## YOUR SCRIPT BEGINS HERE ##
	* Keep the comment block ## YOUR SCRIPT ENDS   HERE ##
	Everything outside the CmdletBinding block or the YOUR SCRIPT block will be lost !
	!! WARNING !! WARNING !! WARNING !!

	In other words, what will be kept from your script :
	* the comment-based help (and anything before it)
	* the CmdletBinding() block
	* everything between ## YOUR SCRIPT BEGINS HERE ## and ## YOUR SCRIPT ENDS   HERE ## tags

	Caveats :
	* new standard paramters added to skel.ps1 will not be merged with customer's script.

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

	.PARAMETER Skel
	full path to the reference to skeleton from Tiny {PowerShell} Framework

	.PARAMETER Script
	ful path to custom script to update

	.NOTES
	Author: Charles-Antoine Degennes <cadegenn@gmail.com>

	.LINK
		https://github.com/cadegenn/pwsh_fw
#>

[CmdletBinding()]Param(
	[switch]$h = $false,
	[switch]$v = $false,
	[switch]$d = $false,
	[switch]$dev = $false,
	[switch]$trace = $false,
	[switch]$ask = $false,
	[ValidateScript({
		Test-Path -Path $_ -PathType container
	})][string]$api = $null,
	# if you want each invocation to overwrite logfile
	#[ValidateScript({New-Item $_ -ItemType file -force})][string]$log = ""
	# if you want each invocation to NOT overwrite logfile
	[ValidateScript({
		New-Item $_ -ItemType file -ErrorAction:SilentlyContinue
		Test-Path -Path $_ -PathType leaf
	})][string]$log = "",
	[switch]$Force = $false,
	[Alias('Skel', 'Skeleton')]
	[Parameter(Mandatory = $true)][string]$SkelFilename,
	[Alias('Script', 'Scriptname')]
	[Parameter(Mandatory = $true)][string]$ScriptFilename
)

$Global:BASENAME = Split-Path -Leaf $MyInvocation.MyCommand.Definition
$Global:VERBOSE = $v
$Global:DEBUG = $d
$Global:DEVEL = $dev
$Global:TRACE = $trace
$Global:ASK = $ask
$Global:LOG = $log
$rc = Import-Module PwSh.Fw.Core -ErrorAction Stop
$modules = @()

if ($h) {
	Get-Help $MyInvocation.MyCommand.Definition
	Exit
}

# keep the order as-is please !
if ($ASK)   { Set-PSDebug -Step }
if ($TRACE) {
	# Set-PSDebug -Trace 1
	$Global:DEVEL = $true
}
if ($DEVEL) {
	$Global:DEBUG = $true;
}
if ($DEBUG) {
	$DebugPreference="Continue"
	$Global:VERBOSE = $true
}
if ($VERBOSE) {
	$VerbosePreference="Continue"
}

if ($log) {
	if ($TRACE) {
		Start-Transcript -Path $log
	# } else {
	# 	# add -Append:$false to overwrite logfile
	# 	# Write-ToLogFile -Message "Initialize log" -Append:$false
	# 	Write-ToLogFile -Message "Initialize log"
	}
	$modules += "PwSh.Log"
}

# write-output "Language mode :"
# $ExecutionContext.SessionState.LanguageMode

#
# Load Everything
#
everbose("Loading modules")
# $modules += "PsIni"
# $modules += "PwSh.ConfigFile"
# $modules += "Microsoft.PowerShell.Archive"
# USER MODULES HERE

$ERRORFOUND = $false
ForEach ($m in $modules) {
	$rc = Load-Module -Name $m -Force:$Force
	if ($rc -eq $false) { $ERRORFOUND = $true }
}
if ($ERRORFOUND) { efatal("At least one module could not be loaded.") }

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

etitle ("$Global:BASENAME")

# get the line numbers of skeleton
$PATTERN = '^\$Global:BASENAME'
$SKEL_LINENO_HEAD_START = (Select-String -Path $SkelFilename -Pattern $PATTERN).LineNumber
if ( ! $SKEL_LINENO_HEAD_START) { efatal "$PATTERN anchor not found in script." }
$PATTERN = '^## YOUR SCRIPT BEGINS HERE ##'
$SKEL_LINENO_MAIN_START = (Select-String -Path $SkelFilename -Pattern $PATTERN).LineNumber
if ( ! $SKEL_LINENO_MAIN_START) { efatal "$PATTERN anchor not found in script." }
$PATTERN = '^## YOUR SCRIPT ENDS   HERE ##'
$SKEL_LINENO_MAIN_END = (Select-String -Path $SkelFilename -Pattern $PATTERN).LineNumber
if ( ! $SKEL_LINENO_MAIN_END) { efatal "$PATTERN anchor not found in script." }

edevel("SKEL_LINENO_HEAD_START = $SKEL_LINENO_HEAD_START")
edevel("SKEL_LINENO_MAIN_START = $SKEL_LINENO_MAIN_START")
edevel("SKEL_LINENO_MAIN_END = $SKEL_LINENO_MAIN_END")

# get the line numbers of customer script
$PATTERN = '^\$Global:BASENAME'
$SCRIPT_LINENO_HEAD_START = (Select-String -Path $ScriptFilename -Pattern $PATTERN).LineNumber
if ( ! $SCRIPT_LINENO_HEAD_START) { efatal "$PATTERN anchor not found in script." }
$PATTERN = '^## YOUR SCRIPT BEGINS HERE ##'
$SCRIPT_LINENO_MAIN_START = (Select-String -Path $ScriptFilename -Pattern $PATTERN).LineNumber
if ( ! $SCRIPT_LINENO_MAIN_START) { efatal "$PATTERN anchor not found in script." }
$PATTERN = '^## YOUR SCRIPT ENDS   HERE ##'
$SCRIPT_LINENO_MAIN_END = (Select-String -Path $ScriptFilename -Pattern $PATTERN).LineNumber
if ( ! $SCRIPT_LINENO_MAIN_END) { efatal "$PATTERN anchor not found in script." }

edevel("SCRIPT_LINENO_HEAD_START = $SCRIPT_LINENO_HEAD_START")
edevel("SCRIPT_LINENO_MAIN_START = $SCRIPT_LINENO_MAIN_START")
edevel("SCRIPT_LINENO_MAIN_END = $SCRIPT_LINENO_MAIN_END")

# cut everything together
$skel = @{}
$skel.head = Get-Content -Path $SkelFilename -TotalCount $($SKEL_LINENO_MAIN_START - 1) | Select-Object -Skip $($SKEL_LINENO_HEAD_START - 1)
$skel.tail = Get-Content -Path $SkelFilename | Select-Object -Skip $($SKEL_LINENO_MAIN_END + 1)

$Script = @{}
$script.head = Get-Content -Path $ScriptFilename -TotalCount $($SCRIPT_LINENO_HEAD_START - 1)
$script['body'] = Get-Content -Path $ScriptFilename -TotalCount $($SCRIPT_LINENO_MAIN_END + 1) | Select-Object -Skip $($SCRIPT_LINENO_MAIN_START - 1)
$sModules = Get-Content -Path $ScriptFilename | select-string -Pattern '^\$modules \+='
$script.modules = foreach ($m in $sModules) { "{0}`n" -f $m }

Clear-Content -Path $($ScriptFilename + ".new") -ErrorAction:SilentlyContinue
$script.head | Add-Content -Path $($ScriptFilename + ".new")
$skel.head | Add-Content -Path $($ScriptFilename + ".new")
$script.body | Add-Content -Path $($ScriptFilename + ".new")
$skel.tail | Add-Content -Path $($ScriptFilename + ".new")
(Get-Content $($ScriptFilename + ".new")) -replace "^# USER MODULES HERE$", $("$&`n" + ($script.modules -f 'string')) | Set-Content $($ScriptFilename + ".new")

if ($Force) {
	if (fileExist("$ScriptFilename.bak")) { Remove-Item -Path "$ScriptFilename.bak" }
}
Rename-Item -Path $ScriptFilename -NewName $(($ScriptFilename | Split-Path -Leaf) + ".bak") -Force:$Force
Rename-Item -Path $($ScriptFilename + ".new") -NewName ($ScriptFilename | Split-Path -Leaf) -Force:$Force

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

# reinit values
$Global:DebugPreference = "SilentlyContinue"
Set-PSDebug -Off
$Script:indent = ""
