--- list/remove an image --

docker images -a
docker rmi {{Image ID}}

--- make a new image --- 

cd "C:\Users\mnewman\Desktop\Docker"
docker build -t my-python-console ./console
docker build -t my-python-app ./app

--- list/stop/remove a container---

docker ps -a
docker kill {{Container ID}}
docker rm {{Container ID}}

--- shell into a container ---

docker run -it python:3
docker run -it my-python-console
docker run -it my-python-app

docker start {{Container ID}}


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


[azure]: https://azure.microsoft.com
[blob]: https://azure.microsoft.com/en-us/services/storage/blobs
[multipart]: https://stackoverflow.com/questions/16958448/what-is-http-multipart-request
[python]: 
[queue]: https://azure.microsoft.com/en-us/services/storage/queues/
[storage]: https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction
[vm]: https://docs.microsoft.com/en-us/azure/virtual-machines/windows
[webaware]: https://en.oxforddictionaries.com/definition/web_aware
[webhook]: https://en.wikipedia.org/wiki/Webhook