---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Find-CloudResource
---

# Find-CloudResource

## SYNOPSIS

Searches for cloud resources by name across providers and resource kinds.

## SYNTAX

### __AllParameterSets

```
Find-CloudResource [-Name] <string> [-Provider <string[]>] [-Kind <string[]>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  fcr

## DESCRIPTION

Find-CloudResource performs a cross-kind, cross-cloud search for resources by name.
Use this when you know a resource name but not whether it's a VM, disk, storage account,
network, or function, or when you need to search multiple clouds simultaneously.

Wildcards are supported in the -Name parameter.

## EXAMPLES

### EXAMPLE 1

Find-CloudResource -Name 'payment-svc-03'

Searches all providers and all resource kinds for 'payment-svc-03'.

### EXAMPLE 2

Find-CloudResource -Name 'prod-*' -Provider Azure, AWS

Searches Azure and AWS for any resource starting with 'prod-'.

### EXAMPLE 3

Find-CloudResource -Name 'web-*' -Kind Instance, Network

Searches for instances and networks with names starting with 'web-'.

### EXAMPLE 4

Find-CloudResource -Name '*test*' -Provider GCP -Kind Storage

Searches GCP storage resources for names containing 'test'.

## PARAMETERS

### -Kind

Limit search to specific resource kinds.
If not specified, searches all kinds.

```yaml
Type: System.String[]
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

The resource name to search for.
Wildcards are supported.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: true
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Provider

Limit search to specific providers.
If not specified, searches all connected providers.

```yaml
Type: System.String[]
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

See the command description and examples above.

## NOTES

## RELATED LINKS

None.



