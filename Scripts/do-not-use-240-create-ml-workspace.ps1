$ErrorActionPreference = "Stop"
$scriptDir=($PSScriptRoot, '.' -ne "")[0]
. "$scriptDir\Include\common.ps1"




#region Create AML workspace
$resourceGroupName = 'deleteme2'

# Create a Resource Group, TemplateFile is the location of the JSON template.
$rgd = New-AzureRmResourceGroupDeployment `
            -Name ("CISBotAmlDeployment" + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
            -ResourceGroupName $resourceGroupName `
            -TemplateFile "..\Resources\MachineLearning\amlworkspace.json" `
            -TemplateParameterObject @{ amlLocation = $amlLocation}
            #-TemplateParameterFile "..\Resources\MachineLearning\amlworkspace.parameters.json"

# Access Azure ML Workspace Token after its deployment.
Write-Host "AML Workspace created:"
Write-Host "Workspace ID:" $rgd.Outputs.mlWorkspaceWorkspaceID.Value
Write-Host "Workspace Token:" $rgd.Outputs.mlWorkspaceToken.Value
Write-Host "Workspace Link:" $rgd.Outputs.mlWorkspaceWorkspaceLink.Value

#endregion
    
#region Setup AML PowerShell module and connection to the workspace that was just created
$amlPsDll = "..\Resources\MachineLearning\AzureMLPS.dll"
$amlPsConfig = "..\Resources\MachineLearning\config.json"
$amlPsConfigTemplate = "..\Resources\MachineLearning\config - template.json"

# Create/replace AML PowerShell config.json file with the values of Location, WorkspaceId, 
# and AuthorizationToken from the newly created workspace 
$amlPsConfig=substituteInTemplate $amlPsConfigTemplate  @{
 '$location' = $amlLocation
 '$workspaceId' = $rgd.Outputs.mlWorkspaceWorkspaceID.Value
 '$authorizationToken' = $rgd.Outputs.mlWorkspaceToken.Value
} | Out-File $amlPsConfig

Unblock-File $amlPsDll
Import-Module $amlPsDll

#endregion

#region Get Storage account containing interaction data
#$temp=New-TemporaryFile

#$storageContext = getStorageContext
#$storageKey = getStorageKey

#substituteInTemplate $linkedServicesDir\BlobLinkedService.json @{
#    '$storageAccountName' = "$storageAccountName";
#    '$storageKey' = "$storageKey";
#    } | Out-File $temp

#endregion

#region Create AML Experiment

# replace the input source in the local experiment json file with the storage account created earlier

# import AML experiment to the newly created workspace
$amlWorkspace = Get-AmlWorkspace -WorkspaceId $rgd.Outputs.mlWorkspaceWorkspaceID.Value `
                                 -AuthorizationToken $rgd.Outputs.mlWorkspaceToken.Value `
                                 -Location $amlLocation

Import-AmlExperimentGraph `
    -InputFile 'C:\Repos\next-best-offer-bot\Resources\MachineLearning\NextBestOfferAmlExperiment.json' `
    -NewName 'Next Best Offer' `
    -WorkspaceId $amlWorkspace.WorkspaceId `
    -AuthorizationToken $rgd.Outputs.mlWorkspaceToken.Value

#endregion

