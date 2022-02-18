﻿Import-Module .\PSWriteHTML.psd1 -Force

$Processes = Get-Process | Select-Object -First 20

New-HTML -TitleText 'Title' -Online -FilePath $PSScriptRoot\Example2501.html {
    New-HTMLSection -Invisible {
        New-HTMLPanel -Invisible {
            New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconRegular address-card
        }
        New-HTMLPanel -Invisible {
            New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconColor DarkGrey -BarColorLeft ForestGreen -TextColor Gainsboro -IconBrands 500px
        }
    }
    New-HTMLSection -Invisible {
        New-HTMLTable -DataTable $Processes -HideFooter
    }
    New-HTMLPanel -Invisible {
        New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconColor AliceBlue -BarColorLeft Grey -TextHeaderColor Gold -IconRegular eye
        New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconBrands app-store
        New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconRegular surprise
        New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconSolid bell
        New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconBrands cloudsmith
        New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconBrands accessible-icon
        New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconBrands accusoft -BarColorRight DarkTurquoise
    }
    New-HTMLSection -Invisible {
        New-HTMLPanel -Invisible
        New-HTMLPanel -Invisible {
            New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconRegular address-card
        }
        New-HTMLPanel -Invisible {
            New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconColor DarkGrey -BarColorLeft ForestGreen -TextColor Gainsboro -IconBrands 500px
        }
        New-HTMLPanel -Invisible
    }
    New-HTMLSection -Invisible {
        New-HTMLPanel -Invisible
        New-HTMLPanel -Invisible
        New-HTMLPanel -Invisible {
            New-HTMLToast -TextHeader 'Maintenance' -Text "We've planned maintenance on 24th of January 2020. It will last 30 hours." -IconColor DarkGrey -BarColorLeft ForestGreen -TextColor Gainsboro -IconBrands 500px
        }
        New-HTMLPanel -Invisible
    }
} -ShowHTML