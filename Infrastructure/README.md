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
. ./Deploy-RootCert.ps1
# TODO: dont upload the root cert private key, upload the whole client cert
```
7. Deploy the hosting environment
```{posh}
. ./Deploy-Infrastructure.ps1
# TODO: Add script to automaticaly attach "disk 2" on initial create. Re-attaching works as expected
```
8. Setup the VPN client (If necessary)
```
. ./Deploy-VpnClient.ps1
# Unzip and install the software
```

---------
[p2scertimport]: https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps
[p2scerts]: https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site