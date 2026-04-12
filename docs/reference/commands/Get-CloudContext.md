---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Get-CloudContext
---

# Get-CloudContext

## SYNOPSIS

Returns the current PSCumulus session context for all connected providers.

## SYNTAX

### __AllParameterSets

```
Get-CloudContext [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  gcont

## DESCRIPTION

Shows all cloud providers that have been connected in this session, along with
the active account, scope, and region for each.
IsActive indicates which provider
is currently active for the session.

## EXAMPLES

### EXAMPLE 1

Get-CloudContext

Returns context entries for all providers connected in this session.

## PARAMETERS

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

