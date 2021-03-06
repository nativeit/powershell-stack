$ROOTDIR = (Resolve-Path $PSScriptRoot/../).Path
$BASENAME = Split-Path -Path $PSCommandPath -Leaf
$ModuleName = $BASENAME -replace ".tests.ps1"

# load header
. $PSScriptRoot/header.inc.ps1

$null = Import-Module -FullyQualifiedName $ROOTDIR/$($Project.Name)/$ModuleName.psm1 -Force -PassThru -ErrorAction stop

Describe "PwSh.Fw.Core" {

    Context "File handling" {

        It "Return $true if given file exist" {
            # New-Item /pester.txt -ErrorAction:SilentlyContinue
            $rc = Test-FileExist -Name $($PSScriptRoot + "/" + $BASENAME)
            $rc | Should Be $true
            # remove-item /pester.txt -Force:$true
        }

        It "Return $false if given file does NOT exist" {
            $rc = Test-FileExist -Name $($BASENAME + ".donotexist")
            $rc | Should Be $false
        }

        It "Return $false if given file is a directory" {
            # New-Item /pester.dir -ItemType Directory -ErrorAction:SilentlyContinue
            $rc = Test-FileExist -Name $PSScriptRoot
            $rc | Should Be $false
            # remove-item /pester.dir -Force:$true
        }

        It "Return $false if given file is an empty string" {
            $rc = Test-FileExist -Name ''
            $rc | Should Be $false
        }

        It "Return $false if given file is null" {
            $rc = Test-FileExist -Name $null
            $rc | Should Be $false
        }

    }

    Context "Directory handling" {

        It "Return $true if given directory exist" {
            # New-Item /pester.dir -ItemType Directory -ErrorAction:SilentlyContinue
            $rc = Test-DirExist -Path $PSScriptRoot
            $rc | Should Be $true
            # remove-item /pester.dir -Force:$true
        }

        It "Return $false if given directory does NOT exist" {
            # New-Item $Env:TEMP\noexist.txt -ErrorAction:SilentlyContinue
            $rc = Test-DirExist -Path $($PSScriptRoot + ".donotexist")
            $rc | Should Be $false
        }

        It "Return $false if given directory is a file" {
            # New-Item /pester.txt -ErrorAction:SilentlyContinue
            $rc = Test-DirExist -Path $($PSScriptRoot + "/" + $BASENAME)
            $rc | Should Be $false
            # remove-item /pester.txt -Force:$true
        }

	}

    Context "Registry handling" {

        $skipRegistryTest = $false
        $rc = Test-Path -Path "HKLM:\SOFTWARE" -PathType Container
        if ($rc -eq $false) { $skipRegistryTest = $true }

        it "Return $true if given registry key exist" -Skip:$skipRegistryTest {
            $rc = Test-RegKeyExist "HKLM:\SOFTWARE"
            $rc | Should Be $true
        }

        it "Return $false if given registry key does not exist" -Skip:$skipRegistryTest {
            $rc = Test-RegKeyExist "HKLM:\SOFTWARE_NOT_EXITS"
            $rc | Should Be $false
        }

        it "Return $true if given registry value exist" -Skip:$skipRegistryTest {
            $rc = Test-RegValueExist "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -name "ProductName"
            $rc | Should Be $true
        }

        it "Return $false if given registry value does not exist" -Skip:$skipRegistryTest {
            $rc = Test-RegValueExist "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -name "ProductNameNotExist"
            $rc | Should Be $false
        }

    }

    Context "Variable handling" {

        It "Return $true if variable exist" {
            $rc = Test-Variable -Name PWD
            $rc | Should -BeTrue
        }

        It "Return $false if variable does not exist" {
            $rc = Test-Variable -Name PWDQSDMOKJ
            $rc | Should -BeFalse
        }

    }

	Context "Functions testing" {

		It "New-TemplateFunction() exist" {
			$rc = New-TemplateFunction -string "This is a test"
			$rc | Should -BeExactly "This is a test"
		}

	}

    Context "Module" {

		It "Load-Module() return `$true on already loaded module (by name)" {
            $rc = Load-Module -Name Microsoft.PowerShell.Management
            $rc | Should -BeTrue
		}

		It "Load-Module() return `$true on successfully loaded module (by name)" {
            $rc = Load-Module -Name Microsoft.PowerShell.Management -Force
            $rc | Should -BeTrue
		}

		It "Load-Module() return `$true on successfully loaded module (by fqn)" {
            # $m = get-module -Name Microsoft.PowerShell.Management
            # Write-Debug "Loading $($PSScriptRoot)/../$($project.name)/$($project.name).psm1 module..."
            $rc = Load-Module -FullyQualifiedName "$PSScriptRoot/test.psd1" -Force
            $rc | Should -BeTrue
		}

		It "Load-Module() return `$false (by name)" {
            $rc = Load-Module -Name "nonExistingModule1" -Policy Optional
            $rc | Should -BeFalse
		}

		It "Load-Module() throws exception (by name)" {
            { Load-Module -Name "nonExistingModule2" -Policy Required } | Should -Throw
            # Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

		It "Load-Module() return `$false (by fqn)" {
            $rc = Load-Module -FullyQualifiedName "/path/to/nonExistingModule1" -Policy Optional
            $rc | Should -BeFalse
		}

		It "Load-Module() throws exception (by fqn)" {
            { Load-Module -FullyQualifiedName "/path/to/nonExistingModule2" -Policy Required } | Should -Throw
            # Assert-MockCalled -ModuleName PwSh.Fw.Write Write-Host -Exactly 1 -Scope It
		}

        $Global:VERBOSE=$true
		It "Load-Module() honors VERBOSE variable" {
            $rc = Load-Module -Name Microsoft.PowerShell.Management -Force
            $rc | Should -BeTrue
		}

        $Global:DEBUG=$true
		It "Load-Module() honors DEBUG variable" {
            $rc = Load-Module -Name Microsoft.PowerShell.Management -Force
            $rc | Should -BeTrue
		}

    }

}

Describe "Execute commands" {

	Mock -CommandName Write-Host { } -ModuleName PwSh.Fw.Write
	Context "Execute commands" {

        Mock Write-Host { } -ModuleName PwSh.Fw.Write
        Mock Write-Host { } -ModuleName PwSh.Fw.Core
        # $project = Get-Content "$PSScriptRoot/../project.conf" -Raw | ConvertFrom-StringData
        # $module = Get-Module $($project.name)
        # $module | Format-Table Name, Version

        foreach ($dev in @($false, $true)) {
            foreach ($d in @($false, $true)) {
                $Global:DEBUG = $d
                $Global:DEVEL = $dev

                It "Execute-Command() (DEBUG = $d / DEVEL = $dev) return `$true" {
                    $rc = Execute-Command -exe hostname
                    $rc | Should -BeTrue
                }
        
                It "Execute-Command() -AsInt (DEBUG = $d / DEVEL = $dev) return 0" {
                    $rc = Execute-Command -AsInt -exe hostname
                    $rc | Should -Be 0
                }
        
                It "Execute-Command() (DEBUG = $d / DEVEL = $dev) return `$true" {
                    $rc = Execute-Command -exe "$PSScriptRoot/test.ps1" -args "-q"
                    $rc | Should -BeTrue
                }
        
                It "Execute-Command() -AsInt (DEBUG = $d / DEVEL = $dev) return 0" {
                    $rc = Execute-Command -AsInt -exe "$PSScriptRoot/test.ps1" -args "-q"
                    $rc | Should -Be 0
                }
        
            }
        }
    }

}
