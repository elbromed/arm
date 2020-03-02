
[CmdletBinding()]
Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet('DEV','STG','PROD','HUB')]
        [string]$environment
        
    )
#write-Output $envirnt
#write-verbose $envirnt
$Location="canadacentral"
$envirntU=$environment.ToUpper()
$rsg=("RG-"+$envirntU)

if ($envirntU -eq "DEV") {
    $parameterFile="D:\git\repo\elbro.parameters.dev.json"
    $templateFile = "D:\git\repo\elbro.template.json"
    $Namedeployment="DevEnvironment"
}
if ($envirntU -eq "STG") {
    $parameterFile="D:\git\repo\elbro.parameters.stg.json"
    $templateFile = "D:\git\repo\elbro.template.json"
    $Namedeployment="StageEnvironment"
}
if ($envirntU -eq "PROD") {
    $parameterFile="D:\git\repo\elbro.parameters.prod.json"
    $templateFile = "D:\git\repo\elbro.template.json"
    $Namedeployment="ProdEnvironment"
}
if ($envirntU -eq "HUB") {
    $parameterFile="D:\git\repo\elbro.parameters.hub.json"
    $templateFile = "D:\git\repo\elbro.template.hub.json"
    $Namedeployment="ProdEnvironment"
}
New-AzResourceGroup -Name $rsg -Location $Location 
New-AzResourceGroupDeployment -Name $Namedeployment -ResourceGroupName $rsg -TemplateFile $templateFile -TemplateParameterFile $parameterFile
