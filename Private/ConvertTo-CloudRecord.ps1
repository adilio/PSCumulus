function ConvertTo-CloudRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [string]$Region,
        [string]$Status,
        [string]$Size,
        [datetime]$CreatedAt,
        [hashtable]$Metadata = @{}
    )

    [pscustomobject]@{
        Name      = $Name
        Provider  = $Provider
        Region    = $Region
        Status    = $Status
        Size      = $Size
        CreatedAt = $CreatedAt
        Metadata  = $Metadata
    }
}

