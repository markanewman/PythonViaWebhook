# Architecture

1. A [Virtual Machine][vm] (VM) that will allow the console app to remain unchanged. This is a real advantage as devolopment tools, custom file locations, and other ["It works on my machine"][works] settings can be applied.
2. A [Virtual Network][vnet] (VNET) to provide simple security.
3. An [Azure Function][func] to serve as the [Webhook][webhook] frontend. It will accept files to be processed and a URL callback. There will also be a status endpoint in case polling is more your thing.
4. A console app that is [web aware][webaware] to bridge the gap between old and new.
5. An [Azure Storage][storage] account to tie everything together.



[func]: https://azure.microsoft.com/en-us/services/functions
[storage]: https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction
[vm]: https://docs.microsoft.com/en-us/azure/virtual-machines/windows
[vnet]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
[webaware]: https://en.oxforddictionaries.com/definition/web_aware
[webhook]: https://en.wikipedia.org/wiki/Webhook
