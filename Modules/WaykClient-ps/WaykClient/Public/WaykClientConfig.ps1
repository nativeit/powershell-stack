
enum ControlMode 
{
    Both = 0
    Client = 1
    Server = 2
}

enum PersonalPasswordType 
{
    Generated = 0
    Custom = 1
}

enum GeneratedPasswordCharSet 
{
    Numeric = 0
    Alphanumeric = 1
}

enum QualityMode 
{
    Low = 1
    Medium = 2
    High = 3
}

enum LoggingLevel 
{
    Trace = 0
    Debug = 1
    Info = 2
    Warn = 3
    Error = 4
    Fatal = 5
    Off = 6
}

enum AccessControl
{
    Allow = 1
    Confirm = 2
    Disable = 4
}

class WaykClientConfig
{
	# General
    [string] $FriendlyName
    [string] $Language
    [ControlMode] $ControlMode = [ControlMode]::Both
    [bool] $AutoLaunchOnUserLogon = $false
    [bool] $ShowMainWindowOnLaunch = $true
    [bool] $MinimizeToNotificationArea = $false
    [bool] $ElevationPrompt = $false

    # Security
    [bool] $AllowPersonalPassword = $true
    [bool] $AllowSystemAuth = $true
    [bool] $AllowNoPassword = $true
    [PersonalPasswordType] $PersonalPasswordType
    [string] $PersonalPassword
    [int32] $GeneratedPasswordLength = 6
    [bool] $GeneratedPasswordAutoReset = $true
    [GeneratedPasswordCharSet] $GeneratedPasswordCharSet = [GeneratedPasswordCharSet]::Alphanumeric

    # Connectivity
    [bool] $DenEnabled = $true
    [string] $DenUrl = "https://den.wayk.net"

    # Advanced
    [QualityMode] $QualityMode = [QualityMode]::Medium
    [LoggingLevel] $LoggingLevel
    [string] $LoggingFilter

    # Access Control
    [AccessControl] $AccessControlViewing = [AccessControl]::Allow
    [AccessControl] $AccessControlInteract = [AccessControl]::Allow
    [AccessControl] $AccessControlClipboard = [AccessControl]::Allow
    [AccessControl] $AccessControlFileTransfer = [AccessControl]::Allow
    [AccessControl] $AccessControlExec = [AccessControl]::Allow
    [AccessControl] $AccessControlChat = [AccessControl]::Allow

    [bool] $AnalyticsEnabled = $true
    [bool] $CrashReporterEnabled = $true
    [bool] $CrashReporterAutoUpload = $true
    [bool] $VersionCheck = $true
    [bool] $AutoUpdateEnabled = $true
}

function Get-WaykClientConfigFile
{
    param(
    )

    $ConfigPath = Get-WaykClientPath
    $ConfigFile = Join-Path $ConfigPath "WaykNow.cfg"
    return $ConfigFile
}

function Set-WaykClientConfig
{
    [CmdletBinding()]
    param(
        [string] $FriendlyName,
        [ValidateSet("en", "fr", "de", "it", "pl", "zh-CN", "zh-TW")]
        [string] $Language,
        [ControlMode] $ControlMode,
        [bool] $AutoLaunchOnUserLogon,
        [bool] $ShowMainWindowOnLaunch,
        [bool] $MinimizeToNotificationArea,
        [bool] $ElevationPrompt,

        [bool] $AllowPersonalPassword,
        [bool] $AllowSystemAuth,
        [bool] $AllowNoPassword,
        [PersonalPasswordType]  $PersonalPasswordType,
        [string] $PersonalPassword,
        [ValidateRange(3,9)]
        [int32] $GeneratedPasswordLength,
        [GeneratedPasswordCharSet] $GeneratedPasswordCharSet,

        [bool] $DenEnabled,
        [string] $DenUrl,

        [QualityMode] $QualityMode,
        [LoggingLevel] $LoggingLevel,
        [string] $LoggingFilter,

        [AccessControl] $AccessControlViewing,
        [AccessControl] $AccessControlInteract,
        [AccessControl] $AccessControlClipboard,
        [AccessControl] $AccessControlFileTransfer,
        [AccessControl] $AccessControlExec,
        [AccessControl] $AccessControlChat,

        [bool] $AnalyticsEnabled,
        [bool] $CrashReporterEnabled,
        [bool] $CrashReporterAutoUpload,
        [bool] $VersionCheck,
        [bool] $AutoUpdateEnabled
    )

    $ConfigFile = Get-WaykClientConfigFile

    if (Test-Path $ConfigFile) {
        $json = Get-Content -Path $ConfigFile -Encoding UTF8 | ConvertFrom-Json
    } else {
        $json = '{}' | ConvertFrom-Json
    }

    $properties = [WaykClientConfig].GetProperties() | ForEach-Object { $_.Name }

    foreach ($param in $PSBoundParameters.GetEnumerator()) {
        if ($param.Key -NotLike 'AccessControl*') {
            if ($properties -Contains $param.Key) {
                $json | Add-Member -Type NoteProperty -Name $param.Key -Value $param.Value -Force
            }
        }
    }

    $AccessControlNames = @('Viewing', 'Interact', 'Clipboard', 'FileTransfer', 'Exec', 'Chat')

    if (-Not $json.AccessControl) {
        $json | Add-Member -Type NoteProperty -Name "AccessControl" -Value $([PSCustomObject]@{})
    }

    foreach ($ShortName in $AccessControlNames) {
        $LongName = "AccessControl$ShortName"
        $Value = $PSBoundParameters[$LongName]
        if ($Value) {
            $json.AccessControl | Add-Member -Type NoteProperty -Name $ShortName -Value $Value -Force
        }
    }

    New-Item -Path $(Split-Path $ConfigFile -Parent) -ItemType 'Directory' -Force | Out-Null

    $FileValue = $json | ConvertTo-Json
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($ConfigFile, $FileValue, $Utf8NoBomEncoding)
}

function Get-WaykClientConfig
{
    [CmdletBinding()]
    [OutputType('WaykClientConfig')]
    param(
    )

    $ConfigFile = Get-WaykClientConfigFile

    if (Test-Path $ConfigFile) {
        $ConfigJson = Get-Content -Path $ConfigFile -Encoding UTF8 | ConvertFrom-Json
    }

    $config = [WaykClientConfig]::new()

    [WaykClientConfig].GetProperties() | ForEach-Object {
        if ($_.Name -NotLike 'AccessControl*') {
            $Name = $_.Name
            $Property = $null

            if ($ConfigJson -And $ConfigJson.PSObject.Properties[$Name]) {
                $Property = $ConfigJson.PSObject.Properties[$Name]
            }

            if ($Property) {
                $Value = $Property.Value
                $config.$Name = $Value
            }
        }
    }

    $AccessControlNames = @('Viewing', 'Interact', 'Clipboard', 'FileTransfer', 'Exec', 'Chat')

    foreach ($ShortName in $AccessControlNames) {
        $LongName = "AccessControl$ShortName"

        $AccessControl = $null
        $Property = $null

        if ($ConfigJson -And $ConfigJson.PSObject.Properties['AccessControl']) {
            $AccessControl = $ConfigJson.PSObject.Properties['AccessControl'].Value
            $Property = $AccessControl.PSObject.Properties[$ShortName]
        }

        if ($Property) {
            $Value = $Property.Value
            $config.$LongName = $Value
        }
    }

    return $config
}
