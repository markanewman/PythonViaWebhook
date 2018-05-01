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
$publicKey = 'RootCert.public.cer'
$privateKey = 'RootCert.pfx'
New-AzureStorageContainer -Context $ctx -Name $containerName -Permission Off -ErrorAction SilentlyContinue | Out-Null
$blob = Get-AzureStorageBlob -Context $ctx -Container $containerName -Blob $publicKey -ErrorAction SilentlyContinue
if(!$blob)
{
	Write-Host "Public Key not found. Making new Keys"
	$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
		-Subject "CN=Azure P2S $baseName Root Cert" -KeyExportPolicy Exportable `
		-HashAlgorithm sha256 -KeyLength 2048 `
		-CertStoreLocation "Cert:\CurrentUser\My" `
		-KeyUsageProperty Sign -KeyUsage CertSign

	$mypwd = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
	Export-Certificate -Cert $cert -FilePath "./$publicKey" -Type CERT | Out-Null
	Export-PfxCertificate -Cert $cert -FilePath "./$privateKey" -Password $mypwd | Out-Null
	Set-AzureStorageBlobContent -Context $ctx -Container $containerName -File "./$privateKey" -Blob $privateKey
	Set-AzureStorageBlobContent -Context $ctx -Container $containerName -File "./$publicKey" -Blob $publicKey 	
	Remove-Item –path "./$publicKey"
	Remove-Item –path "./$privateKey"
	Remove-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)"
}

Write-Host "Finished the PowerShell script: $($MyInvocation.MyCommand.Path)"