﻿Import-Module .\PSWinDocumentation.AD.psd1 -Force

# Using built-in password list (just one password P@ssw0rd!)
$Passwords = Invoke-ADPasswordAnalysis -Verbose

# Autogenerated HTML, without prettifying
New-HTML {
    foreach ($Domain in $Passwords.Keys) {
        New-HTMLTab -Name "Domain $Domain" {
            foreach ($Key in $Passwords.$Domain.Keys) {
                New-HTMLTab -Name "$Key" {
                    New-HTMLTable -DataTable $Passwords.$Domain[$Key]
                }
            }
        }
    }
} -Online -FilePath $Env:USERPROFILE\Desktop\Passwords.html -ShowHTML