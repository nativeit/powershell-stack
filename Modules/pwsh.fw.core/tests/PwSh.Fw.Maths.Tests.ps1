$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
$Project = Get-Content "$ROOTDIR/project.yml" -Raw | ConvertFrom-Yaml
$ModuleName = $BASENAME -replace ".tests.ps1"

# load header
. $PSScriptRoot/header.inc.ps1

$null = Import-Module -FullyQualifiedName $ROOTDIR/$($Project.Name)/Includes/$ModuleName.psm1 -Force -PassThru -ErrorAction stop

Describe "PwSh.Fw.Maths" {

    Context "Convert-Size bytes" {

        It "Convert from bytes to bytes" {
			$size = 128
			$rc = $size | Convert-Size -From bytes -To bytes
			$rc | should -BeExactly 128
		}

        It "Convert from kilobytes to bytes" {
			$size = 128
			$rc = $size | Convert-Size -From KB -To bytes
			$rc | should -BeExactly 131072
		}

        It "Convert from kilobytes to kilobytes" {
			$size = 128
			$rc = $size | Convert-Size -From KB -To KB
			$rc | should -BeExactly 128
		}

        It "Convert from megabytes to bytes" {
			$size = 128
			$rc = $size | Convert-Size -From MB -To bytes
			$rc | should -BeExactly 134217728
		}

        It "Convert from megabytes to kilobytes" {
			$size = 128
			$rc = $size | Convert-Size -From MB -To KB
			$rc | should -BeExactly 131072
		}

        It "Convert from megabytes to megabytes" {
			$size = 128
			$rc = $size | Convert-Size -From MB -To MB
			$rc | should -BeExactly 128
		}

        It "Convert from gigabytes to bytes" {
			$size = 128
			$rc = $size | Convert-Size -From GB -To bytes
			$rc | should -BeExactly 137438953472
		}

        It "Convert from gigabytes to kilobytes" {
			$size = 128
			$rc = $size | Convert-Size -From GB -To KB
			$rc | should -BeExactly 134217728
		}

        It "Convert from gigabytes to megabytes" {
			$size = 128
			$rc = $size | Convert-Size -From GB -To MB
			$rc | should -BeExactly 131072
		}

        It "Convert from gigabytes to gigabytes" {
			$size = 128
			$rc = $size | Convert-Size -From GB -To GB
			$rc | should -BeExactly 128
		}

        It "Convert from terrabytes to bytes" {
			$size = 128
			$rc = $size | Convert-Size -From TB -To bytes
			$rc | should -BeExactly 140737488355328
		}

        It "Convert from terrabytes to kilobytes" {
			$size = 128
			$rc = $size | Convert-Size -From TB -To KB
			$rc | should -BeExactly 137438953472
		}

        It "Convert from terrabytes to megabytes" {
			$size = 128
			$rc = $size | Convert-Size -From TB -To MB
			$rc | should -BeExactly 134217728
		}

        It "Convert from terrabytes to gigabytes" {
			$size = 128
			$rc = $size | Convert-Size -From TB -To GB
			$rc | should -BeExactly 131072
		}

        It "Convert from terrabytes to terrabytes" {
			$size = 128
			$rc = $size | Convert-Size -From TB -To TB
			$rc | should -BeExactly 128
		}

    }

}
