# Azure Network Interface Module

This module is used to create and manage Azure Network Interfaces (NICs) and associate them with various resources, including load balancers, application gateways, and network security groups.

This module includes the following functionalities:

- Creating Network Interfaces (NICs) and associating them with various Azure resources.
- Configuring settings such as IPv4 and IPv6 addressing, security groups, and load balancer associations.

## Features

- Creating a network interface and associate it with backend pools of load balancers and application gateways.
- Attaching a network interface to an application security group.
- Managing the association of network security groups with a netwqork interface.
- Configuring both IPv4 and IPv6 addressing on a network interface for dual networking.
- Connecting a network interface to a load balancer rule.

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Add a network interface to an application gateway backend pool

This example demonstrates how to add a network interface to an Application Gateway backend pool.

```terraform
module "nic-app-gateway-backend-pool" {
  source = "Azure/avm-res-compute-network/azurerm"

  resource_group_name    = "myResourceGroup"
  location               = "East US"
  network_interface_name = "myNetworkInterface"

  ip_configurations = {
    "example" = {
      name                          = "internal"
      subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet/subnets/mySubnet"
      private_ip_address_allocation = "Dynamic"
    }
  }

  application_gateway_backend_address_pool_association = {
    application_gateway_backend_address_pool_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/applicationGateways/myAppGateway"
    ip_configuration_name                       = "internal"
  }
}
```

### Example - Associate a network interface to a network security group

This example demonstrates how to associate a network interface to an network security group.

```terraform
module "nic-app-gateway-backend-pool" {
  source = "Azure/avm-res-compute-network/azurerm"

  resource_group_name    = "myResourceGroup"
  location               = "East US"
  network_interface_name = "myNetworkInterface"

  ip_configurations = {
    "example" = {
      name                          = "internal"
      subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet/subnets/mySubnet"
      private_ip_address_allocation = "Dynamic"
    }
  }

  network_security_group_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/networkSecurityGroups/myNSG"]
}
```

### Example - Configure both IPv4 and IPv6 on a network interface for dual stack networking

This example demonstrates how to configure both IPv4 and IPv6 on a network interface for dual stack networking.

```terraform
module "nic-app-gateway-backend-pool" {
  source = "Azure/avm-res-compute-network/azurerm"

  resource_group_name    = "myResourceGroup"
  location               = "East US"
  network_interface_name = "myNetworkInterface"

  ip_configurations = {
    "dualstackIPv4config" = {
      name                          = "internal"
      subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet/subnets/myInternalSubnet"
      private_ip_address_allocation = "Dynamic"
      private_ip_address_version    = "IPv4"
      primary                       = true
    }
    "dualstackIPv6config" = {
      name                          = "external"
      subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet/subnets/myExternalSubnet"
      private_ip_address_allocation = "Dynamic"
      private_ip_address_version    = "IPv6"
    }
  }
}
```
