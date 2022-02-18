
function Get-WaykPSRemotingPath
{
    [CmdletBinding()]
    param(
    )

    if ($IsWindows) {
        $WaykClient = Get-WaykClientCommand
        $WaykBinPath = $(Get-Item $WaykClient).Directory.FullName
        $PSRemotingPath = Join-Path $WaykBinPath 'psremoting'
    } elseif ($IsMacOS) {
        $WaykBinPath = "/Applications/WaykClient.app/Contents/MacOS"
        $PSRemotingPath = Join-Path $WaykBinPath 'psremoting'
    } elseif ($IsLinux) {
        $WaykLibPath = "/usr/lib"
        $PSRemotingPath = Join-Path $WaykLibPath 'psremoting'
    }

    $PSRemotingPath
}

function Enter-WaykPSEnvironment
{
    [CmdletBinding()]
    param(
    )

    if ($PSEdition -eq 'Desktop') {
        throw "Wayk PowerShell remoting requires PowerShell 7 or later"
    }

    $PSRemotingPath = Get-WaykPSRemotingPath

    if (-Not (Test-Path $PSRemotingPath -PathType 'Container')) {
        throw "Could not find required Wayk PSRemoting directory: `"$PSRemotingPath`""
    }

    $EnvPaths = $Env:PATH -Split $([IO.Path]::PathSeparator) | Where-Object { $_ -ne $PSRemotingPath }
    $Env:PATH = $(@($PSRemotingPath) + $EnvPaths) -Join $([IO.Path]::PathSeparator)
}

function Exit-WaykPSEnvironment
{
    [CmdletBinding()]
    param(
    )

    Remove-Item Env:JETSOCAT_ARGS -ErrorAction 'SilentlyContinue'

    $PSRemotingPath = Get-WaykPSRemotingPath

    if (Test-Path $PSRemotingPath -PathType 'Container') {
        $EnvPaths = $Env:PATH -Split $([IO.Path]::PathSeparator) | Where-Object { $_ -ne $PSRemotingPath }
        $Env:PATH = $EnvPaths -Join $([IO.Path]::PathSeparator)
    }
}

function Connect-WaykPSSession
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential
    )

    Enter-WaykPSEnvironment

    $UserName = $Credential.UserName
    $Password = $Credential.GetNetworkCredential().Password

    $WaykClient = Get-WaykClientCommand

    $CommandInput = [PSCustomObject]@{
        Hostname = $HostName
        Username = $UserName
        Password = $Password
    } | ConvertTo-Json -Compress | Out-String

    if ($IsWindows) {
        $WaykClient = $WaykClient -Replace '.exe', '.com'
    }

    $CommandOutput = $CommandInput | & "$WaykClient" 'pwsh' '-' 2>$null

    $CommandOutput = $CommandOutput | ConvertFrom-Json

    if (-Not $CommandOutput.Success) {
        throw "Failed to connect to ${HostName} with user ${UserName} with error $($CommandOutput.Error)"
    }

    $JetUrl = $CommandOutput.JetUrl
    $Env:JETSOCAT_ARGS = "forward $JetUrl -"

    return $CommandOutput
}

function New-WaykPSSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential
    )

    $UserName = $Credential.UserName
    $Result = Connect-WaykPSSession -HostName:$HostName -Credential:$Credential
    New-PSSession -UserName:$UserName -HostName:$HostName -SSHTransport
    Exit-WaykPSEnvironment
}

function Enter-WaykPSSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential
    )

    $UserName = $Credential.UserName
    $Result = Connect-WaykPSSession -HostName:$HostName -Credential:$Credential
    Enter-PSSession -UserName:$UserName -HostName:$HostName -SSHTransport
    Exit-WaykPSEnvironment
}

function DecodeBase64UrlSafe($Base64Url)
{
    # short circuit on empty strings
    if ($Base64Url -eq [string]::Empty) {
        return [string]::Empty
    }

    # put the standard unsafe characters back
    $s = $Base64Url.Replace('-', '+').Replace('_', '/')

    # put the padding back
    switch ($s.Length % 4) {
        0 { break; }             # no padding needed
        2 { $s += '=='; break; } # two pad chars
        3 { $s += '='; break; }  # one pad char
        default { throw "Invalid Base64Url string" }
    }

    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($s))
}

function Connect-WaykRdpSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [String] $RdpOutputFile
    )

    $WaykClient = Get-WaykClientCommand

    $CommandInput = [PSCustomObject]@{
        Hostname = $HostName
    } | ConvertTo-Json -Compress | Out-String

    if ($IsWindows) {
        $WaykClient = $WaykClient -Replace '.exe', '.com'
    }

    $OldInputEncoding = [Console]::InputEncoding
    [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)

    $CommandOutput = $CommandInput | & "$WaykClient" 'rdp-tcp' '-' 2>$null

    [Console]::InputEncoding = $OldInputEncoding

    $CommandOutput = $CommandOutput | ConvertFrom-Json

    if (-Not $CommandOutput.Success) {
        throw "Failed to connect to ${HostName} with error $($CommandOutput.Error)"
    }

    $RdpConfig = DecodeBase64UrlSafe($CommandOutput.RdpConfig)

    if ($RdpOutputFile) {
        $RdpConfig | Out-File -FilePath $RdpOutputFile
        return
    }

    return $RdpConfig
}

function Enter-WaykRdpSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [String] $UserName,
        [String] $Domain
    )

    if ($IsWindows -And ($UserName -Or $Domain)) {
        # There is no simple way to specify user name and domain to the mstsc,
        # they are only can be stored on the machine globally for the specified
        # hostname using cmdkey command, which may leave a trace on the machine
        throw "-UserName/-Domain arguements are not supported on the Windows platform"
    }

    $RdpConfigFile = $(New-TemporaryFile) -Replace "[.][^.]+$", ".rdp"

    Connect-WaykRdpSession -HostName:$HostName -RdpOutputFile:$RdpConfigFile

    $RdpArgs = @("${RdpConfigFile}")

    if ($IsWindows) {
        $RdpApp = "mstsc"
        Start-Process -FilePath:$RdpApp -ArgumentList:$RdpArgs
    } else {
        $RdpApp = "xfreerdp"
        $RdpArgs += "/sec:nla"
        $RdpArgs += "/cert-ignore"
        $RdpArgs += "/from-stdin"
        if ($UserName) {
            $RdpArgs += "/u:${UserName}"
        }
        if ($Domain) {
            $RdpArgs += "/d:${Domain}"
        }

        Start-Process -FilePath:$RdpApp -ArgumentList:$RdpArgs -Wait
    }
}

Function Get-RandomPort
{
    Param(
        [Int] $MaxTries = 100
    );

    $Result = -1;
    $NbTries = 0;

    do {
        $NbTries += 1;

        $Port = Get-Random -Min 10001 -Max 32767;
        if (-Not (Test-Connection localhost -TcpPort $Port)) {
            $Result = $Port;
        }
    } while (($Result -lt 0) -and ($NbTries -lt $MaxTries));

    return $Result;
}

Function Spawn-JetsocatWithLocalTcpListener
{
    Param(
        [String] $JetPipe,
        [Int] $TcpPort
    );

    # Give access to jetsocat (and fake ssh)
    Enter-WaykPSEnvironment

    # Spawn local jetsocat tunnel for ssh ↔ jetsocat ↔ wss/jet-tcp/… ↔ gateway
    Start-Process -FilePath "jetsocat" -ArgumentList "forward", "$JetPipe", "tcp-listen://localhost:$TcpPort"

    # Get back access to system ssh
    Exit-WaykPSEnvironment

    # Wait a bit for jetsocat to be ready
    Start-Sleep -Seconds 0.5
}

function Enter-WaykSshSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [Parameter(Mandatory=$true)]
        [String] $UserName
    )

    $WaykClient = Get-WaykClientCommand

    $CommandInput = [PSCustomObject]@{
        Hostname = $HostName
    } | ConvertTo-Json -Compress | Out-String

    if ($IsWindows) {
        $WaykClient = $WaykClient -Replace '.exe', '.com'
    }

    $CommandOutput = $CommandInput | & "$WaykClient" 'ssh' '-' 2>$null

    $CommandOutput = $CommandOutput | ConvertFrom-Json

    if (-Not $CommandOutput.Success) {
        throw "Failed to connect to ${HostName} with user ${UserName} with error $($CommandOutput.Error)"
    }

    $JetUrl = $CommandOutput.JetUrl
    $PortToUse = Get-RandomPort
    Spawn-JetsocatWithLocalTcpListener $JetUrl $PortToUse

    $Prgm = "ssh"
    $Args = "localhost", "-p", "$PortToUse", "-l", "${UserName}"
    if ($IsWindows) {
        $Args += "-o", "GlobalKnownHostsFile=NUL", "-o", "UserKnownHostsFile=NUL"
    } else {
        $Args += "-o", "GlobalKnownHostsFile=/dev/null", "-o", "UserKnownHostsFile=/dev/null"
    }

    Start-Process -FilePath:$Prgm -ArgumentList:$Args -Wait
}

function Connect-WaykSftpSession
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential
    )

    Enter-WaykPSEnvironment

    $UserName = $Credential.UserName
    $Password = $Credential.GetNetworkCredential().Password

    $WaykClient = Get-WaykClientCommand

    $CommandInput = [PSCustomObject]@{
        Hostname = $HostName
        Username = $UserName
        Password = $Password
    } | ConvertTo-Json -Compress | Out-String

    if ($IsWindows) {
        $WaykClient = $WaykClient -Replace '.exe', '.com'
    }

    $CommandOutput = $CommandInput | & "$WaykClient" 'sftp' '-' 2>$null

    $CommandOutput = $CommandOutput | ConvertFrom-Json

    if (-Not $CommandOutput.Success) {
        throw "Failed to connect to ${HostName} with user ${UserName} with error $($CommandOutput.Error)"
    }

    $JetUrl = $CommandOutput.JetUrl
    $Env:JETSOCAT_ARGS = "forward $JetUrl -"

    return $CommandOutput
}

function New-WaykSftpSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential
    )

    $UserName = $Credential.UserName
    $Result = Connect-WaykSftpSession -HostName:$HostName -Credential:$Credential
    New-SftpSession -UserName:$UserName -HostName:$HostName -SSHTransport
    Exit-WaykPSEnvironment
}

function Enter-WaykSftpSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $HostName,
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential
    )

    $UserName = $Credential.UserName
    $Result = Connect-WaykSftpSession -HostName:$HostName -Credential:$Credential
    $Args = "-D", "jetsocat"
    Start-Process -FilePath:"sftp" -ArgumentList:$Args -Wait
    Exit-WaykPSEnvironment
}

