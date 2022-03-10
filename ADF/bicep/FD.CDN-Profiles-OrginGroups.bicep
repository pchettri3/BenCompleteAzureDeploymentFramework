param Deployment string
param DeploymentURI string
param cdn object
param originGroup object
param Global object
param Prefix string
param Environment string
param DeploymentID string

var regionLookup = json(loadTextContent('./global/region.json'))
var primaryPrefix = regionLookup[Global.PrimaryLocation].prefix

var GlobalRGJ = json(Global.GlobalRG)
// var HubKVJ = json(Global.hubKV)
// var HubRGJ = json(Global.hubRG)

var gh = {
  globalRGPrefix: contains(GlobalRGJ, 'Prefix') ? GlobalRGJ.Prefix : primaryPrefix
  globalRGOrgName: contains(GlobalRGJ, 'OrgName') ? GlobalRGJ.OrgName : Global.OrgName
  globalRGAppName: contains(GlobalRGJ, 'AppName') ? GlobalRGJ.AppName : Global.AppName
  globalRGName: contains(GlobalRGJ, 'name') ? GlobalRGJ.name : '${Environment}${DeploymentID}'

  // hubKVPrefix: contains(HubKVJ, 'Prefix') ? HubKVJ.Prefix : Prefix
  // hubKVOrgName: contains(HubKVJ, 'OrgName') ? HubKVJ.OrgName : Global.OrgName
  // hubKVAppName: contains(HubKVJ, 'AppName') ? HubKVJ.AppName : Global.AppName
  // hubKVRGName: contains(HubKVJ, 'RG') ? HubKVJ.RG : HubRGJ.name
}

var globalRGName = '${gh.globalRGPrefix}-${gh.globalRGOrgName}-${gh.globalRGAppName}-RG-${gh.globalRGName}'
// var HubKVRGName = '${gh.hubKVPrefix}-${gh.hubKVOrgName}-${gh.hubKVAppName}-RG-${gh.hubKVRGName}'
// var HubKVName = toLower('${gh.hubKVPrefix}-${gh.hubKVOrgName}-${gh.hubKVAppName}-${gh.hubKVRGName}-kv${HubKVJ.name}')

resource OMS 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${DeploymentURI}LogAnalytics'
}

resource CDNProfile 'Microsoft.Cdn/profiles@2020-09-01' existing = {
  name: toLower('${DeploymentURI}cdn${cdn.name}')
}

resource customDomains 'Microsoft.Cdn/profiles/customDomains@2021-06-01' existing = {
  name: toLower(replace('${cdn.name}.${cdn.zone}', '.', '-'))
  parent: CDNProfile
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2020-09-01' existing = {
  name: toLower('${DeploymentURI}cdn${cdn.name}')
  parent: CDNProfile
}

resource originGroups 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: originGroup.name
  parent: CDNProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: originGroup.probePath
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: bool(originGroup.sessionAffinity) ? 'Enabled' : 'Disabled'
  }
}

resource origins 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = [for (origin, index) in originGroup.origins: {
  name: origin.name
  parent: originGroups
  properties: {
    hostName: origin.hostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: origin.hostname
    priority: 1
    weight: 1000
    enabledState: bool(origin.enabled) ? 'Enabled' : 'Disabled'
    enforceCertificateNameCheck: true
    sharedPrivateLinkResource: {
      privateLink: {
        id: '/subscriptions/b8f402aa-20f7-4888-b45c-3cf086dad9c3/resourceGroups/AWU2-BRW-AOA-RG-T4/providers/Microsoft.Storage/storageAccounts/awu2brwaoat4sadiag'
      }
      groupId: 'blob'
      privateLinkLocation: 'westus2'
      requestMessage: 'Private link service from AFD'
    }
  }
}]

resource afdRoutes 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = [for (rt, index) in cdn.originGroups: {
  name: rt.name
  parent: endpoint
  properties: {
    customDomains: [
      {
        id: customDomains.id
      }
    ]
    originGroup: {
      id: originGroups.id
    }
    enabledState: 'Enabled'
    supportedProtocols: [
      'Http'
      'Https'
    ]
    forwardingProtocol: 'MatchRequest'
    httpsRedirect: 'Enabled'
    originPath: rt.probePath
    linkToDefaultDomain: 'Disabled'
    patternsToMatch: cdn.pattern
    cacheConfiguration: {
      queryStringCachingBehavior: 'UseQueryString'
      // compressionSettings: 
      // queryParameters: 
    }
  }
  dependsOn: [
    origins
  ]
}]