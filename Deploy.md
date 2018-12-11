# Enviormental Setup

Before you can do anything, there is some amount of prep work involved.

* Install [Docker][docker] desktop
    * You will need to setup a free account on [Docker][docker] to download the software
* Install [Python](https://docs.python.org/3/)
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
	
# Deploy Worker

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

## Validate Worker

1. Place a file in the `todo` [blob][blob] container
2. Place a message containing the file name in the `todo` [queue][queue]
3. Run the worker
```{shell}
python worker.py
```
4. There should be a new file in the `done` [blob][blob] container.
   The content should be "0--" then the content of the origional file
5. There should be a new message in the `done` [queue][queue] with the file name as the content
6. The worker should terminate automaticaly once the `todo` [queue][queue] is empty
7. The origional file should remain in the [blob][blob] container
8. After a 5-10 min delay, there should be some notices in [Application Insights][appinsights] detailing the process

# Deploy Docker (localy)

1. Open a command console
2. Change to the repo's root directory
    * When building a [Docker][docker] image, a 'context' is needed.
	  All files that you want to use need to be under it.
	  In this case, the `./Docker` and `./Worker` are siblings so make the 'context' their parent
	  (works as of [here](https://github.com/docker/cli/pull/886))
3. Make the [Docker][docker] Image / Container
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

## Validate Docker

1. Make sure the [Docker][docker] image and container were created
```{shell}
docker images -a
docker ps -a
```
2. Run the [Docker][docker] Container.
   It should startup then exit a moment later.
   If there are still messages in the [queue][queue] from testing the **Worker**, they will be processed.
   Multipul starts should keep the same container
```{shell}
docker start my-python-via-webhook
docker ps -a
```
3. After a 5-10 min delay, there should be some notices in [Application Insights][appinsights] detailing the process

# Deploy Azure Host

1. Open a Powershell console
2. Change to the repo's root directory
3. Login to [Azure][azure], specifying the name if necessary
```{posh}
Login-AzureRmAccount
Set-AzureRmContext -SubscriptionName "{{Subscription name}}"
```
4. Create a [resource group][arm]
    * `$location` needs be one of the regions that can host [Application Insights][appinsights].
	  Availability can be found [here](https://azure.microsoft.com/en-us/updates/?product=application-insights)
```{posh}
$resourceGroupName = "PythonViaWebhook"
$location = "South Central US"
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force
```
5. Deploy the [Azure resources][arm]
```{posh}
$deploy = New-AzureRMResourceGroupDeployment `
	-Name $("AzureHost-" + $(Get-Date -F 'yyyyMMddHHmmss')) `
	-ResourceGroupName $resourceGroupName `
	-Mode 'Incremental' `
	-TemplateFile './AzureHost/azuredeploy.json' `
	-Verbose
```
6. Add in the queues/table
    * They cannot be automaticaly setup by in the [ARM Template][arm] _yet_
```{posh}
$storageName = $deploy.Outputs['storageName'].Value
$storageKey = $deploy.Outputs['storageKey'].Value
$ctx = New-AzureStorageContext -StorageAccountName $storageName -StorageAccountKey $storageKey
New-AzureStorageQueue –Name 'todo' -Context $ctx | Out-Null
New-AzureStorageQueue –Name 'done' -Context $ctx | Out-Null
New-AzureStorageTable –Name 'status' -Context $ctx | Out-Null
```
7. Build the secrets file for the **Worker**
```{posh}
$ikey = $deploy.Outputs['appInsightsKey'].Value
$content = "[AZURE]
iKey = $ikey
AccountName = $storageName
AccountKey = $storageKey"
Set-Content -Path ./Worker/secrets.ini -Value $content
```
8. Build the [Docker][docker] image
```{posh}
$imageName = $deploy.Outputs['imageName'].Value
docker build -t $imageName -f ./Docker/Dockerfile .
```
9. Send the [Docker][docker] image to [Azure][azure]
   * This login process is the [recomended](https://docs.docker.com/engine/reference/commandline/login/#parent-command) method
```{posh}
$registryName = $deploy.Outputs['registryName'].Value
$registryHost = "$registryName.azurecr.io"
Set-Content -Path ./login.secrets -Value $($deploy.Outputs['registryKey'].Value)
cat ./login.secrets | docker login $registryHost -u $registryName --password-stdin
Remove-Item ./login.secrets
docker tag $imageName "$registryHost/$imageName"
docker push "$registryHost/$imageName"
```

## Validate Azure Host

1. Check the [Azure Portal](https://portal.azure.com).
   * The resource group should contain 10 items.
   * The container registery should contain the `python-via-webhook` repositery


[arm]: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview
[appinsights]: https://docs.microsoft.com/en-us/azure/application-insights/app-insights-overview
[azure]: https://azure.microsoft.com
[docker]: https://docs.docker.com/get-started/
[blob]: https://azure.microsoft.com/en-us/services/storage/blobs
[queue]: https://azure.microsoft.com/en-us/services/storage/queues/
[storage]: https://docs.microsoft.com/en-us/azure/storage/
