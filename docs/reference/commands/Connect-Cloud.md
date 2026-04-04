---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
ms.date: 04-04-2026
PlatyPS schema version: 2024-05-01
title: Connect-Cloud
---

# Connect-Cloud

## SYNOPSIS

Connects to a cloud provider using the PSCumulus abstraction.

## SYNTAX

### Azure (Default)

```
Connect-Cloud -Provider <string> [<CommonParameters>]
```

### GCP

```
Connect-Cloud -Provider <string> -Project <string> [<CommonParameters>]
```

### AWS

```
Connect-Cloud -Provider <string> -Region <string> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  cc

## DESCRIPTION

Routes a provider-specific connection request to the matching backend
implementation for Azure, AWS, or GCP.

## EXAMPLES

### EXAMPLE 1

Connect-Cloud -Provider Azure

Connects to Azure using the Azure backend.

### EXAMPLE 2

Connect-Cloud -Provider AWS -Region 'us-east-1'

Connects to AWS using the region-aware backend path.

### EXAMPLE 3

Connect-Cloud -Provider GCP -Project 'my-project'

Connects to GCP using the project-aware backend path.

## PARAMETERS

### -Project

The GCP project to target for the connection context.

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

The cloud provider to connect to.

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
- Name: AWS
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
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

### -Region

The AWS region to target for the connection context.

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


