
@description('The name of the KeyVault')
param vaultName string

@description('The location of the KeyVault')
param location string = resourceGroup().location

param tags object

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    enableSoftDelete: false    
    sku:{
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
  }
}
