# Movation

I have a [Python](https://www.python.org) script with a _hefty_ up front initialization cost, but a _very_ low incremental cost.
I want to be able to surface the output of this script [cheaply and at scale](https://www.hanselman.com/blog/PennyPinchingInTheCloudDeployingContainersCheaplyToAzure.aspx) while maintaining source code confidentiality.
I also don't want to rewrite a lot.

# Parts

There are 3 parts to this project (listed below) that incrementally build on top of each other.
Deploy steps can be found [here](./Deploy.md).
They are aranged in [AAA](http://wiki.c2.com/?ArrangeActAssert) form for understanding and experimentation.

1. [Worker](./Worker)
2. [Docker](./Docker)
3. [Azure Host](./AzureHost)

