# demo-setup.ps1
# Injects fake multi-cloud data into the PSCumulus module scope for demo purposes.
#
# -- From PSGallery (talk demo) ------------------------------------------------
#
#   Install-Module PSCumulus -Scope CurrentUser
#   Import-Module PSCumulus
#   Invoke-WebRequest https://raw.githubusercontent.com/adilio/PSCumulus/main/scripts/demo-setup.ps1 -OutFile demo-setup.ps1
#   . ./demo-setup.ps1
#
# -- From source (development) -------------------------------------------------
#
#   Import-Module ./PSCumulus.psd1 -Force
#   . ./scripts/demo-setup.ps1
#
# -- Talk flow: slide-by-slide commands ----------------------------------------
# Mirrors the live demo in talk/presentation.md (Slides 7 and 8).
#
# -- DEMO A - Native vs. Unified (Slide 7) -------------------------------------
#
#   # Native (shown, NOT run on stage)
#   Get-AzVM
#   Get-EC2Instance
#   gcloud compute instances list --format=json
#
#   # Unified (run live)
#   Connect-Cloud     -Provider AWS, Azure, GCP
#   Get-CloudContext
#   Get-CloudInstance -Provider Azure -ResourceGroup prod-rg
#   Get-CloudInstance -Provider AWS   -Region us-east-1
#   Get-CloudInstance -Provider GCP   -Project contoso-prod
#
# -- DEMO B - One Pipe, Three Clouds (Slide 8) ---------------------------------
#
#   Get-CloudInstance -All
#
#   Get-CloudInstance -All |
#     Where-Object { -not $_.Tags['owner'] } |
#     Format-Table Name, Provider, Region -AutoSize
#
#   Show-FleetHealth
#   Get-CloudInstance -All | Group-Object Provider | Select-Object Name, Count
#
# -- Bonus pre-built queries (optional, if time allows) ------------------------
#
#   Find-UntaggedInstances   # tagging compliance: missing owner tag
#   Find-StaleInstances      # cost waste: stopped/terminated > 30 days
#   Show-FleetHealth         # running vs not-running by provider
#   Show-CostCenterRollup    # instance count per cost-center tag
#   Find-OldestInstances     # oldest five instances across all clouds
#   Invoke-AllDemoQueries    # run all of the above in sequence
#
# -- Per-resource spot checks (Slide 11 reference commands) --------------------
#
#   Get-CloudStorage  -Provider Azure -ResourceGroup prod-rg
#   Get-CloudStorage  -Provider AWS   -Region us-east-1
#   Get-CloudStorage  -Provider GCP   -Project contoso-prod
#
#   Get-CloudDisk     -Provider Azure -ResourceGroup prod-rg
#   Get-CloudDisk     -Provider AWS   -Region us-east-1
#   Get-CloudDisk     -Provider GCP   -Project contoso-prod
#
#   Get-CloudNetwork  -Provider Azure -ResourceGroup prod-rg
#   Get-CloudNetwork  -Provider AWS   -Region us-east-1
#   Get-CloudNetwork  -Provider GCP   -Project contoso-prod
#
#   Get-CloudFunction -Provider Azure -ResourceGroup prod-rg
#   Get-CloudFunction -Provider AWS   -Region us-east-1
#   Get-CloudFunction -Provider GCP   -Project contoso-prod
#
#   Get-CloudTag      -Provider Azure -ResourceId '/subscriptions/00000000/resourceGroups/prod-rg/providers/Microsoft.Compute/virtualMachines/web-server-01'
#   Get-CloudTag      -Provider AWS   -ResourceId 'i-0a1b2c3d4e5f00001'
#   Get-CloudTag      -Provider GCP   -Project contoso-prod -Resource 'instances/prod-web-01'
#
# -- Start / Stop (write path) -------------------------------------------------
#
#   Start-CloudInstance -Provider Azure -Name web-server-01   -ResourceGroup prod-rg
#   Start-CloudInstance -Provider AWS   -InstanceId i-0a1b2c3d4e5f00003 -Region us-east-1
#   Start-CloudInstance -Provider GCP   -Name prod-worker-01  -Zone us-central1-c -Project contoso-prod
#
#   Stop-CloudInstance  -Provider Azure -Name api-server-01   -ResourceGroup prod-rg
#   Stop-CloudInstance  -Provider AWS   -InstanceId i-0a1b2c3d4e5f00002 -Region us-east-1
#   Stop-CloudInstance  -Provider GCP   -Name prod-api-01     -Zone us-central1-b -Project contoso-prod
#
# -- Cleanup -------------------------------------------------------------------
#
#   Remove-DemoSetup            # unload module, remove demo functions
#   Remove-DemoSetup -Uninstall # also uninstalls PSCumulus from the system
#
# -----------------------------------------------------------------------------

$module = Get-Module PSCumulus
if (-not $module) {
    Write-Error "PSCumulus is not loaded. Run: Import-Module ./PSCumulus.psd1 -Force"
    return
}

$module.Invoke({

    # -- Connect backends ------------------------------------------------------

    Set-Item -Path 'Function:Connect-AzureBackend' -Value {
        [pscustomobject]@{
            PSTypeName   = 'PSCumulus.ConnectionResult'
            Provider     = 'Azure'
            Connected    = $true
            ContextName  = 'contoso-production (00000000-0000-0000-0000-000000000001)'
            TenantId     = '00000000-0000-0000-0000-000000000002'
            Subscription = 'contoso-production'
            Account      = 'adil@contoso.com'
            Region       = 'eastus'
        }
    }

    Set-Item -Path 'Function:Connect-AWSBackend' -Value {
        param([string]$Region)
        [pscustomobject]@{
            PSTypeName  = 'PSCumulus.ConnectionResult'
            Provider    = 'AWS'
            Connected   = $true
            Account     = '123456789012'
            ProfileName = 'default'
            Region      = if ($Region) { $Region } else { 'us-east-1' }
        }
    }

    Set-Item -Path 'Function:Connect-GCPBackend' -Value {
        param([string]$Project)
        [pscustomobject]@{
            PSTypeName = 'PSCumulus.ConnectionResult'
            Provider   = 'GCP'
            Connected  = $true
            Account    = 'adil@contoso-prod.iam.gserviceaccount.com'
            Project    = if ($Project) { $Project } else { 'contoso-prod' }
            Region     = 'us-central1'
        }
    }

    # -- Instances -------------------------------------------------------------

    Set-Item -Path 'Function:Get-AzureInstanceData' -Value {
        param([string]$ResourceGroup)
        $null = $ResourceGroup
        ConvertTo-CloudRecord -Name 'web-server-01'  -Provider Azure -Region 'eastus'  -Status 'Running' -Size 'Standard_D2s_v3' -CreatedAt ([datetime]'2025-03-15') -Tags @{ environment = 'prod';    team = 'platform'; 'cost-center' = 'eng-001'; owner = 'platform-team' } -Metadata @{ ResourceGroup = 'prod-rg'; VmId = 'aaaaaaaa-0001-0001-0001-aaaaaaaaaaaa'; OsType = 'Linux' }
        ConvertTo-CloudRecord -Name 'api-server-01'  -Provider Azure -Region 'eastus'  -Status 'Running' -Size 'Standard_D4s_v3' -CreatedAt ([datetime]'2024-11-01') -Tags @{ environment = 'prod';    team = 'platform'; 'cost-center' = 'eng-001'; owner = 'platform-team' } -Metadata @{ ResourceGroup = 'prod-rg'; VmId = 'aaaaaaaa-0002-0002-0002-aaaaaaaaaaaa'; OsType = 'Linux' }
        ConvertTo-CloudRecord -Name 'db-server-01'   -Provider Azure -Region 'eastus2' -Status 'Stopped' -Size 'Standard_E8s_v3' -CreatedAt ([datetime]'2024-08-20') -Tags @{ environment = 'staging'; team = 'data';     'cost-center' = 'eng-002' }                                    -Metadata @{ ResourceGroup = 'prod-rg'; VmId = 'aaaaaaaa-0003-0003-0003-aaaaaaaaaaaa'; OsType = 'Windows' }
    }

    Set-Item -Path 'Function:Get-AWSInstanceData' -Value {
        param([string]$Region)
        $null = $Region
        ConvertTo-CloudRecord -Name 'prod-web-01'    -Provider AWS -Region 'us-east-1a' -Status 'Running' -Size 't3.medium'  -CreatedAt ([datetime]'2026-01-10') -Tags @{ environment = 'prod';    team = 'platform'; 'cost-center' = 'eng-001'; owner = 'platform-team' } -Metadata @{ InstanceId = 'i-0a1b2c3d4e5f00001'; PrivateIpAddress = '10.0.1.10'; PublicIpAddress = '54.210.10.1'; VpcId = 'vpc-0a1b2c3d'; SubnetId = 'subnet-0a1b2c3d' }
        ConvertTo-CloudRecord -Name 'prod-api-01'    -Provider AWS -Region 'us-east-1b' -Status 'Running' -Size 't3.large'   -CreatedAt ([datetime]'2025-06-01') -Tags @{ environment = 'prod';    team = 'platform'; 'cost-center' = 'eng-001'; owner = 'platform-team' } -Metadata @{ InstanceId = 'i-0a1b2c3d4e5f00002'; PrivateIpAddress = '10.0.2.10'; PublicIpAddress = '54.210.10.2'; VpcId = 'vpc-0a1b2c3d'; SubnetId = 'subnet-1a2b3c4d' }
        ConvertTo-CloudRecord -Name 'prod-worker-01' -Provider AWS -Region 'us-east-1c' -Status 'Stopped' -Size 't3.xlarge'  -CreatedAt ([datetime]'2024-09-30') -Tags @{ environment = 'staging'; team = 'workers';  'cost-center' = 'eng-003' }                                    -Metadata @{ InstanceId = 'i-0a1b2c3d4e5f00003'; PrivateIpAddress = '10.0.3.10'; PublicIpAddress = $null;         VpcId = 'vpc-0a1b2c3d'; SubnetId = 'subnet-2a3b4c5d' }
    }

    Set-Item -Path 'Function:Get-GCPInstanceData' -Value {
        param([string]$Project)
        $null = $Project
        ConvertTo-CloudRecord -Name 'prod-web-01'    -Provider GCP -Region 'us-central1-a' -Status 'Running'    -Size 'n2-standard-2' -CreatedAt ([datetime]'2025-11-20') -Tags @{ environment = 'prod';    team = 'platform'; 'cost-center' = 'eng-001'; owner = 'platform-team' } -Metadata @{ Project = 'contoso-prod'; Id = '1234567890000001'; Zone = 'us-central1-a'; PrivateIpAddress = '10.128.0.10'; PublicIpAddress = '34.72.10.1'; Labels = @{ env = 'production'; team = 'platform' } }
        ConvertTo-CloudRecord -Name 'prod-api-01'    -Provider GCP -Region 'us-central1-b' -Status 'Running'    -Size 'n2-standard-4' -CreatedAt ([datetime]'2025-04-08') -Tags @{ environment = 'prod';    team = 'platform'; 'cost-center' = 'eng-001'; owner = 'platform-team' } -Metadata @{ Project = 'contoso-prod'; Id = '1234567890000002'; Zone = 'us-central1-b'; PrivateIpAddress = '10.128.0.11'; PublicIpAddress = '34.72.10.2'; Labels = @{ env = 'production'; team = 'platform' } }
        ConvertTo-CloudRecord -Name 'prod-worker-01' -Provider GCP -Region 'us-central1-c' -Status 'Terminated' -Size 'n2-standard-8' -CreatedAt ([datetime]'2024-07-14') -Tags @{ environment = 'staging'; team = 'workers';  'cost-center' = 'eng-003' }                                    -Metadata @{ Project = 'contoso-prod'; Id = '1234567890000003'; Zone = 'us-central1-c'; PrivateIpAddress = '10.128.0.12'; PublicIpAddress = $null;        Labels = @{ env = 'production'; team = 'workers' } }
    }

    # -- Storage ---------------------------------------------------------------

    Set-Item -Path 'Function:Get-AzureStorageData' -Value {
        param([string]$ResourceGroup)
        $null = $ResourceGroup
        ConvertTo-CloudRecord -Name 'contosoproddata' -Provider Azure -Region 'eastus'  -Status 'available' -Size 'Standard_LRS' -CreatedAt ([datetime]'2024-09-01') -Metadata @{ ResourceGroup = 'prod-rg'; Kind = 'StorageV2';   AccessTier = 'Hot' }
        ConvertTo-CloudRecord -Name 'contosobackups'  -Provider Azure -Region 'eastus2' -Status 'available' -Size 'Standard_GRS' -CreatedAt ([datetime]'2024-09-01') -Metadata @{ ResourceGroup = 'prod-rg'; Kind = 'BlobStorage'; AccessTier = 'Cool' }
    }

    Set-Item -Path 'Function:Get-AWSStorageData' -Value {
        param([string]$Region)
        $null = $Region
        ConvertTo-CloudRecord -Name 'contoso-prod-assets'  -Provider AWS -Region 'us-east-1' -Status 'Available' -CreatedAt ([datetime]'2024-09-01') -Metadata @{ BucketName = 'contoso-prod-assets' }
        ConvertTo-CloudRecord -Name 'contoso-prod-backups' -Provider AWS -Region 'us-west-2' -Status 'Available' -CreatedAt ([datetime]'2024-09-01') -Metadata @{ BucketName = 'contoso-prod-backups' }
    }

    Set-Item -Path 'Function:Get-GCPStorageData' -Value {
        param([string]$Project)
        $null = $Project
        ConvertTo-CloudRecord -Name 'contoso-prod-assets'  -Provider GCP -Region 'US-CENTRAL1' -Status 'Available' -Size 'STANDARD' -CreatedAt ([datetime]'2024-09-01') -Metadata @{ Project = 'contoso-prod'; StorageClass = 'STANDARD'; Location = 'US-CENTRAL1' }
        ConvertTo-CloudRecord -Name 'contoso-prod-backups' -Provider GCP -Region 'US'           -Status 'Available' -Size 'NEARLINE' -CreatedAt ([datetime]'2024-09-01') -Metadata @{ Project = 'contoso-prod'; StorageClass = 'NEARLINE'; Location = 'US' }
    }

    # -- Disks -----------------------------------------------------------------

    Set-Item -Path 'Function:Get-AzureDiskData' -Value {
        param([string]$ResourceGroup)
        $null = $ResourceGroup
        ConvertTo-CloudRecord -Name 'web-server-01_OsDisk_1' -Provider Azure -Region 'eastus'  -Status 'Attached'   -Size '128 GB' -CreatedAt ([datetime]'2024-11-01') -Metadata @{ ResourceGroup = 'prod-rg'; DiskSizeGB = 128; OsType = 'Linux';   Sku = 'Premium_LRS' }
        ConvertTo-CloudRecord -Name 'api-server-01_OsDisk_1' -Provider Azure -Region 'eastus'  -Status 'Attached'   -Size '128 GB' -CreatedAt ([datetime]'2024-11-01') -Metadata @{ ResourceGroup = 'prod-rg'; DiskSizeGB = 128; OsType = 'Linux';   Sku = 'Premium_LRS' }
        ConvertTo-CloudRecord -Name 'data-disk-prod-01'       -Provider Azure -Region 'eastus'  -Status 'Attached'   -Size '512 GB' -CreatedAt ([datetime]'2024-10-01') -Metadata @{ ResourceGroup = 'prod-rg'; DiskSizeGB = 512; OsType = $null;    Sku = 'Premium_LRS' }
        ConvertTo-CloudRecord -Name 'db-server-01_OsDisk_1'   -Provider Azure -Region 'eastus2' -Status 'Unattached' -Size '256 GB' -CreatedAt ([datetime]'2024-10-15') -Metadata @{ ResourceGroup = 'prod-rg'; DiskSizeGB = 256; OsType = 'Windows'; Sku = 'Premium_LRS' }
    }

    Set-Item -Path 'Function:Get-AWSDiskData' -Value {
        param([string]$Region)
        $null = $Region
        ConvertTo-CloudRecord -Name 'prod-web-root'        -Provider AWS -Region 'us-east-1a' -Status 'in-use'    -Size '100 GB' -CreatedAt ([datetime]'2024-11-01') -Metadata @{ VolumeId = 'vol-0a1b2c3d00000001'; VolumeType = 'gp3'; Encrypted = $true;  InstanceId = 'i-0a1b2c3d4e5f00001' }
        ConvertTo-CloudRecord -Name 'prod-api-root'        -Provider AWS -Region 'us-east-1b' -Status 'in-use'    -Size '100 GB' -CreatedAt ([datetime]'2024-11-01') -Metadata @{ VolumeId = 'vol-0a1b2c3d00000002'; VolumeType = 'gp3'; Encrypted = $true;  InstanceId = 'i-0a1b2c3d4e5f00002' }
        ConvertTo-CloudRecord -Name 'prod-data-store'      -Provider AWS -Region 'us-east-1a' -Status 'in-use'    -Size '500 GB' -CreatedAt ([datetime]'2024-10-01') -Metadata @{ VolumeId = 'vol-0a1b2c3d00000003'; VolumeType = 'io1'; Encrypted = $true;  InstanceId = 'i-0a1b2c3d4e5f00001' }
        ConvertTo-CloudRecord -Name 'vol-0a1b2c3d00000004' -Provider AWS -Region 'us-east-1c' -Status 'available' -Size '100 GB' -CreatedAt ([datetime]'2024-10-15') -Metadata @{ VolumeId = 'vol-0a1b2c3d00000004'; VolumeType = 'gp3'; Encrypted = $false; InstanceId = $null }
    }

    Set-Item -Path 'Function:Get-GCPDiskData' -Value {
        param([string]$Project)
        $null = $Project
        ConvertTo-CloudRecord -Name 'prod-web-01'    -Provider GCP -Region 'us-central1-a' -Status 'Ready' -Size '100 GB' -CreatedAt ([datetime]'2024-11-01') -Metadata @{ Project = 'contoso-prod'; Zone = 'us-central1-a'; DiskType = 'pd-balanced'; SizeGb = '100' }
        ConvertTo-CloudRecord -Name 'prod-api-01'    -Provider GCP -Region 'us-central1-b' -Status 'Ready' -Size '100 GB' -CreatedAt ([datetime]'2024-11-01') -Metadata @{ Project = 'contoso-prod'; Zone = 'us-central1-b'; DiskType = 'pd-balanced'; SizeGb = '100' }
        ConvertTo-CloudRecord -Name 'prod-data-disk' -Provider GCP -Region 'us-central1-a' -Status 'Ready' -Size '500 GB' -CreatedAt ([datetime]'2024-10-01') -Metadata @{ Project = 'contoso-prod'; Zone = 'us-central1-a'; DiskType = 'pd-ssd';      SizeGb = '500' }
    }

    # -- Networks --------------------------------------------------------------

    Set-Item -Path 'Function:Get-AzureNetworkData' -Value {
        param([string]$ResourceGroup)
        $null = $ResourceGroup
        ConvertTo-CloudRecord -Name 'prod-vnet' -Provider Azure -Region 'eastus' -Status 'Succeeded' -Size '10.0.0.0/16'   -Metadata @{ ResourceGroup = 'prod-rg'; AddressSpace = @('10.0.0.0/16'); SubnetCount = 3 }
        ConvertTo-CloudRecord -Name 'dev-vnet'  -Provider Azure -Region 'eastus' -Status 'Succeeded' -Size '10.1.0.0/16'   -Metadata @{ ResourceGroup = 'dev-rg';  AddressSpace = @('10.1.0.0/16'); SubnetCount = 2 }
    }

    Set-Item -Path 'Function:Get-AWSNetworkData' -Value {
        param([string]$Region)
        ConvertTo-CloudRecord -Name 'prod-vpc' -Provider AWS -Region $Region -Status 'available' -Size '10.0.0.0/16'   -Metadata @{ VpcId = 'vpc-0a1b2c3d4e5f0001'; IsDefault = $false; CidrBlock = '10.0.0.0/16' }
        ConvertTo-CloudRecord -Name 'default'  -Provider AWS -Region $Region -Status 'available' -Size '172.31.0.0/16' -Metadata @{ VpcId = 'vpc-0a1b2c3d4e5f0002'; IsDefault = $true;  CidrBlock = '172.31.0.0/16' }
    }

    Set-Item -Path 'Function:Get-GCPNetworkData' -Value {
        param([string]$Project)
        $null = $Project
        ConvertTo-CloudRecord -Name 'prod-network' -Provider GCP -Region 'global' -Status 'Available' -Metadata @{ Project = 'contoso-prod'; AutoCreateSubnetworks = $false; SubnetworkMode = 'custom' }
        ConvertTo-CloudRecord -Name 'default'       -Provider GCP -Region 'global' -Status 'Available' -Metadata @{ Project = 'contoso-prod'; AutoCreateSubnetworks = $true;  SubnetworkMode = 'auto' }
    }

    # -- Tags / Labels ---------------------------------------------------------

    Set-Item -Path 'Function:Get-AzureTagData' -Value {
        param([string]$ResourceId)
        $name = ($ResourceId -split '/')[-1]
        ConvertTo-CloudRecord -Name $name -Provider Azure -Metadata @{
            ResourceId = $ResourceId
            Tags       = @{ env = 'production'; team = 'platform'; 'cost-center' = 'eng-001'; app = 'contoso-web' }
        }
    }

    Set-Item -Path 'Function:Get-AWSTagData' -Value {
        param([string]$ResourceId)
        ConvertTo-CloudRecord -Name $ResourceId -Provider AWS -Metadata @{
            ResourceId = $ResourceId
            Tags       = @{ Name = 'prod-web-01'; env = 'production'; team = 'platform'; 'cost-center' = 'eng-001' }
        }
    }

    Set-Item -Path 'Function:Get-GCPTagData' -Value {
        param([string]$Project, [string]$Resource)
        $resourceName = ($Resource -split '/')[-1]
        ConvertTo-CloudRecord -Name $resourceName -Provider GCP -Metadata @{
            Project  = if ($Project) { $Project } else { 'contoso-prod' }
            Resource = $Resource
            Labels   = @{ env = 'production'; team = 'platform'; 'cost-center' = 'eng-001' }
        }
    }

    # -- Functions -------------------------------------------------------------

    Set-Item -Path 'Function:Get-AzureFunctionData' -Value {
        param([string]$ResourceGroup)
        $null = $ResourceGroup
        ConvertTo-CloudRecord -Name 'process-orders'     -Provider Azure -Region 'eastus' -Status 'Running' -Size 'dotnet' -CreatedAt ([datetime]'2024-12-01') -Metadata @{ ResourceGroup = 'prod-rg'; Runtime = 'dotnet';  RuntimeVersion = '8';    OSType = 'Linux'; Kind = 'functionapp' }
        ConvertTo-CloudRecord -Name 'send-notifications' -Provider Azure -Region 'eastus' -Status 'Running' -Size 'node'   -CreatedAt ([datetime]'2024-12-01') -Metadata @{ ResourceGroup = 'prod-rg'; Runtime = 'node';    RuntimeVersion = '20';   OSType = 'Linux'; Kind = 'functionapp' }
        ConvertTo-CloudRecord -Name 'resize-images'      -Provider Azure -Region 'eastus' -Status 'Running' -Size 'python' -CreatedAt ([datetime]'2025-01-10') -Metadata @{ ResourceGroup = 'prod-rg'; Runtime = 'python';  RuntimeVersion = '3.11'; OSType = 'Linux'; Kind = 'functionapp' }
    }

    Set-Item -Path 'Function:Get-AWSFunctionData' -Value {
        param([string]$Region)
        $r = if ($Region) { $Region } else { 'us-east-1' }
        ConvertTo-CloudRecord -Name 'ProcessOrders'     -Provider AWS -Region $r -Status 'Active' -Size 'nodejs18.x' -CreatedAt ([datetime]'2024-12-01') -Metadata @{ FunctionArn = "arn:aws:lambda:${r}:123456789012:function:ProcessOrders";    Runtime = 'nodejs18.x'; Handler = 'index.handler';   MemorySize = 512;  Timeout = 30 }
        ConvertTo-CloudRecord -Name 'SendNotifications' -Provider AWS -Region $r -Status 'Active' -Size 'python3.11' -CreatedAt ([datetime]'2024-12-01') -Metadata @{ FunctionArn = "arn:aws:lambda:${r}:123456789012:function:SendNotifications"; Runtime = 'python3.11'; Handler = 'main.handler';    MemorySize = 256;  Timeout = 15 }
        ConvertTo-CloudRecord -Name 'ResizeImages'      -Provider AWS -Region $r -Status 'Active' -Size 'python3.11' -CreatedAt ([datetime]'2025-01-10') -Metadata @{ FunctionArn = "arn:aws:lambda:${r}:123456789012:function:ResizeImages";      Runtime = 'python3.11'; Handler = 'resize.handler';  MemorySize = 1024; Timeout = 60 }
    }

    Set-Item -Path 'Function:Get-GCPFunctionData' -Value {
        param([string]$Project)
        $p = if ($Project) { $Project } else { 'contoso-prod' }
        ConvertTo-CloudRecord -Name 'process-orders'     -Provider GCP -Region 'us-central1' -Status 'Active' -Size 'nodejs18'  -CreatedAt ([datetime]'2024-12-01') -Metadata @{ Project = $p; Runtime = 'nodejs18';  EntryPoint = 'processOrders';    FullName = "projects/$p/locations/us-central1/functions/process-orders" }
        ConvertTo-CloudRecord -Name 'send-notifications' -Provider GCP -Region 'us-central1' -Status 'Active' -Size 'python311' -CreatedAt ([datetime]'2024-12-01') -Metadata @{ Project = $p; Runtime = 'python311'; EntryPoint = 'send_notifications'; FullName = "projects/$p/locations/us-central1/functions/send-notifications" }
        ConvertTo-CloudRecord -Name 'resize-images'      -Provider GCP -Region 'us-central1' -Status 'Active' -Size 'python311' -CreatedAt ([datetime]'2025-01-10') -Metadata @{ Project = $p; Runtime = 'python311'; EntryPoint = 'resize_image';        FullName = "projects/$p/locations/us-central1/functions/resize-images" }
    }

    # -- Start / Stop ----------------------------------------------------------

    Set-Item -Path 'Function:Start-AzureInstance' -Value {
        param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$ResourceGroup)
        Start-Sleep -Milliseconds 600
        ConvertTo-CloudRecord -Name $Name -Provider Azure -Status 'Starting' -Metadata @{ ResourceGroup = $ResourceGroup }
    }

    Set-Item -Path 'Function:Stop-AzureInstance' -Value {
        param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$ResourceGroup)
        Start-Sleep -Milliseconds 600
        ConvertTo-CloudRecord -Name $Name -Provider Azure -Status 'Stopping' -Metadata @{ ResourceGroup = $ResourceGroup }
    }

    Set-Item -Path 'Function:Start-AWSInstance' -Value {
        param([Parameter(Mandatory)][string]$InstanceId, [string]$Region)
        Start-Sleep -Milliseconds 600
        ConvertTo-CloudRecord -Name $InstanceId -Provider AWS -Region $Region -Status 'Starting' -Metadata @{ InstanceId = $InstanceId }
    }

    Set-Item -Path 'Function:Stop-AWSInstance' -Value {
        param([Parameter(Mandatory)][string]$InstanceId, [string]$Region)
        Start-Sleep -Milliseconds 600
        ConvertTo-CloudRecord -Name $InstanceId -Provider AWS -Region $Region -Status 'Stopping' -Metadata @{ InstanceId = $InstanceId }
    }

    Set-Item -Path 'Function:Start-GCPInstance' -Value {
        param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Zone, [string]$Project)
        Start-Sleep -Milliseconds 600
        ConvertTo-CloudRecord -Name $Name -Provider GCP -Region $Zone -Status 'Starting' -Metadata @{ Project = $Project; Zone = $Zone }
    }

    Set-Item -Path 'Function:Stop-GCPInstance' -Value {
        param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Zone, [string]$Project)
        Start-Sleep -Milliseconds 600
        ConvertTo-CloudRecord -Name $Name -Provider GCP -Region $Zone -Status 'Stopping' -Metadata @{ Project = $Project; Zone = $Zone }
    }

    # -- Seed context via Connect-Cloud ----------------------------------------
    # Call the real command so context is established the same way a user would.
    # Suppress pipeline output -- the demo presenter calls it interactively.

    $null = Connect-Cloud -Provider Azure, AWS, GCP
})

Write-Host "PSCumulus demo mode active. All commands return simulated data." -ForegroundColor Cyan
Write-Host "Demo queries: Find-UntaggedInstances, Find-StaleInstances, Show-FleetHealth, Show-CostCenterRollup, Find-OldestInstances, Invoke-AllDemoQueries" -ForegroundColor DarkCyan
Write-Host "Cleanup: Remove-DemoSetup [-Uninstall]" -ForegroundColor DarkCyan

# -- Demo query functions ------------------------------------------------------
# Pre-built queries for the talk. Each can be called individually or run all
# at once with Invoke-AllDemoQueries.

function Find-UntaggedInstances {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Demo shortcut name is intentionally audience-facing.')]
    param()

    # Tagging compliance -- instances missing a required owner tag
    Get-CloudInstance -All | Where-Object { -not $_.Tags['owner'] }
}

function Find-StaleInstances {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Demo shortcut name is intentionally audience-facing.')]
    param()

    # Cost waste candidates -- stopped/terminated instances older than 30 days
    $cutoff = (Get-Date).AddDays(-30)
    Get-CloudInstance -All |
        Where-Object { $_.Status -ne 'Running' -and $_.CreatedAt -lt $cutoff } |
        Select-Object Name, Provider, Status, CreatedAt |
        Format-Table -AutoSize
}

function Show-FleetHealth {
    # Fleet health -- running vs not-running breakdown by provider
    Get-CloudInstance -All |
        Group-Object Provider, Status |
        Select-Object Name, Count |
        Sort-Object Count -Descending |
        Format-Table -AutoSize
}

function Show-CostCenterRollup {
    # Cost-center rollup -- instance count per cost center across all clouds
    Get-CloudInstance -All |
        Group-Object { $_.Tags['cost-center'] } |
        Select-Object Name, Count |
        Sort-Object Count -Descending |
        Format-Table -AutoSize
}

function Find-OldestInstances {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Demo shortcut name is intentionally audience-facing.')]
    param()

    # Legacy/forgotten VM candidates -- oldest five instances across all clouds
    Get-CloudInstance -All |
        Where-Object { $_.CreatedAt } |
        Sort-Object CreatedAt |
        Select-Object Name, Provider, Region, CreatedAt -First 5 |
        Format-Table -AutoSize
}

function Remove-DemoSetup {
    [CmdletBinding(SupportsShouldProcess)]
    # Removes all demo functions, unloads the module, and optionally uninstalls it.
    param(
        [switch]$Uninstall
    )

    $demoFunctions = @(
        'Find-UntaggedInstances'
        'Find-StaleInstances'
        'Show-FleetHealth'
        'Show-CostCenterRollup'
        'Find-OldestInstances'
        'Invoke-AllDemoQueries'
        'Remove-DemoSetup'
    )

    foreach ($fn in $demoFunctions) {
        if (Get-Item -Path "Function:$fn" -ErrorAction SilentlyContinue) {
            if ($PSCmdlet.ShouldProcess("Function:$fn", 'Remove demo function')) {
                Remove-Item -Path "Function:$fn"
            }
        }
    }

    if ($PSCmdlet.ShouldProcess('PSCumulus', 'Remove module')) {
        Remove-Module PSCumulus -Force -ErrorAction SilentlyContinue
    }

    if ($Uninstall) {
        if ($PSCmdlet.ShouldProcess('PSCumulus', 'Uninstall module')) {
            Uninstall-Module PSCumulus -AllVersions -Force -ErrorAction SilentlyContinue
        }
        Write-Host "PSCumulus uninstalled." -ForegroundColor Yellow
    } else {
        Write-Host "PSCumulus unloaded. Run 'Uninstall-Module PSCumulus' to remove it fully." -ForegroundColor Yellow
    }
}

function Invoke-AllDemoQueries {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Demo shortcut name is intentionally audience-facing.')]
    param()

    # Each section prints the underlying pipeline, then the result. Queries are
    # inlined (not delegated to the Find-* / Show-* helpers) so the audience
    # sees the real PowerShell -- not a wrapper.

    function Write-DemoQuery {
        param([string]$Title, [string]$Helper, [string]$Query)
        Write-Host "`n-- $Title " -ForegroundColor Cyan -NoNewline
        Write-Host ('-' * [Math]::Max(0, 60 - $Title.Length)) -ForegroundColor Cyan
        Write-Host ''
        if ($Helper) {
            Write-Host "PS> # shortcut: $Helper" -ForegroundColor DarkGreen
        }
        foreach ($line in ($Query -split "`n")) {
            Write-Host "PS> $line" -ForegroundColor DarkGray
        }
        Write-Host ''
    }

    Write-DemoQuery 'Tagging compliance' 'Find-UntaggedInstances' @'
Get-CloudInstance -All |
    Where-Object { -not $_.Tags['owner'] } |
    Format-Table Name, Provider, Region -AutoSize
'@
    Get-CloudInstance -All |
        Where-Object { -not $_.Tags['owner'] } |
        Format-Table Name, Provider, Region -AutoSize

    Write-DemoQuery 'Stale instances (stopped/terminated > 30 days)' 'Find-StaleInstances' @'
$cutoff = (Get-Date).AddDays(-30)
Get-CloudInstance -All |
    Where-Object { $_.Status -ne 'Running' -and $_.CreatedAt -lt $cutoff } |
    Select-Object Name, Provider, Status, CreatedAt |
    Format-Table -AutoSize
'@
    $cutoff = (Get-Date).AddDays(-30)
    Get-CloudInstance -All |
        Where-Object { $_.Status -ne 'Running' -and $_.CreatedAt -lt $cutoff } |
        Select-Object Name, Provider, Status, CreatedAt |
        Format-Table -AutoSize

    Write-DemoQuery 'Fleet health' 'Show-FleetHealth' @'
Get-CloudInstance -All |
    Group-Object Provider, Status |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize
'@
    Get-CloudInstance -All |
        Group-Object Provider, Status |
        Select-Object Name, Count |
        Sort-Object Count -Descending |
        Format-Table -AutoSize

    Write-DemoQuery 'Cost-center rollup' 'Show-CostCenterRollup' @'
Get-CloudInstance -All |
    Group-Object { $_.Tags['cost-center'] } |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize
'@
    Get-CloudInstance -All |
        Group-Object { $_.Tags['cost-center'] } |
        Select-Object Name, Count |
        Sort-Object Count -Descending |
        Format-Table -AutoSize

    Write-DemoQuery 'Oldest instances' 'Find-OldestInstances' @'
Get-CloudInstance -All |
    Where-Object { $_.CreatedAt } |
    Sort-Object CreatedAt |
    Select-Object Name, Provider, Region, CreatedAt -First 5 |
    Format-Table -AutoSize
'@
    Get-CloudInstance -All |
        Where-Object { $_.CreatedAt } |
        Sort-Object CreatedAt |
        Select-Object Name, Provider, Region, CreatedAt -First 5 |
        Format-Table -AutoSize
}
