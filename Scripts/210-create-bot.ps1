$ErrorActionPreference = "Stop"
$scriptDir=($PSScriptRoot, '.' -ne "")[0]
. "$scriptDir\Include\common.ps1"

Write-Host "Create LUIS Cognitive Service..."  -ForegroundColor Green

New-AzureRmCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Location $cognitiveServiceLocation -Name $luisCognitiveServiceName -SkuName S0 -Type LUIS -Force
$cognitiveServiceKey=(Get-AzureRmCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $luisCognitiveServiceName).Key1


Write-Host -ForegroundColor Magenta "Perform this manual configuration"
Write-Host -ForegroundColor Magenta "In Azure Portal -> New -> Bot Service"
Write-Host -ForegroundColor Magenta "App name: $botName"
Write-Host -ForegroundColor Magenta "Resource Group: $resourceGroupName"
Write-Host -ForegroundColor Magenta "Location: $location"
Write-Host -ForegroundColor Magenta "`nRegister your bot, select C# Language understanding template."
Write-Host -ForegroundColor Magenta "In the code editor, replace the file BasicLuisDialog.csx with the one in the Resources/Bot directory."
Write-Host -ForegroundColor Magenta "Set the value for logicAppURL to:"
(Get-AzureRmLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroupName -Name $logicAppName -TriggerName manual).Value | Write-Host -ForegroundColor Cyan
Write-Host -ForegroundColor Magenta "Go to luis.ai -> My Keys -> Add a new key -> using the following as Key Value:"
Write-Host -ForegroundColor Magenta "Key Value: $cognitiveServiceKey"
Write-Host -ForegroundColor Magenta "Key Name: $luisCognitiveServiceName"
Write-Host -ForegroundColor Magenta "Go to My Apps -> Select LUIS app created by Bot Service -> Create intents and entities"
Write-Host -ForegroundColor Magenta "Go to Train & Test -> Train Application -> test your model"
Write-Host -ForegroundColor Magenta "Go to Publish App -> Endpoint Key -> Choose the key created earlier -> Publish"
Write-Host -ForegroundColor Magenta "In Azure Portal -> Go to Bot Service created earlier -> Channels -> Web Chat -> Edit -> Add new site -> Copy Secret Key to clipboard"

