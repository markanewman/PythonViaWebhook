#Requires -Version 5.0

Set-StrictMode -Version 3
Write-Host "Executing the PowerShell script: $($MyInvocation.MyCommand.Path)"

Write-Host ""
Write-Host "--- Expected Parameters Start ---"
Write-Host "resourceGroupName = $resourceGroupName"
Write-Host "location = $location"
Write-Host "addressSpace = $addressSpace"
Write-Host "baseName = $baseName"
Write-Host "user = $user"
Write-Host "password = $password"
Write-Host "vmCount = $vmCount"
Write-Host "--- Expected Parameters End --"
Write-Host ""

# Assemble the script variables
$root = Split-Path $MyInvocation.MyCommand.Path
$now = (get-date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$deployName = "Infrastructure-$now"

Write-Host "root = $root"
Write-Host "now = $now"
Write-Host "deployName = $deployName"

Write-Host "Deploying $resourceGroupName"
$deploy = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop -Force

Write-Host "Pulling Public Keys"
$publicKey = 'RootCert.public.cer'
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $baseName
Get-AzureStorageBlobContent -Context $storageAccount.Context -Container 'certs' -Blob $publicKey -Destination "./$publicKey" -Force | Out-Null
$certpubkey = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($(Resolve-Path "./$publicKey"))
$certBase64 = [system.convert]::ToBase64String($certpubkey.RawData)
Remove-Item –path "./$publicKey"

# Assemble the paths for the ARM Template files.
$templatePath =  Join-Path -Path $root './Templates/azuredeploy.json'
Write-Host "templatePath = $templatePath"
	
# Deploy the template
Write-Host "Deploying $deployName"
$deploy = New-AzureRMResourceGroupDeployment `
	-Name $deployName `
	-ResourceGroupName $resourceGroupName `
	-Mode 'Incremental' `
	-TemplateFile $templatePath `
	-baseName $baseName `
	-addressSpace $addressSpace.Substring(0, $addressSpace.LastIndexOf('.')) `
	-vmUser $user `
	-vmPassword $(ConvertTo-SecureString -String $password -Force -AsPlainText) `
	-vmCount $vmCount `
	-rootCert $certBase64 `
	-Verbose `
	-ErrorAction Stop `
	-Force

Write-Verbose "Verifying $deployName"
$verify = Get-AzureRmResourceGroupDeployment `
	-Name $deployName `
	-ResourceGroupName $resourceGroupName

if(($deploy.ProvisioningState -ne 'Succeeded') -or ($verify.ProvisioningState -ne 'Succeeded'))
{
	Write-Host "Deploy.DeploymentName = $deploy.DeploymentName"
	Write-Host "Verify.DeploymentName = $verify.DeploymentName"
	Write-Host "Deploy.ProvisioningState = $deploy.ProvisioningState"
	Write-Host "Verify.ProvisioningState = $verify.ProvisioningState"
	Write-Host "Deploy.Timestamp = $deploy.Timestamp"
	Write-Host "Verify.Timestamp = $verify.Timestamp"
	throw "$deployName Failed: $($deploy.ProvisioningState)/$($verify.ProvisioningState)"
}


Write-Host "Finished the PowerShell script: $($MyInvocation.MyCommand.Path)"