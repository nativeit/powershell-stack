# Array of error and return code translation to text. Only english for the moment.
$E_CODE = @()
# rc = 0
$E_CODE += "ok"
$E_CODE += "failed"
$E_CODE += "running"
$E_CODE += "missed"
$E_CODE += "skiped"
$E_CODE += "unused"
$E_CODE += "unknown"
$E_CODE += "dead"
$E_CODE += "notfound"

$E_ID = @{}
for ($i = 0; $i -lt $E_CODE.Length; $i++) {
	$id = $E_CODE.$i
	$E_ID.$id = $i
}

# set default colors
$E_COLOR = @()
$E_COLOR += "Green"
$E_COLOR += "Red"
$E_COLOR += "DarkGreen"
$E_COLOR += "Yellow"
$E_COLOR += "Gray"
$E_COLOR += "Gray"
$E_COLOR += "Gray"
$E_COLOR += "Red"
$E_COLOR += "Gray"

function Get-ReturnCodeString {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][uint16]$code
	)

	return $E_CODE[$code]
}

function Get-ReturnCodeId {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][string]$id
	)

	return $E_ID.$id
}

function Get-ReturnCodeColor {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][uint16]$code
	)

	return $E_COLOR[$code]
}
