#Requires -Version 5.0

Set-StrictMode -Version 3
Write-Host "Executing the PowerShell script: $($MyInvocation.MyCommand.Path)"

Write-Host ""
Write-Host "--- Expected Parameters Start ---"
Write-Host "resourceGroupName = $resourceGroupName"
Write-Host "location = $location"
Write-Host "baseName = $baseName"
Write-Host "certPassword = $certPassword" 
Write-Host "--- Expected Parameters End --"
Write-Host ""

$containerName = 'certs'
Write-Host "containerName = $containerName" 

Write-Host "Deploying $resourceGroupName"
$deploy = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop -Force

Write-Host "Getting the Storage Account"
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $baseName -ErrorAction SilentlyContinue 
if(!$storageAccount)
{
	Write-Host "Storage Account not found. Making a new one."
	$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Location $location -Name $baseName  -SkuName Standard_LRS -Kind Storage
}
$ctx = $storageAccount.Context

Write-Host "Validating Root Cert"
$rootCertName = 'RootCert.cer'
$clientCertName = 'Client.pfx'
New-AzureStorageContainer -Context $ctx -Name $containerName -Permission Off -ErrorAction SilentlyContinue | Out-Null
$blob = Get-AzureStorageBlob -Context $ctx -Container $containerName -Blob $clientCertName -ErrorAction SilentlyContinue
if(!$blob)
{
	Write-Host "Client Cert not found. Making new Keys"
	$rootCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
		-Subject "CN=Azure P2S $baseName Root Cert" -KeyExportPolicy Exportable `
		-HashAlgorithm sha256 -KeyLength 2048 `
		-CertStoreLocation "Cert:\CurrentUser\My" `
		-KeyUsageProperty Sign -KeyUsage CertSign
	$clientCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
		-Subject "CN=Azure P2S $baseName Child Cert" -KeyExportPolicy Exportable `
		-HashAlgorithm sha256 -KeyLength 2048 `
		-CertStoreLocation "Cert:\CurrentUser\My" `
		-DnsName "Azure P2S $baseName Child Cert" `
		-Signer $rootCert -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.2')

	$mypwd = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
	Export-Certificate -Cert $rootCert -FilePath "./$rootCertName" -Type CERT | Out-Null
	Export-PfxCertificate -Cert $clientCert -FilePath "./$clientCertName" -Password $mypwd | Out-Null
	Set-AzureStorageBlobContent -Context $ctx -Container $containerName -File "./$rootCertName" -Blob $rootCertName
	Set-AzureStorageBlobContent -Context $ctx -Container $containerName -File "./$clientCertName" -Blob $clientCertName 	
	Remove-Item –path "./$rootCertName"
	Remove-Item –path "./$clientCertName"
	Remove-Item -Path "Cert:\CurrentUser\My\$($rootCert.Thumbprint)"
	Remove-Item -Path "Cert:\CurrentUser\My\$($clientCert.Thumbprint)"
}

Write-Host "Finished the PowerShell script: $($MyInvocation.MyCommand.Path)"