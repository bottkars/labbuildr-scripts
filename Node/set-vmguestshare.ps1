[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <##>
	[Parameter(Mandatory = $true)][string]$user,
    [Parameter(Mandatory = $true)][string]$Password
)
$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $SecurePassword
New-PSDrive –Name “z” –PSProvider FileSystem –Root “\\192.168.7.3\Scripts” –Persist -Credential $Credential