# Integration round-trip templates — SKIPPED BY DEFAULT.
#
# These tests run against real cloud accounts and are gated twice:
#   1. $env:PSCUMULUS_INTEGRATION must be '1'.
#   2. The per-provider credential env vars below must be present.
# A normal `Invoke-Pester -Path tests` therefore never executes them; they
# show up as skipped. See tests/Integration/README.md for how to enable.

$script:integrationEnabled = $env:PSCUMULUS_INTEGRATION -eq '1'

$script:azureReady = $script:integrationEnabled -and
    -not [string]::IsNullOrWhiteSpace($env:PSCUMULUS_AZURE_SUBSCRIPTION)

$script:awsReady = $script:integrationEnabled -and
    -not [string]::IsNullOrWhiteSpace($env:AWS_ACCESS_KEY_ID) -and
    -not [string]::IsNullOrWhiteSpace($env:PSCUMULUS_AWS_REGION)

$script:gcpReady = $script:integrationEnabled -and
    -not [string]::IsNullOrWhiteSpace($env:PSCUMULUS_GCP_PROJECT)

BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Azure connect and inventory round trip' -Tag 'Integration' -Skip:(-not $script:azureReady) {
    It 'connects and lists instances in the throwaway subscription' {
        Connect-Cloud -Provider Azure -Subscription $env:PSCUMULUS_AZURE_SUBSCRIPTION

        $context = Get-CloudContext -Provider Azure
        $context.Connected | Should -BeTrue

        # The throwaway subscription may legitimately be empty; the round trip
        # asserts the call path works, not that resources exist.
        { Get-CloudInstance -Provider Azure -ResourceGroup $env:PSCUMULUS_AZURE_RESOURCE_GROUP } |
            Should -Not -Throw
    }
}

Describe 'AWS connect and inventory round trip' -Tag 'Integration' -Skip:(-not $script:awsReady) {
    It 'connects and lists instances in the throwaway account region' {
        Connect-Cloud -Provider AWS -Region $env:PSCUMULUS_AWS_REGION

        $context = Get-CloudContext -Provider AWS
        $context.Connected | Should -BeTrue

        { Get-CloudInstance -Provider AWS -Region $env:PSCUMULUS_AWS_REGION } |
            Should -Not -Throw
    }
}

Describe 'GCP connect and inventory round trip' -Tag 'Integration' -Skip:(-not $script:gcpReady) {
    It 'connects and lists instances in the throwaway project' {
        Connect-Cloud -Provider GCP -Project $env:PSCUMULUS_GCP_PROJECT

        $context = Get-CloudContext -Provider GCP
        $context.Connected | Should -BeTrue

        { Get-CloudInstance -Provider GCP -Project $env:PSCUMULUS_GCP_PROJECT } |
            Should -Not -Throw
    }
}
