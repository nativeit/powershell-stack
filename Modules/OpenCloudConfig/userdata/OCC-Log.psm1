<#
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
#>

function Write-Log {
  [CmdletBinding()]
  param (
    [string] $message,
    [string] $severity = 'INFO',
    [string] $source = 'OpenCloudConfig',
    [string] $logName = 'Application'
  )
  begin {
    if (!([Diagnostics.EventLog]::Exists($logName)) -or !([Diagnostics.EventLog]::SourceExists($source))) {
      New-EventLog -LogName $logName -Source $source
    }
  }
  process {
    switch ($severity) {
      'DEBUG' {
        $entryType = 'SuccessAudit'
        $eventId = 2
        break
      }
      'WARN' {
        $entryType = 'Warning'
        $eventId = 3
        break
      }
      'ERROR' {
        $entryType = 'Error'
        $eventId = 4
        break
      }
      default {
        $entryType = 'Information'
        $eventId = 1
        break
      }
    }
    Write-EventLog -LogName $logName -Source $source -EntryType $entryType -Category 0 -EventID $eventId -Message $message
  }
  end {}
}