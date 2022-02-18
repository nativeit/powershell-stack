[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

![Gitlab pipeline status - master](https://img.shields.io/gitlab/pipeline/pwsh.fw/pwsh.fw.core/master?label=pipeline%20-%20master)
![Gitlab pipeline status - develop](https://img.shields.io/gitlab/pipeline/pwsh.fw/pwsh.fw.core/develop?label=pipeline%20-%20develop)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/cdac39b6e5ae4999ae612d2204c084df)](https://www.codacy.com/gl/pwsh.fw/pwsh.fw.core?utm_source=gitlab.com&amp;utm_medium=referral&amp;utm_content=pwsh.fw/pwsh.fw.core&amp;utm_campaign=Badge_Grade)
[![coverage report](https://gitlab.com/pwsh.fw/pwsh.fw.core/badges/master/coverage.svg)](https://gitlab.com/pwsh.fw/pwsh.fw.core/-/commits/master)

[![PowerShell Gallery - Version](https://img.shields.io/powershellgallery/v/PwSh.Fw.Core)](https://www.powershellgallery.com/packages/PwSh.Fw.Core)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PwSh.Fw.Core)](https://www.powershellgallery.com/packages/PwSh.Fw.Core)
[![Powershell Platform](https://img.shields.io/powershellgallery/p/PwSh.Fw.Core)](https://www.powershellgallery.com/packages/PwSh.Fw.Core)

<img align="left" width="48" height="48" src="images/favicon.png">

# PwSh.Fw.Core

PwSh Framework core module.

New era of `pwsh_fw` framework for PowerShell. The future of this framework will be available as modules deployed via [PowerShell Gallery](https://www.powershellgallery.com/). It will also be splitted in pieces to make it very modular.

## Content

`PwSh.Fw.Core` as its name suggest contain the core of the `PwSh` framework. All `PwSh.Fw` modules require `PwSh.Fw.Core`. It implements all the basics of the framework like displaying messages or debugging scripts.

## Highlights

-	`New-Function` is a template to create new functions. You can copy-paste the
    code, or your can use the code to create a snippet for VisualStudioCode for
    example.
-   `Write-*` are functions to display piece of information. It is similar to
    using `Write-Debug` or `Write-Information` or the like, but the display is
    inpired from `e*()` functions of the `gentoo` linux distribution. Information
    displayed is more human-readable.
-   `Load-Module` is a wrapper to `Import-Module`. It handle missing module, can
    make a module optional, and handle proper logging.
-   `Execute-Command` is a wrapper to execute native OS programs. It handles
    proper logging, arguments and return code.
