// Setting target scope
targetScope= 'subscription'

param location string

param creator string = 'f13233'
param creationDate string = utcNow('YY-mm-ddTHH:mm:ss')

var tags = {
  creator: creator
  created: creationDate
  deployed: 'bicep'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'az-deploy-demo-bicep-rg'
  location: location
}

module vnet  './modules/vnet.bicep' = {
  name: 'vNet'
  scope: resourceGroup
  params: {
    vNetSettings: {
      name: 'az-bicep-vnet'
      location: location
      addressPrefixes: [
        {
          addressPrefix: '10.0.0.0/16'
        }
      ]
      subnets: [
        {
          name: 'az-bicep-db-subnet'
          addressPrefix: '10.0.0.0/24'
        }
      ]
    }  
    tags: tags
  }
}

module kv  './modules/kv.bicep' = {
  name: 'keyVault'
  scope: resourceGroup
  params: {
    vaultName: 'az-bicep-kv'    
    location: location
    tags: tags
  }
}

module db  './modules/db.bicep' = {
  name: 'database'
  scope: resourceGroup
  params: {
    dbName: 'az-bicep-sql-db'
    serverName:'az-bicep-sql-server'
    location: location
    tags: tags
  }
}

module webApp './modules/webapp.bicep' = {
  name: 'webApp'
  scope:resourceGroup
  params: {
    webAppName: 'az-bicep-webapp'
    sku: 'F1'
    location:location
    tags: tags
  }
}
