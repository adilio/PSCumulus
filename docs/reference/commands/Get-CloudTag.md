---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Get-CloudTag
---

# Get-CloudTag

## SYNOPSIS

Gets resource tags or labels from a selected cloud provider.

## SYNTAX

### All

```
Get-CloudTag [-Provider <string>] [-ResourceId <string>] [-Project <string>] [-Resource <string>]
 [-All] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  None

## DESCRIPTION

Routes resource metadata requests to the matching provider backend for
Azure, AWS, or GCP.

Use -All to query every provider that has an established session context,
returning tags/labels from all connected clouds in one pipeline.

## EXAMPLES

### EXAMPLE 1

Get-CloudTag -Provider Azure -ResourceId '/subscriptions/.../virtualMachines/vm01'

Gets Azure tags for a resource identifier.

### EXAMPLE 2

Get-CloudTag -Provider AWS -ResourceId 'i-0123456789abcdef0'

Gets AWS tags for a resource identifier.

### EXAMPLE 3

Get-CloudTag -Provider GCP -Project 'my-project' -Resource 'instances/vm-01'

Gets GCP labels for a project-scoped resource.

### EXAMPLE 4

Get-CloudTag -All

Gets tags/labels from all providers with an established session context.
Note: This returns a representative sample of tags per provider based on
stored context (region for AWS, resource group for Azure, project for GCP).
Use after Connect-Cloud -Provider AWS, Azure, GCP.

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
  IsRequired: false
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

### -Provider

The cloud provider to query.

```yaml
Type: System.String
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

### -Resource

The GCP resource path used to resolve labels.

```yaml
Type: System.String
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

### -ResourceId

The provider resource identifier for Azure or AWS.

```yaml
Type: System.String
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}


