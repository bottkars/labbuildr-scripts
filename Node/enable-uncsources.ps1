[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <##>
	[Parameter(Mandatory = $true)][string]$SMBuser,
    [Parameter(Mandatory = $true)][string]$SMBPassword,
    [Parameter(Mandatory = $true)]$Sources
)
$SecurePassword = $SMBPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $SMBuser, $SecurePassword

$uri = new-object System.Uri("$Sources")
$HostIP = $uri.Host
Get-PSDrive X -ErrorAction SilentlyContinue | Remove-PSDrive
try
    {
    New-PSDrive -Persist –Name “X” –PSProvider FileSystem –Root “$Sources” -Credential $Credential -Scope Global -ErrorAction Stop
    }
catch
    {
    Write-Warning "Share already mounted"
    }

$Zonemaps = ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap")

 # "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap",
 Foreach ($Zonemap in $Zonemaps)
    {
    #$Zonemap = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap"
    # $Ranges = New-Item -Path $Zonemap -Name "Ranges" -Force
    Write-Host "Setting $Zonemap for $Host"
    $Ranges = "$Zonemap\Ranges"
    $Range1 = New-Item -Path $Ranges -Name "Range1" -Force
    Set-ItemProperty $ZoneMap -Name "UNCAsIntranet" -Value "1" 
    Set-ItemProperty $ZoneMap -Name "AutoDetect" -Value "1" 
    $Range1 | New-ItemProperty -Name ":Range" -Value $HostIP
    # $Range1 | New-ItemProperty -Name "*" -PropertyType DWORD -Value  "1"
    $Range1 | New-ItemProperty -Name "file" -PropertyType DWORD -Value  "1"
   }

