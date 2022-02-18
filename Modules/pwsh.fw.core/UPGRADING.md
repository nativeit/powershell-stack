# Upgrading

## everytime

As a global best practice, it is advised to upgrade your script to the latest `skel.ps1` version.

To do so, please follow this guide :
-	Ensure you leave following anchors :
```powershell
...
$Global:BASENAME = Split-Path -Leaf $MyInvocation.MyCommand.Definition
...
# USER MODULES HERE
...
#############################
## YOUR SCRIPT BEGINS HERE ##
#############################
...
...
#############################
## YOUR SCRIPT ENDS   HERE ##
#############################
...
```

-	Run the update script :

```powershell
/path/to/update-script.ps1 -Skel /path/to/skel.ps1 -Script /path/to/you/script.ps1
```

A backup `script.ps1.bak` will be created alongside the new version of your script. Please review the new script before running it again.
