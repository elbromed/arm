
[CmdletBinding()]
Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet('DEV','STG','PROD')]
        [string]$environment
        
    )
#write-Output $envirnt
#write-verbose $envirnt
$Location="canadacentral"
$envirntU=$environment.ToUpper()
$rsg=("RG-"+$envirntU)

$templateFile = "D:\scripts\Azure\elbro.template.json"
if ($envirntU -eq "DEV") {
    $parameterFile="D:\scripts\Azure\elbro.parameters.dev.json"
    $Namedeployment="DevEnvironment"
}
if ($envirntU -eq "STG") {
    $parameterFile="D:\scripts\Azure\elbro.parameters.stg.json"
    $Namedeployment="StageEnvironment"
}
if ($envirntU -eq "PROD") {
    $parameterFile="D:\scripts\Azure\elbro.parameters.prod.json"
    $Namedeployment="ProdEnvironment"
}

New-AzResourceGroup -Name $rsg -Location $Location 
New-AzResourceGroupDeployment -Name $Namedeployment -ResourceGroupName $rsg -TemplateFile $templateFile -TemplateParameterFile $parameterFile
