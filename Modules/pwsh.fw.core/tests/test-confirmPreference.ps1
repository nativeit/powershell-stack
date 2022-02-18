[CmdletBinding(DefaultParameterSetName = 'NAME', SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
Param(
)

function Test-ConfirmPreferenceLowImpact {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	[OutputType([String])]
	Param (
	)
	Begin {
		# Write-EnterFunction
		$FUNCNAME = $MyInvocation.MyCommand
	}

	Process {
		Write-Host "$FUNCNAME\ConfirmPreference = $ConfirmPreference"
		# Write-Host "$FUNCNAME\ConfirmImpact = $ConfirmImpact"	}
		if ($PSCmdlet.ShouldProcess($FUNCNAME)) {
			Write-Output "OK"
		} else {
			Write-Output "NO"
		}
	}

	End {
		# Write-LeaveFunction
	}
}

function Test-ConfirmPreferenceMediumImpact {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	[OutputType([String])]
	Param (
	)
	Begin {
		# Write-EnterFunction
		$FUNCNAME = $MyInvocation.MyCommand
	}

	Process {
		Write-Host "$FUNCNAME\ConfirmPreference = $ConfirmPreference"
		# Write-Host "$FUNCNAME\ConfirmImpact = $ConfirmImpact"	}
		if ($PSCmdlet.ShouldProcess($FUNCNAME)) {
			Write-Output "OK"
		} else {
			Write-Output "NO"
		}
	}

	End {
		# Write-LeaveFunction
	}
}

function Test-ConfirmPreferenceHighImpact {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	[OutputType([String])]
	Param (
	)
	Begin {
		# Write-EnterFunction
		$FUNCNAME = $MyInvocation.MyCommand
	}

	Process {
		Write-Host "$FUNCNAME\ConfirmPreference = $ConfirmPreference"
		# Write-Host "$FUNCNAME\ConfirmImpact = $ConfirmImpact"
		if ($PSCmdlet.ShouldProcess($FUNCNAME)) {
			Write-Output "OK"
		} else {
			Write-Output "NO"
		}
	}

	End {
		# Write-LeaveFunction
	}
}

Write-Host "Confirm = $Confirm"
Write-Host "ConfirmPreference = $ConfirmPreference"
Write-Host "ConfirmImpact = $ConfirmImpact"
Write-Host "ConfirmImpactPreference = $ConfirmImpactPreference"

Test-ConfirmPreferenceLowImpact
Test-ConfirmPreferenceMediumImpact
Test-ConfirmPreferenceHighImpact

Test-ConfirmPreferenceLowImpact -Confirm:$true
Test-ConfirmPreferenceMediumImpact -Confirm:$true
Test-ConfirmPreferenceHighImpact -Confirm:$true

Test-ConfirmPreferenceLowImpact -Confirm:$false
Test-ConfirmPreferenceMediumImpact -Confirm:$false
Test-ConfirmPreferenceHighImpact -Confirm:$false
