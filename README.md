# Movation

This repo was started because I wanted to be able to run a console app for which I do not have the code into a web service. The application at hand was devoloped by a gentalman whose talents lie in acedemic research not in web technologies. I wanted to empower him to share his works in a more modern way.

# Architecture

1. A [Virtual Machine][vm] (VM) that will allow the console app to remain unchanged. This is a real advantage as devolopment tools, custom file locations, and other ["It works on my machine"][works] settings can be applied.
2. A [Virtual Network][vnet] (VNET) to provide simple security.
3. An [Azure Function][func] to serve as the [Webhook][webhook] frontend. It will accept files to be processed and a URL callback. There will also be a status endpoint in case polling is more your thing.
4. A console app that is [web aware][webaware] to bridge the gap between old and new.
5. An [Azure Storage][storage] account to tie everything together.

# Data Flow

As part of the initial setup, the service owner needs to provide the service user a URL and an access token.

1. The client makes a [multipart form post][multipart] (HTTP POST) to the [Webhook][webhook] URL; passing in an optional callback URL.
2. The [Webhook][webhook] writes the information to [blob storage][blob], places a message in the [queue][queue], and returns 202(accepted) with location where the result will eventualy be placed.
3. The [web aware][webaware] console app on the [VM][vm] monitors the [queue][queue].
    1. When a message is received, the file information is retrieved from [blob storage][blob] and copied localy to the [VM][vm].
	2. The origional console app is called via shell exec; passing in a file name corsponding to the data sent in the [multipart form post][multipart] as well as a location to place all data that should be sent back.
	3. The [web aware][webaware] console app logs the aproate things and writes the output file back to [blob storage][blob].
4. If applicable, the [Webhook][webhook] informs the client via the optional callback URL (HTTP GET) that processing is done.



---------

[blob]: https://azure.microsoft.com/en-us/services/storage/blobs
[func]: https://azure.microsoft.com/en-us/services/functions
[multipart]: https://stackoverflow.com/questions/16958448/what-is-http-multipart-request
[queue]: https://azure.microsoft.com/en-us/services/storage/queues/
[storage]: https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction
[vm]: https://docs.microsoft.com/en-us/azure/virtual-machines/windows
[vnet]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
[webaware]: https://en.oxforddictionaries.com/definition/web_aware
[webhook]: https://en.wikipedia.org/wiki/Webhook
[works]: https://www.leadingagile.com/2017/03/works-on-my-machine