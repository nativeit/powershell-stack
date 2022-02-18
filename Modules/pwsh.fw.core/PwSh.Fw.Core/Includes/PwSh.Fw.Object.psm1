$Script:NS = "PwSh.Object"

<#

 ##     ## ##     ## ##
  ##   ##  ###   ### ##
   ## ##   #### #### ##
    ###    ## ### ## ##
   ## ##   ##     ## ##
  ##   ##  ##     ## ##
 ##     ## ##     ## ########

#>

<#
.SYNOPSIS
Convert an XML content to a PowerShell Object

.DESCRIPTION
Convert any XML content to a PSCustomObject. It can then be manipulated like any object.
It handles array and nested XML content.
It is useful for example to convert an XML object to a JSON object

.PARAMETER InputObject
XML object to convert

.EXAMPLE
[XML]$xml = Get-Content /path/to/file.xml
$obj = $xml | ConvertFrom-Xml
$json = $obj | ConvertTo-Json

.NOTES

.LINK
#>

function ConvertFrom-Xml {
	[CmdletBinding()]Param (
		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)][System.Object]$InputObject
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		$OutputObject = New-Object PSObject
		if ($null -ne $InputObject) {
			if ($InputObject.HasAttributes) {
				ForEach ($attr in $InputObject.Attributes) {
					$OutputObject | Add-Member -MemberType NoteProperty -Name $attr.Name -Value $attr.Value
				}
			}
			if ($InputObject.HasChildNodes) {
				ForEach ($child in $InputObject.ChildNodes) {
					$OutputObject | Add-Member -MemberType NoteProperty -Name $child.LocalName -Value @() -ErrorAction SilentlyContinue
					$OutputObject.($child.LocalName) += ($child | ConvertFrom-Xml)
				}
			}
		}
		return $OutputObject
	}

	End {
		# Write-LeaveFunction
	}
}

# <#
# .SYNOPSIS
# List object's properties.

# .DESCRIPTION
# Get properties of the type of an object.
# It can be used to filter out default object's type properties.

# .PARAMETER obj
# Object of reference

# .EXAMPLE
# $s = "this is a test"
# $s | Get-ObjectProperties

# .NOTES
# #>
# function Get-ObjectProperties {
# 	[CmdletBinding()]Param (
# 		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)][System.object]$obj,
# 		[string[]]$Exclude
# 	)
# 	Begin {
# 		# Write-EnterFunction
# 	}

# 	Process {
# 		if (!$obj) { return }
# 		if ($null -eq $obj) { return }

# 		Try	{
# 			$DefaultTypeProps = @( $obj.GetType().GetProperties() | Where-Object { $_.Name -notIn $Exclude } | Select-Object -ExpandProperty Name -ErrorAction Stop )
# 			if ($DefaultTypeProps.count -gt 0) {
# 				# edevel("Excluding default properties for $($obj.GetType().FullName):")
# 				# edevel($($DefaultTypeProps | Out-String))
# 			}
# 		}
# 		Catch {
# 			Write-Warning "Failed to extract properties from $($obj.GetType().FullName): $_"
# 			$DefaultTypeProps = @()
# 		}

# 		@( $DefaultTypeProps ) | Select-Object -Unique
# 	}

# 	End {
# 		# Write-LeaveFunction
# 	}
# }

# <#
# .SYNOPSIS
# Get the useful properties of an object.

# .DESCRIPTION
# Get the properties of an object minus the default object properties. It is the opposite of Get-ObjectProperties.

# .PARAMETER InputObject
# Object to inspect

# .PARAMETER Include
# For inclusion of a default property that would otherwise been stripped out.

# .EXAMPLE
# $obj | Get-CustomObjectProperties

# .EXAMPLE
# $obj | Get-CustomObjectProperties -Include Name

# .NOTES
# General notes
# #>

# function Get-CustomObjectProperties {
# 	[CmdletBinding()]Param (
# 		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)][Object]$InputObject,
# 		[string[]]$Include
# 	)
# 	Begin {
# 		# Write-EnterFunction
# 	}

# 	Process {
# 		$excludeProps = $InputObject | Get-ObjectProperties | Where-Object { $_ -notIn $Include }
# 		Try	{
# 			$DefaultTypeProps = @($InputObject.GetType().GetProperties() | Where-Object { $_.Name -notIn $excludeProps } | Select-Object -ExpandProperty Name -ErrorAction Stop )
# 			if ($DefaultTypeProps.count -gt 0) {
# 				# edevel($($DefaultTypeProps | Out-String))
# 			}
# 		} Catch {
# 			Write-Warning "Failed to extract properties from $($obj.GetType().FullName): $_"
# 			$DefaultTypeProps = @()
# 		}

# 		return @($DefaultTypeProps) | Sort-Object -Unique
# 	}

# 	End {
# 		# Write-LeaveFunction
# 	}
# }

<#

  #######  ########        ## ########  ######  ########
 ##     ## ##     ##       ## ##       ##    ##    ##
 ##     ## ##     ##       ## ##       ##          ##
 ##     ## ########        ## ######   ##          ##
 ##     ## ##     ## ##    ## ##       ##          ##
 ##     ## ##     ## ##    ## ##       ##    ##    ##
  #######  ########   ######  ########  ######     ##

#>

<#
.SYNOPSIS
Merge two objects

.DESCRIPTION
The `Merge-Object` merge two objects into one. If keys are found in both objects, the keys from InputObject1 are overridden with the values of InputObject2.
Keep that in mind to order your objects appropriately.

.PARAMETER InputObject1
1st object to merge

.PARAMETER InputObject2
2nd object to merge

.EXAMPLE
Merge-Object -InputObject (Get-Process)[0] -InputObject2 (Get-Item ./file)

.NOTES
General notes

.LINK
http://powershelldistrict.com/how-to-combine-powershell-objects/
#>

function Merge-Object {
	[CmdletBinding()]Param (
		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)][Object]$InputObject1,
		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)][Object]$InputObject2
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		$arguments = @{}
		foreach ($Property in $InputObject1.PSObject.Properties) {
			$arguments += @{ $Property.Name = $Property.value }
		}

		foreach ($Property in $InputObject2.PSObject.Properties) {
			# this syntax avoid duplicate keys
			$arguments.$($Property.Name) = $Property.value
		}
		$OutputObject = [PSCustomObject]$arguments

		return $OutputObject
	}

	End {
		# Write-LeaveFunction
	}
}

<#

 ##     ##    ###     ######  ##     ## ########    ###    ########  ##       ########
 ##     ##   ## ##   ##    ## ##     ##    ##      ## ##   ##     ## ##       ##
 ##     ##  ##   ##  ##       ##     ##    ##     ##   ##  ##     ## ##       ##
 ######### ##     ##  ######  #########    ##    ##     ## ########  ##       ######
 ##     ## #########       ## ##     ##    ##    ######### ##     ## ##       ##
 ##     ## ##     ## ##    ## ##     ##    ##    ##     ## ##     ## ##       ##
 ##     ## ##     ##  ######  ##     ##    ##    ##     ## ########  ######## ########

#>

<#
.SYNOPSIS
Merge two or more hashtables

.DESCRIPTION
Merge multiple hashtables into one.
For this cmdlet you can use several syntaxes and you are not limited to two input tables: Using the pipeline: $h1, $h2, $h3 | Merge-Hashtables
Using arguments: Merge-Hashtables $h1 $h2 $h3
Or a combination: $h1 | Merge-Hashtables $h2 $h3

.EXAMPLE
$h1, $h2, $h3 | Merge-Hashtables

.EXAMPLE
Merge-Hashtables $h1 $h2 $h3

.EXAMPLE
$h1 | Merge-Hashtables $h2 $h3

.NOTES
https://stackoverflow.com/questions/8800375/merging-hashtables-in-powershell-how

.LINK
#>

Function Merge-Hashtables {
    $Output = @{}
    ForEach ($Hashtable in ($Input + $Args)) {
        If ($Hashtable -is [Hashtable]) {
            ForEach ($Key in $Hashtable.Keys) { $Output.$Key = $Hashtable.$Key }
        }
    }
    $Output
}

<#
.SYNOPSIS
Sort a hashtable

.DESCRIPTION
Sort a hashtable by Name

.PARAMETER InputObject
Hashtable to sort

.EXAMPLE
$h = @{ "this" = "is"; "a" = "test"}
$h | Sort-HashTable

.NOTES
I know Sort is not an approved verb but hey, this function actually DOES sort a hashtable

.OUTPUTS
The sorted hashtable

.LINK
#>

function Sort-HashTable {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Sort-HashTable is a more intuitive verb for this function.")]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][hashtable]$InputObject
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		# return $InputObject.GetEnumerator() | Sort-Object -Property Name
		$hReturn = [ordered]@{}
		$InputObject.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
			$hReturn.Add($_.Name, $_.Value)
		}
		return $hReturn
	}

	End {
		# Write-LeaveFunction
	}
}

<#
.SYNOPSIS
Sort properties of an object

.DESCRIPTION
Sort properties of an object in ascending alphabetical order

.PARAMETER InputObject
Object to display properties

.EXAMPLE
$object| Sort-Properties

.NOTES
General notes

.LINK
#>

function Sort-ByProperties {
	[CmdletBinding()][OutputType([String[]])]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="'Sort'-ByProperties is a more intuitive verb for this function and does not conflict other cmdlet. Actually, this function DOES sort an object by it properties name, alphabetically. After all 'Sort-Object' does exist too isn't it ?")]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][Object]$InputObject
	)
	Begin {
		Write-EnterFunction
	}

	Process {
		return $InputObject | Format-List ($InputObject | Get-Member -MemberType Properties).name
	}

	End {
		Write-LeaveFunction
	}
}

<#
.SYNOPSIS
	Convert a XML Plist to a PowerShell object

.DESCRIPTION
    Converts an XML PList (property list) in to a usable object in PowerShell.
	Properties will be converted in to ordered hashtables, the values of each property may be integer, double, date/time, boolean, string, or hashtables, arrays of any these, or arrays of bytes.

.PARAMETER plist
	The property list as an [XML] document object, to be processed.  This parameter is mandatory and is accepted from the pipeline.

.EXAMPLE
    $pList = [xml](Get-Content 'someFile.plist') | ConvertFrom-Plist

.INPUTS
	system.xml.document

.OUTPUTS
	system.object

.NOTES
    Original Script / Function / Class assembled by Carl Morris, Morris Softronics, Hooper, NE, USA
	Initial release - Aug 27, 2018
	Rewritten without the use of class

.LINK
	https://github.com/msftrncs/PwshReadXmlPList

.FUNCTIONALITY
    data format conversion
#>
function ConvertFrom-Plist {
	[CmdletBinding()]Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][xml]$plist
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		if ($null -eq $plist.item('plist')) {
			return $null
		} else {
			return (Read-PlistNode -Node $plist.item('plist').FirstChild)
		}
	}

	End {
		# Write-LeaveFunction
	}
}

function Read-PlistNode {
	[CmdletBinding()][OutputType([System.Object], [System.Boolean])]Param (
		[Parameter(Mandatory = $true, ValueFromPipeLine = $true)][System.Xml.XmlElement]$node
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		if ($node.HasChildNodes) {
			# edevel "$($node.name) - $($node.'#text')"
			switch ($node.Name) {
				array {
					# for arrays, recurse each node in the subtree, returning an array (forced)
					, @($node.ChildNodes.foreach{ (Read-PlistNode -Node $_) })
					continue
				}
				date {
					# must be a date-time type value element, return its value
					$node.InnerText -as [dateTime]
					continue
				}
				data {
					# must be a data block value element, return its value as [byte[]]
					# [convert]::FromBase64String((Read-PlistNode -Node $node.InnerText))
					$node.InnerText
					continue
				}
				dict {
					# for dictionary, return the subtree as a ordered hashtable, with possible recursion of additional arrays or dictionaries
					$collection = [ordered]@{}
					$CurrentNode = $node.FirstChild # start at the first child node of the dictionary
					while ($null -ne $CurrentNode) {
						if ($CurrentNode.Name -eq 'key') {
							# edevel "$($CurrentNode.name) - $($CurrentNode.'#text')"
							# a key in a dictionary, add it to a collection
							if ($null -ne $CurrentNode.NextSibling) {
								# edevel "$($CurrentNode.NextSibling.name) - $($CurrentNode.NextSibling.'#text')"
								# note: keys are forced to [string], insures a $null key is accepted
								# $collection[$CurrentNode.InnerText] = (Read-PlistNode -Node $CurrentNode.NextSibling)
								$collection.Add($CurrentNode.InnerText, (Read-PlistNode -Node $CurrentNode.NextSibling))
								$CurrentNode = $CurrentNode.NextSibling.NextSibling # skip the next sibling because it was the value of the property
							} else {
								throw "Dictionary property value missing!"
							}
						} else {
							throw "Non 'key' element found in dictionary: <$($CurrentNode.Name)>!"
						}
					}
					# return the collected hash table
					$collection
					continue
				}
				integer {
					# must be an integer type value element, return its value
					$node.InnerText -as [int]
					continue
				}
				real {
					$node.InnerText -as [double]
					continue
				}
				string {
					# for string, return the value, with possible recursion and
					# collection
					$node.InnerText
					continue
				}
				default {
					# we didn't recognize the element type!
					throw "Unhandled PLIST property type <$($node.Name)>!"
				}
			}
		} else {
			# return simple element value (need to check for Boolean datatype, and process value accordingly)
			switch ($node.Name) {
				true { $true; continue } # return a Boolean TRUE value
				false { $false; continue } # return a Boolean FALSE value
				# default { $node.Value } # return the element value
			}
		}
	}

	End {
		# Write-LeaveFunction
	}
}

function ConvertTo-CamelCase {
    [CmdletBinding()]Param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[AllowNull()][AllowEmptyString()]
        [string]$String
    )
    Begin {
        # Write-EnterFunction
    }

    Process {
		# convert to Title Case
		$camelCase = (get-culture).TextInfo.ToTitleCase($String)
		# transforms accent to normal letters
		$camelCase = $camelCase | Remove-StringLatinCharacters
		# remove non alphanumeric characters
		$camelCase = $camelCase -replace '[^a-zA-Z0-9]', ''
		# convert 1st letter to lowercase
		$camelCase = $camelCase.Substring(0,1).ToLower() + $camelCase.Substring(1)

		return $camelCase
    }

    End {
        # Write-LeaveFunction
    }
}

<#
	.SYNOPSIS
	Serialize an object to a single string

	.DESCRIPTION
	Convert an object to a single string to ease display and debug

	.PARAMETER InputObject
	an object (currently, only hashtable are supported)

	.EXAMPLE
	$ht = @{'key'="value";'key2'="value2"}
	This defines a hashtable

	.EXAMPLE
	$ht | ConvertTo-SingleString
	This example convert the previously created hashtable into a single, serialized string

	.NOTES
	General notes

	.LINK
#>
function ConvertTo-SingleString {
    [CmdletBinding()]param(
		[parameter(Mandatory,ValueFromPipeline = $True)]
		$InputObject
    )

	Begin {
	}

	Process {
		# $InputObject.GetType()
		switch ($InputObject.GetType()) {
			'Hashtable' {
				# $serialized = ($InputObject.GetEnumerator() | % { "'$($_.Key)'=`"$($_.Value)`"" }) -join ';'
				$serialized = Foreach ($k in $InputObject.GetEnumerator()) {
					switch ($k.Value.GetType()) {
						'dateTime' {
							"'$($k.Key)'=[System.DateTime]`"$($k.Value)`""
						}
						default {
							"'$($k.Key)'=`"$($k.Value)`""
						}
					}
				}
				$serialized = $serialized -join(';')
			}
			default {
				Write-Error "Object type '$($InputObject.GetType())' not supported yet."
				return $false
			}
		}
		return "@{" + $serialized + "}"
	}

	End {
	}
}

<#
.SYNOPSIS
Convert a simple object to a stringData

.DESCRIPTION
Convert an object or a hashtable to an array of "key = value" pairs

.PARAMETER InputObject
Object to convert

.EXAMPLE
$myHash | ConvertTo-StringData

.NOTES
General notes
#>
function ConvertTo-StringData {
	[CmdletBinding()]
	[OutputType([String])]
	Param (
		[parameter(Mandatory,ValueFromPipeline = $True)]
		$InputObject
	)
	Begin {
	}

	Process {
		if ($($InputObject) -is [array]) {
			$InputObject -join (',')
		} else {
			switch ($InputObject.GetType()) {
				'Hashtable' {
					$InputObject.Keys | ForEach-Object {
						"$_ = $(ConvertTo-StringData $($InputObject.$_))"
					}
				}
				default {
					$InputObject
				}
			}
		}
	}

	End {
	}
}

<#
	.LINK
	http://www.lazywinadmin.com/2015/05/powershell-remove-diacritics-accents.html
#>
function Remove-StringLatinCharacters
{
    PARAM (
        [parameter(ValueFromPipeline = $true)]
        [string]$String
    )
    PROCESS
    {
        [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
    }
}

<#
.SYNOPSIS
Resolve boolean well-known values

.DESCRIPTION
Boolean are not just (true | false) value. It can by yes/no or 0/1. Resolve-Boolean handle all of this.

.PARAMETER var
The variable name to check

.EXAMPLE
true | Resolve-Boolean

.EXAMPLE
0 | Resolve-Boolean

.EXAMPLE
if ((Resolve-Boolean -var "yes") -eq $true) { echo "yes is true" }

.NOTES
General notes

.LINK
#>

function Resolve-Boolean {
    [CmdletBinding()][OutputType([boolean])]Param (
		[Parameter(Mandatory,ValueFromPipeLine = $true)]$var
    )
    Begin {
        # Write-EnterFunction
    }

    Process {
		switch -regex ($var.GetType()) {
			'bool*' {
				return $var
			}
			'int*' {
				switch ($var) {
					0 		{ return $false }
					1 		{ return $true  }
				}
			}
			'string' {
				switch -wildcard ($var) {
					'false' { return $false }
					'true'	{ return $true  }
					'n*'	{ return $false }
					'y*'	{ return $true  }
				}
			}
		}
		return $false
    }

    End {
        # Write-LeaveFunction
    }
}

<#
.SYNOPSIS
List object's properties.

.DESCRIPTION
Get properties of the type of an object.
It can be used to filter out default object's type properties.

.PARAMETER obj
Object of reference

.EXAMPLE
$s = "this is a test"
$s | Get-ObjectProperties

.NOTES
#>
function Get-ObjectProperties {
	[CmdletBinding()]Param (
		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)][System.object]$obj,
		[string[]]$Exclude
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		if (!$obj) { return }
		if ($null -eq $obj) { return }

		Try	{
			$DefaultTypeProps = @( $obj.GetType().GetProperties() | Where-Object { $_.Name -notIn $Exclude } | Select-Object -ExpandProperty Name -ErrorAction Stop )
			if ($DefaultTypeProps.count -gt 0) {
				# edevel("Excluding default properties for $($obj.GetType().FullName):")
				# edevel($($DefaultTypeProps | Out-String))
			}
		}
		Catch {
			Write-Warning "Failed to extract properties from $($obj.GetType().FullName): $_"
			$DefaultTypeProps = @()
		}

		@( $DefaultTypeProps ) | Select-Object -Unique
	}

	End {
		# Write-LeaveFunction
	}
}

<#
.SYNOPSIS
Get the useful properties of an object.

.DESCRIPTION
Get the properties of an object minus the default object properties. It is the opposite of Get-ObjectProperties.

.PARAMETER InputObject
Object to inspect

.PARAMETER Include
For inclusion of a default property that would otherwise been stripped out.

.EXAMPLE
$obj | Get-CustomObjectProperties

.EXAMPLE
$obj | Get-CustomObjectProperties -Include Name

.NOTES
General notes
#>

function Get-CustomObjectProperties {
	[CmdletBinding()]Param (
		[Parameter(Mandatory = $true,ValueFromPipeLine = $true)][Object]$InputObject,
		[string[]]$Include
	)
	Begin {
		# Write-EnterFunction
	}

	Process {
		$excludeProps = $InputObject | Get-ObjectProperties | Where-Object { $_ -notIn $Include }
		Try	{
			$DefaultTypeProps = @($InputObject.GetType().GetProperties() | Where-Object { $_.Name -notIn $excludeProps } | Select-Object -ExpandProperty Name -ErrorAction Stop )
			if ($DefaultTypeProps.count -gt 0) {
				# edevel($($DefaultTypeProps | Out-String))
			}
		} Catch {
			Write-Warning "Failed to extract properties from $($obj.GetType().FullName): $_"
			$DefaultTypeProps = @()
		}

		return @($DefaultTypeProps) | Sort-Object -Unique
	}

	End {
		# Write-LeaveFunction
	}
}

<#
.SYNOPSIS
Convert anything into a PSCustomObject

.DESCRIPTION
Convert anything that contains a list of "name/value" pairs to a simple PSCustomObject
This function can convert hashtables or dictionaries to PSCustomObject

.EXAMPLE

.NOTES
General notes
#>
function ConvertTo-PSCustomObject {
	Begin {
		Write-EnterFunction
	}

	Process {
		$object = New-Object Object
		$_.GetEnumerator() | ForEach-Object { Add-Member -inputObject $object -memberType NoteProperty -name $_.Name -value $_.Value }
		return $object
	}

	End {
		Write-LeaveFunction
	}
}
