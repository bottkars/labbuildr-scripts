param(
$computername = $null
)

$code = {
get-itemproperty 'hklm:\software\microsoft\windows\currentversion\uninstall\*' |where-object { $_.DisplayName } |Select-Object DisplayName, DisplayVersion, Publisher
}

if ($computername)
{
Invoke-Command -ScriptBlock $code -computerName $computername |
Select-Object DisplayName, DisplayVersion, Publisher
} 
else 
{
    Invoke-Command -ScriptBlock $code
}

### Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\
