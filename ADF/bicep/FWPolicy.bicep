@allowed([
  'AZE2'
  'AZC1'
  'AEU2'
  'ACU1'
  'AWCU'
])
param Prefix string = 'ACU1'

@allowed([
  'I'
  'D'
  'U'
  'P'
  'S'
  'G'
  'A'
])
param Environment string = 'D'

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
param DeploymentID string = '1'
param Stage object
#disable-next-line no-unused-params
param Extensions object
param Global object
param DeploymentInfo object



var Deployment = '${Prefix}-${Global.OrgName}-${Global.Appname}-${Environment}${DeploymentID}'
var DeploymentURI = toLower('${Prefix}${Global.OrgName}${Global.Appname}${Environment}${DeploymentID}')

resource OMS 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${DeploymentURI}LogAnalytics'
}

var FWInfo = contains(DeploymentInfo, 'FWInfo') ? DeploymentInfo.FWInfo : []

var FW = [for (fw, index) in FWInfo: {
  match: ((Global.CN == '.') || contains(Global.CN, fw.Name))
}]

module FireWall 'FWPolicy-Policy.bicep' = [for (fw, index) in FWInfo: if(FW[index].match) {
  name: 'dp${Deployment}-FWPolicy-Deploy${((length(FW) != 0) ? fw.name : 'na')}'
  params: {
    Deployment: Deployment
    DeploymentURI: DeploymentURI
    FWPolicyInfo: fw.policy
    Global: Global
  }
}]
