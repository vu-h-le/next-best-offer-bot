#region - used for creating Azure service names
$studentnumber = "00"
$namePrefix = "cisbot" + $studentnumber
$resourceGroupName = $namePrefix
#endregion

#region - service locations
$location = "West US" # default location for resource group and all services except ADL and AML
$dataFactoryLocation = $location
$cognitiveServiceLocation = $location # LUIS and Text Analytics are only available in West US
$dataLakeLocation = "Central US" # ADLS service availability: centralus, eastus2, northeurope
$amlLocation = 'West Central US' # AML service availability: southcentralus,westeurope,southeastasia,japaneast,westcentralus
#endregion

#region - service names
$dataLakeStoreName = $namePrefix + "adls"
$dataLakeAnalyticsName = $namePrefix + "adla"
$storageAccountName = $namePrefix + "storage"
#endregion

$sqlName = $namePrefix + "sqlsrv"
$dwName = $namePrefix + "dw"

$dataFactoryName = $namePrefix + "adf"

$eventHubNamespace = $namePrefix + "eventhubs"
$eventHubName = "botdata"
$eventHubSendPolicyName = "sendFromBot"
$eventHubListenPolicyName = "listenIntoStreamAnalytics"
$functionAppName = $namePrefix + "function"
$functionName = "PostToEventHub"
$logicAppName = $namePrefix + "logicapp"
$streamAnalyticsName = $namePrefix + "streamjob"
$textAnalyticsCognitiveServiceName =  $namePrefix + "textanalytics"
$luisCognitiveServiceName = $namePrefix + "luis"
$botName = $namePrefix + "botservice"
$username = "zeus"

