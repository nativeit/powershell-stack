# RDM Helper PowerShell Module

The `RdmHelper` PowerShell module provides helper installation, configuration and detection commands for [Devolutions Remote Desktop Manager](https://remotedesktopmanager.com). It is meant to complement and simplify the usage of the real RDM PowerShell module but not replace it.

## Getting Started

Install the `RdmHelper` PowerShell module from [PSGallery](https://www.powershellgallery.com/packages/RdmHelper):

```powershell
Install-Module RdmHelper
Import-Module RdmHelper
```

Alternatively, this module can also be loaded directly from its sources:

```powershell
Import-Module '.\RdmHelper'
```

Use `Get-Command -Module RdmHelper` to list the commands exported by the module.

## Import-RdmModule

The `Import-RdmModule` command finds the RDM installation path and loads the real RDM PowerShell module it contains. Because `RdmHelper` is an installed PowerShell module, you can use the `Import-RdmHelper` command in your scripts without explicitly calling `Import-Module RdmHelper` first. This command is meant to be a handy shortcut to import RDM PowerShell module without using long, hardcoded paths. Since the RDM PowerShell module is only available on RDM Windows, this command will not work on other platforms.

```powershell
Import-RdmModule
```

The `Import-RdmModule` is the same as the following `Import-Module` command using the complete, hardcoded path to the RDM PowerShell module:

```powershell
Import-Module "C:\Program Files (x86)\Devolutions\Remote Desktop Manager\RemoteDesktopManager.PowerShellModule.psd1"
```

Since the RDM PowerShell module uses the same libraries as RDM, it cannot be shipped separately without including a full copy of RDM along with it (~100MB compressed). Since the `RdmHelper` PowerShell module is installed the regular way, the `Import-RdmModule` command becomes automatically available without loading anything manually from a given path, solving the problem in a convenient way.

Once the `RemoteDesktopManager.PowerShellModule` PowerShell module is loaded, you can list its commands using `Get-Command -Module 'RemoteDesktopManager.PowerShellModule'`.

### Parameters

The **-Platform** parameter specifies the target platform: **Windows**, **macOS**, **Linux**.

The **-Edition** parameter specifies the RDM edition: **Enterprise**, **Free**.

The **-RequiredVersion** parameter forces a specific version number other than the latest.

## Install-RdmPackage

The `Install-RdmPackage` command downloads and installs the latest RDM package for the current platform, and accepts the same parameters as `Get-RdmPackage`. The installation is skipped if RDM is already up to date, unless the `-Force` parameter is used.

### Examples

```powershell
Install-RdmPackage -Edition 'Enterprise'
```

```powershell
Install-RdmPackage -Edition 'Free' -Force
```

```powershell
Install-RdmPackage -Platform 'Windows'
```

```powershell
Install-RdmPackage -Platform 'macOS'
```

```powershell
Install-RdmPackage -Platform 'Linux'
```

### Parameters

The **-Platform** parameter specifies the target platform: **Windows**, **macOS**, **Linux**.

The **-Edition** parameter specifies the RDM edition: **Enterprise**, **Free**.

The **-RequiredVersion** parameter forces a specific version number other than the latest.

The **-Quiet** parameter makes a silent installation. On Windows, this only works from an elevated PowerShell session, otherwise the UAC prompt will be used to elevate permissions. On Windows and Linux, the `sudo` command is called to elevate permissions for the installation when the current context is not elevated.

## Update-RdmPackage

The `Update-RdmPackage` command downloads and updates the latest RDM package. It is almost the same as `Install-RdmPackage` except it restarts RDM after the update if it was previously running.

## Uninstall-RdmPackage

The `Uninstall-RdmPackage` command uninstalls RDM from the system.

## Register-RdmLicense

The `Register-RdmLicense` command registers a license with RDM using its [command-line interface](https://kb.devolutions.net/rdm_command_line_arguments.html).

```PowerShell
Register-RdmLicense -Serial 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX' -Name 'Bob'
```

## Get-RdmPackage

The `Get-RdmPackage` command finds the RDM package CDN download URL for a given platform, edition and version. It accepts the same parameters as `Install-RdmPackage`.

### Examples

```powershell
PS /opt/wayk/dev/RdmHelper-ps> Get-RdmPackage | Format-List
Url     : https://cdn.devolutions.net/download/Setup.RemoteDesktopManager.2020.3.16.0.msi
Version : 2020.3.16
```

```powershell
PS > Get-RdmPackage -Platform 'macOS' -Edition 'Free' | Format-List
Url     : https://cdn.devolutions.net/download/Mac/Devolutions.RemoteDesktopManager.Free.Mac.2020.3.1.0.dmg
Version : 2020.3.16
```

```powershell
PS > Get-RdmPackage -Platform 'Linux' -Edition 'Enterprise' -RequiredVersion '2020.3.0.0' | Format-List

Url     : https://cdn.devolutions.net/download/Linux/RDM/2020.3.0.0/RemoteDesktopManager_2020.3.0.0_amd64.deb
Version : 2020.3.0
```

## Get-RdmCommand

The `Get-RdmCommand` detects and returns the full path to the RDM executable.

### Examples

```powershell
PS > Get-RdmCommand
C:\Program Files (x86)\Devolutions\Remote Desktop Manager\RemoteDesktopManager64.exe
```

```powershell
PS > Get-RdmCommand -Architecture 'x86'
C:\Program Files (x86)\Devolutions\Remote Desktop Manager\RemoteDesktopManager.exe
```

```powershell
PS > Get-RdmCommand
/Applications/Remote Desktop Manager.app/Contents/MacOS/RemoteDesktopManager
```

### Parameters

The **-Architecture** parameter specifies a target architecture for the RDM executable on Windows: **x86** (32-bit) or **x64** (64-bit).

## Get-RdmPath

The `Get-RdmPath` command finds RDM installation path or configuration path.

### Examples

```powershell
PS > Get-RdmPath InstallPath
C:\Program Files (x86)\Devolutions\Remote Desktop Manager\
```

```powershell
PS > Get-RdmPath ConfigPath
C:\Users\Administrator\AppData\Local\Devolutions\RemoteDesktopManager
```

```powershell
PS > Get-RdmPath InstallPath
/Applications/Remote Desktop Manager.app
```

```powershell
PS > Get-RdmPath ConfigPath
/Users/devolutions/Library/Application Support/com.devolutions.remotedesktopmanager
```

### Parameters

The **-PathType** parameter (position 0) specifies the path type to return:
 * **InstallPath**: the RDM installation path
 * **ConfigPath**: the RDM configuration path

## Get-RdmVersion

The `Get-RdmVersion` command detects the current RDM installed version.

### Examples

```powershell
PS > Get-RdmVersion
2020.3.16.0
```

## Get-RdmProcess

The `Get-RdmProcess` command finds the RDM running process.

### Examples

```powershell
PS > Get-RdmProcess

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    718      75   273240     332964      10.64  40560   7 RemoteDesktopManager64
```

```powershell
PS > Get-RdmProcess

 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
      0     0.00     721.77      15.36   56681 …65 RemoteDesktopMa
```

## Start-RdmProcess

The `Start-RdmProcess` command starts the RDM process. This is the same as calling `Start-Process` with the RDM executable path returned by `Get-RdmCommand`.

## Stop-RdmProcess

The `Stop-RdmProcess` command stops the RDM process. This is the same as calling `Stop-Process` on the process returned by `Get-RdmProcess`.

## Restart-RdmProcess

The `Restart-RdmProcess` command restarts the RDM process. This is the same as calling `Stop-RdmProcess` and `Start-RdmProcess`.
