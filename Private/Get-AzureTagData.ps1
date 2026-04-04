function Get-AzureTagData {
    [CmdletBinding()]
    param(
        [string]$ResourceId
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzTag' `
        -InstallHint "Install the Az.Resources module with: Install-Module Az.Resources -Scope CurrentUser"

    $tagWrapper = Get-AzTag -ResourceId $ResourceId -ErrorAction Stop

    $tags = @{}
    if ($tagWrapper.Properties -and $tagWrapper.Properties.TagsProperty) {
        foreach ($kvp in $tagWrapper.Properties.TagsProperty.GetEnumerator()) {
            $tags[$kvp.Key] = $kvp.Value
        }
    }

    $resourceName = ($ResourceId -split '/')[-1]

    ConvertTo-CloudRecord `
        -Name $resourceName `
        -Provider Azure `
        -Metadata @{
            ResourceId = $ResourceId
            Tags       = $tags
        }
}
