<#
.SYNOPSIS
Helper functions for Pester

.DESCRIPTION
Helper functions found around the web to improve Pester

#>

<#
.SYNOPSIS
Assert array are equals

.DESCRIPTION
Long description

.PARAMETER test
Parameter description

.PARAMETER expected
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Assert-ArrayEquality($test, $expected) {
    $test | Should -HaveCount $expected.Count
    0..($test.Count - 1) | % {$test[$_] | Should -Be $expected[$_]}
}

function Assert-HashtableEquality($test, $expected) {
    $test.Keys | Should -HaveCount $expected.Keys.Count
    $test.Keys | % {$test[$_] | Should -Be $expected[$_]}
}

<#
.SYNOPSIS
Helper function to test equality between 2 objects

.DESCRIPTION
Deeply assert that two objects are the same

.PARAMETER test
the object to test

.PARAMETER expected
the object that contains expected values

.EXAMPLE
Assert-ObjectEquality $test $expected

.NOTES
* find @url https://medium.com/swlh/deep-equality-with-pester-a9a00c3cd8a1
* source code @url https://gist.github.com/chriskuech/cb86e8fddc6cca21ccffbe664ecdd803#file-medium-de-shallow-ps1

#>
function Assert-ObjectEquality($test, $expected) {
    $testKeys = $test.psobject.Properties | ForEach-Object Name
    $expectedKeys = $expected.psobject.Properties | ForEach-Object Name
    $testKeys | Should -HaveCount $expectedKeys.Count
    $testKeys | ForEach-Object { $test.$_ | Should -Be $expected.$_}
}

function Test-ParameterSet {
	[CmdletBinding(DefaultParameterSetName = 'NAME')]
	[OutputType([string])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'NAME')][string]$Name,
		[ValidateSet('Public', 'Private')]
		[Parameter(Mandatory = $false, ValueFromPipeLine = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'NAME')][string]$Type = 'Public',
		[Parameter(Mandatory = $false, ValueFromPipeLine = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'NAME')][string]$BasePath = $($Script:config.WWWRoot),
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'OBJECT')][object]$InputObject
	)

	Begin {
		Write-EnterFunction
	}

	Process {
		Write-Host "ParameterSetName =" $PSCmdlet.ParameterSetName
	}

	End {
		Write-EnterFunction
	}
}

