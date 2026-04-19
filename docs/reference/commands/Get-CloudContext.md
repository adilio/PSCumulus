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
Get-CloudContext [[-Provider] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  gcont

## DESCRIPTION

Shows all cloud providers that have been connected in this session, along with
the active account, scope, and region for each.
ConnectionState shows whether a
provider is the current active session context or simply connected in the session.
IsActive is retained as a compatibility flag and is only populated for the current
provider.

Use -Provider to filter the output to a specific provider.

## EXAMPLES

### EXAMPLE 1

Get-CloudContext

Returns context entries for all providers connected in this session.

### EXAMPLE 2

Get-CloudContext -Provider Azure

Returns context entry only for Azure.

## PARAMETERS

### -Provider

Filter to a specific provider.

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


