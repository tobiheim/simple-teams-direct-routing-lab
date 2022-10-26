# simple-teams-direct-routing-lab

| [About The Project](#about-the-project) | [Usage](#usage) | [Prerequisites](#prerequisites) | [Deployment](#deployment) | 
| ---- | ---- | ---- | ---- |

Learn how to configure Microsoft Teams Direct Routing. This project provides a simple way to configure a SBC in Azure using Terraform to spend less time on installing required components and focus more on the actual Microsoft Teams configuration.

The official Microsoft documentation about the Microsoft Teams Direct Routing can be found here:  
[Plan Direct Routing](https://learn.microsoft.com/en-us/microsoftteams/direct-routing-plan)

> :warning: This **example** should be used to familiarize with all the configuration requirements of Microsoft Teams Direct Routing. This scenario **does not** represent a real-life configuration that you would see in an enterprise environment but includes everything to practice a Microsoft Teams Direct Routing configuration.

## Table of Contents

- [simple-teams-direct-routing-lab](#simple-teams-direct-routing-lab)
  - [Table of Contents](#table-of-contents)
  - [About The Project](#about-the-project)
    - [Built With](#built-with)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Deployment](#deployment)
      - [1. Clone the repo or download the files directly](#1-clone-the-repo-or-download-the-files-directly)
      - [2. Get Tenant & subscription id](#2-get-tenant--subscription-id)
      - [3. Create the Terraform variables file (terraform.tfvars)](#3-create-the-terraform-variables-file-terraformtfvars)
      - [4. Run the deployment script](#4-run-the-deployment-script)
      - [5. Upload the INI file to the SBC](#5-upload-the-ini-file-to-the-sbc)
      - [6. Upload your Public Certificate to the SBC](#6-upload-your-public-certificate-to-the-sbc)
      - [7. Verify & update the Network Security Group of the SBC in Azure](#7-verify--update-the-network-security-group-of-the-sbc-in-azure)
      - [8. Create DNS-Records for SBC](#8-create-dns-records-for-sbc)
      - [9. Configure the Admin-Host](#9-configure-the-admin-host)
      - [10. 📞 Configure the generic SIP-Client](#10--configure-the-generic-sip-client)
      - [11. Configure Microsoft Teams Direct Routing](#11-configure-microsoft-teams-direct-routing)
      - [12. Start Testing](#12-start-testing)
  - [Usage](#usage)
  - [🔭 Roadmap](#-roadmap)
  - [Contributing](#contributing)
  - [License](#license)


## About The Project

This project provides an example deployment how to build a Microsoft Teams Direct Routing Lab.

The lab includes an Audiocodes VE SBC to connect to Microsoft Teams and is also used as Registrar to simulate a PBX connection (3CX Phone Soft-Client).
The idea of this lab is to familiarize with the configuration of Direct Routing and also to learn how to troubleshoot the SIP-Stack in case of an problem.

### Built With

* Terraform
* PowerShell

## Getting Started

To get a copy up and running make sure to meet the requirements and follow the steps below.
This project should help to gain knowledge how to build Microsoft Teams Direct Routing 🚀.

### Prerequisites

The solution requires an Office 365 and Azure subscription including the following:

- Office 365 Demo Tenant
  - Registered Custom Domain (Personal owned Domain)
  - Configured [Office 365 DNS-Records](https://learn.microsoft.com/en-us/microsoft-365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider?view=o365-worldwide) for the Custom Domain
  - Ability to request a [Public Trusted Certificate](https://learn.microsoft.com/en-us/microsoftteams/direct-routing-plan#public-trusted-certificate-for-the-sbc) (supported my Office 365)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli#install)
- [Azure Subscription](https://azure.microsoft.com/en-us/free/) (Not required to be linked to the O365 Demo Tenant)
- PowerShell

### Deployment

#### 1. Clone the repo or download the files directly

Clone the repo:

```sh
git clone https://github.com/tobiheim/mw-core-lab-phone.git
```

#### 2. Get Tenant & subscription id

After you installed the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli#install), you can use the following cmdlet to connect against Azure.

```powershell
az login
```

Now you check your available subscriptions by using the following cmdlet:

```powershell
az account show
```

The result include all your subscriptions. Select the one you would like to use for the lab deployment.


```json
{
  "cloudName": "ContosoCloud",
  "homeTenantId": "3a7287a7-aebc-4ebd-a2e1-de183bd23f26",
  "id": "c9c67f9a-54a2-4dd8-bd7c-f6f699fda103",
  "isDefault": true,
  "managedByTenants": [],
  "name": "Microsoft Azure Contoso Lab",
  "state": "Enabled",
  "tenantId": "57e10107-9236-40e3-bc0e-9792852f4fc1",
  "user": {
    "name": "john.doe@contoso.com",
    "type": "user"
  }
}
```

|Output Value    |Description |
|---------|---------|
|"id":     | This is the id of your Subscription      |
|"tenantId":    | This is the id of your Tenant        |

Take a note of both id's, you will need them in the next step.


#### 3. Create the Terraform variables file (terraform.tfvars)

After you cloned the repo you need to create a Terraform variables file in the **Terraform folder**.
This file will allow you to customize the resources that you will deploy in Azure based on your needs.

Filename: **terraform.tfvars**

```
subscription_id = "<Your subscription id (e.g. 3a7287a7-aebc-4ebd-a2e1-de183bd23f26)>"
tenant_id = "<Your tenant id (e.g. 57e10107-9236-40e3-bc0e-9792852f4fc1)>"
location = "westeurope"
resource_group_name = "rg-learn-voice"
sbc_vm_name = "sbc01"
sbc_vm_size = "Standard_DS1_v2"
admin_host_name = "admin-host"
admin_host_vm_size = "Standard_DS1_v2"
```
Update the values with your Subscription & Tenant id in the terraform.tfvars file.
**Note:** The Names of the SBC and Admin Host can not be longer then 15 characters.

👨🏽‍💻 Make sure to check if the selected VM-Size is available in your region. You can review the different available sizes by using the Azure Cli:

`az vm list-skus --location westeurope -o table --query "[].[name, locations[0], restrictions]"`


#### 4. Run the deployment script

**Note:** The PowerShell script will install all prerequisites such as:
- [Chocolatey](https://chocolatey.org/) (To automatically install Terraform)
- [Terraform](https://www.terraform.io/)

Now you are ready to run the PowerShell Script `Deploy-TeamsDirectRoutingLab.ps1` to start the deployment.

|Parameter|Description  |
|---------|---------|
|SbcFQDN  |The FQDN of your SBC. Keep in mind the Domain name need to be owned by you to issue a certificate and to register a DNS-Record to allow Microsoft Teams to connect to it.         |

**PS-Example (Run the script as Administrator in PowerShell):**

```powershell
./Deploy-TeamsDirectRoutingLab.ps1 -SbcFQDN "sbc01.contoso.com"
```

 👉 Make sure that the used Domain is registered in your M365 tenant. You can learn more here:
[Add a domain to Microsoft 365](https://learn.microsoft.com/en-gb/microsoft-365/admin/setup/add-domain?redirectSourcePath=%252fen-us%252farticle%252fAdd-a-domain-to-Office-365-6383f56d-3d09-4dcb-9b41-b5f5a5efd611&view=o365-worldwide)

✏️ Please take a note of the provided IP's and Credentials.

After the SBC & Admin-Host is deployed successfully you can use the provided details to connect to both of them.

![Ps Output](https://www.tnext-labs.com/GitHub/voice-lab/ps-output_4.png)

#### 5. Upload the INI file to the SBC

The script will automatically create a configuration file for the Session Border Controller including the required environment variables in the script root folder.

![ini file](https://www.tnext-labs.com/GitHub/voice-lab/ini-file.png)

Login to the SBC by using the IP and credentials provided in the PowerShell output.

![sbc login](https://www.tnext-labs.com/GitHub/voice-lab/ac-login.png)

Now upload your **your-lab-sbc.ini** to configure the SBC as **Auxiliary** file.

![upload ini 1](https://www.tnext-labs.com/GitHub/voice-lab/upload-ini-01.png)

![upload ini 2](https://www.tnext-labs.com/GitHub/voice-lab/upload-ini-02.png)


After the incremental configuration file was uploaded successfully, you need to click on `Save` and then on `Reset`. 

![Save SBC](https://www.tnext-labs.com/GitHub/voice-lab/save_sbc.png)

![Reset SBC](https://www.tnext-labs.com/GitHub/voice-lab/reset_sbc.png)

The SBC will now restart. This may take some time. 🕔

#### 6. Upload your Public Certificate to the SBC

After the successfully restarted, you can upload to certificate to the device.
Make sure that the certificate is supported by Microsoft Teams. You can learn more here:
[Public trusted certificate for the SBC](https://learn.microsoft.com/en-us/microsoftteams/direct-routing-plan#public-trusted-certificate-for-the-sbc)

Go to **IP NETWORK**

![ip network](https://www.tnext-labs.com/GitHub/voice-lab/sbc-ipn.png)

Then to **SECURITY** and **TLS Contexts**

![cert 1](https://www.tnext-labs.com/GitHub/voice-lab/sbc-cert-1.png)

Select **Change Certificate >>**

![cert 2](https://www.tnext-labs.com/GitHub/voice-lab/sbc-cert-2.png)

Scroll down to the following section and enter the password for your certificate and upload the certificate file (*.pfx).

![cert 3](https://www.tnext-labs.com/GitHub/voice-lab/sbc-cert-3.png)

Don't forget to save (in the top blue bar) to permanently store your configuration change.

That's all on the SBC! 👏  
*(At least the required steps)*

#### 7. Verify & update the Network Security Group of the SBC in Azure

Ensure that the Firewall Rules (inbound and outbound) are configure as shown in the following screenshot below:

![NSG Rules](https://www.tnext-labs.com/GitHub/voice-lab/NSG_SBC_2.png)

It might be that you have NSG rules applied that are preventing the automated creation of the required rules.
In this case you have to create the rules manually.

#### 8. Create DNS-Records for SBC

👨🏽‍💻 Now create the DNS-Record for your SBC with the Public IP Address provided by the script at your DNS Provider.
Make sure the record can be resolved:

**Example:**

`nslookup sbc01.contoso.com`

Now you can verify the access to the SBC via HTTPS using the FQDN of the SBC in your browser.

❌ If the connect was successful, you can safely delete the **TCP/80 (HTTP)** inbound rule on the Azure Network Security Group of the SBC VM. After that you are only able to connect to the SBC via HTTPS/ the FQDN.

![NSG Rules](https://www.tnext-labs.com/GitHub/voice-lab/NSG_SBC_80_1.png)

#### 9. Configure the Admin-Host

Now let's connect to the Admin-Host to configure Syslog to allow you to troubleshoot and understand the SIP-Stack Routing between Microsoft Teams and the SBC.

To do so, use the RDP Client of your choice and connect to the IP provided in the PowerShell output.  

After you successfully connected and signed-in to the Admin-Host, you can copy the PowerShell script **Install-Admin-HostSoftware.ps1** in the folder **Client Configuration** to the VM.

The script will ensure the following:
- Install Chocolatey to install Microsoft Teams and VsCode
- Enable the Telnet Client Windows Feature
- Download and install the [Audiocodes Syslog Viewer](http://redirect.audiocodes.com/install/index.html)
- Download and install the [Soft-Client 3CX Phone 6](https://downloads.3cx.com/downloads/)

Start the PS as Administrator and run it:

```powershell
./Install-Admin-HostSoftware.ps1
```

After a successful run you should see the following output:

![client prep](https://www.tnext-labs.com/GitHub/voice-lab/client-prep_2.png)

After the script finished you will notice that the Syslog Viewer is already receiving SIP messages from the SBC.

#### 10. 📞 Configure the generic SIP-Client

The SBC is configured to act also as registrar to allow generic SIP-Clients to register against it to simulate a PBX/ PSTN user the Microsoft Teams Direct Routing scenario.

After the script installed the client, you can configure a account profile as shown in the image below:

![sip client](https://www.tnext-labs.com/GitHub/voice-lab/sip-client_2.png)

You can use numbers from the following fictional number plan:

|Number Range |Description  |
|---------|---------|
|+1 719 555 0100-0149     |  Fictional number range in U.S. Colorado. Only numbers in within this range will be routed as source to Microsoft Teams.     |

**Note:** The SBC doesn't require Authentication to simplify the process.

#### 11. Configure Microsoft Teams Direct Routing

To configure Direct Routing, follow the steps in the official Microsoft documentation:  
 📚 [Configure Direct Routing](https://learn.microsoft.com/en-us/MicrosoftTeams/direct-routing-configure)

**Note:** Do not configure Media Bypass or Local Media Optimization for your SBC. 

You can use numbers from the following fictional number plan:

|Number Range |Description  |
|---------|---------|
|+1 719 555 0150-0199     |  Fictional number range in U.S. Colorado.       |

 **Note:** Make sure to configure a valid E.164 number for your demo users.

#### 12. Start Testing

If you configured everything correctly, you should be able to call the SIP-Client from a Teams users and the other way around. 

![test-call](https://www.tnext-labs.com/GitHub/voice-lab/test-call_2.png)

You can always use the Syslog Viewer on your Admin-Host to better understand the routing and troubleshoot problems in case of an miss-configured setup.

I hope you will enjoy your learning experience using this setup.   

**☎️ Happy testing!**

## Usage

The idea of this project is to learn and explore how to configure Microsoft Teams Direct Routing without the need to spend a lot of time to configure a session border controller. 🤙

## 🔭 Roadmap 

The following items are considered as Roadmap for this repo:

- LMO (Local Media Optimization)
- Failover Routing
- Teams SBA


## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.