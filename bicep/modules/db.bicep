@description('The name of the SQL logical server.')
param serverName string = uniqueString('sql', resourceGroup().id)

@description('The name of the SQL Database.')
param dbName string

@description('Location for database resources.')
param location string = resourceGroup().location

param administratorLogin string = newGuid()

@secure()
param administratorLoginPassword string = newGuid()

param tags object

resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
  tags: tags
}

resource sqlDB 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: dbName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  tags: tags
}
