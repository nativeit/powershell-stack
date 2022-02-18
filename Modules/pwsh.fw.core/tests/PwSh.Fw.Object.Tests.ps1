$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
$Project = Get-Content "$ROOTDIR/project.yml" -Raw | ConvertFrom-Yaml
$ModuleName = $BASENAME -replace ".tests.ps1"

# load header
. $PSScriptRoot/header.inc.ps1

Remove-Module $ModuleName
$null = Import-Module -FullyQualifiedName $ROOTDIR/$($Project.Name)/Includes/$ModuleName.psm1 -Force -PassThru -ErrorAction stop
Mock Write-Host { } -ModuleName PwSh.Fw.Write

Describe "PwSh.Fw.Object" {

	Context "objects" {

		It "Merge 2 objects" {
			$o1 = [PSCustomObject]@{'h1_1' = "value 1-1"; 'h1_2' = "value 1-2"}
			$o2 = [PSCustomObject]@{'h2_1' = "value 2-1"; 'h2_2' = "value 2-2"}
			# $res = [PSCustomObject]@{'h1_1' = "value 1-1"; 'h1_2' = "value 1-2"; 'h2_1' = "value 2-1"; 'h2_2' = "value 2-2"}
			$out = Merge-Object $o1 $o2
			$out.'h1_1' | Should -BeExactly "value 1-1"
			$out.'h2_2' | Should -BeExactly "value 2-2"
		}

		It "Merge 2 objects with same key" {
			$o1 = [PSCustomObject]@{'key1' = "value 1"; 'h1_2' = "value 1-2"}
			$o2 = [PSCustomObject]@{'key1' = "value 2"; 'h2_2' = "value 2-2"}
			# $res = [PSCustomObject]@{'h1_1' = "value 1-1"; 'h1_2' = "value 1-2"; 'h2_1' = "value 2-1"; 'h2_2' = "value 2-2"}
			$out = Merge-Object $o1 $o2
			$out.key1 | Should -BeExactly "value 2"
		}

		# It "Sort object properties" {
		# 	$o1 = [PSCustomObject]@{'zz' = "value 1"; 'aa' = "value 1-2"}
		# 	$res = [PSCustomObject]@{'aa' = "value 1-2"; 'zz' = "value 1"}
		# 	$out = $o1 | Sort-Properties
		# 	$out | Should -BeExactly $res
		# }

	}

    Context "hashtables" {

        It "Convert a hashtable to a single string" {
            $ht = @{'key'="value";'key2'="value2"}
            $s = $ht | ConvertTo-SingleString
            $s | Should -BeExactly "@{'key'=`"value`";'key2'=`"value2`"}" 
        }

        It "Convert a hashtable with date to a single string" {
            $ht = @{'key'="value";'key2'= (Get-Date -Year 2020 -Month 12 -Day 31 -Hour 08 -Minute 16 -Second 32)}
            $s = $ht | ConvertTo-SingleString
            $s | Should -BeExactly "@{'key'=`"value`";'key2'=[System.DateTime]`"12/31/2020 08:16:32`"}"
        }

        It "Convert another type of object to a single string fail" {
            $obj = Get-Process | Select-Object -First 1
            $s = $obj | ConvertTo-SingleString
            $s | Should -BeFalse
		}
		
		It "Merge 2 hashtables" {
			$h1 = @{'h1_1' = "value 1-1"; 'h1_2' = "value 1-2"}
			$h2 = @{'h2_1' = "value 2-1"; 'h2_2' = "value 2-2"}
			$ht = Merge-Hashtables $h1 $h2
			$ht | Should -MatchHashtable @{'h1_1' = "value 1-1"; 'h1_2' = "value 1-2"; 'h2_1' = "value 2-1"; 'h2_2' = "value 2-2"}
		}

		It "Sort hashtable" {
			$h1 	= 			@{'a' = "a"; 'z' = "z"; 'b' = "b"; 'm' = "m"; 'j' = "j"}
			# $tpl 	= [ordered]	@{'a' = "a"; 'b' = "b"; 'j' = "j"; 'm' = "m"; 'z' = "z"}
			$ht = $h1 | Sort-HashTable
			$ht | Should -MatchHashtable @{'a' = "a"; 'b' = "b"; 'j' = "j"; 'm' = "m"; 'z' = "z"}
		}

	}

	Context "Strings" {

        It "Remove latin char from string" {
            $s = "aàâä-AÀÂÄ eéèêë-EÉÈÊË iîï-IÎÏ oôö-OÔÖ uùûü-UÙÛÜ yŷÿ-YŶŸ"
            $s | Remove-StringLatinCharacters | Should -BeExactly "aaaa-AAAA eeeee-EEEEE iii-III ooo-OOO uuuu-UUUU yyy-YYY"
        }

        It "Convert a string to camelCase" {
            $s = "This is a test" | ConvertTo-CamelCase
            $s | Should -BeExactly "thisIsATest"
        }

        It "Get a property from a file $PSScriptRoot/../project.conf" {
            $p = Get-PropertyValueFromFile -Filename "$PSScriptRoot/../project.conf" -Propertyname name
            $p | Should -BeExactly "PwSh.Fw.Core"
        }
    
    }

	Context "Boolean" {

        $TestCases = @(
            @{ var = $true; eRC = $true },
            @{ var = 1; eRC = $true },
            @{ var = "yes"; eRC = $true },
            @{ var = "Yes"; eRC = $true },
            @{ var = "true"; eRC = $true },
            @{ var = "TRUE"; eRC = $true }
            @{ var = $false; eRC = $false },
            @{ var = 0; eRC = $false },
            @{ var = "no"; eRC = $false },
            @{ var = "NO"; eRC = $false },
            @{ var = "false"; eRC = $false },
            @{ var = "FALSE"; eRC = $false },
            @{ var = 34; eRC = $false },
            @{ var = "aze"; eRC = $false }
        )
        It "<var> return <eRC>" -TestCases $TestCases {
            param ($var, $eRC)
            $rc = Resolve-Boolean -var $var
            $rc | Should -Be $eRC
        }

    }

}
