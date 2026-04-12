---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Connect-Cloud
---

# Connect-Cloud

## SYNOPSIS

Prepares a ready-to-use cloud session for the specified provider.

## SYNTAX

### Azure (Default)

```
Connect-Cloud -Provider <string[]> [-Tenant <string>] [-Subscription <string>] [<CommonParameters>]
```

### GCP

```
Connect-Cloud -Provider <string[]> -Project <string> [<CommonParameters>]
```

### AWS

```
Connect-Cloud -Provider <string[]> -Region <string> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  conc

## DESCRIPTION

Connect-Cloud is the session readiness command for PSCumulus.
It checks whether
the provider tools are installed, detects whether an active authentication session
already exists, triggers the provider-native login flow if one is needed, and stores
a normalized session context for the current PowerShell session.

After Connect-Cloud completes, the active provider is remembered so that later
commands can omit -Provider when the intent is unambiguous.

Pass an array to -Provider to connect multiple providers in one call:

    Connect-Cloud -Provider AWS, Azure, GCP

Per-provider context (account identity, scope, region, and connection time) is
stored separately for each provider.
Use Get-CloudContext to inspect all established
sessions.

## EXAMPLES

### EXAMPLE 1

Connect-Cloud -Provider Azure

Checks for an existing Azure session.
If none is found, triggers
Connect-AzAccount interactively, then stores the session context.

### EXAMPLE 2

Connect-Cloud -Provider Azure -Tenant '00000000-0000-0000-0000-000000000000' -Subscription 'my-subscription'

Connects to Azure without prompting for tenant or subscription selection.

### EXAMPLE 3

Connect-Cloud -Provider AWS -Region 'us-east-1'

Checks for existing AWS credentials.
If none are found, triggers
the AWS configuration flow, then stores the session context.

### EXAMPLE 4

Connect-Cloud -Provider GCP -Project 'my-project'

Checks for an active gcloud account.
If none is found, triggers
gcloud auth application-default login, then stores the session context.

### EXAMPLE 5

Connect-Cloud -Provider AWS, Azure, GCP

Connects all three providers in sequence.
Each gets its own stored context.
ActiveProvider is set to the last provider connected.

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

The cloud provider or providers to connect to.

```yaml
Type: System.String[]
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

### -Subscription

The Azure subscription to target for the connection context.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
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

### -Tenant

The Azure tenant to target for the connection context.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
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

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}


