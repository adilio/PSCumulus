---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Get-CloudRegion
---

# Get-CloudRegion

## SYNOPSIS

Lists supported regions for each cloud provider.

## SYNTAX

### __AllParameterSets

```
Get-CloudRegion [[-Provider] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  None

## DESCRIPTION

Returns all supported regions for Azure, AWS, or GCP.
Use this to discover
valid region values for Connect-Cloud and other provider-specific commands.

## EXAMPLES

### EXAMPLE 1

Get-CloudRegion

Returns all regions for all providers.

### EXAMPLE 2

Get-CloudRegion -Provider Azure

Returns only Azure regions.

### EXAMPLE 3

Get-CloudRegion -Provider AWS | Where-Object { $_.Name -like 'us-*' }

Returns AWS regions in the US.

## PARAMETERS

### -Provider

The cloud provider to list regions for.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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


