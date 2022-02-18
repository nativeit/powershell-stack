
function Invoke-InstanceHealthCheck {
  begin {
    if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
      Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
    }
  }
  process {
    Write-LogDirectoryContents -path 'C:\generic-worker'
    Get-WorkerStatus
  }
  end {
    if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
      Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
    }
  }
}

function Write-LogDirectoryContents {
  param (
    [string] $path
  )
  begin {
    if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
      Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
    }
  }
  process {
    if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
      if (Test-Path -Path $path -ErrorAction 'SilentlyContinue') {
        $directoryContents = (Get-ChildItem -Path $path -ErrorAction 'SilentlyContinue')
        if ($directoryContents.Length) {
          Write-Log -message ('{0} :: directory contents of "{1}":' -f $($MyInvocation.MyCommand.Name), $path) -severity 'DEBUG'
          foreach ($directoryEntry in $directoryContents) {
            Write-Log -message ('{0} :: {1}:' -f $($MyInvocation.MyCommand.Name), $directoryEntry.Name) -severity 'DEBUG'
          }
        } else {
          Write-Log -message ('{0} :: directory "{1}" is empty' -f $($MyInvocation.MyCommand.Name), $path) -severity 'DEBUG'
        }
      } else {
        Write-Log -message ('{0} :: directory "{1}" not found' -f $($MyInvocation.MyCommand.Name), $path) -severity 'DEBUG'
      }
    }
  }
  end {
    if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
      Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
    }
  }
}

function Get-WorkerStatus {
  param (
    [string] $apiUrl = 'https://queue.taskcluster.net/v1',
    [string] $gwConfigPath = $(if ((${env:PROCESSOR_ARCHITEW6432} -eq 'ARM64') -and (Test-Path -Path 'C:\generic-worker\gw.config' -ErrorAction 'SilentlyContinue')) { 'C:\generic-worker\gw.config' } else { 'C:\generic-worker\generic-worker.config' })
  )
  begin {
    if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
      Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
    }
  }
  process {
    try {
      if ((Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') -and (Test-Path -Path $gwConfigPath -ErrorAction 'SilentlyContinue')) {
        $gwConfig = (Get-Content -Path $gwConfigPath -raw | ConvertFrom-Json)
        $workerStatusUri = ('{0}/provisioners/{1}/worker-types/{2}/workers/{3}/{4}' -f $apiUrl, $gwConfig.provisionerId, $gwConfig.workerType, $gwConfig.workerGroup, $gwConfig.workerId)
        Write-Log -message ('{0} :: worker status api uri determined as: {1} from {2}' -f $($MyInvocation.MyCommand.Name), $workerStatusUri, $gwConfigPath) -severity 'DEBUG'
        $workerStatus = ((Invoke-WebRequest -Uri $workerStatusUri -UseBasicParsing).Content | ConvertFrom-Json)
        Write-Log -message ('{0} :: latest task determined as: {1}/{2}' -f $($MyInvocation.MyCommand.Name), $workerStatus.recentTasks[-1].taskId, $workerStatus.recentTasks[-1].runId) -severity 'DEBUG'
        $taskStatusUri = ('{0}/task/{1}/status' -f $apiUrl, $workerStatus.recentTasks[-1].taskId)
        Write-Log -message ('{0} :: task status api uri determined as: {1}' -f $($MyInvocation.MyCommand.Name), $taskStatusUri) -severity 'DEBUG'
        $taskStatus = ((Invoke-WebRequest -Uri $taskStatusUri -UseBasicParsing).Content | ConvertFrom-Json)
        Write-Log -message ('{0} :: task: {1}, run: {2}, started: {3}, state: {4}' -f $($MyInvocation.MyCommand.Name), $taskStatus.status.taskId, $workerStatus.recentTasks[-1].runId, $taskStatus.status.runs[$workerStatus.recentTasks[-1].runId].started, $taskStatus.status.runs[$workerStatus.recentTasks[-1].runId].state) -severity 'DEBUG'
      }
    } catch {
      if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
        Write-Log -message ('{0} :: exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.Message) -severity 'DEBUG'
      }
    }
  }
  end {
    if (Get-Command -Name 'Write-Log' -ErrorAction 'SilentlyContinue') {
      Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'DEBUG'
    }
  }
}

Invoke-InstanceHealthCheck