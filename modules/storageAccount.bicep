@description('The naming prefix of the storage account.')
param namingPrefix string = uniqueString(resourceGroup().id)

module stg 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'stg'
  params: {
    name: uniqueString(resourceGroup().id,namingPrefix)
    location: resourceGroup().location
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
  }
}