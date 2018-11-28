# Enviormental Setup

Before you can do anything, there is some amount of prep work involved.

* Install [Docker][docker] desktop
    * You will need to setup a free account on [Docker][docker] to download the software
* Install [Python][python]
    * Install the non-core packages
```{cmd}
pip install applicationinsights
pip install azure-storage-blob
pip install azure-storage-queue
```
* Make your _primary_ [Azure][azure] resources
    * You will need to setup a trial account on [Azure][azure] to be able to do this. 
    * [Storage account][storage]
	    * Make a `todo` and a `done` [blob][blob] container in your [storage account][storage]
        * Make a `todo` and a `done` [queue][queue] in your [storage account][storage]
	* [Application Insights][appinsights]

	
# Worker

## Arrange

1. Open a command console
2. Change to the `./Worker` directory
3. Make sure there is a `secrets.ini`.
   The _xxx_ are replaced by the values found in your _primary_ [Azure][azure] resources
```{txt}
[AZURE]
iKey = xxx
AccountName = xxx
AccountKey = xxx
```

## Act

1. Place a file in the `todo` [blob][blob] container
2. Place a message containing the file name in the `todo` [queue][queue]
3. Run the worker
```{shell}
python worker.py
```

## Assert

1. There should be a new file in the `done` [blob][blob] container.
   The content should be "0--" then the content of the origional file
2. There should be a new message in the `done` [queue][queue] with the file name as the content
3. The worker should terminate automaticaly once the `todo` [queue][queue] is empty
4. The origional file should remain in the [blob][blob] container
5. After a 5-10 min delay, there should be some notices in the [Application Insights][appinsights] detailing the process

# Docker

## Arrange

1. Make sure the steps in **Worker** have been followed and can run sucessfuly
2. Open a command console
3. Change to the repo's root directory
    * When building a [Docker][docker] image, a 'context' is needed.
	  All files that you want to use need to be under it.
	  In this case, the `./Docker` and `./Worker` are siblings so make the 'context' their parent
	  (works as of [here](https://github.com/docker/cli/pull/886))
4. Make the [Docker][docker] Image / Container
    * Run `docker` to
	  `build` an image
	  while explicitly specifying the name of the image (`-t python-via-webhook`)
	  and the name of the docker file (`-f ./Docker/Dockerfile`)
	  with the context `.`
	* Run `docker` to
	  `create` a
	  named container (`--name my-python-via-webhook`)
	  from a know image (`python-via-webhook`)
	* Addtional notes can be found [here](./DockerNotes.md)
```{shell}
docker build -t python-via-webhook -f ./Docker/Dockerfile .
docker create --name my-python-via-webhook python-via-webhook
```

## Act

1. Place a file in the `todo` [blob][blob] container
2. Place a message containing the file name in the `todo` [queue][queue]
3. Run the [Docker][docker] Container
```{shell}
docker start my-python-via-webhook
```

## Assert

Same as for **Worker**

# Azure Host

## Arrange

1. Make sure the steps in **Docker** have been followed and can run sucessfuly
2. Open a Powershell console
3. Change to the repo's root directory
4. Login to [Azure][azure], specifying the name if necessary
```{posh}
Login-AzureRmAccount
Set-AzureRmContext -SubscriptionName "{{Subscription name}}"
```
5. Create a [resource group][arm]
    * `$location` needs be one of the regions that can host [Application Insights][appinsights].
	  Availability can be found [here](https://azure.microsoft.com/en-us/updates/?product=application-insights)
```{posh}
$resourceGroupName = "PythonViaWebhook"
$location = "South Central US"
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force
```
6. Deploy the [Azure resources][arm]
```{posh}
$deploy = New-AzureRMResourceGroupDeployment `
	-Name $("AzureHost-" + $(Get-Date -F 'yyyyMMddHHmmss')) `
	-ResourceGroupName $resourceGroupName `
	-Mode 'Incremental' `
	-TemplateFile './AzureHost/azuredeploy.json' `
	-Verbose
```
7. Add in the queues
    * They cannot be automaticaly setup by in the [ARM Template][arm] _yet_
```{posh}
$storageName = $deploy.Outputs['storageName'].Value
$storageKey = $deploy.Outputs['storageKey'].Value
$ctx = New-AzureStorageContext -StorageAccountName $storageName -StorageAccountKey $storageKey
New-AzureStorageQueue –Name 'todo' -Context $ctx | Out-Null
New-AzureStorageQueue –Name 'done' -Context $ctx | Out-Null
New-AzureStorageTable –Name 'status' -Context $ctx | Out-Null
```
8. Build the secrets file for the **Worker**
```{posh}
$ikey = $deploy.Outputs['appInsightsKey'].Value
$content = "[AZURE]
iKey = $ikey
AccountName = $storageName
AccountKey = $storageKey"
Set-Content -Path ./Worker/secrets.ini -Value $content
```

## Act

1. Post a sample file to the service
    * Putting in a value for callback in the header will cause the service to webhook to that url when the process is done.
```{shell}
$acceptRequestName = $deploy.Outputs['acceptRequestName'].Value
$acceptUrl = Get-AzureRmLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroupName -Name $acceptRequestName -TriggerName 'manual'
Set-Content -Path ./sample.txt -Value 'xxxxxxxx'
$response = Invoke-WebRequest -Uri $($acceptUrl.Value) -Method Post -InFile ./sample.txt -Headers @{ 'Callback-Url' = 'xxx' }
Remove-Item ./sample.txt
```

## Assert

1. Same as for **Docker**
2. The Response code should be 202.
   The body chould contain a key that is a GUID.
```{shell}
 $response.StatusCode
 $response.Content | ConvertFrom-Json
```












-----------
https://blogs.technet.microsoft.com/uktechnet/2018/04/04/run-your-python-script-on-demand-with-azure-container-instances-and-azure-logic-apps/


# Data Flow

As part of the initial setup, the service owner needs to provide the service user a URL and an access token.

1. The client makes a [multipart form post][multipart] (HTTP POST) to the [Webhook][webhook] URL; passing in an optional callback URL.
2. The [Webhook][webhook] writes the information to [blob storage][blob], places a message in the [queue][queue], and returns 202(accepted) with location where the result will eventualy be placed.
3. The [web aware][webaware] console app on the [VM][vm] monitors the [queue][queue].
    1. When a message is received, the file information is retrieved from [blob storage][blob] and copied localy to the [VM][vm].
	2. The origional console app is called via shell exec; passing in a file name corsponding to the data sent in the [multipart form post][multipart] as well as a location to place all data that should be sent back.
	3. The [web aware][webaware] console app logs the aproate things and writes the output file back to [blob storage][blob].
4. If applicable, the [Webhook][webhook] informs the client via the optional callback URL (HTTP GET) that processing is done.

[arm]: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview
[appinsights]: https://docs.microsoft.com/en-us/azure/application-insights/app-insights-overview
[azure]: https://azure.microsoft.com
[docker]: https://docs.docker.com/get-started/
[python]: https://docs.python.org/3/
[blob]: https://azure.microsoft.com/en-us/services/storage/blobs
[queue]: https://azure.microsoft.com/en-us/services/storage/queues/
[storage]: https://docs.microsoft.com/en-us/azure/storage/
[vm]: https://docs.microsoft.com/en-us/azure/virtual-machines/windows
[webaware]: https://en.oxforddictionaries.com/definition/web_aware
[webhook]: https://en.wikipedia.org/wiki/Webhook