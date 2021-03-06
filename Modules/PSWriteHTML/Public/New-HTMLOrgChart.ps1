function New-HTMLOrgChart {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER ChartNodes
    Define nodes to be shown on the chart

    .PARAMETER Direction
    The available values are "top to bottom" (default value), "bottom to top", "left to right" and "right to left"

    .PARAMETER VisileLevel
    It indicates the level that at the very beginning orgchart is expanded to.

    .PARAMETER VerticalLevel
    Users can make use of this option to align the nodes vertically from the specified level.

    .PARAMETER ToggleSiblings
    Once enable this option, users can show/hide left/right sibling nodes respectively by clicking left/right arrow.

    .PARAMETER NodeTitle
    It sets one property of datasource as text content of title section of orgchart node. In fact, users can create a simple orghcart with only nodeTitle option.

    .PARAMETER Pan
    Users could pan the orgchart by mouse drag&drop if they enable this option.

    .PARAMETER Zoom
    Users could zoomin/zoomout the orgchart by mouse wheel if they enable this option.

    .PARAMETER ZoomInLimit
    Users are allowed to set a zoom-in limit.

    .PARAMETER ZoomOutLimit
    Users are allowed to set a zoom-out limit.

    .PARAMETER Draggable
    Users can drag & drop the nodes of orgchart if they enable this option. **Note**: this feature doesn't work on IE due to its poor support for HTML5 drag & drop API.

    .PARAMETER AllowExport
    It enable the export button for orgchart.

    .PARAMETER ExportFileName
    It's filename when you export current orgchart as a picture.

    .PARAMETER ExportExtension
    Available values are png and pdf.

    .PARAMETER ChartID
    Forces ChartID to be set to known value rather than having it autogenerated

    .EXAMPLE
    New-HTML {
        New-HTMLOrgChart {
            New-OrgChartNode -Name 'Test' -Title 'Test2' {
                New-OrgChartNode -Name 'Test' -Title 'Test2'
                New-OrgChartNode -Name 'Test' -Title 'Test2'
                New-OrgChartNode -Name 'Test' -Title 'Test2' {
                    New-OrgChartNode -Name 'Test' -Title 'Test2'
                }
            }
        } -AllowExport -ExportExtension pdf -Draggable
    } -FilePath $PSScriptRoot\Example-OrgChart01.html -ShowHTML -Online

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [ScriptBlock] $ChartNodes,
        [ValidateSet("TopToBottom", "BottomToTop", "LeftToRight", "RightToLeft")][string] $Direction,
        [int] $VisileLevel,
        [int] $VerticalLevel,
        [string] $NodeTitle,
        [switch] $ToggleSiblings,
        [switch] $Pan,
        [switch] $Zoom,
        [double] $ZoomInLimit,
        [double] $ZoomOutLimit,
        [switch] $Draggable,
        [switch] $AllowExport,
        [string] $ExportFileName = 'PSWriteHTML-OrgChart',
        [ValidateSet('png', 'pdf')] $ExportExtension = 'png',
        [string] $ChartID
    )

    $DirectionDictionary = @{
        "TopToBottom" = 't2b'
        "BottomToTop" = 'b2t'
        "LeftToRight" = 'l2r'
        "RightToLeft" = 'r2l'
    }
    $Script:HTMLSchema.Features.MainFlex = $true
    $Script:HTMLSchema.Features.Jquery = $true
    $Script:HTMLSchema.Features.ChartsOrg = $true
    if ($ExportExtension -eq 'png' -and $AllowExport) {
        $Script:HTMLSchema.Features.ES6Promise = $true
        $Script:HTMLSchema.Features.ChartsOrgExportPNG = $true
    }
    if ($ExportExtension -eq 'pdf' -and $AllowExport) {
        $Script:HTMLSchema.Features.ES6Promise = $true
        $Script:HTMLSchema.Features.ChartsOrgExportPDF = $true
        $Script:HTMLSchema.Features.ChartsOrgExportPNG = $true
    }

    if (-not $ChartID) {
        $ChartID = "OrgChart-$(Get-RandomStringName -Size 8 -LettersOnly)"
    }

    if ($ChartNodes) {
        $DataSource = & $ChartNodes
    }

    $OrgChart = [ordered] @{
        data                = $DataSource
        nodeContent         = 'title'
        exportButton        = $AllowExport.IsPresent
        exportFileName      = $ExportFileName
        exportFileextension = $ExportExtension
    }
    if ($NodeTitle) {
        $OrgChart['nodeTitle'] = $NodeTitle
    }
    if ($Direction) {
        $OrgChart['direction'] = $DirectionDictionary[$Direction]
    }
    if ($Draggable) {
        $OrgChart['draggable'] = $Draggable.IsPresent
    }
    if ($VisileLevel) {
        # It indicates the level that at the very beginning orgchart is expanded to.
        $OrgChart['visibleLevel'] = $VisileLevel
    }
    if ($VerticalLevel) {
        # Users can make use of this option to align the nodes vertically from the specified level.
        $OrgChart['verticalLevel'] = $VerticalLevel
    }
    if ($ToggleSiblings) {
        # Once enable this option, users can show/hide left/right sibling nodes respectively by clicking left/right arrow.
        $OrgChart['toggleSiblingsResp'] = $ToggleSiblings.IsPresent
    }
    if ($Pan) {
        # Users could pan the orgchart by mouse drag&drop if they enable this option.
        $OrgChart['pan'] = $Pan.IsPresent
    }
    if ($Zoom) {
        # Users could zoomin/zoomout the orgchart by mouse wheel if they enable this option.
        $OrgChart['zoom'] = $Zoom.IsPresent
        if ($ZoomInLimit) {
            $OrgChart['zoominLimit'] = $ZoomInLimit
        }
        if ($ZoomOutLimit) {
            $OrgChart['zoomoutLimit'] = $ZoomOutLimit
        }
    }
    $JsonOrgChart = $OrgChart | ConvertTo-Json -Depth 100

    New-HTMLTag -Tag 'script' {
        "`$(function () {"
        "`$(`"#$ChartID`").orgchart($JsonOrgChart);"
        "});"
    }
    New-HTMLTag -Tag 'div' -Attributes @{ id = $ChartID; class = 'orgchartWrapper flexElement' }
}