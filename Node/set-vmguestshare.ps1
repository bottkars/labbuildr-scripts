[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <##>
	[Parameter(Mandatory = $true)][string]$user,
    [Parameter(Mandatory = $true)][string]$Password,
    [Parameter(Mandatory = $false)][string]$HostIP = "192.168.7.3"
)
$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $SecurePassword
New-PSDrive –Name “Z” –PSProvider FileSystem –Root “\\$HostIP\Scripts” –Persist -Credential $Credential -Scope Global
New-PSDrive –Name “X” –PSProvider FileSystem –Root “\\$HostIP\Sources” –Persist -Credential $Credential -Scope Global