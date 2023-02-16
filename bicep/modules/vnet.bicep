param vNetSettings object = {
  name: 'VNet1'
  location: resourceGroup().location
  addressPrefixes: [
    {
      addressPrefix: '10.0.0.0/16'
    }
  ]
  subnets: [
    {
      name: 'firstSubnet'
      addressPrefix: '10.0.0.0/24'
    }
  ]
}

param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vNetSettings.name
  location: vNetSettings.location
  properties: {
    addressSpace: {
      addressPrefixes: [for prefix in vNetSettings.addressPrefixes: prefix.addressPrefix]
    }
    subnets: [for subnet in vNetSettings.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
  tags: tags
}
