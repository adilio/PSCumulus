function Should-HaveMandatoryParameter {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [Parameter(Mandatory)]
        [string]$ParameterSetName,

        [Parameter(Mandatory)]
        [string]$ParameterName
    )

    (Get-Command $CommandName).ParameterSets |
        Where-Object Name -eq $ParameterSetName |
        Select-Object -ExpandProperty Parameters |
        Where-Object Name -eq $ParameterName |
        Select-Object -ExpandProperty IsMandatory |
        Should -Be $true
}

function Should-HaveMandatoryParameters {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [Parameter(Mandatory)]
        [string]$ParameterSetName,

        [Parameter(Mandatory)]
        [string[]]$ParameterNames
    )

    foreach ($parameterName in $ParameterNames) {
        Should-HaveMandatoryParameter `
            -CommandName $CommandName `
            -ParameterSetName $ParameterSetName `
            -ParameterName $parameterName
    }
}
