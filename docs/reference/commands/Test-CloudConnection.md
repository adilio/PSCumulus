---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Test-CloudConnection
---

# Test-CloudConnection

## SYNOPSIS

Tests the validity of stored cloud provider credentials.

## SYNTAX

### All

```
Test-CloudConnection [-Provider <string>] [-All] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  tci

## DESCRIPTION

Tests whether stored credentials for cloud providers are still valid.
Makes a lightweight read-only API call to verify authentication.
Returns connection test results without throwing on auth failure.

When run without parameters, defaults to testing all providers (equivalent to -All).

## EXAMPLES

### EXAMPLE 1

Test-CloudConnection -Provider Azure

Tests Azure credentials validity.

### EXAMPLE 2

Test-CloudConnection -All

Tests all stored provider credentials.

### EXAMPLE 3

Test-CloudConnection

Tests all stored provider credentials (equivalent to -All).

### EXAMPLE 4

Test-CloudConnection -All | Where-Object { -not $_.Connected }

Shows all providers with invalid or expired credentials.

## PARAMETERS

### -All

Test all providers with stored credentials.

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

### -Provider

The cloud provider to test.

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

See the command description and examples above.

## NOTES

## RELATED LINKS

None.


