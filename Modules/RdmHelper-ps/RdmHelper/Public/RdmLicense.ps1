
function Register-RdmLicense
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Name,
        [Parameter(Mandatory=$true)]
        $Serial
    )

    $LicensePattern = '[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}'

    if (-Not ($Serial -CMatch $LicensePattern)) {
        throw "Invalid license format: `"$Serial`""
    }

    $RdmCommand = Get-RdmCommand
    & $RdmCommand "/RegisterUser:`"$Name`"" "/RegisterSerial:`"$Serial`""
}
