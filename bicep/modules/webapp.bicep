@description('Base name of the resource such as web app name and app service plan ')
@minLength(2)
param webAppName string

@description('The SKU of App Service Plan')
param sku string = 'S1'

@description('Flag if WebApp should be enabled')
param enabled bool = true

@description('Location for all resources.')
param location string = resourceGroup().location

param tags object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${webAppName}-appserviceplan'
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: tags
}

resource webAppPortal 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    enabled: enabled
    httpsOnly: true
    siteConfig: {    
      alwaysOn: false  
      linuxFxVersion: 'NODE|14-LTS'
    }
   
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}
