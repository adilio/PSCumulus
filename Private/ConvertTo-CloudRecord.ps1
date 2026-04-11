function ConvertTo-CloudRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [string]$Region,
        [string]$Status,
        [string]$Size,
        [datetime]$CreatedAt,
        [hashtable]$Tags = @{},
        [hashtable]$Metadata = @{}
    )

    $record = [pscustomobject]@{
        Name      = $Name
        Provider  = $Provider
        Region    = $Region
        Status    = $Status
        Size      = $Size
        CreatedAt = $CreatedAt
        Tags      = $Tags
        Metadata  = $Metadata
    }

    $record.PSObject.TypeNames.Insert(0, 'PSCumulus.CloudRecord')

    $record
}
