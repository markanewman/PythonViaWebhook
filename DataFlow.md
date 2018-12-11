# Data Flow

As part of the initial setup, the service owner needs to provide the service user a URL and an access token.

1. The client makes a HTTP POST to the [Webhook][webhook] URL
   * An optional callback URL is supported via a header value (CallbackUrl)
2. The [Webhook][webhook] writes the information to [blob storage][blob], places a message in the [queue][queue], and returns 202(accepted) with location where the result will eventualy be placed.
3. A [Docker](https://docs.docker.com/get-started/) container is started and processing begins
    1. The file information is retrieved from [blob storage][blob] and copied localy to the container.
	2. A worker process calls the origional [Python](https://docs.python.org/3/) app via its well-known interface
	   * `init()` and `execute()`
	   * The initalized state and corsponding file data is sent in the application as well as a location to place all data that should be sent back to the caller
	   * Once the request is processed, the worker places a message in the [queue][queue] and continues processing more files, or terminates if there is nothing more to doleft.
4. The [Webhook][webhook] logs the aproate things.
5. If applicable, the [Webhook][webhook] informs the client via the optional callback URL (HTTP GET) that processing is done.

# Data Endpoints

There are two (2) data endpoints (listed below).
It is assumed that the Azure Host has already been deployed (instructions [here][deploy]) before testing can begin

1. Submit the request
2. Get the request status

## Testing the 'Submit the request' data flow

### Arange

1. Get all the necessary keys.
   They can be found in the [Azure Portal](https://portal.azure.com).
   If the same Powershell window is used for both the [**Deploy Azure Host**][deploy] and this integration testing, the keys will be already available in the session as below
```{posh}
$resourceGroupName = $resourceGroupName
$acceptRequestName = $deploy.Outputs['acceptRequestName'].Value
```

### Act

1. **Post** a sample file to the service.
   Adding a header value ('CallbackUrl') allows the service to webhook to that url when the process is done.
   Add `-Headers @{ 'CallbackUrl' = 'https://my.fqdn.com' }` to the `Invoke-WebRequest` to acomplish this
```{posh}
$acceptUrl = Get-AzureRmLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroupName -Name $acceptRequestName -TriggerName 'manual'
Set-Content -Path ./sample.txt -Value 'xxxxxxxx'
$response = Invoke-WebRequest -Uri $($acceptUrl.Value) -Method Post -InFile ./sample.txt
Remove-Item ./sample.txt
```

### Assert

1. The Response code should be 202.
   The body chould contain a URL to the status page.
```{shell}
 $response.StatusCode
 $response.Content | ConvertFrom-Json
```

## Testing the 'Get the request status' data flow

### Arange

1. Get the status URL.
   It can be found in the [Azure Portal][portal].
   If the same Powershell window is used for both **Testing the 'Submit the request' data flow** and **Testing the 'Get the request status' data flow**, the keys will be already available in the session as below
```{posh}
$statusUrl = ($response.Content | ConvertFrom-Json).statusUrl
```

### Act
1. Wait for a while.
   This is important because there is a built in delay in the sample work (1 min) **AND** in the starting of new containers (5 min)
   * The sample work deplay is to make the processing more realistic
   * The container creation delay is to reduce operation cost
   * For the impaintant, The status of these processes can be checked in the [Azure Portal][portal] 
2. Check the status
```{shell}
$response = Invoke-WebRequest -Uri $statusUrl -Method Get
```
### Assert

1. The Response code should be 200/202.
   * If the response is 200, the content will be the processed file data
   * If the response is 202, wait a little while and re-check
```{shell}
 $response.StatusCode
 Set-Content -Path ./result.txt -Value $($response.Content)
```

[blob]: https://azure.microsoft.com/en-us/services/storage/blobs
[deploy]: ./Deploy.md
[portal]: https://portal.azure.com
[queue]: https://azure.microsoft.com/en-us/services/storage/queues/
[storage]: https://docs.microsoft.com/en-us/azure/storage/
[webhook]: https://en.wikipedia.org/wiki/Webhook



https://blogs.technet.microsoft.com/uktechnet/2018/04/04/run-your-python-script-on-demand-with-azure-container-instances-and-azure-logic-apps/