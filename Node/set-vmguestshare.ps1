[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <##>
	[Parameter(Mandatory = $true)][string]$user,
    [Parameter(Mandatory = $true)][string]$Password,
    [Parameter(Mandatory = $false)][string]$HostIP = "192.168.7.3",
    [Parameter(Mandatory = $true)]$Scripts_share_name,
    [Parameter(Mandatory = $true)]$Sources_share_name
)
$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $SecurePassword
try
    {
    New-PSDrive –Name “Z” –PSProvider FileSystem –Root “\\$HostIP\$Scripts_share_name” –Persist -Credential $Credential -Scope Global
    }
catch
    {
    Write-Warning "Share already mounted"
    }


try
    {
    New-PSDrive –Name “X” –PSProvider FileSystem –Root “\\$HostIP\$Sources_share_name” –Persist -Credential $Credential -Scope Global
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

