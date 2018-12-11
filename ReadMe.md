# Movation

I have a [Python](https://www.python.org) script with a _hefty_ up front initialization cost, but a _very_ low incremental cost.
I want to be able to surface the output of this script [cheaply and at scale](https://www.hanselman.com/blog/PennyPinchingInTheCloudDeployingContainersCheaplyToAzure.aspx) while maintaining source code confidentiality.
I also don't want to rewrite a lot.

# Parts

There are three (3) parts to this project (listed below) that incrementally build on top of each other.
Deploy steps can be found [here](./Deploy.md).
An explination of the [data flow](./DataFlow.md) is also provided.
Tests of the data flow are aranged in [AAA](http://wiki.c2.com/?ArrangeActAssert) form for understanding and experimentation.

1. [Worker](./Worker)
2. [Docker](./Docker)
3. [Azure Host](./AzureHost)

# External links

Below is a partial list of the sources used in constructing this work.
Some resources were complete, some not so much, but they all helped in their own way.

* [Run your Python script on demand with Azure Container Instances and Azure Logic Apps](https://blogs.technet.microsoft.com/uktechnet/2018/04/04/run-your-python-script-on-demand-with-azure-container-instances-and-azure-logic-apps/)
* [Serverless^2 - Azure Logic Apps and Azure Container Instances](https://lnx.azurewebsites.net/serverless-2-azure-logic-apps-and-azure-container-instances/)
* [Azure Resource Manager template functions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions)
* [Deploy Logic Apps & API Connection with ARM](https://www.bruttin.com/2017/06/13/deploy-logic-app-with-arm.html)
* [Azure Container Instance (Preview)](https://docs.microsoft.com/en-us/connectors/aci/)
* [LogicAppConnectionAuth](https://github.com/logicappsio/LogicAppConnectionAuth)