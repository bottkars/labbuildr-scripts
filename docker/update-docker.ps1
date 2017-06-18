## base function to update to latest docker

Stop-Service docker
$sourcepath = "https://master.dockerproject.org/windows/x86_64"
$targetpath = "C:\Program Files\docker" 
$Updatefiles = ('docker.exe','dockerd.exe')
foreach ($Updatefile in $Updatefiles) {
    Start-BitsTransfer -Source "$sourcepath/$Updatefile" -Destination $targetpath -Verbose
}
Start-Service docker