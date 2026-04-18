---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Set-CloudTag
---

# Set-CloudTag

## SYNOPSIS

Sets tags or labels on cloud resources across Azure, AWS, and GCP.

## SYNTAX

### Piped (Default)

```
Set-CloudTag -InputObject <CloudRecord> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Azure

```
Set-CloudTag -Name <string> -ResourceGroup <string> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### AWS

```
Set-CloudTag -ResourceId <string> -Region <string> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### GCP

```
Set-CloudTag -Project <string> -Resource <string> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Path

```
Set-CloudTag -Path <string> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  sct

## DESCRIPTION

Sets tags or labels on cloud resources across Azure, AWS, and GCP.
Use -Merge to combine with existing tags instead of replacing them.

## EXAMPLES

### Example 1

Set-CloudTag -Name 'web-01' -ResourceGroup 'prod-rg' -Tags @{Environment = 'Prod'; Owner = 'Adil'}

Sets tags on an Azure VM, replacing any existing tags.

### Example 2

Set-CloudTag -ResourceId 'i-12345' -Region 'us-east-1' -Tags @{Environment = 'Prod'} -Merge

Adds or updates the Environment tag on an AWS EC2 instance while preserving existing tags.

### Example 3

Get-CloudInstance -Name 'gcp-vm' | Set-CloudTag -Tags @{CostCenter = '12345'} -Merge

Adds a CostCenter tag to a GCP instance using pipeline input, preserving existing tags.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

A PSCumulus cloud record piped from Get-CloudInstance or other Get-* commands.

```yaml
Type: System.Management.Automation.PSObject
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Piped
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Merge

Merge the specified tags with existing tags on the resource. If not specified, all existing tags are replaced.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
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

The Azure resource name.

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

### -Path

A cloud path string (e.g., 'Azure:\prod-rg\Instances\web-01')

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Path
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

The GCP project containing the target resource.

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

### -Region

The AWS region where the resource resides.

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

### -Resource

The GCP resource path (e.g., 'projects/test/zones/us-central1-a/instances/vm01')

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

### -ResourceGroup

The Azure resource group containing the target resource.

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

### -ResourceId

The AWS resource identifier (e.g., EC2 instance ID).

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

### -Tags

A hashtable of tags to set on the resource.

```yaml
Type: System.Collections.Hashtable
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
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

### System.Management.Automation.PSObject

PSCumulus cloud records from Get-CloudInstance or other Get-* commands.

## OUTPUTS

### System.Management.Automation.PSObject

Cloud records with updated tags.

## NOTES

## RELATED LINKS

[Get-CloudInstance](./Get-CloudInstance.md)


