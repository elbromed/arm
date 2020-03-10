
$Location="canadacentral"
$rsg="RG-HUB"

$parameterFile="C:\studio\repo\azfw07.parameters.json"
$templateFile = "C:\studio\repo\azfw07.template.json"
$Namedeployment="AzFwEnvironment"

New-AzResourceGroup -Name $rsg -Location $Location 
New-AzResourceGroupDeployment -Name $Namedeployment -ResourceGroupName $rsg -TemplateFile $templateFile -TemplateParameterFile $parameterFile -Verbose

#az group deployment validate --resource-group RG-HUB --template-file .\azfw07.template.json --parameters .\azfw07.parameters.json