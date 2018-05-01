# Introduction
Creates a hosting environment for the Console App Via Webhook application

## Deploy via PowerShell
1. Build the Project in VS2017
2. Open Windows Power Shell
3. Change to Project directory
4. Setup the runtime environment
```{posh}
Login-AzureRmAccount
Set-AzureRmContext -SubscriptionName "My MSDN"
```
5. Decide on your settings
```{posh}
$resourceGroupName = "ConsoleAppViaWebhook"
$location = "SouthCentralUS"
$addressSpace = "10.0.0.0"
$baseName = 'cavw'
$user = $baseName
$password = $(new-guid).Guid;$password
$vmCount = 1
```
6. Generate Certs (If necessary)
```{posh}
$certPassword = $(new-guid).Guid;$certPassword
. ./Azure-CertDeploy.ps1
```
7. Deploy the hosting environment
```{posh}
. ./Azure-Deploy.ps1
```

TODO
	* Generate certs if necessary script
		* Make script to download script to generate new client cert
	* Add azure file storage
		* Add script to automaticaly attach azure files to VMs
	* Add script to automaticaly attach "disk 2" on initial create. Re-attaching works as expected



7. Generate the [certs][p2scerts] and [import][p2scertimport] into Azure
```{posh}
New-SelfSignedCertificate -Type Custom -DnsName "Azure P2S CAVW Child Cert" -KeySpec Signature `
	-Subject "CN=Azure P2S CAVW Child Cert" -KeyExportPolicy Exportable `
	-HashAlgorithm sha256 -KeyLength 2048 `
	-CertStoreLocation "Cert:\CurrentUser\My" `
	-Signer $cert -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.2')
```
8. Get the VPN client
```
$profile=New-AzureRmVpnClientConfiguration -ResourceGroupName $resourceGroupName -Name $virtualNetworkGatewayName -AuthenticationMethod "EapTls"
Invoke-WebRequest -Uri  $profile.VPNProfileSASUrl -OutFile './VPNClient.zip'
```
9. Unzip and install the software

---------
[p2scertimport]: https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps
[p2scerts]: https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site