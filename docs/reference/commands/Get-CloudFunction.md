---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
ms.date: 04-04-2026
PlatyPS schema version: 2024-05-01
title: Get-CloudFunction
---

# Get-CloudFunction

## SYNOPSIS

Gets serverless functions from a selected cloud provider.

## SYNTAX

### Azure (Default)

```
Get-CloudFunction -ResourceGroup <string> [-Provider <string>] [<CommonParameters>]
```

### GCP

```
Get-CloudFunction -Project <string> [-Provider <string>] [<CommonParameters>]
```

### AWS

```
Get-CloudFunction -Region <string> [-Provider <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  None

## DESCRIPTION

Routes function inventory requests to the matching provider backend and
returns normalized cloud record objects for the serverless compute surface.

## EXAMPLES

### EXAMPLE 1

Get-CloudFunction -Provider Azure -ResourceGroup 'prod-rg'

Gets Azure Function Apps in a resource group.

### EXAMPLE 2

Get-CloudFunction -Provider AWS -Region 'us-east-1'

Gets AWS Lambda functions in a region.

### EXAMPLE 3

Get-CloudFunction -Provider GCP -Project 'my-project'

Gets GCP Cloud Functions for a project.

## PARAMETERS

### -Project

The GCP project to query for Cloud Functions.

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

The AWS region to query for Lambda functions.

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

The Azure resource group containing the target Function Apps.

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


