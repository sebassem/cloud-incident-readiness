# Azure Bicep Deployment

This repository contains Bicep templates for deploying a virtual machine scale set (VMSS) with associated networking resources on Azure. The deployment includes a custom script to set up a web application on the VMSS instances.

## Repository Structure

```
main.bicep
modules/
    networking.bicep
    utilities.bicep
scripts/
    deploy-webapp.ps1
```

- main.bicep : The main Bicep file that orchestrates the deployment of all resources.
- networking.bicep : A module for deploying networking resources such as virtual networks, NAT gateways, network security groups (NSGs), and load balancers.
- utilities.bicep: A module for deploying utility resources and role assignments.
- deploy-webapp.ps1: A PowerShell script to set up a web application on the VMSS instances.

## Deployment Overview

### `main.bicep`

The `main.bicep` file defines the overall deployment, including parameters for the virtual machine admin credentials and location. It deploys the following resources:

- **Networking Resources**: Defined in the `networking.bicep` module.
- **Virtual Machine Scale Set (VMSS)**: Configured with a custom script extension to deploy a web application.
- **Utility Resources**: Defined in the `utilities.bicep` module.

### `networking.bicep`

This module deploys the following networking resources:

- Virtual Network (VNet)
- NAT Gateway
- Network Security Group (NSG)
- Load Balancer (LB)

### `utilities.bicep`

This module deploys utility resources and assigns roles to the managed identity used by the deployment script. It includes:

- Managed Identity
- Role Assignments for VMSS, VNet, LB, and NSG
- Deployment Script to update VMSS instances

### `deploy-webapp.ps1`

This PowerShell script sets up a web application on the VMSS instances. It installs the IIS web server and creates a simple HTML page displaying the instance's hostname and zone.

## Parameters

The `main.bicep` file accepts the following parameters:

- `adminUsername`: The admin username for the virtual machines.
- `adminPassword`: The admin password for the virtual machines.
- `location`: The location for all resources.
- `virtualNetworkName`: The name of the virtual network.
- `virtualNetworkAddressPrefix`: The address prefix for the virtual network.

## Outputs

The `main.bicep` file outputs the following:

- `frontendIpAddress`: The public IP address of the load balancer.

## Deployment

To deploy the resources, use the following Azure CLI command:

```sh
az deployment group create --resource-group <resource-group-name> --template-file main.bicep
```

Replace `<resource-group-name>` with the name of your Azure resource group.