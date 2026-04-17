BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'CloudPath.Parse' {
    It 'Parses a full Azure instance path' {
        InModuleScope PSCumulus {
            $path = 'Azure:\prod-rg\Instances\web-server-01'
            $result = [CloudPath]::Parse($path)

            $result.Provider | Should -Be 'Azure'
            $result.Scope | Should -Be 'prod-rg'
            $result.Kind | Should -Be 'Instances'
            $result.ResourceName | Should -Be 'web-server-01'
            $result.Depth | Should -Be ([CloudPathDepth]::Resource)
        }
    }

    It 'Parses a full AWS instance path' {
        InModuleScope PSCumulus {
            $path = 'AWS:\us-east-1\Instances\app-server-01'
            $result = [CloudPath]::Parse($path)

            $result.Provider | Should -Be 'AWS'
            $result.Scope | Should -Be 'us-east-1'
            $result.Kind | Should -Be 'Instances'
            $result.ResourceName | Should -Be 'app-server-01'
            $result.Depth | Should -Be ([CloudPathDepth]::Resource)
        }
    }

    It 'Parses a full GCP instance path' {
        InModuleScope PSCumulus {
            $path = 'GCP:\my-project\Instances\gcp-vm-01'
            $result = [CloudPath]::Parse($path)

            $result.Provider | Should -Be 'GCP'
            $result.Scope | Should -Be 'my-project'
            $result.Kind | Should -Be 'Instances'
            $result.ResourceName | Should -Be 'gcp-vm-01'
            $result.Depth | Should -Be ([CloudPathDepth]::Resource)
        }
    }

    It 'Parses a root path' {
        InModuleScope PSCumulus {
            $path = 'Azure:\'
            $result = [CloudPath]::Parse($path)

            $result.Provider | Should -Be 'Azure'
            $result.Scope | Should -BeNullOrEmpty
            $result.Kind | Should -BeNullOrEmpty
            $result.ResourceName | Should -BeNullOrEmpty
            $result.Depth | Should -Be ([CloudPathDepth]::Root)
        }
    }

    It 'Parses a scope path' {
        InModuleScope PSCumulus {
            $path = 'AWS:\us-east-1'
            $result = [CloudPath]::Parse($path)

            $result.Provider | Should -Be 'AWS'
            $result.Scope | Should -Be 'us-east-1'
            $result.Kind | Should -BeNullOrEmpty
            $result.ResourceName | Should -BeNullOrEmpty
            $result.Depth | Should -Be ([CloudPathDepth]::Scope)
        }
    }

    It 'Parses a kind path' {
        InModuleScope PSCumulus {
            $path = 'GCP:\my-project\Disks'
            $result = [CloudPath]::Parse($path)

            $result.Provider | Should -Be 'GCP'
            $result.Scope | Should -Be 'my-project'
            $result.Kind | Should -Be 'Disks'
            $result.ResourceName | Should -BeNullOrEmpty
            $result.Depth | Should -Be ([CloudPathDepth]::Kind)
        }
    }

    It 'Normalizes singular kind names to plural' {
        InModuleScope PSCumulus {
            { [CloudPath]::Parse('Azure:\rg\Instances\vm') } | Should -Not -Throw

            $result = [CloudPath]::Parse('Azure:\rg\Storage\acct')
            $result.Kind | Should -Be 'Storage'

            $result = [CloudPath]::Parse('AWS:\region\Networks\vpc')
            $result.Kind | Should -Be 'Networks'

            $result = [CloudPath]::Parse('GCP:\proj\Functions\fn')
            $result.Kind | Should -Be 'Functions'

            $result = [CloudPath]::Parse('Azure:\rg\Tags\t')
            $result.Kind | Should -Be 'Tags'
        }
    }

    It 'Handles case-insensitive provider names' {
        InModuleScope PSCumulus {
            $result = [CloudPath]::Parse('azure:\rg\Instances\vm')
            $result.Provider | Should -Be 'Azure'

            $result = [CloudPath]::Parse('AZURE:\rg\Instances\vm')
            $result.Provider | Should -Be 'Azure'

            $result = [CloudPath]::Parse('aws:\rg\Instances\vm')
            $result.Provider | Should -Be 'AWS'

            $result = [CloudPath]::Parse('gcp:\rg\Instances\vm')
            $result.Provider | Should -Be 'GCP'
        }
    }

    It 'Throws on null or empty path' {
        InModuleScope PSCumulus {
            { [CloudPath]::Parse($null) } | Should -Throw -ExpectedMessage '*cannot be null or empty*'
            { [CloudPath]::Parse('') } | Should -Throw -ExpectedMessage '*cannot be null or empty*'
            { [CloudPath]::Parse('   ') } | Should -Throw -ExpectedMessage '*cannot be null or empty*'
        }
    }

    It 'Throws on missing provider separator' {
        InModuleScope PSCumulus {
            { [CloudPath]::Parse('Azure-prod-rg-Instances') } | Should -Throw -ExpectedMessage '*must contain a provider separator*'
        }
    }

    It 'Throws on invalid provider' {
        InModuleScope PSCumulus {
            { [CloudPath]::Parse('Invalid:\rg\Instances\vm') } | Should -Throw -ExpectedMessage "*Invalid provider 'Invalid'*"
        }
    }

    It 'Throws on invalid kind' {
        InModuleScope PSCumulus {
            { [CloudPath]::Parse('Azure:\rg\InvalidKind\vm') } | Should -Throw -ExpectedMessage "*Invalid kind 'InvalidKind'*"
        }
    }

    It 'Throws on too many path segments' {
        InModuleScope PSCumulus {
            { [CloudPath]::Parse('Azure:\rg\Instances\vm\extra') } | Should -Throw -ExpectedMessage '*too many segments*'
        }
    }
}

Describe 'CloudPath.IsValid' {
    It 'Returns true for valid paths' {
        InModuleScope PSCumulus {
            [CloudPath]::IsValid('Azure:\prod-rg\Instances\web-server-01') | Should -Be $true
            [CloudPath]::IsValid('AWS:\us-east-1\Disks') | Should -Be $true
            [CloudPath]::IsValid('GCP:\my-project') | Should -Be $true
            [CloudPath]::IsValid('Azure:\') | Should -Be $true
        }
    }

    It 'Returns false for invalid paths' {
        InModuleScope PSCumulus {
            [CloudPath]::IsValid('Invalid:\rg\Instances\vm') | Should -Be $false
            [CloudPath]::IsValid('Azure:\rg\InvalidKind\vm') | Should -Be $false
            [CloudPath]::IsValid('') | Should -Be $false
            [CloudPath]::IsValid($null) | Should -Be $false
        }
    }
}

Describe 'CloudPath.ToString' {
    It 'Roundtrips a root path' {
        InModuleScope PSCumulus {
            $original = 'Azure:\'
            $parsed = [CloudPath]::Parse($original)
            $parsed.ToString() | Should -Be $original
        }
    }

    It 'Roundtrips a scope path' {
        InModuleScope PSCumulus {
            $original = 'AWS:\us-east-1'
            $parsed = [CloudPath]::Parse($original)
            $parsed.ToString() | Should -Be $original
        }
    }

    It 'Roundtrips a kind path' {
        InModuleScope PSCumulus {
            $original = 'GCP:\my-project\Disks'
            $parsed = [CloudPath]::Parse($original)
            $parsed.ToString() | Should -Be $original
        }
    }

    It 'Roundtrips a resource path' {
        InModuleScope PSCumulus {
            $original = 'Azure:\prod-rg\Instances\web-server-01'
            $parsed = [CloudPath]::Parse($original)
            $parsed.ToString() | Should -Be $original
        }
    }

    It 'Normalizes singular to plural in ToString output' {
        InModuleScope PSCumulus {
            $parsed = [CloudPath]::Parse('Azure:\rg\Instances\vm')
            $parsed.Kind | Should -Be 'Instances'
            $parsed.ToString() | Should -Be 'Azure:\rg\Instances\vm'
        }
    }
}

Describe 'CloudPathResolver.Resolve' {
    It 'Resolves Azure instance path correctly' {
        InModuleScope PSCumulus {
            $cloudPath = [CloudPath]::Parse('Azure:\prod-rg\Instances\web-server-01')
            $resolved = [CloudPathResolver]::Resolve($cloudPath)

            $resolved.CommandName | Should -Be 'Get-AzureInstanceData'
            $resolved.ArgumentMap.ResourceGroup | Should -Be 'prod-rg'
            $resolved.ArgumentMap.Name | Should -Be 'web-server-01'
        }
    }

    It 'Resolves Azure disk path correctly' {
        InModuleScope PSCumulus {
            $cloudPath = [CloudPath]::Parse('Azure:\prod-rg\Disks\disk-01')
            $resolved = [CloudPathResolver]::Resolve($cloudPath)

            $resolved.CommandName | Should -Be 'Get-AzureDiskData'
            $resolved.ArgumentMap.ResourceGroup | Should -Be 'prod-rg'
            $resolved.ArgumentMap.Name | Should -Be 'disk-01'
        }
    }

    It 'Resolves AWS instance path correctly' {
        InModuleScope PSCumulus {
            $cloudPath = [CloudPath]::Parse('AWS:\us-east-1\Instances\i-12345')
            $resolved = [CloudPathResolver]::Resolve($cloudPath)

            $resolved.CommandName | Should -Be 'Get-AWSInstanceData'
            $resolved.ArgumentMap.Region | Should -Be 'us-east-1'
            $resolved.ArgumentMap.Name | Should -Be 'i-12345'
        }
    }

    It 'Resolves GCP instance path correctly' {
        InModuleScope PSCumulus {
            $cloudPath = [CloudPath]::Parse('GCP:\my-project\Instances\gcp-vm')
            $resolved = [CloudPathResolver]::Resolve($cloudPath)

            $resolved.CommandName | Should -Be 'Get-GCPInstanceData'
            $resolved.ArgumentMap.Project | Should -Be 'my-project'
            $resolved.ArgumentMap.Name | Should -Be 'gcp-vm'
        }
    }

    It 'Resolves kind-level path without resource name' {
        InModuleScope PSCumulus {
            $cloudPath = [CloudPath]::Parse('Azure:\prod-rg\Storage')
            $resolved = [CloudPathResolver]::Resolve($cloudPath)

            $resolved.CommandName | Should -Be 'Get-AzureStorageData'
            $resolved.ArgumentMap.ResourceGroup | Should -Be 'prod-rg'
            $resolved.ArgumentMap.ContainsKey('Name') | Should -Be $false
        }
    }
}

Describe 'CloudPathResolver.GetBackendCommand' {
    It 'Returns correct command for each kind' {
        InModuleScope PSCumulus {
            [CloudPathResolver]::GetBackendCommand('Azure', 'Instances') | Should -Be 'Get-AzureInstanceData'
            [CloudPathResolver]::GetBackendCommand('Azure', 'Disks') | Should -Be 'Get-AzureDiskData'
            [CloudPathResolver]::GetBackendCommand('Azure', 'Storage') | Should -Be 'Get-AzureStorageData'
            [CloudPathResolver]::GetBackendCommand('Azure', 'Network') | Should -Be 'Get-AzureNetworkData'
            [CloudPathResolver]::GetBackendCommand('Azure', 'Functions') | Should -Be 'Get-AzureFunctionData'
            [CloudPathResolver]::GetBackendCommand('Azure', 'Tags') | Should -Be 'Get-AzureTagData'

            [CloudPathResolver]::GetBackendCommand('AWS', 'Instances') | Should -Be 'Get-AWSInstanceData'
            [CloudPathResolver]::GetBackendCommand('GCP', 'Instances') | Should -Be 'Get-GCPInstanceData'
        }
    }

    It 'Throws on invalid kind' {
        InModuleScope PSCumulus {
            { [CloudPathResolver]::GetBackendCommand('Azure', 'Invalid') } | Should -Throw
        }
    }
}

Describe 'CloudPathResolver.GetScopeArgument' {
    It 'Returns correct scope argument for each provider' {
        InModuleScope PSCumulus {
            $azureScope = [CloudPathResolver]::GetScopeArgument('Azure', 'prod-rg')
            $azureScope.ResourceGroup | Should -Be 'prod-rg'
            $azureScope.Count | Should -Be 1

            $awsScope = [CloudPathResolver]::GetScopeArgument('AWS', 'us-east-1')
            $awsScope.Region | Should -Be 'us-east-1'
            $awsScope.Count | Should -Be 1

            $gcpScope = [CloudPathResolver]::GetScopeArgument('GCP', 'my-project')
            $gcpScope.Project | Should -Be 'my-project'
            $gcpScope.Count | Should -Be 1
        }
    }

    It 'Throws on invalid provider' {
        InModuleScope PSCumulus {
            { [CloudPathResolver]::GetScopeArgument('Invalid', 'scope') } | Should -Throw
        }
    }
}
