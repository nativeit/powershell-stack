<#
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
#>

function Write-Log {
  param (
    [string] $message,
    [string] $severity = 'INFO',
    [string] $source = 'OpenCloudConfig',
    [string] $logName = 'Application'
  )
  if ((-not ([System.Diagnostics.EventLog]::Exists($logName))) -or (-not ([System.Diagnostics.EventLog]::SourceExists($source)))) {
    try {
      New-EventLog -LogName $logName -Source $source
    } catch {
      Write-Error -Exception $_.Exception -message ('failed to create event log source: {0}/{1}' -f $logName, $source)
    }
  }
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
  try {
    Write-EventLog -LogName $logName -Source $source -EntryType $entryType -Category 0 -EventID $eventId -Message $message
  } catch {
    Write-Error -Exception $_.Exception -message ('failed to write to event log source: {0}/{1}. the log message was: {2}' -f $logName, $source, $message)
  }
  if ($env:OccConsoleOutput -eq 'host') {
    $fc = @{ 'Information' = 'White'; 'Error' = 'Red'; 'Warning' = 'DarkYellow'; 'SuccessAudit' = 'DarkGray' }[$entryType]
    Write-Host -object $message -ForegroundColor $fc
  } elseif ($env:OccConsoleOutput) {
    Write-Output -InputObject $message
  }
}

function Install-SupportingModules {
  param (
    [string] $sourceOrg,
    [string] $sourceRepo,
    [string] $sourceRev,
    [string] $modulesPath = ('{0}\Modules' -f $pshome),
    [string[]] $moduleUrls = @(
      ('https://raw.githubusercontent.com/{0}/{1}/{2}/userdata/OCC-Bootstrap.psm1' -f $sourceOrg, $sourceRepo, $sourceRev)
    )
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
  }
  process {
    foreach ($url in $moduleUrls) {
      $filename = [IO.Path]::GetFileName($url)
      $moduleName = [IO.Path]::GetFileNameWithoutExtension($filename)
      $modulePath = ('{0}\{1}' -f $modulesPath, $moduleName)
      if ((Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') -or (Test-Path -Path $modulePath -ErrorAction 'SilentlyContinue')) {
        try {
          Remove-Module -Name $moduleName -Force -ErrorAction 'SilentlyContinue'
          Join-Path -Path $env:PSModulePath.split(';') -ChildPath $moduleName | % { Remove-Item -path $_ -recurse -force -ErrorAction 'SilentlyContinue' }
          Remove-Item -path $modulePath -recurse -force -ErrorAction 'SilentlyContinue'
          if (Test-Path -Path $modulePath -ErrorAction 'SilentlyContinue') {
            Write-Log -message ('{0} :: failed to remove module: {1}.' -f $($MyInvocation.MyCommand.Name), $moduleName) -severity 'ERROR'
          } else {
            Write-Log -message ('{0} :: removed module: {1}.' -f $($MyInvocation.MyCommand.Name), $moduleName) -severity 'DEBUG'
          }
        } catch {
          Write-Log -message ('{0} :: error removing module: {1}. {2}' -f $($MyInvocation.MyCommand.Name), $moduleName, $_.Exception.Message) -severity 'ERROR'
          if ($_.Exception.InnerException) {
            Write-Log -message ('{0} :: inner exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.InnerException.Message) -severity 'ERROR';
          }
        }
      }
      try {
        New-Item -ItemType Directory -Force -Path $modulePath
        (New-Object Net.WebClient).DownloadFile(('{0}?{1}' -f $url, [Guid]::NewGuid()), ('{0}\{1}' -f $modulePath, $filename))
        Unblock-File -Path ('{0}\{1}' -f $modulePath, $filename)
        if (Test-Path -Path $modulePath -ErrorAction 'SilentlyContinue') {
          Write-Log -message ('{0} :: installed module: {1}.' -f $($MyInvocation.MyCommand.Name), $moduleName) -severity 'DEBUG'
        } else {
          Write-Log -message ('{0} :: failed to install module: {1} from {2}.' -f $($MyInvocation.MyCommand.Name), $moduleName, $url) -severity 'ERROR'
        }
      } catch {
        Write-Log -message ('{0} :: error installing module: {1} from {2}. {3}' -f $($MyInvocation.MyCommand.Name), $moduleName, $url, $_.Exception.Message) -severity 'ERROR'
        if ($_.Exception.InnerException) {
          Write-Log -message ('{0} :: inner exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.InnerException.Message) -severity 'ERROR';
        }
      }
      try {
        Import-Module -Name $moduleName
        Write-Log -message ('{0} :: imported module: {1}.' -f $($MyInvocation.MyCommand.Name), $moduleName) -severity 'DEBUG'
      } catch {
        Write-Log -message ('{0} :: error importing module: {1}. {2}' -f $($MyInvocation.MyCommand.Name), $moduleName, $_.Exception.Message) -severity 'ERROR'
        if ($_.Exception.InnerException) {
          Write-Log -message ('{0} :: inner exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.InnerException.Message) -severity 'ERROR';
        }
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
  }
}

function Set-OpenCloudConfigSource {
  param (
    [string] $locationType = $(
      if (Get-Service @('Ec2Config', 'AmazonSSMAgent', 'AWSLiteAgent') -ErrorAction SilentlyContinue) {
        'AWS'
      } elseif (Get-Service -Name @('WindowsAzureGuestAgent', 'WindowsAzureNetAgentSvc') -ErrorAction 'SilentlyContinue') {
        'Azure'
      } elseif ((Get-Service -Name 'GCEAgent' -ErrorAction 'SilentlyContinue') -or (Test-Path -Path ('{0}\GooGet\googet.exe' -f $env:ProgramData) -ErrorAction 'SilentlyContinue')) {
        'GCP'
      } else {
        try {
          # on azure we may trigger occ before the agent is installed or we may not have installed the agent (32 bit systems). this is a quick check to verify if that is what's happening here.
          if ((Invoke-WebRequest -Headers @{'Metadata'=$true} -UseBasicParsing -Uri ('http://169.254.169.254/metadata/instance?api-version={0}' -f '2019-06-04')).Content) {
            'Azure'
          }
        } catch {
          'DataCenter'
        }
      }
    ),
    [string] $regPath = 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source'
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
  }
  process {
    switch ($locationType) {
      'AWS' {
        try {
          $userdata = (New-Object Net.WebClient).DownloadString('http://169.254.169.254/latest/user-data')
        } catch {
          $userdata = $null
        }
        foreach ($sourceItemName in @('Organisation', 'Repository', 'Revision')) {
          if ((Test-Path -Path $regPath -ErrorAction 'SilentlyContinue') -and ((Get-Item -LiteralPath $regPath).GetValue($sourceItemName, $null))) {
            Write-Log -message ('{0} :: detected Source/{1} in registry as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, (Get-ItemProperty -Path $regPath -Name $sourceItemName)."$sourceItemName") -severity 'DEBUG'
          } elseif (($userdata) -and ($userdata.Contains('</SourceOrganisation>') -or $userdata.Contains('</SourceRepository>') -or $userdata.Contains('</SourceRevision>'))) {
            try {
              $sourceItemValue = [regex]::matches($userdata, ('<Source{0}>(.*)<\/Source{0}>' -f $sourceItemName))[0].Groups[1].Value
            }
            catch {
              $sourceItemValue = $null
            }
            if ($sourceItemValue) {
              Write-Log -message ('{0} :: detected Source/{1} in userdata as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              try {
                if (-not (Test-Path -Path $regPath -ErrorAction 'SilentlyContinue')) {
                  New-Item -Path $regPath -Force
                  Write-Log -message ('{0} :: created registry path: {1}' -f $($MyInvocation.MyCommand.Name), $regPath) -severity 'INFO'
                }
                Set-ItemProperty -Path $regPath -Type 'String' -Name $sourceItemName -Value $sourceItemValue
                Write-Log -message ('{0} :: set Source/{1} in registry to: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              }
              catch {
                Write-Log -message ('{0} :: error setting Source/{1} in registry to: {2}. {3}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue, $_.Exception.Message) -severity 'ERROR'
              }
            } else {
              Write-Log -message ('{0} :: failed to detect Source/{1} in userdata' -f $($MyInvocation.MyCommand.Name), $sourceItemName) -severity 'ERROR'
            }
          }
        }
      }
      'GCP' {
        foreach ($sourceItemName in @('Organisation', 'Repository', 'Revision')) {
          if ((Test-Path -Path $regPath -ErrorAction 'SilentlyContinue') -and ((Get-Item -LiteralPath $regPath).GetValue($sourceItemName, $null))) {
            Write-Log -message ('{0} :: detected Source/{1} in registry as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, (Get-ItemProperty -Path $regPath -Name $sourceItemName)."$sourceItemName") -severity 'DEBUG'
          } else {
            $sourceItemValue = (Invoke-WebRequest -Uri 'http://169.254.169.254/computeMetadata/v1beta1/instance/attributes/taskcluster' -UseBasicParsing | ConvertFrom-Json).workerConfig.openCloudConfig.source."$sourceItemName"
            if (-not ($sourceItemValue)) {
              # fall back to these values
              switch ($sourceItemName) {
                'Organisation' {
                  $sourceItemValue = 'mozilla-releng'
                }
                'Repository' {
                  $sourceItemValue = 'OpenCloudConfig'
                }
                'Revision' {
                  $sourceItemValue = 'gamma'
                }
              }
            }
            if ($sourceItemValue) {
              Write-Log -message ('{0} :: detected Source/{1} in instance metadata attributes as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              try {
                if (-not (Test-Path -Path $regPath -ErrorAction 'SilentlyContinue')) {
                  New-Item -Path $regPath -Force
                  Write-Log -message ('{0} :: created registry path: {1}' -f $($MyInvocation.MyCommand.Name), $regPath) -severity 'INFO'
                }
                Set-ItemProperty -Path $regPath -Type 'String' -Name $sourceItemName -Value $sourceItemValue
                Write-Log -message ('{0} :: set Source/{1} in registry to: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              }
              catch {
                Write-Log -message ('{0} :: error setting Source/{1} in registry to: {2}. {3}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue, $_.Exception.Message) -severity 'ERROR'
              }
            } else {
              Write-Log -message ('{0} :: failed to detect Source/{1} in instance metadata attributes' -f $($MyInvocation.MyCommand.Name), $sourceItemName) -severity 'ERROR'
            }
          }
        }
      }
      'Azure' {
        foreach ($sourceItemName in @('Organisation', 'Repository', 'Revision')) {
          if ((Test-Path -Path $regPath -ErrorAction 'SilentlyContinue') -and ((Get-Item -LiteralPath $regPath).GetValue($sourceItemName, $null))) {
            Write-Log -message ('{0} :: detected Source/{1} in registry as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, (Get-ItemProperty -Path $regPath -Name $sourceItemName)."$sourceItemName") -severity 'DEBUG'
          } else {
            try {
              $sourceItemValue = (@(((Invoke-WebRequest -Headers @{'Metadata'=$true} -UseBasicParsing -Uri ('http://169.254.169.254/metadata/instance?api-version={0}' -f '2019-06-04')).Content) | ConvertFrom-Json).compute.tagsList | ? { $_.name -eq ('source{0}' -f $sourceItemName) })[0].value
            } catch {
              switch ($sourceItemName) {
                'Organisation' {
                  $sourceItemValue = 'mozilla-releng'
                }
                'Repository' {
                  $sourceItemValue = 'OpenCloudConfig'
                }
                'Revision' {
                  $sourceItemValue = 'master'
                }
              }
            }
            if ($sourceItemValue) {
              Write-Log -message ('{0} :: detected Source/{1} in instance metadata attributes as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              try {
                if (-not (Test-Path -Path $regPath -ErrorAction 'SilentlyContinue')) {
                  New-Item -Path $regPath -Force
                  Write-Log -message ('{0} :: created registry path: {1}' -f $($MyInvocation.MyCommand.Name), $regPath) -severity 'INFO'
                }
                Set-ItemProperty -Path $regPath -Type 'String' -Name $sourceItemName -Value $sourceItemValue
                Write-Log -message ('{0} :: set Source/{1} in registry to: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              }
              catch {
                Write-Log -message ('{0} :: error setting Source/{1} in registry to: {2}. {3}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue, $_.Exception.Message) -severity 'ERROR'
              }
            } else {
              Write-Log -message ('{0} :: failed to detect Source/{1} in instance metadata attributes' -f $($MyInvocation.MyCommand.Name), $sourceItemName) -severity 'ERROR'
            }
          }
        }
      }
      default {
        foreach ($sourceItemName in @('Organisation', 'Repository', 'Revision')) {
          if ((Test-Path -Path $regPath -ErrorAction 'SilentlyContinue') -and ((Get-Item -LiteralPath $regPath).GetValue($sourceItemName, $null))) {
            Write-Log -message ('{0} :: detected Source/{1} in registry as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, (Get-ItemProperty -Path $regPath -Name $sourceItemName)."$sourceItemName") -severity 'DEBUG'
          } else {
            switch ($sourceItemName) {
              'Organisation' {
                $sourceItemValue = 'mozilla-releng'
              }
              'Repository' {
                $sourceItemValue = 'OpenCloudConfig'
              }
              'Revision' {
                $sourceItemValue = 'master'
              }
            }
            if ($sourceItemValue) {
              Write-Log -message ('{0} :: determined Source/{1} as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              try {
                if (-not (Test-Path -Path $regPath -ErrorAction 'SilentlyContinue')) {
                  New-Item -Path $regPath -Force
                  Write-Log -message ('{0} :: created registry path: {1}' -f $($MyInvocation.MyCommand.Name), $regPath) -severity 'INFO'
                }
                Set-ItemProperty -Path $regPath -Type 'String' -Name $sourceItemName -Value $sourceItemValue
                Write-Log -message ('{0} :: set Source/{1} in registry to: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
              }
              catch {
                Write-Log -message ('{0} :: error setting Source/{1} in registry to: {2}. {3}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue, $_.Exception.Message) -severity 'ERROR'
              }
            } else {
              Write-Log -message ('{0} :: detected Source/{1} in userdata as: {2}' -f $($MyInvocation.MyCommand.Name), $sourceItemName, $sourceItemValue) -severity 'INFO'
            }
          }
        }
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
  }
}

$sysprepState = [string]((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State' -Name 'ImageState' -ErrorAction 'SilentlyContinue').ImageState)
switch -regex ($sysprepState) {
  'IMAGE_STATE_(COMPLETE|SPECIALIZE_RESEAL_TO_AUDIT|UNDEPLOYABLE)' {
    Write-Log -message ('{0} :: bootstrap triggered. sysprep state: {1}' -f $($MyInvocation.MyCommand.Name), $sysprepState) -severity 'WARN'
    try {
      Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Force -ErrorAction SilentlyContinue
    } catch {
      Write-Log -message ('{0} :: failed to set powershell execution policy to remote signed. {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.Message) -severity 'WARN'
    }
    if ([Net.ServicePointManager]::SecurityProtocol -ne ([Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12)) {
      try {
        [Net.ServicePointManager]::SecurityProtocol = ([Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12)
        Write-Log -message ('{0} :: added TLS v1.2 to security protocol support list for current powershell session' -f $($MyInvocation.MyCommand.Name))
      } catch {
        Write-Log -message ('{0} :: failed to add TLS v1.2 to security protocol support list for current powershell session. {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.Message) -severity 'WARN'
      }
    } else {
      Write-Log -message ('{0} :: detected TLS v1.2 in security protocol support list' -f $($MyInvocation.MyCommand.Name))
    }
    Set-OpenCloudConfigSource
    $sourceOrg = $(if ((Test-Path -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -ErrorAction 'SilentlyContinue') -and (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -Name 'Organisation' -ErrorAction 'SilentlyContinue')) { (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -Name 'Organisation').Organisation } else { 'mozilla-releng' })
    $sourceRepo = $(if ((Test-Path -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -ErrorAction 'SilentlyContinue') -and (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -Name 'Repository' -ErrorAction 'SilentlyContinue')) { (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -Name 'Repository').Repository } else { 'OpenCloudConfig' })
    $sourceRev = $(if ((Test-Path -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -ErrorAction 'SilentlyContinue') -and (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -Name 'Revision' -ErrorAction 'SilentlyContinue')) { (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Mozilla\OpenCloudConfig\Source' -Name 'Revision').Revision } else { 'master' })
    Install-SupportingModules -sourceOrg $sourceOrg -sourceRepo $sourceRepo -sourceRev $sourceRev
    Invoke-OpenCloudConfig -sourceOrg $sourceOrg -sourceRepo $sourceRepo -sourceRev $sourceRev
    break
  }
  default {
    Write-Log -message ('{0} :: bootstrap skipped. no implementation for sysprep state: {1}' -f $($MyInvocation.MyCommand.Name), $sysprepState) -severity 'WARN'
    break
  }
}
