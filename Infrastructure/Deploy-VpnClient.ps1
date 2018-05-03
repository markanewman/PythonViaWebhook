#Requires -Version 5.0

Set-StrictMode -Version 3
Write-Host "Executing the PowerShell script: $($MyInvocation.MyCommand.Path)"

Write-Host ""
Write-Host "--- Expected Parameters Start ---"
Write-Host "resourceGroupName = $resourceGroupName"
Write-Host "baseName = $baseName"
Write-Host "certPassword = $certPassword" 
Write-Host "--- Expected Parameters End --"
Write-Host ""

$containerName = 'certs'
$clientCertName = 'Client.pfx'
$virtualNetworkGatewayName = "$baseName-gateway"
Write-Host "containerName = $containerName" 
Write-Host "clientCertName = $clientCertName" 
Write-Host "virtualNetworkGatewayName = $virtualNetworkGatewayName" 

Write-Host "Getting the Storage Account"
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $baseName

Write-Host "Getting the Client Cert"
Get-AzureStorageBlobContent -Context $storageAccount.Context -Container $containerName -Blob $clientCertName -Destination "./$clientCertName" -Force | Out-Null

Write-Host "Loading Client Cert"
Import-PfxCertificate `
	-Password $(ConvertTo-SecureString -String $certPassword -Force -AsPlainText) `
	-CertStoreLocation "Cert:\CurrentUser\My" `
	-FilePath "./$clientCertName" | Out-Null
Remove-Item –path "./$clientCertName"

Write-Host "Downloading Vpn Client"
$profile = New-AzureRmVpnClientConfiguration -ResourceGroupName $resourceGroupName -Name $virtualNetworkGatewayName -AuthenticationMethod "EapTls"
Invoke-WebRequest -Uri  $profile.VPNProfileSASUrl -OutFile './VpnClient.zip'

Write-Host "Finished the PowerShell script: $($MyInvocation.MyCommand.Path)"