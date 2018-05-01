Param (
	[Parameter()]
	[String]$storageName,
	[String]$storageKey,
	[String]$shareName,
	[String]$driveLetter
)

$cmd = "net use $($driveLetter): \\$storageName.file.core.windows.net\$shareName /u:AZURE\$storageName $storageKey /PERSISTENT:YES"
cmd.exe /c $cmd