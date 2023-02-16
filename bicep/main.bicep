// Setting target scope
targetScope= 'subscription'

param location string

param creator string = 'f13233'
param creationDate string = utcNow('YY-mm-ddTHH:mm:ss')

var tags = {
  creator: creator
  created: creationDate
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
      name: 'demo-vnet'
      location: location
      addressPrefixes: [
        {
          addressPrefix: '10.0.0.0/16'
        }
      ]
      subnets: [
        {
          name: 'demo-db-subnet'
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
    vaultName: 'demo-kv'    
    location: location
    tags: tags
  }
}


module db  './modules/db.bicep' = {
  name: 'database'
  scope: resourceGroup
  params: {
    dbName: 'demo-mssql-db'
    serverName:'demo-mssql-server'
    location: location
    tags: tags
  }
}

