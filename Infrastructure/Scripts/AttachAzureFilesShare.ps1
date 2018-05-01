Param (
	[Parameter()]
	[String]$storageName,
	[String]$storageKey,
	[String]$shareName,
	[String]$driveLetter
)

$acctKey = ConvertTo-SecureString -String $storageKey -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\$storageName", $acctKey
New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root "\\$storageName.file.core.windows.net\$shareName" -Credential $credential -Persist