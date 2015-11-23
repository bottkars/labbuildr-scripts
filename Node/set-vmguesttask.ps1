
[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <##>
	[Parameter(Mandatory = $true)][string]$Task,
    [Parameter(Mandatory = $true)][string]$Status
)
$regPath = "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest"
Set-ItemProperty -Path $regPath -Name $Task -Value $Status
