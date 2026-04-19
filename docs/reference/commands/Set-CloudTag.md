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

Sets tags or labels on a cloud resource across Azure, AWS, or GCP.

## SYNTAX

### Piped (Default)

```
Set-CloudTag -InputObject <psobject> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### AzureByName

```
Set-CloudTag -Name <string> -ResourceGroup <string> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### AzureById

```
Set-CloudTag -AzureResourceId <string> -Tags <hashtable> [-Merge] [-WhatIf] [-Confirm]
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

## ALIASES

This cmdlet has the following aliases,
  sct

## DESCRIPTION

Set-CloudTag applies tags (Azure), tags (AWS), or labels (GCP) to cloud resources.
For Azure, you can specify a VM by Name/ResourceGroup or any resource by ResourceId.
For AWS, provide the ResourceId and Region.
For GCP, provide the Project and Resource.
You can also pipe CloudRecord objects from other PSCumulus commands.

## EXAMPLES

### EXAMPLE 1

Set-CloudTag -Name 'vm01' -ResourceGroup 'rg-test' -Tags @{Environment='Dev'; Owner='TeamA'}

Tags an Azure VM by name and resource group.

### EXAMPLE 2

Set-CloudTag -AzureResourceId '/subscriptions/123/resourceGroups/rg/providers/Microsoft.Compute/disks/disk01' -Tags @{Backup='Weekly'}

Tags an Azure disk using its full resource ID (AzureById parameter set).

### EXAMPLE 3

Set-CloudTag -ResourceId 'i-1234567890abcdef0' -Region 'us-east-1' -Tags @{Environment='Prod'}

Tags an AWS EC2 instance by its resource ID.

### EXAMPLE 4

Set-CloudTag -Project 'my-project' -Resource 'projects/my/zones/us-central1-a/instances/vm01' -Tags @{Owner='Ops'}

Tags a GCP compute instance.

### EXAMPLE 5

Get-CloudDisk -Provider Azure | Set-CloudTag -Tags @{Encrypted='AES256'}

Tags all Azure disks returned from Get-CloudDisk (piped input).

## PARAMETERS

### -AzureResourceId

{{ Fill AzureResourceId Description }}

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AzureById
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

{{ Fill InputObject Description }}

```yaml
Type: System.Management.Automation.PSObject
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Piped
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Merge

{{ Fill Merge Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

{{ Fill Name Description }}

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AzureByName
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

{{ Fill Project Description }}

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

{{ Fill Region Description }}

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

{{ Fill Resource Description }}

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

{{ Fill ResourceGroup Description }}

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AzureByName
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

{{ Fill ResourceId Description }}

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

{{ Fill Tags Description }}

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

See the command description and examples above.

## OUTPUTS

### System.Management.Automation.PSObject

See the command description and examples above.

## NOTES

## RELATED LINKS

None.


