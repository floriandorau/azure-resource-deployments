
@description('Name of the KeyVault')
param vaultName string

@description('Location of the KeyVault')
param location string = resourceGroup().location

param tags object

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    enableSoftDelete: false 
    enablePurgeProtection: false   
    enabledForDiskEncryption: true 
    sku:{
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
  }
}
