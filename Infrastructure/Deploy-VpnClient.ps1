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
$privateKey = 'RootCert.pfx'
$virtualNetworkGatewayName = "$baseName-gateway"
Write-Host "containerName = $containerName" 
Write-Host "privateKey = $privateKey" 
Write-Host "virtualNetworkGatewayName = $virtualNetworkGatewayName" 

Write-Host "Getting the Storage Account"
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $baseName

Write-Host "Getting the Root Cert's private key"
Get-AzureStorageBlobContent -Context $storageAccount.Context -Container $containerName -Blob $privateKey -Destination "./$privateKey" -Force | Out-Null

Write-Host "Loading Root Cert"
$cert = Import-PfxCertificate `
	-Password $(ConvertTo-SecureString -String $certPassword -Force -AsPlainText) `
	-CertStoreLocation "Cert:\CurrentUser\My" `
	-FilePath "./$privateKey"
Remove-Item –path "./$privateKey"

Write-Host "Generating Client Cert"
New-SelfSignedCertificate -Type Custom -DnsName "Azure P2S $baseName Child Cert" -KeySpec Signature `
	-Subject "CN=Azure P2S $baseName Child Cert" -KeyExportPolicy Exportable `
	-HashAlgorithm sha256 -KeyLength 2048 `
	-CertStoreLocation "Cert:\CurrentUser\My" `
	-Signer $cert -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.2')
Remove-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)"

Write-Host "Downloading Vpn Client"
$profile = New-AzureRmVpnClientConfiguration -ResourceGroupName $resourceGroupName -Name $virtualNetworkGatewayName -AuthenticationMethod "EapTls"
Invoke-WebRequest -Uri  $profile.VPNProfileSASUrl -OutFile './VpnClient.zip'

Write-Host "Finished the PowerShell script: $($MyInvocation.MyCommand.Path)"