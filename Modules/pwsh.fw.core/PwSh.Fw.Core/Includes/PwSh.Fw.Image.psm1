<#
.SYNOPSIS
   Resize an image
.DESCRIPTION
   Resize an image based on a new given height or width or a single dimension and a maintain ratio flag. 
   The execution of this CmdLet creates a new file named "OriginalName_resized" and maintains the original
   file extension
.PARAMETER Width
   The new width of the image. Can be given alone with the MaintainRatio flag
.PARAMETER Height
   The new height of the image. Can be given alone with the MaintainRatio flag
.PARAMETER ImagePath
   The path to the image being resized
.PARAMETER MaintainRatio
   Maintain the ratio of the image by setting either width or height. Setting both width and height and also this parameter
   results in an error
.PARAMETER Percentage
   Resize the image *to* the size given in this parameter. It's imperative to know that this does not resize by the percentage but to the percentage of
   the image.
.PARAMETER SmoothingMode
   Sets the smoothing mode. Default is HighQuality.
.PARAMETER InterpolationMode
   Sets the interpolation mode. Default is HighQualityBicubic.
.PARAMETER PixelOffsetMode
   Sets the pixel offset mode. Default is HighQuality.
.EXAMPLE
   Resize-Image -Height 45 -Width 45 -ImagePath "Path/to/image.jpg"
.EXAMPLE
   Resize-Image -Height 45 -MaintainRatio -ImagePath "Path/to/image.jpg"
.EXAMPLE
   #Resize to 50% of the given image
   Resize-Image -Percentage 50 -ImagePath "Path/to/image.jpg"
.NOTES
   Written By: 
   Christopher Walker
.LINK
	https://gist.github.com/someshinyobject/617bf00556bc43af87cd
#>
Function Resize-Image() {
    [CmdLetBinding(
        SupportsShouldProcess=$true, 
        PositionalBinding=$false,
        ConfirmImpact="Low",
        DefaultParameterSetName="Absolute"
    )]
    Param (
        [Parameter(Mandatory=$True)]
        [ValidateScript({
                Test-Path $_
        })][String]$Image,
        [Parameter(Mandatory=$False, ParameterSetName="ABSOLUTE")][Switch]$MaintainRatio,
        [Parameter(Mandatory=$False, ParameterSetName="ABSOLUTE")][Int]$Height,
        [Parameter(Mandatory=$False, ParameterSetName="ABSOLUTE")][Int]$Width,
        [Parameter(Mandatory=$False, ParameterSetName="PERCENT")][Double]$Percentage,
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.SmoothingMode]$SmoothingMode = "HighQuality",
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.InterpolationMode]$InterpolationMode = "HighQualityBicubic",
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.PixelOffsetMode]$PixelOffsetMode = "HighQuality",
        [Parameter(Mandatory=$False)][String]$NameModifier,
		[Parameter(Mandatory=$False)][String]$Destination,
		[Parameter(Mandatory=$False)][String]$Filename
    )
    Begin {
        If ($Width -and $Height -and $MaintainRatio) {
            Throw "Absolute Width and Height cannot be given with the MaintainRatio parameter."
        }
 
        If (($Width -xor $Height) -and (-not $MaintainRatio)) {
            Throw "MaintainRatio must be set with incomplete size parameters (Missing height or width without MaintainRatio)"
        }
	}
    Process {
		$Item = Get-Item $Image
		# $Path = (Resolve-Path $Image).Path
		$Path = $Item.FullName
		# $Dot = $Path.LastIndexOf(".")

		$OldImage = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Path
		# Grab these for use in calculations below. 
		$OldHeight = $OldImage.Height
		$OldWidth = $OldImage.Width

		If ($MaintainRatio) {
			$OldHeight = $OldImage.Height
			$OldWidth = $OldImage.Width
			If ($Height) {
				$Width = $OldWidth / $OldHeight * $Height
			}
			If ($Width) {
				$Height = $OldHeight / $OldWidth * $Width
			}
		}

		If ($Percentage) {
			$Product = ($Percentage / 100)
			$Height = $OldHeight * $Product
			$Width = $OldWidth * $Product
		}

		$Bitmap = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Width, $Height
		$NewImage = [System.Drawing.Graphics]::FromImage($Bitmap)
			
		#Retrieving the best quality possible
		$NewImage.SmoothingMode = $SmoothingMode
		$NewImage.InterpolationMode = $InterpolationMode
		$NewImage.PixelOffsetMode = $PixelOffsetMode
		$NewImage.DrawImage($OldImage, $(New-Object -TypeName System.Drawing.Rectangle -ArgumentList 0, 0, $Width, $Height))

		#Add name modifier (OriginalName_{$NameModifier}.jpg)
		if ([string]::IsNullOrEmpty($Destination)) { $Destination = $Item.DirectoryName }
		if ([string]::IsNullOrEmpty($Filename)) { $Filename = "$($Item.Basename)" }
		if ([string]::IsNullOrEmpty($NameModifier)) {
			$OutputPath = "$Destination/${Filename}"
		} else {
			switch ($NameModifier) {
				'NEWSIZE' {
					# $OutputPath = $Path.Substring(0,$Dot) + "_" + $Width + "x" + $Height + $Path.Substring($Dot,$Path.Length - $Dot)
					$OutputPath = "${Destination}/${Filename}_${Width}x${Height}$($Item.Extension)"
				}
				default {
					# $OutputPath = $Path.Substring(0,$Dot) + "_" + $NameModifier + $Path.Substring($Dot,$Path.Length - $Dot)
					$OutputPath = "${Destination}/${Filename}_${NameModifier}$($Item.Extension)"
				}
			}
		}
		If ($PSCmdlet.ShouldProcess("Resized image based on $Path", "save to $OutputPath")) {
			$Bitmap.Save($OutputPath)
		}

		$Bitmap.Dispose()
		$NewImage.Dispose()
		$OldImage.Dispose()
    }
}
