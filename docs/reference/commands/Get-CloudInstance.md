---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Get-CloudInstance
---

# Get-CloudInstance

## SYNOPSIS

Gets compute instances from a selected cloud provider.

## SYNTAX

### Azure (Default)

```
Get-CloudInstance -ResourceGroup <string> [-Provider <string>] [-Name <string>] [-Detailed]
 [-Status <CloudInstanceStatus>] [-Tag <hashtable>] [<CommonParameters>]
```

### GCP

```
Get-CloudInstance -Project <string> [-Provider <string>] [-Name <string>] [-Detailed]
 [-Status <CloudInstanceStatus>] [-Tag <hashtable>] [<CommonParameters>]
```

### AWS

```
Get-CloudInstance -Region <string> [-Provider <string>] [-Name <string>] [-Detailed]
 [-Status <CloudInstanceStatus>] [-Tag <hashtable>] [<CommonParameters>]
```

### All

```
Get-CloudInstance -All [-Detailed] [-Status <CloudInstanceStatus>] [-Tag <hashtable>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  gcin

## DESCRIPTION

Routes instance inventory requests to the matching provider backend and
returns normalized cloud record objects.

Use -All to query every provider that has an established session context,
returning instances from all connected clouds in one pipeline.

## EXAMPLES

### EXAMPLE 1

Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'

Gets Azure instances scoped to a resource group.

### EXAMPLE 2

Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg' -Name 'web-server-01'

Gets the Azure instance named web-server-01 within the resource group.

### EXAMPLE 3

Get-CloudInstance -Provider AWS -Region 'us-east-1'

Gets AWS instances for a region.

### EXAMPLE 4

Get-CloudInstance -Provider AWS -Region 'us-east-1' -Name 'app-server-01'

Gets the AWS instance with the matching Name tag or InstanceId.

### EXAMPLE 5

Get-CloudInstance -Provider GCP -Project 'my-project'

Gets GCP instances for a project.

### EXAMPLE 6

Get-CloudInstance -Provider GCP -Project 'my-project' -Name 'gcp-vm-01'

Gets the GCP instance with the matching instance name.

### EXAMPLE 7

Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg' -Name 'web-server-01' -Detailed

Gets the Azure instance with a richer, detail-focused view.

### EXAMPLE 8

Get-CloudInstance -All

Gets instances from all providers with an established session context.
Use after Connect-Cloud -Provider AWS, Azure, GCP.

### EXAMPLE 9

Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }

Gets all prod-tagged instances across every connected cloud.

### EXAMPLE 10

Get-CloudInstance -All -Status Running -Tag @{ environment = 'production' }

Gets all running instances with the production environment tag across all connected clouds.

## PARAMETERS

### -All

Query all providers with an established session context.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Detailed

Returns a richer display-oriented view of cloud records.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: GCP
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AWS
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Azure
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Name

The instance name to filter within the selected scope.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: GCP
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AWS
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Azure
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

The GCP project to query for instances.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: GCP
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Provider

The cloud provider to query.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: GCP
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AWS
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Azure
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Region

The AWS region to query for instances.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AWS
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ResourceGroup

The Azure resource group containing the target instances.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Azure
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Status

Filter results by instance status.

```yaml
Type: CloudInstanceStatus
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: GCP
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AWS
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Azure
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Tag

Filter results by tag key-value pairs.
All specified tags must match.

```yaml
Type: System.Collections.Hashtable
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: GCP
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AWS
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Azure
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

PSCumulus.CloudRecord or a vendor subclass (PSCumulus.AzureCloudRecord, PSCumulus.AWSCloudRecord, PSCumulus.GCPCloudRecord).

## NOTES

## RELATED LINKS

None.


