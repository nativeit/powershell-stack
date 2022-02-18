<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER From
Parameter description

.PARAMETER To
Parameter description

.PARAMETER Value
Parameter description

.PARAMETER Precision
Parameter description

.EXAMPLE
An example

.NOTES
General notes

.LINK
http://techibee.com/powershell/convert-from-any-to-any-bytes-kb-mb-gb-tb-using-powershell/2376
#>

function Convert-Size {
	[cmdletbinding()]
	param(
		[validateset("Bytes","KB","MB","GB","TB")][string]$From = "Bytes",
		[validateset("Bytes","KB","MB","GB","TB")][string]$To,
		[Parameter(Mandatory=$true,ValueFromPipeLine = $true)][double]$Value
		# [int]$Precision = 4
	)
	switch($From) {
		"Bytes" { $value = $Value }
		"KB" { $value = $Value * 1024 }
		"MB" { $value = $Value * 1024 * 1024}
		"GB" { $value = $Value * 1024 * 1024 * 1024}
		"TB" { $value = $Value * 1024 * 1024 * 1024 * 1024}
	}

	switch ($To) {
		"Bytes" {return $value}
		"KB" { $Value = $Value/1KB}
		"MB" { $Value = $Value/1MB}
		"GB" { $Value = $Value/1GB}
		"TB" { $Value = $Value/1TB}

	}

	# return [Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)
	return [Math]::Round($value)

	}

