$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
$Project = Get-Content "$ROOTDIR/project.yml" -Raw | ConvertFrom-Yaml
$ModuleName = $BASENAME -replace ".tests.ps1"

# load header
. $PSScriptRoot/header.inc.ps1

Remove-Module $ModuleName
$null = Import-Module -FullyQualifiedName $ROOTDIR/$($Project.Name)/Includes/$ModuleName.psm1 -Force -PassThru -ErrorAction stop
Mock Write-Host { } -ModuleName PwSh.Fw.Write

Describe "PwSh.Fw.Write Module" {

	Context "Functions Write-*" {

        # Mock Write-Host { return $Message } -ModuleName PwSh.Fw.Write

		It "Indent correctly - 1st time" {
			$indent = Write-Indent -PassThru
			$indent | Should -BeExactly "   "
		}

		It "Indent correctly - 2nd time" {
			$indent = Write-Indent -PassThru
			$indent | Should -BeExactly "      "
		}
		
		It "Outdent correctly - 1st time" {
			$indent = Write-Outdent -PassThru
			$indent | Should -BeExactly "   "
		}

		It "Outdent correctly - 2nd time" {
			$indent = Write-Outdent -PassThru
			$indent | Should -BeExactly ""
		}
		
		It "Write-Title() exist -PassThru" {
			$msg = Write-Title -Message "This is a title" -PassThru
			$msg | Should -BeExactly "** This is a title **"
		}

		It "Write-Title() exist" {
			Write-Title -Message "This is a title"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 2 -Scope It
		}

		It "Write-Begin() exist" {
			Write-Begin -Message "This is a begin"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-Add() exist" {
			Write-Add -Message "This is a Add"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

        $TestCases = @($true, $false, [int]0, 1, 2, 3, 4, 5, 6, 7, 8, 'default')
        Foreach ($t in $TestCases) {
            It "Write-End() handle '$t'" {
                Write-End $t
                Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
            }
        }

		It "Write-EnterFunction() honor `$Global:TRACE" {
            $Global:TRACE = $false
			Write-EnterFunction -Message "Enter a function"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 0 -Scope It
            $Global:TRACE = $true
			Write-EnterFunction -Message "Enter a function"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-LeaveFunction() honor `$Global:TRACE" {
            $Global:TRACE = $false
			Write-LeaveFunction -Message "Enter a function"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 0 -Scope It
            $Global:TRACE = $true
			Write-LeaveFunction -Message "Enter a function"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-Enter() exist" {
			Write-Enter -Message "Write-Enter()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-Leave() exist" {
			Write-Leave -Message "Write-Leave()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-Devel() honor `$Global:DEVEL" {
            $Global:DEVEL = $false
			Write-Devel -Message "Write-Devel()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 0 -Scope It
            $Global:DEVEL = $true
			Write-Devel -Message "Write-Devel()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-MyDebug() honor `$Global:DEBUG" {
            $Global:DEBUG = $false
			Write-MyDebug -Message "Write-MyDebug()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 0 -Scope It
            $Global:DEBUG = $true
			Write-MyDebug -Message "Write-MyDebug()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-MyVerbose() honor `$Global:VERBOSE" {
            $Global:VERBOSE = $false
			Write-MyVerbose -Message "Write-MyVerbose()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 0 -Scope It
            $Global:VERBOSE = $true
			Write-MyVerbose -Message "Write-MyVerbose()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-MyWarning() exist" {
			Write-MyWarning -Message "Write-MyWarning()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-MyError() exist" {
			Write-MyError -Message "Write-MyError()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-Info() exist" {
			Write-Info -Message "Write-Info()"
            Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Write-Fatal() throws error" {
            { Write-Fatal -Message "Write-Fatal()" } | Should -Throw
            # Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

	}
}
