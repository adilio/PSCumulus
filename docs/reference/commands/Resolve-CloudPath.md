---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Resolve-CloudPath
---

# Resolve-CloudPath

## SYNOPSIS

Parses a cloud path string into a structured CloudPath object.

## SYNTAX

### __AllParameterSets

```
Resolve-CloudPath [-Path] <string> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  None

## DESCRIPTION

Resolve-CloudPath converts a cloud path string into a structured CloudPath object
that can be used for path-based operations.
The path format is:

    {Provider}:\{Scope}\{Kind}\{ResourceName}

Where Provider is Azure, AWS, or GCP; Scope is resource group/region/project;
Kind is Instances, Disks, Storage, Networks, Functions, or Tags; and
ResourceName is the specific resource name.

## EXAMPLES

### EXAMPLE 1

Resolve-CloudPath 'Azure:\prod-rg\Instances\web-server-01'

Parses the full Azure instance path.

### EXAMPLE 2

'AWS:\us-east-1\Disks' | Resolve-CloudPath

Parses an AWS disk container path via pipeline.

### EXAMPLE 3

Resolve-CloudPath 'GCP:\my-project'

Parses a GCP project scope path.

## PARAMETERS

### -Path

The cloud path string to parse.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

### System.String

See the command description and examples above.

## OUTPUTS

### CloudPath

See the command description and examples above.

## NOTES

## RELATED LINKS

None.


