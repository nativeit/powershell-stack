using namespace System.Management.Automation
<#

    .SYNOPSIS
    Resource file to export useful functions to prettify output

    .DESCRIPTION

    .NOTES
		Author: Charles-Antoine Degennes <cadegenn@gmail.com>
		New-ModuleManifest api.psd1 -RootModule api.psm1 -ModuleVersion "0.0.1" -Author "Charles-Antoine Degennes <cadegenn@gmail.com>"
#>

if (!($Global:QUIET)) { $Global:QUIET = $false }
$Script:NS = (get-item $PSCommandPath).basename

# # Error codes enum
# Enum pwshfwERROR {
# 	OK = 0
# 	FAILED = 1
# 	RUNNING = 2
# 	MISSED = 3
# 	SKIPPED = 4
# 	UNUSED = 5
# 	UNKNOWN = 6
# 	DEAD = 7
# 	NOTFOUND = 8
# }

$Script:indent = ""
$Script:IndentLength = 3
$Script:IndentChar = " "
$Script:prepend = " * "
$Script:postpend = ""
# MessageDisplayFormat is a string following -f powershell operator syntax
# {0} is the message title (message type)
# {1} is the indentation
# {2} is the message text
$Script:MessageDisplayFormat = " * {0,3}: {1}{2}"
# another example of MessageDisplayFormat
# $Script:MessageDisplayFormat = "[{0,4}] {2}"
# example without type but with indentation
# $Script:MessageDisplayFormat = "{1}{2}"
# same example without indentation. only print message
# $Script:MessageDisplayFormat = "{2}"
$Script:DisplaySeverity = $true
$Script:titleChar = "*"
$Script:lineBreakChar = "-"

# display type of messages (not mandatory, but useful in a logfile)
$Script:BeginTitle = "BEG"
$Script:DebugTitle = "DBG"
$Script:DevelTitle = "DEV"
$Script:EnterTitle = ">>>"
$Script:LeaveTitle = "<<<"
$Script:EnterFunctionTitle = ">> "	# not really a title, as the title of EnterFunction is $DevelTitle
$Script:LeaveFunctionTitle = "<< "	# not really a title, as the title of LeaveFunction is $DevelTitle
$Script:ErrorTitle = "ERR"
# $Script:FatalTitle = "ERR"		# unused, the ErrorTitle is used
$Script:InfoTitle = "INF"
$Script:MessageTitle = "MSG"
$Script:QuestionTitle = "ASK"
$Script:TodoTitle = "TDO"
$Script:TitleTitle = "TTL"
$Script:VerboseTitle = "VRB"
$Script:WarningTitle = "WRN"
$Script:BannerChar = "*"

# color according to message type
$Script:BeginColor = "Gray"
$Script:DebugColor = "Gray"
$Script:DevelColor = "DarkGray"
$Script:EnterColor = "Gray"
$Script:LeaveColor = "Gray"
# this use Write-Devel, so it use the DevelColor
# $Script:EnterFunctionColor = "DarkGray"
# $Script:LeaveFunctionColor = "DarkGray"
$Script:ErrorColor = "Red"
# Write-Fatal call Write-Error, so it use ErrorColor
# $Script:FatalColor = "Red"
$Script:InfoColor = "White"
$Script:MessageColor = "Gray"
$Script:QuestionColor = "Cyan"
$Script:TitleColor = "Green"
$Script:TodoColor = "Magenta"
$Script:VerboseColor = "Gray"
$Script:WarningColor = "Yellow"

# RCPosition specify the position of return codes on screen. Value can be
# * BEGIN : display return code at the beginning of the line
# * END   : display return code at the end of the line of the terminal
# * HALF  : display return code at half the width of the terminal
# * FLOW  : display return code in the terminal flow
$Script:RCPosition = 'HALF'
$Script:RCLength = 8
$Script:RCOpenChar = '['
$Script:RCCloseChar = ']'
$Script:RCDisplayFormat = "[{0,6}]"

<#
.SYNOPSIS
Change behavior of all Write-* functions

.DESCRIPTION
This function give the user full power over the way Write-* functions display information

.PARAMETER MessageDisplayFormat
Full string format to use to display text.
The format is compliant with the "-f" powershell operator.
See https://docs.microsoft.com/fr-fr/powershell/scripting/learn/deep-dives/everything-about-string-substitutions?view=powershell-7.1#format-string
or https://ss64.com/ps/syntax-f-operator.html for details about -f operator
In the string, use {#} syntax as placeholders for following parameters, where # is a number :
{0} is the message title (message type)
{1} is the indentation
{2} is the message text

.PARAMETER RCDisplayFormat
Full string format to use to display return codes.
The format is compliant with the "-f" powershell operator.
See https://docs.microsoft.com/fr-fr/powershell/scripting/learn/deep-dives/everything-about-string-substitutions?view=powershell-7.1#format-string
or https://ss64.com/ps/syntax-f-operator.html for details about -f operator
In the string, use {#} syntax as placeholders for following parameters, where # is a number :
{0} is the message text to display

.PARAMETER titleChar
Character to use to surround title text

.PARAMETER lineBreakChar
Character to use as line break

.EXAMPLE
Set-PwShFwDisplayConfiguration -MessageDisplayFormat "[{0,4}] {2}"

Will display severity between square brackets and suppress indentation.

.EXAMPLE
Set-PwShFwDisplayConfiguration -MessageDisplayFormat "{1}{2}" -RCDisplayFormat "[ {0,6} ]"

Will configure to display indentation an message text, but not severity. It will also configure the format of return codes.

.NOTES
General notes
#>
function Set-PwShFwDisplayConfiguration {
	[CmdletBinding()]
	[OutputType([void])]
	Param (
		# [Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$prepend = $Script:prepend,
		# [Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$postpend = $Script:postpend,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$MessageDisplayFormat = $Script:MessageDisplayFormat,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$RCDisplayFormat = $Script:RCDisplayFormat,
		[ValidateSet('BEGIN', 'END', 'HALF', 'FLOW')]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$RCPosition = $Script:RCPosition,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$IndentChar = $Script:IndentChar,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$IndentLength = $Script:IndentLength,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$titleChar = $Script:titleChar,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$lineBreakChar = $Script:lineBreakChar
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		# $Script:prepend = $prepend
		# $Script:postpend = $postpend
		$Script:MessageDisplayFormat = $MessageDisplayFormat
		$Script:RCDisplayFormat = $RCDisplayFormat
		$Script:RCPosition = $RCPosition
		$Script:IndentChar = $IndentChar
		$Script:IndentLength = $IndentLength
		$Script:titleChar = $titleChar
		$Script:lineBreakChar = $lineBreakChar
	}

	End {
		Write-LeaveFunction
	}
}

function Get-PwShFwDisplayConfiguration {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		# Write-Devel "New configuration : "
		# Write-Devel "Prepend = $Prepend"
		# Write-Devel "Postpend = $postpend"
		Write-Devel "MessageDisplayFormat = $Script:MessageDisplayFormat"
		Write-Devel "RCDisplayFormat = $Script:RCDisplayFormat"
		Write-Devel "RCPosition = $Script:RCPosition"
		Write-Devel "IndentChar = $Script:IndentChar"
		Write-Devel "IndentLength = $Script:IndentLength"
		Write-Devel "titleChar = $Script:titleChar"
		Write-Devel "lineBreakChar = $Script:lineBreakChar"
	}

	End {
		Write-LeaveFunction
	}
}


function Set-ReturnCodePosition {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[ValidateSet('BEGINNIG', 'END')]
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$position
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		$Script:RCPosition = $position
	}

	End {
		Write-LeaveFunction
	}
}

<#
.SYNOPSIS
Set new indentation

.DESCRIPTION
Set-Indent permit user to set indentation regardless of where indentation actually is.

.PARAMETER String
String parameter must be only composed of ' ' (space) character. It sets the indentation with literal given string

.PARAMETER Int
Int is the number of space character to indent

.EXAMPLE
Set-Indent -String "   "

.EXAMPLE
Set-Indent -Int 8

.EXAMPLE
Set-Indent -String ""
Resets the indentation string. It is equivalent as calling Reset-Indent

.NOTES
General notes

.LINK
#>

function Set-Indent {
	[CmdletBinding()][OutputType([String])]Param (
		[ValidatePattern('^ *$')]
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ParameterSetName = 'STRING')][string]$String,
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ParameterSetName = 'INT')][UInt16]$Int
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		switch ($PSCmdlet.ParameterSetName) {
			'STRING' {
				$Script:indent = $String
			}
			'INTEGER' {
				$Script:indent = " " * $Int
			}
		}
	}

	End {
		Write-LeaveFunction
	}
}

<#
.SYNOPSIS
Reset indentation to its default

.DESCRIPTION
Seomtimes indentation can be messed up with function that do not return properly, try-catch block, etc...
In this cases it is wishable to reset indentation string.
The default indentation is an empty string.

.EXAMPLE
Reset-Indent

.NOTES
General notes

.LINK
#>

function Reset-Indent {
	# [CmdletBinding()][OutputType([String])]Param (
	# 	[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$string
	# )
	Begin {
		Write-EnterFunction
	}

	Process {
		$Script:indent = ""
	}

	End {
		Write-LeaveFunction
	}
}

<#
	.SYNOPSIS
	Indent further calls to e*() functions

	.DESCRIPTION
	Indent with 2 spaces

	.NOTES
		TODO:
			. add parameter to override indent size

.LINK
#>
function Write-Indent() {
	[CmdletBinding()]
	[OutputType([String])]
	param(
        [switch]$PassThru
    )
	# $Script:indent += "   "
	$Script:indent += $Script:IndentChar * $Script:IndentLength
	if ($PassThru) { return $Script:indent }
}

<#
	.SYNOPSIS
	Outdent further calls to e*() functions

	.DESCRIPTION
	un-indent for 2 spaces

	.NOTES
		TODO:
			. add parameter to override indent size

.LINK
#>
function Write-Outdent() {
	[CmdletBinding()]
	[OutputType([String])]
	param(
        [switch]$PassThru
    )
	if ($Script:indent.Length -gt $Script:IndentLength) {
		$Script:indent = $Script:indent.Substring(0,$Script:indent.Length - $Script:IndentLength)
	} else {
		$Script:indent = ""
	}
	if ($PassThru) { return $Script:indent }
}

<#
	.SYNOPSIS
	Print a title

	.DESCRIPTION
	Print a title in green


.LINK
#>
function Write-Title() {
	[CmdletBinding()]param(
		[string]$Message
    )
    $hr = $Script:titleChar * ($message.Length + $indent.length + 6)
	$message = ($Script:titleChar * 2) + " " + $message + " " + ($Script:titleChar * 2)
	Add-ToLogFile -NoNewline -Message $hr
	Add-ToLogFile -NoNewline -Message $message
	if ($Global:QUIET -eq $false) { Write-Message -Title $Script:TitleTitle -Color $Script:TitleColor "$hr" }
	if ($Global:QUIET -eq $false) { Write-Message -Title $Script:TitleTitle -Color $Script:TitleColor $message }
	if ($Global:QUIET -eq $false) { Write-Message -Title $Script:TitleTitle -Color $Script:TitleColor "$hr" }
}

function Write-LineBreak {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[string]$char = $Script:lineBreakChar
	)

	[int32]$width = $Host.UI.RawUI.WindowSize.Width
    $hr = $char * $width
	Add-ToLogFile -NoNewline -Message $hr
	if ($Global:QUIET -eq $false) { Write-Host $hr }

}

<#
	.SYNOPSIS
	Print a message without new line

	.DESCRIPTION
	Print a message without new line

	 .PARAMETER message
	Text to display on screen

	 .PARAMETER width
	Optional. Used to pad text to the left.


.LINK
#>
function Write-Begin() {
    [CmdletBinding()]param(
        [string]$Message,
		[int32]$width = $Host.UI.RawUI.WindowSize.Width
    )
    # $fullMessage = $prepend + $indent + $message + "... "
    #$ht = "." * ($Host.UI.RawUI.WindowSize.Width - $message.Length)
	# $width = $width - 16
    # if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor DarkGreen $("`n{0,-$width}" -f $fullMessage) }
	# Add-ToLogFile -NoNewline -Message $fullMessage
	Write-Message -Message $Message -Title $Script:BeginTitle
}

<#
	.SYNOPSIS
	Add message to current line.

	.DESCRIPTION
	Add text to current line of text. No new line at the beginning, no new line at the end.


.LINK
#>
function Write-Add() {
    [CmdletBinding()]param(
        [string]$Message
    )
    if ($Global:QUIET -eq $false) { Write-Host -NoNewline $Message }
	Add-ToLogFile -NoNewline -NoHeader -Message $message
}

function Write-ReturnCode {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ParameterSetName = 'STRING')][string]$string,
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ParameterSetName = 'CODE')][string]$code,
		[ValidateSet('BEGINNIG', 'END')][string]$Position = $Script:RCPosition
	)

	switch ($PSCmdlet.ParameterSetName) {
		'STRING' {
			$code = Get-ReturnCodeId -id "$string"
		}
		'CODE' {
			$string = Get-ReturnCodeString -code $code
		}
	}
	$color = Get-ReturnCodeColor -code $code
	$message = "{0} {1,-$Script:RCLength} {2} " -f $Script:RCOpenChar, $string, $Script:RCCloseChar
	if ($Global:QUIET -eq $false) {
		if ($Host) {
			switch ($Position) {
				'BEGINNIG' {
					$X = 0
					$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $X,$Host.UI.RawUI.CursorPosition.Y
				}
				'END' {
					$Width = $Host.UI.RawUI.WindowSize.Width
					$X = $Width - $message.length
					$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $X,$Host.UI.RawUI.CursorPosition.Y
				}
			}
		}
		Write-Host -NoNewline -ForegroundColor $color $message
	}
	Add-ToLogFile -NoNewline -NoHeader -Message "`t$message"

}

<#
	.SYNOPSIS
	Print a message depending on return code

	.DESCRIPTION
	Print a message of status code.
    All status MUST have the same length. It is used to properly align all messages


.LINK
#>
function Write-End() {
    [CmdletBinding()]param(
        $errorCode,
		[string]$Message
    )

	if ([string]::IsNullOrEmpty($Message)) {
		if (-not($errorCode)) { $errorCode = $false }
		$color = "White"  ; $message = $errorCode

		switch -wildcard ($errorCode.GetTYpe().Name) {
			"Bool*" {
				switch ($errorCode) {
					$true  { $color = "Green"   ; $message = "  ok  " }
					$false { $color = "Red"     ; $message = "failed" }
				}
			}
			"Int*" {
				switch ($errorCode) {
					# 0 is never called since `Write-End 0` goes to the bool switch
					# 0	{ $color = "Green";		$message = "   ok    " }
					1	{ $color = "Red";		$message = "failed " }
					2	{ $color = "DarkGreen"; $message = "running" }
					3	{ $color = "Yellow";	$message = "missed " }
					4	{ $color = "Gray";		$message = "skipped" }
					5	{ $color = "Gray";		$message = "unused " }
					6	{ $color = "Gray";		$message = "unknown" }
					7	{ $color = "Red";		$message = " dead  " }
					8	{ $color = "Gray";		$message = "notFound" }
				}
			}
			# "pwshfwERROR" {
			# 	switch ($errorCode) {
			#         ([pwshfwERROR]::OK)		{ $color = "Green";		$message = "   ok    " }
			# 		([pwshfwERROR]::FAILED)	{ $color = "Red";		$message = " failed  " }
			# 		([pwshfwERROR]::RUNNING)	{ $color = "DarkGreen"; $message = " running " }
			# 		([pwshfwERROR]::MISSED)	{ $color = "Yellow";	$message = " missed  " }
			# 		([pwshfwERROR]::SKIPPED)	{ $color = "Gray";		$message = " skipped " }
			# 		([pwshfwERROR]::UNUSED)	{ $color = "Gray";		$message = " unused  " }
			# 		([pwshfwERROR]::UNKNOWN)	{ $color = "Gray";		$message = " unknown " }
			# 		([pwshfwERROR]::DEAD)		{ $color = "Red";		$message = "  dead   " }
			# 		([pwshfwERROR]::NOTFOUND)	{ $color = "Gray";		$message = "not found" }
			# 		default 			{ $color = "White";		$message = $errorCode }
			# 	}
			# }
		}
	}

	$fullmessage = $Script:RCDisplayFormat -f $Message
	switch ($Script:RCPosition) {
		'BEGIN' {
			$cursor = $host.UI.RawUI.CursorPosition
			$cursor.X = 0
			$host.UI.RawUI.CursorPosition = $cursor
		}
		'END' {
			$cursor = $host.UI.RawUI.CursorPosition
			$cursor.X = $host.UI.RawUI.WindowSize.Width - $fullmessage.Length - 2
			$host.UI.RawUI.CursorPosition = $cursor
		}
		'HALF' {
			$cursor = $host.UI.RawUI.CursorPosition
			$cursor.X = ($host.UI.RawUI.WindowSize.Width / 2) - $fullmessage.Length - 2
			$host.UI.RawUI.CursorPosition = $cursor
		}
		'FLOW' {
			$fullmessage = " $fullmessage"
		}
	}
    if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor $color $fullmessage }
	Add-ToLogFile -NoNewline -NoHeader -Message $fullmessage
}

<#
	.SYNOPSIS
	Print a message when entering a function

	.DESCRIPTION
	Print a message specifically when entering a function.

	.EXAMPLE
	# eenter ""

.LINK

#>
function Write-EnterFunction() {
    # [CmdletBinding()]param(
    #     [string]$Message
    # )
    $callStack = Get-PSCallStack
    if ($callStack.Count -gt 1) {
		$message = "$($callStack[1].InvocationInfo.MyCommand.Module)"
		if (-not [string]::IsNullOrEmpty($message)) { $message += "\" }
		$message += $($callStack[1].Command)
		# $callStack[1] | ConvertTo-Json | Set-Content /tmp/callstack.txt
		# $callStack[1].InvocationInfo | ConvertTo-Json | ForEach-Object { Write-Devel $_ }
    }
	$message = $Script:EnterFunctionTitle + $message + "()"
	if ($Global:TRACE) {
		Write-Devel -Message $message
		Write-Indent
	}
}

<#
	.SYNOPSIS
	Print a message when leaving a function

	.DESCRIPTION
	Print a message specifically when entering a function.

	.EXAMPLE
	# eenter ""

.LINK

#>
function Write-LeaveFunction() {
    # [CmdletBinding()]param(
    #     [string]$Message
    # )
    $callStack = Get-PSCallStack
    if ($callStack.Count -gt 1) {
		$message = "$($callStack[1].InvocationInfo.MyCommand.Module)"
		if (-not [string]::IsNullOrEmpty($message)) { $message += "\" }
		$message += $($callStack[1].Command)
		# $callStack[1] | fl *
    }
	$message = $Script:LeaveFunctionTitle + $message + "()"
	if ($Global:TRACE) {
		Write-Outdent
		Write-Devel -Message $message
	}
}

<#
	.SYNOPSIS
	Print a message when entering something

	.DESCRIPTION
	Print a message and indent output for following messages.
	It is useful when entering a loop, or a module, or an external script.

	.EXAMPLE
	# eenter ""

.LINK

#>
function Write-Enter() {
    [CmdletBinding()]param(
        [string]$Message
    )
	# $message = ">> " + $message
	# Write-Info ($message)
	Write-Message -Message $Message -Title $Script:EnterTitle
	Write-Indent
}

<#
	.SYNOPSIS
	Print a message when leaving a something

	.DESCRIPTION
	Print a message specifically when entering a function.
	It is useful when leaving a loop, or a module, or an external script.

	.EXAMPLE
	# eenter ""

.LINK

#>
function Write-Leave() {
    [CmdletBinding()]param(
        [string]$Message
    )
	Write-Outdent
	# $message = $Script:LeaveTitle + $message
	Write-Message -Message $message -Title $Script:LeaveTitle
}

<#
	.SYNOPSIS
	Print a devel message

	.DESCRIPTION
	Used to print content of command

.LINK

#>
function Write-Devel() {
    [CmdletBinding()]param(
        [string]$Message
    )
	# $fullmessage = $prepend
	# if ($Script:DisplaySeverity) { $fullmessage += "DEV: " }
	# $fullmessage += $indent + $message
	# Add-ToLogFile -NoNewline -Message $fullmessage
    # if ($Global:DEVEL -eq $false) { return }
    # if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor DarkGray ("`n" + $fullmessage) }
    #Write-Debug ($indent + "    " + $message)
	if ($Global:DEVEL) {
		Write-Message -Message $Message -Title $Script:DevelTitle -Color $Script:DevelColor
	}
}

<#
	.SYNOPSIS
	Print a debug message

	.DESCRIPTION
	Override Write-Debug() powershell function
    Mainly used to print Key = Valu pair

.LINK

#>
function Write-Debug() {
    [CmdletBinding()]param(
        [string]$Message
    )
	# $fullmessage = $prepend
	# if ($Script:DisplaySeverity) { $fullmessage += "DBG: " }
	# $fullmessage += $indent + $message
	# Add-ToLogFile -NoNewline -Message $fullmessage
    # if ($Global:DEBUG -eq $false) { return }
    # if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor Gray ("`n" + $fullmessage) }
    #Write-Debug ($indent + "    " + $message)
	if ($Global:DEBUG) {
		Write-Message -Message $Message -Title $Script:DebugTitle -Color $Script:DebugColor
	}
}

<#
	.SYNOPSIS
	Print a verbose message

	.DESCRIPTION
	Override Write-Verbose() powershell function

.LINK

#>
function Write-Verbose() {
    [CmdletBinding()]param(
        [string]$Message
    )
	# $fullmessage = $prepend + $indent + $message
	# Add-ToLogFile -NoNewline -Message $fullmessage
    # if ($VERBOSE -eq $false) { return }
    # if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor White  ("`n" + $fullmessage) }
    #Write-Verbose ($indent + "    " + $message)
	if ($Global:VERBOSE) {
		Write-Message -Message $Message -Title $Script:VerboseTitle -Color $Script:VerboseColor
	}
}

<#
	.SYNOPSIS
	Print a warning message

	.DESCRIPTION
	Override Write-Warning() powershell function

.LINK

#>
function Write-Warning() {
    [CmdletBinding()]param(
        [string]$Message
    )
	# $fullmessage = $prepend
	# if ($Script:DisplaySeverity) { $fullmessage += "WRN: " }
	# $fullmessage += $indent + $message
    # if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor Yellow ("`n" + $fullmessage) }
	# Add-ToLogFile -NoNewline -Message $fullmessage
	Write-Message -Message $Message -Title $Script:WarningTitle -Color $Script:WarningColor
}

<#
	.SYNOPSIS
	Print an error message

	.DESCRIPTION
	Override Write-Error() powershell function

.LINK

#>
function Write-Error() {
    [CmdletBinding(
		DefaultParameterSetName = "MESSAGE"
	)]param(
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true, Position = 1, ParameterSetName = 'MESSAGE')]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true, Position = 1, ParameterSetName = 'EXCEPTION')]
        [string]$Message,
		[string]$ErrorId,
		# [ValidateSet( [System.Management.Automation.ErrorCategory] )]
		[System.Management.Automation.ErrorCategory]$Category = "NotSpecified",
		[Object]$TargetObject,
		[string]$RecommendedAction,
		[string]$CategoryActivity,
		[string]$CategoryReason,
		[string]$CategoryTargetName,
		[string]$CategoryTargetType,
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ParameterSetName = 'EXCEPTION')]
		[System.Exception]$Exception,
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ParameterSetName = 'RECORD')]
		[System.Management.Automation.ErrorCategory]$ErrorRecord
	)
	# $fullmessage = $prepend
	# if ($Script:DisplaySeverity) { $fullmessage += "ERR: " }
	# $fullmessage += $indent + $message
    # if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor Red ("`n$fullmessage`n") }
	# Add-ToLogFile -NoNewline -Message ($fullmessage)
	# # propagate to Powershell's internal Write-Error
	# # Microsoft.PowerShell.Utility\Write-Error @PSBoundParameters
	Write-Message -Message $Message -Title $Script:ErrorTitle -Color $Script:ErrorColor
}

<#
	.SYNOPSIS
	Print an information message

	.DESCRIPTION
	Override Write-Information() powershell function

.LINK

#>
function Write-Info() {
    [CmdletBinding()]param(
        [string]$Message
    )
	# $fullmessage = $prepend + $indent + $message
	# Add-ToLogFile -NoNewline -Message ($fullmessage)
	# if ($INFO -eq $false) { return }
    # if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor Gray ("`n" + $fullmessage) }
	if ($Global:INFO) {
		Write-Message -Message $Message -Title $Script:InfoTitle -Color $Script:InfoColor
	}
}

function Write-Message {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[AllowEmptyString()][AllowNull()]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$Message,
		[ArgumentCompleter(
		{
			param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
			[consolecolor]::GetNames([consolecolor]) | Where-Object { $_ -like "$wordToComplete*" }
		}
		)]
		[ValidateScript(
			{
				$_ -in ([consolecolor]::GetNames([consolecolor]))
			}
		)]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $false)][string]$Color = "Gray",
		[Parameter(Mandatory = $false, ValueFromPipeLine = $false)][string]$Title = "MSG"
	)

	# $fullmessage = $prepend
	# if ($Script:DisplaySeverity) { $fullmessage += $title }
	# $fullmessage += $indent + $message
	$fullmessage = $Script:MessageDisplayFormat -f $title, $indent, $Message
    if ($Global:QUIET -eq $false) { Write-Host -NoNewline -ForegroundColor $color ("`n" + $fullmessage) }
	Add-ToLogFile -NoNewline -Message ($fullmessage)
}

function Write-Todo {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$Message
	)

	Write-Message -color $Script:TodoColor -title $Script:TodoTitle -Message $message
}

<#
	.SYNOPSIS
	Print a fatal error message then exist script

	.DESCRIPTION
	Print an error message before terminate current script

	.EXAMPLE
	Write-Fatal "fatal error. Abort."

.LINK

#>
function Write-Fatal() {
    [CmdletBinding()]param(
        [string]$Message
    )
	Write-Error -Message "$message. Aborting."
	try {
		Throw "$message. Aborting."
	} catch {
		$lines = $_.ScriptStackTrace -split "`n"
		# $lines.GetType()
		[array]::reverse($lines)
		Write-Devel -MEssage "Showing stack trace :"
		$lines | Select-Object -SkipLast 1 | ForEach-Object { Write-Devel -Message $_ }
	}
	# Write-LineBreak
	# if (!$DEVEL) { eerror "Please run your script in devel logging with -dev parameter to see a full stack trace of the exception." }
	Throw "$message. Aborting."
}

<#
	.SYNOPSIS
	Wrapper to PwSh.Fw.Log's Write-ToLogFile().

	.DESCRIPTION
	All the Write-*() functions from this module use Write-ToLogFile(). This wrapper is here just in case the PwSh.Fw.Log module is not loaded/available.

	.PARAMETER Append
	Append message to the log file. Do not overwrite it.
	Append = $true is the default. If you want to overwrite or initiate the file, call
	Write-ToLogFile -message "Logfile initialized" -Append=$false

	.PARAMETER NoNewline
	Do not append a new line at the end of file.

	.PARAMETER NoHeader
	Do not print header informations : "date hostname scriptname". Usefull to append text to an existing line.

	.PARAMETER Message
	The message to write to the logfile

	.PARAMETER LogFile
	Full path to the logfile

	.EXAMPLE
	Write-ToLogFile -message "a log entry" -append

.LINK

#>
function Write-ToLogFile() {
    [CmdletBinding()]param(
		[switch]$Append,
		[switch]$NoNewLine,
		[switch]$NoHeader,
		[string]$Message,
		[string]$logFile = $Global:LOG
	)
	# old method using ubounded arguments, but I failed to make it work
	# # Write-Host("`n >> " + $MyInvocation.MyCommand)
	# Write-Host($MyInvocation.PSBoundParameters | Convertto-Json)
	# Write-Host($MyInvocation.UnboundArguments | Convertto-Json)
	# $module = Get-Module PwSh.Fw.Log -ErrorAction SilentlyContinue
	# if ($null -ne $module) {
	# 	PwSh.Fw.Log\Write-ToLogFile $MyInvocation.PSBoundParameters
	# 	PwSh.Fw.Log\Write-ToLogFile ($MyInvocation.UnboundArguments).ToString()
	# }
	# # Write-Host("`n << " + $MyInvocation.MyCommand)

	# new method with bounded parameters
	$module = Get-Module PwSh.Fw.Log -ErrorAction SilentlyContinue
	if ($null -ne $module) {
		PwSh.Fw.Log\Write-ToLogFile -Append:$Append -NoNewLine:$NoNewLine -NoHeader:$NoHeader -Message "$Message" -logFile $logFile
	}

}

function Add-ToLogFile {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[switch]$NoNewLine,
		[switch]$NoHeader,
		[string]$Message,
		[string]$logFile = $Global:LOG
	)

	Write-ToLogFile -Append -NoNewLine:$NoNewLine -NoHeader:$NoHeader -Message "$Message" -logFile $logFile
}

function Ask-Question {
	[CmdletBinding()]
	[OutputType([String], [Int])]
	Param (
		[Alias('Question')]
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$Prompt,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$DefaultValue,
		[Parameter(Mandatory = $false, ValueFromPipeLine = $true)][string]$DefaultAnswer
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		Write-Message -Message "$Prompt [$DefaultValue] " -Title $Script:QuestionTitle -Color $Script:QuestionColor
		if ($DefaultAnswer) {
			Write-Host -NoNewLine -ForegroundColor Green "$DefaultAnswer "
			return $DefaultAnswer
		}
		# $value = Read-Host -Prompt "$Prompt [$DefaultValue]"
		$value = Read-Host
		if ([string]::IsNullOrWhiteSpace($value)) { $value = $DefaultValue }
		return $value
	}

	End {
		# Write-LeaveFunction
	}
}

Set-Alias -Force -Confirm:$false -Name eindent		-Value Write-Indent
Set-Alias -Force -Confirm:$false -Name eoutdent		-Value Write-Outdent
Set-Alias -Force -Confirm:$false -Name etitle		-Value Write-Title
Set-Alias -Force -Confirm:$false -Name ebegin		-Value Write-Begin
Set-Alias -Force -Confirm:$false -Name eadd			-Value Write-Add
Set-Alias -Force -Confirm:$false -Name eend			-Value Write-End
Set-Alias -Force -Confirm:$false -Name fenter		-Value Write-EnterFunction
Set-Alias -Force -Confirm:$false -Name fleave		-Value Write-LeaveFunction
Set-Alias -Force -Confirm:$false -Name eenter		-Value Write-Enter
Set-Alias -Force -Confirm:$false -Name eleave		-Value Write-Leave
Set-Alias -Force -Confirm:$false -Name einfo		-Value Write-Info
Set-Alias -Force -Confirm:$false -Name everbose		-Value Write-Verbose
Set-Alias -Force -Confirm:$false -Name edebug		-Value Write-Debug
Set-Alias -Force -Confirm:$false -Name edevel		-Value Write-Devel
Set-Alias -Force -Confirm:$false -Name ewarn		-Value Write-Warning
Set-Alias -Force -Confirm:$false -Name eerror		-Value Write-Error
Set-Alias -Force -Confirm:$false -Name efatal		-Value Write-Fatal
Set-Alias -Force -Confirm:$false -Name erc			-Value Write-ReturnCode
Set-Alias -Force -Confirm:$false -Name equestion	-Value Write-Question

# obsoletes aliases
Set-Alias -Force -Confirm:$false -Name Write-MyVerbose		-Value Write-Verbose
Set-Alias -Force -Confirm:$false -Name Write-MyDebug		-Value Write-Debug
Set-Alias -Force -Confirm:$false -Name Write-MyWarning		-Value Write-Warning
Set-Alias -Force -Confirm:$false -Name Write-MyError		-Value Write-Error
