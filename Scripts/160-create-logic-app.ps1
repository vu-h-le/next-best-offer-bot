$ErrorActionPreference = "Stop"
$scriptDir=($PSScriptRoot, '.' -ne "")[0]
. "$scriptDir\Include\common.ps1"

Write-Host "Create Text Analytics Cognitive Service..."  -ForegroundColor Green

New-AzureRmCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Location $cognitiveServiceLocation -Name $textAnalyticsCognitiveServiceName -SkuName S1 -Type TextAnalytics -Force
$cognitiveServiceKey=(Get-AzureRmCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $textAnalyticsCognitiveServiceName).Key1

Write-Host "Create a Logic App..."  -ForegroundColor Green

$requestSchema=Get-Content "..\Resources\LogicApp\request-schema.json" -Raw
$logicAppDefinition=substituteInTemplate "..\Resources\LogicApp\Definition.json"  @{
 '$requestSchema' = $requestSchema
}

New-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $logicAppName -Location $location -Definition $logicAppDefinition

$sub=(Get-AzureRmContext).Subscription.SubscriptionId
Write-Host -ForegroundColor Magenta "Perform this manual configuration"
Write-Host -ForegroundColor Magenta "https://portal.azure.com/#resource/subscriptions/$sub/resourceGroups/$resourceGroupName/providers/Microsoft.Logic/workflows/$logicAppName/logicApp"
Write-Host -ForegroundColor Magenta 
Write-Host -ForegroundColor Magenta "Edit -> New step -> Add Action -> Detect Sentiment"
Write-Host -ForegroundColor Magenta "Connection name: $cognitiveServiceName"
Write-Host -ForegroundColor Magenta "Account key: $cognitiveServiceKey"
Write-Host -ForegroundColor Magenta "Text to analyze: [text] (from Request fields)"
Write-Host -ForegroundColor Magenta 
Write-Host -ForegroundColor Magenta "New step -> Add Action -> TODO: update with instructions to add event hub action"
Write-Host -ForegroundColor Magenta "Enter following JSON and fill values from variables"
@{
    "intent" =  ""
    "channelId" =  ""
    "id" =  ""
    "product" =  ""
    "serviceUrl" =  ""
    "text" =  ""
    "timestamp" =  ""
    "type" =  ""
    "userid" =  ""
    "username" =  ""
    "Score" = ""
} | ConvertTo-Json | Write-Host -ForegroundColor Cyan 

