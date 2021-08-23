@allowed([
  'AZE2'
  'AZC1'
  'AEU2'
  'ACU1'
])
param Prefix string = 'AZE2'

@allowed([
  'I'
  'D'
  'T'
  'U'
  'P'
  'S'
  'G'
  'A'
])
param Environment string

@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
  '5'
  '6'
  '7'
  '8'
  '9'
])
param DeploymentID string
param Stage object
param Extensions object
param Global object
param DeploymentInfo object

@secure()
param vmAdminPassword string

@secure()
param devOpsPat string

@secure()
param sshPublic string

var Deployment = '${Prefix}-${Global.OrgName}-${Global.Appname}-${Environment}${DeploymentID}'
var DeploymentURI = toLower('${Prefix}${Global.OrgName}${Global.Appname}${Environment}${DeploymentID}')
var Deploymentnsg = '${Prefix}-${Global.OrgName}-${Global.AppName}-'
var networkId = '${Global.networkid[0]}${string((Global.networkid[1] - (2 * int(DeploymentID))))}'
var networkIdUpper = '${Global.networkid[0]}${string((1 + (Global.networkid[1] - (2 * int(DeploymentID)))))}'
var OMSworkspaceName = '${DeploymentURI}LogAnalytics'
var OMSworkspaceID = resourceId('Microsoft.OperationalInsights/workspaces/', OMSworkspaceName)
var addressPrefixes = [
  '${networkId}.0/23'
]
var DC1PrivateIPAddress = contains(DeploymentInfo,'DNSServers') ? '${networkId}.${DeploymentInfo.DNSServers[0]}' : Global.DNSServers[0]
var DC2PrivateIPAddress = contains(DeploymentInfo,'DNSServers') ? '${networkId}.${DeploymentInfo.DNSServers[1]}' : Global.DNSServers[1]
var AzureDNS = '168.63.129.16'

//  remove below after they are migrated each stage to Bicep
// will just hard code the bicep file paths, not do a lookup

var DeploymentInfoObject = {
  KV: '../templates-base/00-azuredeploy-KV.json'
  OMS: '../templates-base/01-azuredeploy-OMS.json'
  SA: '../templates-base/01-azuredeploy-Storage.json'
  CDN: '../templates-base/01-azuredeploy-StorageCDN.json'
  RSV: '../templates-base/02-azuredeploy-RSV.json'
  NSGHUB: '../templates-base/02-azuredeploy-NSG.hub.json'
  NSGSPOKE: '../templates-base/02-azuredeploy-NSG.spoke.json'
  NetworkWatcher: '../templates-base/02-azuredeploy-NetworkWatcher.json'
  FlowLogs: '../templates-base/02-azuredeploy-NetworkFlowLogs.json'
  VNET: '../templates-base/03-azuredeploy-VNet.json'
  DNSPrivateZone: '../templates-base/03-azuredeploy-DNSPrivate.json'
  BastionHost: '../templates-base/02-azuredeploy-BastionHost.json'
  FW: '../templates-base/12-azuredeploy-FW.json'
  RT: '../templates-base/02-azuredeploy-RT.json'
  ERGW: '../templates-base/12-azuredeploy-ERGW.json'
  ILB: '../templates-base/04-azuredeploy-ILBalancer.json'
  VNetDNS: '../templates-nested/SetvNetDNS.json'
  ADPrimary: '../templates-base/05-azuredeploy-VMApp.json'
  ADSecondary: '../templates-base/05-azuredeploy-VMApp.json'
  VMSS: '../templates-base/05-azuredeploy-VMAppSS.json'
  InitialDOP: '../templates-base/05-azuredeploy-VMApp.json'
  VMApp: '../templates-base/05-azuredeploy-VMApp.json'
  VMAppLinux: '../templates-base/05-azuredeploy-VMApp.json'
  VMSQL: '../templates-base/05-azuredeploy-VMApp.json'
  VMFILE: '../templates-base/05-azuredeploy-VMApp.json'
  APPCONFIG: '../templates-base/18-azuredeploy-AppConfiguration.json'
  WAF: '../templates-base/06-azuredeploy-WAF.json'
  FRONTDOOR: '../templates-base/02-azuredeploy-FrontDoor.json'
  WAFPOLICY: '../templates-base/06-azuredeploy-WAFPolicy.json'
  REDIS: '../templates-base/20-azuredeploy-Redis.json'
  APIM: '../templates-base/09-azuredeploy-APIM.json'
  ACR: '../templates-base/13-azuredeploy-ContainerRegistry.json'
  AKS: '../templates-base/14-azuredeploy-AKS.json'
  ServerFarm: '../templates-base/18-azuredeploy-AppServiceplan.json'
  WebSite: '../templates-base/19-azuredeploy-AppServiceWebSite.json'
  Function: '../templates-base/19-azuredeploy-AppServiceFunction.json'
  MySQLDB: '../templates-base/20-azuredeploy-DBforMySQL.json'
  DNSLookup: '../templates-base/12-azuredeploy-DNSLookup.json'
  CosmosDB: '../templates-base/10-azuredeploy-CosmosDB.json'
  SQLMI: '../templates-base/11-azuredeploy-SQLManaged.json'
  DASHBOARD: '../templates-base/23-azuredeploy-Dashboard.json'
  SB: '../templates-base/24-azuredeploy-ServiceBus.json'
  AzureSQL: '../templates-base/26-azuredeploy-AzureSQL.json'
  ACI: '../templates-base/30-azuredeploy-ContainerGroups.json'
}

module dp_Deployment_OMS 'OMS.bicep' = if (Stage.OMS == 1) {
  name: 'dp${Deployment}-OMS'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: []
}

module dp_Deployment_SA 'SA.bicep' = if (Stage.SA == 1) {
  name: 'dp${Deployment}-SA'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
  ]
}

module dp_Deployment_CDN 'SA.CDN.bicep' = if (Stage.CDN == 1) {
  name: 'dp${Deployment}-CDN'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_SA
  ]
}

module dp_Deployment_RSV 'RSV.bicep' = if (Stage.RSV == 1) {
  name: 'dp${Deployment}-RSV'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
  ]
}

module dp_Deployment_NSGHUB 'NSG.hub.bicep' = if (Stage.NSGHUB == 1) {
  name: 'dp${Deployment}-NSGHUB'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
  ]
}

module dp_Deployment_NSGSPOKE 'NSG.spoke.bicep' = if (Stage.NSGSPOKE == 1) {
  name: 'dp${Deployment}-NSGSPOKE'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
  ]
}

module dp_Deployment_NetworkWatcher 'NetworkWatcher.bicep' = if (Stage.NetworkWatcher == 1) {
  name: 'dp${Deployment}-NetworkWatcher'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
  ]
}

module dp_Deployment_FlowLogs 'NetworkFlowLogs.bicep' = if (Stage.FlowLogs == 1) {
  name: 'dp${Deployment}-FlowLogs'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
    dp_Deployment_NetworkWatcher
    dp_Deployment_NSGSPOKE
    dp_Deployment_NSGHUB
    dp_Deployment_SA
  ]
}

module dp_Deployment_RT 'RT.bicep' = if (Stage.RT == 1) {
  name: 'dp${Deployment}-RT'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
    // dp_Deployment_FW
  ]
}

module dp_Deployment_VNET 'VNET.bicep' = if (Stage.VNET == 1) {
  name: 'dp${Deployment}-VNET'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_NSGSPOKE
    dp_Deployment_NSGHUB
  ]
}

module dp_Deployment_KV 'KV.bicep' = if (Stage.KV == 1) {
  name: 'dp${Deployment}-KV'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
  ]
}

module dp_Deployment_ACR 'ACR.bicep' = if (Stage.ACR == 1) {
  name: 'dp${Deployment}-ACR'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
  ]
}

module dp_Deployment_BastionHost 'Bastion.bicep' = if (contains(Stage, 'BastionHost') && (Stage.BastionHost == 1)) {
  name: 'dp${Deployment}-BastionHost'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
  ]
}

module dp_Deployment_DNSPrivateZone 'DNSPrivate.bicep' = if (Stage.DNSPrivateZone == 1) {
  name: 'dp${Deployment}-DNSPrivateZone'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
  ]
}

module dp_Deployment_DNSPublicZone 'DNSPublic.bicep' = if (contains(Stage, 'DNSPublicZone') && Stage.DNSPublicZone == 1) {
  name: 'dp${Deployment}-DNSPublicZone'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: []
}

/*
module dp_Deployment_FW '?' = if (Stage.FW == 1) {
  name: 'dp${Deployment}-FW'
  params: {}
  dependsOn: [
    dp_Deployment_VNET
  ]
}

*/

module dp_Deployment_ERGW 'ERGW.bicep' = if (Stage.ERGW == 1) {
  name: 'dp${Deployment}ERGW'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
  ]
}

module dp_Deployment_LB 'LB.bicep' = if (Stage.ILB == 1) {
  name: 'dp${Deployment}-LB'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
  ]
}

module dp_Deployment_VNETDNSPublic 'x.setVNETDNS.bicep' = if (Stage.ADPrimary == 1 || contains(Stage,'CreateADPDC') && Stage.CreateADPDC == 1) {
  name: 'dp${Deployment}-VNETDNSPublic'
  params: {
    Deploymentnsg: Deploymentnsg
    Deployment: Deployment
    DeploymentID: DeploymentID
    Prefix: Prefix
    DeploymentInfo: DeploymentInfo
    DNSServers: [
      DC1PrivateIPAddress
      AzureDNS
    ]
    Global: Global
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
    dp_Deployment_SA
  ]
}

module CreateADPDC 'VM.bicep' = if (Stage.CreateADPDC == 1) {
  name: 'CreateADPDC'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNETDNSPublic
    dp_Deployment_OMS
    dp_Deployment_SA
  ]
}

module ADPrimary 'VM.bicep' = if (Stage.ADPrimary == 1) {
  name: 'ADPrimary'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNETDNSPublic
    dp_Deployment_OMS
    dp_Deployment_SA
  ]
}

module dp_Deployment_VNETDNSDC1 'x.setVNETDNS.bicep' = if (Stage.ADPrimary == 1 || contains(Stage,'CreateADPDC') && Stage.CreateADPDC == 1) {
  name: 'dp${Deployment}-VNETDNSDC1'
  params: {
    Deploymentnsg: Deploymentnsg
    Deployment: Deployment
    DeploymentID: DeploymentID
    Prefix: Prefix
    DeploymentInfo: DeploymentInfo
    DNSServers: [
      DC1PrivateIPAddress
    ]
    Global: Global
  }
  dependsOn: [
    ADPrimary
    CreateADPDC
  ]
}

module CreateADBDC 'VM.bicep' = if (Stage.CreateADBDC == 1) {
  name: 'CreateADBDC'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNETDNSDC1
    dp_Deployment_OMS
    dp_Deployment_SA
  ]
}

module ADSecondary 'VM.bicep' = if (Stage.ADSecondary == 1) {
  name: 'ADSecondary'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNETDNSDC1
    dp_Deployment_OMS
    dp_Deployment_SA
  ]
}

module dp_Deployment_VNETDNSDC2 'x.setVNETDNS.bicep' = if (Stage.ADSecondary == 1 || contains(Stage,'CreateADBDC') && Stage.CreateADBDC == 1) {
  name: 'dp${Deployment}-VNETDNSDC2'
  params: {
    Deploymentnsg: Deploymentnsg
    Deployment: Deployment
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Prefix: Prefix
    DNSServers: [
      DC1PrivateIPAddress
      DC2PrivateIPAddress
    ]
    Global: Global
  }
  dependsOn: [
    ADSecondary
    CreateADBDC
  ]
}

// module DNSLookup '?' = if (Stage.DNSLookup == 1) {
//   name: 'DNSLookup'
//   params: {}
//   dependsOn: [
//     dp_Deployment_WAF
//   ]
// }

module AppServers 'VM.bicep' = if (Stage.VMApp == 1) {
  name: 'AppServers'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNETDNSDC1
    dp_Deployment_VNETDNSDC2
    dp_Deployment_OMS
    dp_Deployment_LB
    // DNSLookup
    dp_Deployment_SA
  ]
}

module VMFile 'VM.bicep' = if (Stage.VMFILE == 1) {
  name: 'VMFile'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNETDNSDC1
    dp_Deployment_VNETDNSDC2
    dp_Deployment_OMS
    dp_Deployment_LB
    // DNSLookup
    dp_Deployment_SA
  ]
}

module AppServersLinux 'VM.bicep' = if (Stage.VMAppLinux == 1) {
  name: 'AppServersLinux'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_LB
    dp_Deployment_OMS
    dp_Deployment_VNETDNSDC1
    dp_Deployment_VNETDNSDC2
    dp_Deployment_SA
  ]
}

module SQLServers 'VM.bicep' = if (Stage.VMSQL == 1) {
  name: 'SQLServers'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNETDNSDC1
    dp_Deployment_VNETDNSDC2
    dp_Deployment_LB
    dp_Deployment_OMS
    dp_Deployment_SA
  ]
}

module dp_Deployment_DASHBOARD 'Dashboard.bicep' = if (Stage.DASHBOARD == 1) {
  name: 'dp${Deployment}-DASHBOARD'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: []
}


module dp_Deployment_CosmosDB 'Cosmos.bicep' = if (Stage.CosmosDB == 1) {
  name: 'dp${Deployment}-CosmosDB'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
  ]
}

module dp_Deployment_ServerFarm 'AppServicePlan.bicep' = if (Stage.ServerFarm == 1) {
  name: 'dp${Deployment}-ServerFarm'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
  ]
}

module dp_Deployment_WebSite 'AppServiceWebSite.bicep' = if (Stage.WebSite == 1) {
  name: 'dp${Deployment}-WebSite'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
    dp_Deployment_ServerFarm
  ]
}

module dp_Deployment_Function 'AppServiceFunction.bicep' = if (Stage.Function == 1) {
  name: 'dp${Deployment}-Function'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
    dp_Deployment_ServerFarm
  ]
}

module dp_Deployment_Container 'AppServiceContainer.bicep' = if (Stage.WebSiteContainer == 1) {
  name: 'dp${Deployment}-Container'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
    dp_Deployment_ServerFarm
  ]
}

module dp_Deployment_ACI 'ACI.bicep' = if (Stage.ACI == 1) {
  name: 'dp${Deployment}-ACI'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_OMS
  ]
}

module dp_Deployment_REDIS 'REDIS.bicep' = if (Stage.REDIS == 1) {
  name: 'dp${Deployment}-REDIS'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
  ]
}

module dp_Deployment_APIM 'APIM.bicep' = if (Stage.APIM == 1) {
  name: 'dp${Deployment}-APIM'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_VNETDNSDC2
    dp_Deployment_OMS
  ]
}

module dp_Deployment_FRONTDOOR 'FD.bicep' = if (Stage.FRONTDOOR == 1) {
  name: 'dp${Deployment}-FRONTDOOR'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    // dp_Deployment_WAF
    dp_Deployment_APIM
  ]
}

module dp_Deployment_SB 'SB.bicep' = if (Stage.SB == 1) {
  name: 'dp${Deployment}-SB'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
  ]
}

module dp_Deployment_APPCONFIG 'AppConfig.bicep' = if (Stage.APPCONFIG == 1) {
  name: 'dp${Deployment}-APPCONFIG'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
    devOpsPat: devOpsPat
    sshPublic: sshPublic
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
  ]
}

/*

module dp_Deployment_SQLMI '?' = if (Stage.SQLMI == 1) {
  name: 'dp${Deployment}-SQLMI'
  params: {}
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_VNETDNSDC1
    dp_Deployment_VNETDNSDC2
  ]
}

module dp_Deployment_WAFPOLICY '?' = if (Stage.WAFPOLICY == 1) {
  name: 'dp${Deployment}-WAFPOLICY'
  params: {}
  dependsOn: [
    dp_Deployment_VNET
  ]
}

module dp_Deployment_WAF '?' = if (Stage.WAF == 1) {
  name: 'dp${Deployment}-WAF'
  params: {}
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
  ]
}

module VMSS '?' = if (Stage.VMSS == 1) {
  name: 'VMSS'
  params: {}
  dependsOn: [
    dp_Deployment_VNETDNSDC1
    dp_Deployment_VNETDNSDC2
    dp_Deployment_OMS
    dp_Deployment_LB
    dp_Deployment_WAF
    dp_Deployment_SA
  ]
}

module dp_Deployment_AKS '?' = if (Stage.AKS == 1) {
  name: 'dp${Deployment}-AKS'
  params: {}
  dependsOn: [
    dp_Deployment_WAF
    dp_Deployment_VNET
    dp_Deployment_ACR
  ]
}

module dp_Deployment_MySQLDB '?' = if (Stage.MySQLDB == 1) {
  name: 'dp${Deployment}-MySQLDB'
  params: {}
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
    dp_Deployment_WebSite
  ]
}

module dp_Deployment_AzureSQL '?' = if (Stage.AzureSQL == 1) {
  name: 'dp${Deployment}-AzureSQL'
  params: {}
  dependsOn: [
    dp_Deployment_VNET
    dp_Deployment_OMS
  ]
}


*/